import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../di.dart';
import '../settings_keys.dart';
import '../utils/log.dart';
import 'data_service.dart';
import 'notification_service.dart';

/// WorkManager 的任務識別碼；改名要記得已安裝的舊任務會留在系統裡（既有代碼用
/// com.example.* 是範例殘留，本檔是本案自己的 task）。
const String stepTrackerTask = 'com.dennys.dhealth.step_tracker';

/// 背景 isolate 的進入點。這裡面每個 await 都要包好：拋出未處理例外時 WorkManager
/// 只會把任務標記失敗，使用者什麼都看不到。
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != stepTrackerTask) return true;
    try {
      // 背景 isolate 有自己的 GetIt，之前從沒 register 過（所以舊版從來沒把同步結果寫進 DB）。
      await configureDependencies();
      // 通知插件是 per-isolate 的：只在 UI 那側 initialize() 過，背景這條 isolate 沒過，
      // createNotification 就永遠发不出去（而且被 catch 吃掉，看不出問題）。
      await NotificationService.initialize();
      await BackgroundService.executeTask();
      return true;
    } catch (e, st) {
      appError('Workmanager 任務異常', e, st);
      return false;
    }
  });
}

/// 該發哪一種通知。**純函數**，不做 IO —— 這是本案最容易測、也最容易錯的一段。
enum StepAlert { goalReached, almostThere, none }

/// 依步數與設定決定通知種類（純函數）。
///
/// [steps] 為 null 代表讀不到步數：這才是真的「例外」，值得發錯誤通知（而且要在
/// 使用者開了「例外」通知時才發）。之前是反過來的 —— 正常未達標也會發
/// "Error Occurred: Not fit any criteria."，等於每 15 分鐘使用者就被叫一次「出錯了」。
StepAlert decideStepAlert({required int? steps, required int dailyStepGoal, required int almostThereMargin}) {
  if (steps == null) return StepAlert.none; // 錯誤由呼叫端走 _exception 那條路
  if (dailyStepGoal <= 0) return StepAlert.none;
  if (steps >= dailyStepGoal) return StepAlert.goalReached;
  if (dailyStepGoal - steps <= almostThereMargin) return StepAlert.almostThere;
  return StepAlert.none;
}

class BackgroundService {
  BackgroundService._();

  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher);
    await scheduleTask();
  }

  /// 依目前設定（重）排周期任務。設定頁改動後呼叫這個，不是 init()。
  static Future<void> scheduleTask() async {
    final prefs = SharedPreferencesAsync();
    final interval = await prefs.getInt(Prefs.syncFrequency) ?? PrefsDefaults.syncFrequencyMinutes;
    final dailyStepGoal = await prefs.getInt(Prefs.dailyStepGoal) ?? PrefsDefaults.dailyStepGoal;

    await Workmanager().cancelByUniqueName(stepTrackerTask);

    if (!(await prefs.getBool(Prefs.healthSyncEnabled) ?? PrefsDefaults.healthSyncEnabled)) {
      appLog('背景同步已停用，不排程');
      return;
    }

    await Workmanager().registerPeriodicTask(
      stepTrackerTask,
      stepTrackerTask,
      frequency: Duration(minutes: interval.clamp(15, 24 * 60)),
      initialDelay: const Duration(seconds: 30),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      inputData: <String, dynamic>{'dailyStepGoal': dailyStepGoal},
    );

    appLog('已排定背景同步，每 $interval 分鐘');
  }

  /// 一次背景同步：讀步數 → 寫 DB → （照設定）發通知。
  ///
  /// inputData 只當「排程當時的目標快照」用；真正比對前一律以 prefs 現值為準，
  /// 否則使用者改了目標，還要等舊的排程資料被替換掉才生效。
  static Future<void> executeTask([Map<String, dynamic>? inputData]) async {
    final prefs = SharedPreferencesAsync();
    // 一律以 prefs 現值為準：inputData 是「排程當時」的快照，拿它會讓使用者改了目標
    // 之後還要等排程被替換才生效（本檔上方的註解講的就是這件事，之前的程式碼做反了）。
    final dailyStepGoal = await prefs.getInt(Prefs.dailyStepGoal) ?? inputData?['dailyStepGoal'] as int? ?? PrefsDefaults.dailyStepGoal;

    final result = await _service().syncNewData();

    switch (result.status) {
      case StepSyncStatus.permissionDenied:
      case StepSyncStatus.unavailable:
      case StepSyncStatus.invalidRange:
        // 文字由 NotificationService 那邊用 l10n 取（背景 isolate 沒有 context），
        // 技術細節留在 result.detail 裡，我們這裡已經 appError 過。
        appLog('背景同步未成功：${result.status.name}');
        await _notifyException(result.status);
        return;
      case StepSyncStatus.success:
        break;
    }

    // 只在同步成功的時候才讀今天的步數：失敗那次讀到的也是舊資料，照樣會被上面的
    // 分支丟掉，白讀一趟 DB。
    final int? steps = await _todayStepCount();

    final settings = await _NotificationSettings.read(prefs);
    if (!settings.enabled) return;

    // 先講備份：它跟今天的步數無關，而且同步失敗那趟已經在上面 return 掉了，
    // 不會在 Health Connect 壞掉的時候又加一顆通知騷擾人。
    await _maybeRemindBackup(settings);

    // 同步成功後「DB 沒有今天的列」有兩種成因，處理不同：
    //   今天讀到 0 步 → 正當的 0，本來就無通知可發（decideStepAlert(0) 也是 none）；
    //   今天讀不到（只跳過今天）且沒有舊列可保留 → 未知。舊版這種讀取失敗會把整個
    //   sync 帶進例外通知路，2ad6e9c 改「只跳過今天」後它變成什麼都不發的靜默
    //   （decideStepAlert(steps:null) 直接 none），所以這裡補回例外路。
    if (steps == null) {
      if (result.todaySkipped) {
        appLog('背景同步成功但今天讀不到（無舊值可保留），發例外通知');
        await _notifyException(StepSyncStatus.unavailable);
      }
      return;
    }

    final alert = decideStepAlert(
      steps: steps,
      dailyStepGoal: dailyStepGoal,
      almostThereMargin: PrefsDefaults.almostThereStepMargin,
    );

    switch (alert) {
      case StepAlert.goalReached:
        if (settings.reachGoal && await NotificationService.canSend(Prefs.reachGoal, settings.frequencyMinutes, settings.window)) {
          if (await NotificationService.showGoalReached(steps, dailyStepGoal)) {
            await NotificationService.markSent(Prefs.reachGoal);
          }
        }
      case StepAlert.almostThere:
        final gap = dailyStepGoal - steps;
        if (settings.motivation && await NotificationService.canSend(Prefs.motivation, settings.motivationMinutes, settings.window)) {
          if (await NotificationService.showAlmostThere(steps, gap, dailyStepGoal)) {
            await NotificationService.markSent(Prefs.motivation);
          }
        }
      case StepAlert.none:
        break;
    }
  }

  static Future<int?> _todayStepCount() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final row = await _service().database.getDailyStep(midnight);
    return row?.stepCount;
  }

  /// 只在使用者開了「例外」通知、且現在在通知時段內時才發。
  static Future<void> _notifyException(StepSyncStatus reason) async {
    final prefs = SharedPreferencesAsync();
    final settings = await _NotificationSettings.read(prefs);
    if (!settings.enabled || !settings.exception) return;
    if (!await NotificationService.canSend(Prefs.exception, settings.frequencyMinutes, settings.window)) return;
    if (await NotificationService.showSyncError(reason)) {
      await NotificationService.markSent(Prefs.exception);
    }
  }

  /// 「距上次成功匯出幾天」的算法（純函式，抽出來是為了能測）。
  ///
  /// [lastExportAtMs] 為 null = 從沒匯出過 → 回門檻值（=「該提醒」），是否真的要念
  /// 由呼叫端再確認資料庫已經有資料可備份。時間是負的（使用者把時鐘往後調）當作
  /// 剛剛匯出過，不念 —— 與 `PetStats.hungerAfterAbsence` 同一個處理基準。
  @visibleForTesting
  static int daysSinceExport({
    int? lastExportAtMs,
    DateTime? now,
    int thresholdDays = PrefsDefaults.backupStaleDays,
  }) {
    if (lastExportAtMs == null) return thresholdDays;
    final days = (now ?? DateTime.now()).difference(DateTime.fromMillisecondsSinceEpoch(lastExportAtMs)).inDays;
    return days < 0 ? 0 : days;
  }

  /// 太久沒匯出就提醒一次：`allowBackup="false"` 之後匯出是唯一備份路，
  /// 而這件事使用者不會自己想到。節流沿用同一套 `canSend`（一個 frequencyMinutes 一顆），
  /// 也只在通知時段內發。
  ///
  /// 「從沒匯出過」也提醒，但要先真的有資料可備份（剛裝好就催是騷擾）。
  static Future<void> _maybeRemindBackup(_NotificationSettings settings) async {
    final prefs = SharedPreferencesAsync();
    if (await _service().database.getLastDate() == null) return;

    final staleDays = daysSinceExport(lastExportAtMs: await prefs.getInt(Prefs.lastExportAt));
    if (staleDays < PrefsDefaults.backupStaleDays) return;

    if (!await NotificationService.canSend(Prefs.backupReminder, settings.frequencyMinutes, settings.window)) return;
    if (await NotificationService.showBackupStale(staleDays)) {
      await NotificationService.markSent(Prefs.backupReminder);
    }
  }

  static StepDataService _service() {
    // 背景 isolate 有自己的 GetIt，裡面的 Health/StepDatabase 由外掛自行重建；
    // 沒註冊過的話這裡會丟例外，由 callbackDispatcher 接住並標記任務失敗。
    return GetIt.instance<StepDataService>();
  }
}

/// 通知相關設定的快照（同一次任務裡讀一次就好，不要每處各讀各的預設值）。
class _NotificationSettings {
  const _NotificationSettings({
    required this.enabled,
    required this.reachGoal,
    required this.motivation,
    required this.exception,
    required this.frequencyMinutes,
    required this.motivationMinutes,
    required this.window,
  });

  final bool enabled;
  final bool reachGoal;
  final bool motivation;
  final bool exception;
  final int frequencyMinutes;
  final int motivationMinutes;
  final NotificationWindow window;

  static Future<_NotificationSettings> read(SharedPreferencesAsync prefs) async {
    final enabled = await prefs.getBool(Prefs.notificationsEnabled) ?? PrefsDefaults.notificationsEnabled;
    final frequency = (await prefs.getInt(Prefs.notificationFrequency) ?? PrefsDefaults.notificationFrequencyMinutes).clamp(15, 24 * 60);
    final limitHours = (await prefs.getInt(Prefs.motivationTimeLimit) ?? PrefsDefaults.motivationTimeLimitHours).clamp(0, 24);

    final startHour = await prefs.getInt(Prefs.activeStartHour) ?? PrefsDefaults.activeStartHour;
    final endHour = await prefs.getInt(Prefs.activeEndHour) ?? PrefsDefaults.activeEndHour;

    return _NotificationSettings(
      enabled: enabled,
      reachGoal: await prefs.getBool(Prefs.reachGoal) ?? PrefsDefaults.reachGoal,
      motivation: await prefs.getBool(Prefs.motivation) ?? PrefsDefaults.motivation,
      exception: await prefs.getBool(Prefs.exception) ?? PrefsDefaults.exception,
      frequencyMinutes: frequency,
      motivationMinutes: (limitHours * 60).clamp(frequency, 24 * 60),
      window: NotificationWindow(startHour: startHour, endHour: endHour),
    );
  }
}
