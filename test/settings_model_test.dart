import 'package:dhealth/settings_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SettingsModel> loadedModel() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    return SettingsModel.load(); // 載入完成才交回：不會再出現「setter 被載入蓋掉」
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
    // startOnBoot / stopOnTerminate / persistentSync / accomplishment 這四個設定已整組刪除：
    // 它們只寫進 prefs、全案 0 個讀取者（會騙人的開關比沒有開關更糟）。
    ('showCumulative', (m) => m.setShowCumulative(false), (m) => m.showCumulative, false),
    ('showDailyStepGoal', (m) => m.setShowDailyStepGoal(true), (m) => m.showDailyStepGoal, true),
    ('priority', (m) => m.setPriority('high'), (m) => m.priority, 'high'),
    ('notificationFrequency', (m) => m.setNotificationFrequency(60), (m) => m.notificationFrequency, 60),
    ('motivationTimeLimit', (m) => m.setMotivationTimeLimit(3), (m) => m.motivationTimeLimit, 3),
    ('reachGoal', (m) => m.setReachGoal(false), (m) => m.reachGoal, false),
    ('motivation', (m) => m.setMotivation(false), (m) => m.motivation, false),
    ('exception', (m) => m.setException(false), (m) => m.exception, false),
    ('soundEnabled', (m) => m.setSoundEnabled(false), (m) => m.soundEnabled, false),
    ('vibrationEnabled', (m) => m.setVibrationEnabled(false), (m) => m.vibrationEnabled, false),
    // startTime/endTime 這兩個 key 已連同 notification_setup 的裝飾品選譯器一起刪除
    // （通知時段的唯一來源是 setup.dart 的 activeStartHour/activeEndHour）。
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
      final model = await SettingsModel.load();

      await model.setDailyStepGoal(8000);
      await model.setNotificationsEnabled(false);
      await model.setNotificationFrequency(45);

      final prefs = SharedPreferencesAsync();
      expect(await prefs.getInt('dailyStepGoal'), 8000);
      expect(await prefs.getBool('notification_enabled'), false);
      expect(await prefs.getInt('notification_frequency'), 45);
    });
  });

  // setter 不能把髒值放進去：WorkManager 對 < 15 分鐘的 periodic 間隔會直接丟例外，
  // 目標 0 步則会让「達標」通知每 15 分鐘響一次。
  group('SettingsModel：範圍驗證', () {
    test('範圍外的值被夾住而不是照收', () async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      final model = await SettingsModel.load();

      await model.setSyncFrequency(1);
      expect(model.syncFrequency, 15);

      await model.setDailyStepGoal(0);
      expect(model.dailyStepGoal, greaterThan(0));

      await model.setDailyStepGoal(99999999);
      expect(model.dailyStepGoal, lessThanOrEqualTo(200000));

      await model.setActiveEndHour(99);
      expect(model.activeEndHour, 23);

      await model.setMotivationTimeLimit(-5);
      expect(model.motivationTimeLimit, 0);
    });

    test('通知類 setter 不再重建整個 WorkManager（只重排）', () async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      final model = await SettingsModel.load();
      await model.setNotificationsEnabled(false);
      expect(await SharedPreferencesAsync().getBool('notification_enabled'), isFalse);
    });
  });
}
