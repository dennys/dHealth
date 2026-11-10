/// 所有 SharedPreferences 的 key 與預設值，全案唯一定義處。
///
/// 之前「每日目標」同時存在于 settings_model(6000)、background_service(300/327)、
/// main(300) 四個地方，改一處漏三處 —— 背景和 foreground 看到的目標不一樣，
/// 於是有人的通知是「走 300 步就恭喜」，有人永遠等不到。
/// UI（SettingsModel）與背景 isolate（BackgroundService）一律從這裡取，
/// 不再各自寫字面值。
class Prefs {
  Prefs._();

  // Interface
  static const language = 'language';
  static const theme = 'theme';
  static const weekStartDay = 'week_start_day';

  // Health data sync
  static const healthSyncEnabled = 'health_sync_enabled';
  static const syncFrequency = 'health_sync_frequency'; // 分鐘
  static const activeStartHour = 'health_sync_active_start_hour';
  static const activeEndHour = 'health_sync_active_end_hour';

  // Display
  static const showCumulative = 'showCumulative';
  static const showDailyStepGoal = 'showDailyStepGoal';
  static const dailyStepGoal = 'dailyStepGoal';

  // Notifications
  static const notificationPrefix = 'notification_';
  static const notificationsEnabled = '${notificationPrefix}enabled';
  static const notificationFrequency = '${notificationPrefix}frequency';
  static const reachGoal = '${notificationPrefix}reach_goal';
  static const motivation = '${notificationPrefix}motivation';
  static const motivationTimeLimit = '${notificationPrefix}motivation_time_limit';
  static const exception = '${notificationPrefix}exception';
  static const soundEnabled = '${notificationPrefix}sound_enabled';
  static const vibrationEnabled = '${notificationPrefix}vibration_enabled';
  static const priority = '${notificationPrefix}priority';

  // Charts
  static const dailyChartRange = 'dailyChartRange';

  // Backup（allowBackup=false 之後，匯出是使用者唯一的備份路）
  static const lastExportAt = 'last_export_at';
  static const backupReminder = '${notificationPrefix}backup_reminder';
}

/// 預設值。同一個語意只准出現一次。
class PrefsDefaults {
  PrefsDefaults._();

  static const language = 'system';
  static const theme = 'system';

  static const healthSyncEnabled = true;
  static const syncFrequencyMinutes = 15;
  static const activeStartHour = 7;
  static const activeEndHour = 23;

  static const showCumulative = true;
  static const showDailyStepGoal = false;
  static const dailyStepGoal = 6000;
  /// 見 `ChartRange.encode`：預設最近 7 期（日圖 = 7 天、週圖 = 7 週、月圖 = 7 月）。
  static const dailyChartRange = '7';

  static const notificationsEnabled = true;
  static const notificationFrequencyMinutes = 15;
  static const reachGoal = true;
  static const motivation = true;
  static const motivationTimeLimitHours = 1;
  static const exception = true;
  static const soundEnabled = true;
  static const vibrationEnabled = true;
  static const priority = 'default';

  /// 距上次成功匯出超過這麼多天就提醒一次（見 `BackgroundService._maybeRemindBackup`）。
  static const backupStaleDays = 14;

  /// 「差多少步以內」算「就差一點點」，發鼓勵通知而不是什麼都不做。
  static const almostThereStepMargin = 1000;

  /// 首次同步往回取幾天（資料庫完全沒資料時）。
  static const firstSyncLookbackDays = 30;

  // Frequency options offered on both settings pages; also the test for
  // "is the stored value one of ours" reads this, so the lists cannot drift.
  static const List<int> frequencyPresets = [15, 30, 60];
}
