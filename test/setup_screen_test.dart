import 'package:dhealth/di.dart';
import 'package:dhealth/generated/l10n/app_localizations.dart';
import 'package:dhealth/services/background_service.dart';
import 'package:dhealth/settings_model.dart';
import 'package:dhealth/widgets/setup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'settings_model_test.mocks.dart'; // MockBackgroundService

/// 設定頁的開關「綁對欄位沒有」—— 這是這頁反覆中過的 bug 類型（copy-paste 時把
/// `value:` 留成上一顆開關的 getter），而 setter 表掃不到它：setter 本身是對的，
/// 錯的是 UI 讀的欄位。所以直接在 widget 層驗。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // 會重排背景同步的 setter 走 getIt<BackgroundService>()；mock 掉，
    // widget test 不碰 Workmanager 的 pigeon channel。
    await getIt.reset();
    getIt.registerSingleton<BackgroundService>(MockBackgroundService());
  });

  tearDown(() async => getIt.reset());

  Future<SettingsModel> pumpSetup(WidgetTester tester, Map<String, Object> initial) async {
    // ListView 是 lazy 的：視窗不够高時「顯示設定」那區根本沒被 build，find 會找不到元素。
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData(initial);
    final model = await SettingsModel.load();
    await tester.pumpWidget(ChangeNotifierProvider<SettingsModel>.value(
      value: model,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const SetupScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    return model;
  }

  SwitchListTile tile(WidgetTester tester, String title) => tester
      .widgetList<SwitchListTile>(find.byType(SwitchListTile))
      .firstWhere((t) => (t.title as Text).data == title);

  testWidgets('兩顆顯示開關各自讀自己的欄位（每日目標那顆曾誤綁 showCumulative）', (tester) async {
    // 故意讓兩個值相反：綁錯的話這裡一定斷得掉
    final model = await pumpSetup(tester, {'showCumulative': false, 'showDailyStepGoal': true});

    expect(tile(tester, 'Show cumulative steps').value, isFalse);
    expect(tile(tester, 'Show daily step goal').value, isTrue);

    await tester.tap(find.byWidget(tile(tester, 'Show daily step goal')));
    await tester.pumpAndSettle();

    expect(model.showDailyStepGoal, isFalse, reason: '點每日目標的開關就要改每日目標');
    expect(model.showCumulative, isFalse, reason: '不能順手改到另一顆的值');
  });

  testWidgets('每日目標輸入不合法時會講一句話，並維持原值', (tester) async {
    final model = await pumpSetup(tester, {'dailyStepGoal': 6000});
    final field = find.byType(TextField); // 這頁只有每日目標那顆欄位（自訂頻率的欄位在 dialog 裡）

    await tester.enterText(field, '500');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('The daily step goal must be between 1000 and 20000'), findsOneWidget);
    expect(model.dailyStepGoal, 6000);

    await tester.enterText(field, '8000');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(model.dailyStepGoal, 8000);
  });

  testWidgets('同步頻率 60 分鐘顯示為 1 小時（不是 60 minutes）', (tester) async {
    await pumpSetup(tester, {'health_sync_frequency': 60, 'health_sync_enabled': true});
    await tester.pumpAndSettle();

    expect(find.text('1 hr'), findsOneWidget);
  });
}
