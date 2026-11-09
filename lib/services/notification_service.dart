import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../generated/l10n/app_localizations.dart';
import '../settings_keys.dart';
import '../utils/sync_reason.dart';
import 'data_service.dart';
import '../utils/log.dart';

/// 通知時段（設定頁的 Start/End Time）。跨午夜（例如 22 → 7）也算對。
class NotificationWindow {
  const NotificationWindow({required this.startHour, required this.endHour});

  final int startHour;
  final int endHour;

  bool contains(DateTime time) {
    final hour = time.hour;
    if (startHour <= endHour) return hour >= startHour && hour <= endHour;
    return hour >= startHour || hour <= endHour; // 跨午夜
  }
}

/// 步數通知的發送端。
///
/// 三件以前不對的事都在这里處理掉：
/// 1. 除錯殘留 `showErrorNotification("debug for steps: …")` 放在每次成功讀取的
///    路徑上 —— 使用者每 15 分鐘收到一顆「Error Occurred: Something went wrong:
///    debug for steps: 4312」。正常未達標也走 else 發錯誤通知，一樣。
/// 2. 權限沒給時回 999 步被當成測量值，對預設 300 步的目標就發「Goal Reached!
///    你走了 999 步」。現在錯誤就是錯誤，不會憑空恭喜。
/// 3. 設定頁的「通知類型 / 音訊 / 震動 / 重要性 / 通知時段」全都没接；現在接了。
class NotificationService {
  static const String _defaultChannel = 'dhealth_step_tracker_channel';
  static const String _lastSentPrefix = 'notification_last_sent_';

  /// 建通知管道。聲音／震動／重要性屬於 **channel** 等級（Android 會快取 channel），
  /// 所以在啟動時從設定讀一次；之後改了要下次啟動才生效 —— 這是平台限制，不是實作偷工。
  static Future<void> initialize() async {
    final l10n = _l10n();
    final prefs = SharedPreferencesAsync();
    final sound = await prefs.getBool(Prefs.soundEnabled) ?? PrefsDefaults.soundEnabled;
    final vibration = await prefs.getBool(Prefs.vibrationEnabled) ?? PrefsDefaults.vibrationEnabled;
    final priority = await prefs.getString(Prefs.priority) ?? PrefsDefaults.priority;

    await AwesomeNotifications().initialize(
      'resource://drawable/ic_stat_notification',
      [
        NotificationChannel(
          channelKey: _defaultChannel,
          channelName: l10n.notificationChannelName,
          channelDescription: l10n.notificationChannelDescription,
          defaultColor: Colors.green,
          ledColor: Colors.white,
          playSound: sound,
          enableVibration: vibration,
          importance: switch (priority) {
            'low' => NotificationImportance.Low,
            'high' => NotificationImportance.High,
            _ => NotificationImportance.Default,
          },
        ),
      ],
    );
  }

  /// 背景 isolate 沒有 BuildContext，用裝置語系直接取字串（不支援的語系會 fallback 到英文）。
  static AppLocalizations _l10n() => lookupAppLocalizations(PlatformDispatcher.instance.locale);

  /// 現在該不該發這一類通知：在時段內、且距上次【真的發出去】超過間隔。
  ///
  /// **只判斷、不留記錄** —— 記錄要等真的顯示成功後由 [markSent] 寫。
  /// 之前是判斷的同時就寫時間戳，結果「通知權限還沒給」或「建立通知失敗」那幾種情況
  /// 也會把節流槽燒掉，使用者連一顆通知都沒看到，卻要再等一個 frequencyMinutes。
  /// 任何一步出錯都採保守做法（發）：通知是加分功能，不該讓整個同步任務失敗。
  static Future<bool> canSend(String kindKey, int minIntervalMinutes, NotificationWindow window, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    if (!window.contains(at)) return false;

    try {
      final last = await SharedPreferencesAsync().getInt('$_lastSentPrefix$kindKey');
      return last == null || at.difference(DateTime.fromMillisecondsSinceEpoch(last)) >= Duration(minutes: minIntervalMinutes);
    } catch (e) {
      appError('通知節流狀態讀取失敗，照常發送', e);
      return true;
    }
  }

  /// 記下「這一類剛剛真的發出去了」，供 [canSend] 節流。
  static Future<void> markSent(String kindKey, {DateTime? now}) async {
    try {
      await SharedPreferencesAsync().setInt('$_lastSentPrefix$kindKey', (now ?? DateTime.now()).millisecondsSinceEpoch);
    } catch (e) {
      appError('記錄通知發送時間失敗', e);
    }
  }

  /// 回傳「是否真的顯示了」，呼叫端據此決定要不要 [markSent]。
  static Future<bool> showGoalReached(int steps, int goal) async {
    final l10n = _l10n();
    return _show(title: l10n.stepGoalReachedTitle, body: l10n.stepGoalReachedBody(steps));
  }

  static Future<bool> showAlmostThere(int steps, int gap, int goal) async {
    final l10n = _l10n();
    return _show(title: l10n.motivationTitle, body: l10n.motivationBody(gap, goal));
  }

  /// 只在「真的出錯」時用（讀不到 Health Connect、沒授權…）。正常未達標不是錯誤。
  ///
  /// 收的是 `StepSyncStatus`（原因）而不是字串：服務層不吐使用者文字，
  /// 否則英文介面就會混出硬編的中文。
  static Future<bool> showSyncError(StepSyncStatus reason) async {
    final l10n = _l10n();
    return _show(title: l10n.errorNotificationTitle, body: l10n.errorNotificationBody(reason.label(l10n)));
  }

  /// 「備份可能過期」。`allowBackup="false"` 之後匯出是唯一備份路，
  /// 這件事不能假裝使用者自己會想到（而且現在完全沒提醒）。
  static Future<bool> showBackupStale(int days) async {
    final l10n = _l10n();
    return _show(title: l10n.backupReminderTitle, body: l10n.backupReminderBody(days));
  }

  static Future<bool> _show({required String title, required String body}) async {
    try {
      // 背景 isolate 沒有 Activity，不能在這裡 request 權限（那要 UI 走 PermissionService）。
      // 沒授權就靜默跳過：通知是加分功能，不該因此讓同步任務失敗。
      if (!await Permission.notification.isGranted) return false;

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          channelKey: _defaultChannel,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
        ),
      );
      return true;
    } catch (e) {
      appError('發通知失敗', e);
      return false;
    }
  }
}
