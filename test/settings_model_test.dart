import 'package:dhealth/settings_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SettingsModel> loadedModel() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final model = SettingsModel();
    await pumpEventQueue(); // ctor 裡的 _loadPreferences() 沒被 await
    return model;
  }

  // 全部 setter 用同一張表掃過：設定的 bug 幾乎都是同一類 copy-paste
  // （把值賦給錯的欄位，或賦成別的欄位的 getter）。之前 setActiveEndHour、
  // setShowDailyStepGoal、setStopOnTerminate 各中過一次，而這些都沒有測試。
  // (名稱, setter, getter, 期待值)
  final cases =
      <(String, Future<void> Function(SettingsModel), Object Function(SettingsModel), Object)>[
    ('language', (m) => m.setLanguage('ja'), (m) => m.language, 'ja'),
    ('theme', (m) => m.setTheme('dark'), (m) => m.theme, 'dark'),
    ('healthSyncEnabled', (m) => m.setHealthSyncEnabled(false), (m) => m.healthSyncEnabled, false),
    ('syncFrequency', (m) => m.setSyncFrequency(30), (m) => m.syncFrequency, 30),
    ('activeStartHour', (m) => m.setActiveStartHour(6), (m) => m.activeStartHour, 6),
    ('activeEndHour', (m) => m.setActiveEndHour(22), (m) => m.activeEndHour, 22),
    ('startOnBoot', (m) => m.setStartOnBoot(false), (m) => m.startOnBoot, false),
    ('stopOnTerminate', (m) => m.setStopOnTerminate(true), (m) => m.stopOnTerminate, true),
    ('persistentSync', (m) => m.setPersistentSync(true), (m) => m.persistentSync, true),
    ('showCumulative', (m) => m.setShowCumulative(false), (m) => m.showCumulative, false),
    ('showDailyStepGoal', (m) => m.setShowDailyStepGoal(true), (m) => m.showDailyStepGoal, true),
    ('priority', (m) => m.setPriority('high'), (m) => m.priority, 'high'),
    ('notificationFrequency', (m) => m.setNotificationFrequency(60), (m) => m.notificationFrequency, 60),
    ('motivationTimeLimit', (m) => m.setMotivationTimeLimit(3), (m) => m.motivationTimeLimit, 3),
    ('reachGoal', (m) => m.setReachGoal(false), (m) => m.reachGoal, false),
    ('motivation', (m) => m.setMotivation(false), (m) => m.motivation, false),
    ('exception', (m) => m.setException(false), (m) => m.exception, false),
    ('accomplishment', (m) => m.setAccomplishment(false), (m) => m.accomplishment, false),
    ('soundEnabled', (m) => m.setSoundEnabled(false), (m) => m.soundEnabled, false),
    ('vibrationEnabled', (m) => m.setVibrationEnabled(false), (m) => m.vibrationEnabled, false),
    ('startTime', (m) => m.setStartTime(const TimeOfDay(hour: 9, minute: 30)), (m) => m.startTime,
        const TimeOfDay(hour: 9, minute: 30)),
    ('endTime', (m) => m.setEndTime(const TimeOfDay(hour: 23, minute: 15)), (m) => m.endTime,
        const TimeOfDay(hour: 23, minute: 15)),
  ];

  group('SettingsModel：setter 要寫進自己對應的欄位', () {
    for (final (name, setter, getter, expected) in cases) {
      test(name, () async {
        final model = await loadedModel();
        await setter(model);
        expect(getter(model), expected, reason: '$name 的 setter 賦值不對');
      });
    }
  });

  // 這三個 setter 會 unawaited 呼叫 BackgroundService.init()（Workmanager 的 pigeon
  // channel），在純 unit test 裡去 mock 十來個 channel 不值得，改成只驗「存檔有落地」：
  group('SettingsModel：帶背景排程副作用的 setter', () {
    test('dailyStepGoal / notificationsEnabled / notificationFrequency 存進 SharedPreferences', () async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      final model = SettingsModel();
      await pumpEventQueue();

      await model.setDailyStepGoal(8000);
      await model.setNotificationsEnabled(false);
      await model.setNotificationFrequency(45);

      final prefs = SharedPreferencesAsync();
      expect(await prefs.getInt('dailyStepGoal'), 8000);
      expect(await prefs.getBool('notification_enabled'), false);
      expect(await prefs.getInt('notification_frequency'), 45);
    });
  });
}
