import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings_keys.dart';
import '../utils/log.dart';

/// 本案只需要「讀步數」，所以授权範圍就固定在 STEPS / READ 這一組。
///
/// 之前是對 dataTypesAndroid 的 33 個類型全部要 READ_WRITE（心跳、血壓、血糖、經期…），
/// 而 app 一個都沒讀：除了每次授權對話框要按到爽，上架審查也會被問「為什麼計步器要讀經期」。
/// 同理不再要求 Location —— 計步不需要，Health Connect 也不拿它當作步數的條件。
const List<HealthDataType> stepTypes = [HealthDataType.STEPS];
const List<HealthDataAccess> stepPermissions = [HealthDataAccess.READ];

/// 授權失敗的原因；由 UI 決定要顯示什麼文字（不在這裡塞字串）。
enum PermissionFailure {
  activityRecognition, // Android 上用 Sensor 數步數的權限，沒有就永遠 0 步
  healthRead, // Health Connect 對 STEPS 的讀取授權
}

/// 所有權限相關的唯一入口。
class PermissionService {
  PermissionService._();

  /// 取得讀步數所需的全部權限。
  ///
  /// 回傳 null 代表「可以開始讀步數」；回傳 [PermissionFailure] 代表關鍵權限拿不到，
  /// 呼叫端必須讓使用者看得见（舊版把每個 return false 都註解掉，結果恆回 true，
  /// 於是在使用者面前讀到 0 步看起來像「今天真的沒走路」而不是「沒權限」）。
  ///
  /// 通知、歷史資料（>30 天）、背景讀取这三項是**加分項**：拿不到就少個功能，
  /// 不該讓整個 app 進不去，所以只在這裡記錄、不當成失敗。
  static Future<PermissionFailure?> requestStepAccess({bool wantNotifications = true}) async {
    final health = GetIt.I<Health>();

    try {
      // 不在這裡 openAppSettings()：選單是「一次性的」，而這條是每次進場都會走的路徑，
      // 一旦使用者選過「拒絕且不再詢問」，就會變成「一開 app 就被丟到系統設定頁」的迴圈。
      // UI 有橫幅 + Retry 按鈕，要改權限由使用者自己按。
      if (Platform.isAndroid && !await Permission.activityRecognition.request().isGranted) {
        return PermissionFailure.activityRecognition;
      }

      final bool? hasRead = await health.hasPermissions(stepTypes, permissions: stepPermissions);
      if (hasRead != true) {
        final authorized = await health.requestAuthorization(stepTypes, permissions: stepPermissions);
        if (!authorized) return PermissionFailure.healthRead;
      }

      // 以下三項非關鍵：失敗只記 log，不影響回傳值。
      await _requestOptionalNotifications(wantNotifications);
      await _requestOptional(
        '健康資料歷史（>30 天）',
        () => health.isHealthDataHistoryAuthorized(),
        () => health.requestHealthDataHistoryAuthorization(),
      );
      await _requestOptional(
        '背景健康資料讀取',
        () => health.isHealthDataInBackgroundAuthorized(),
        () => health.requestHealthDataInBackgroundAuthorization(),
      );
      return null;
    } catch (error, stackTrace) {
      appError('requestStepAccess 異常', error, stackTrace);
      return PermissionFailure.healthRead;
    }
  }

  static Future<void> _requestOptionalNotifications(bool wantNotifications) async {
    if (!wantNotifications) return;
    final prefs = SharedPreferencesAsync();
    if (!(await prefs.getBool(Prefs.notificationsEnabled) ?? PrefsDefaults.notificationsEnabled)) return;

    // 同上：不自動跳系統設定頁，只記下來（通知是加分項，沒給就用不到通知而已）。
    if (!await Permission.notification.request().isGranted) {
      appLog('通知權限未取得（非關鍵）');
    }
  }

  static Future<void> _requestOptional(String label, Future<bool> Function() isGranted, Future<bool> Function() request) async {
    try {
      if (await isGranted()) return;
      await request();
    } catch (e) {
      appLog('$label 未取得（非關鍵）：$e');
    }
  }
}
