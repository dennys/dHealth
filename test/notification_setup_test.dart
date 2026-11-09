import 'package:dhealth/generated/l10n/app_localizations.dart';
import 'package:dhealth/settings_model.dart';
import 'package:dhealth/widgets/notification_setup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// `DropdownButton` 的 `value:` 一定要在 `items` 裡，否則 debug 模式直接 assertion、
/// release 顯示空白（看不到目前值）。這兩顆 dropdown 的現值可以是清單外的任意值：
/// 「自訂」頻率存 45（`_clampMinutes` 只夾 15..1440）、motivation 時限是 0..24 的任意小時，
/// 所以必須走 value=null + hint 的寫法（同 `setup.dart`）。這裡鎖住它不要改回去。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(WidgetTester tester, Map<String, Object> initial) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData(initial);
    final model = await SettingsModel.load();
    await tester.pumpWidget(ChangeNotifierProvider<SettingsModel>.value(
      value: model,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const NotificationSetupScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('自訂頻率 45（不在清單）：不崩，且看得到目前值', (tester) async {
    await pump(tester, {'notification_frequency': 45});

    expect(tester.takeException(), isNull);
    expect(find.text('45 minutes'), findsOneWidget, reason: '不在 items 時要用 hint 顯示現值');
  });

  testWidgets('motivation 時限 3 小時（不在清單）：不崩，且看得到目前值', (tester) async {
    await pump(tester, {'notification_motivation': true, 'notification_motivation_time_limit': 3});

    expect(tester.takeException(), isNull);
    expect(find.text('3 hours'), findsOneWidget);
  });

  testWidgets('清單內的值照樣正常顯示（hint 寫法沒有把預設值弄壞）', (tester) async {
    await pump(tester, {'notification_frequency': 30});

    expect(tester.takeException(), isNull);
    expect(find.text('30 minutes'), findsOneWidget);
  });
}
