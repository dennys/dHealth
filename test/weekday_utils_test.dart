// test/weekday_utils_test.dart
import 'package:dsteps/utils/weekday_utils.dart'; // Adjust import path
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';

void main() {
  group('WeekdayUtils', () {
    setUp(() {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    });

    test('Weekday enum values are correct', () {
      expect(Weekday.monday.value, 1);
      expect(Weekday.sunday.value, 7);
      expect(Weekday.tuesday.name, 'Tuesday');
    });

    test('fromValue returns correct weekday', () {
      expect(Weekday.fromValue(1), Weekday.monday);
      expect(Weekday.fromValue(7), Weekday.sunday);
      expect(Weekday.fromValue(999), Weekday.monday); // Default fallback
    });

    test('getWeekStartDay returns stored value when set', () async {
      // Set mock value
      final prefs = SharedPreferencesAsync();
      await prefs.setInt('week_start_day', Weekday.wednesday.value);

      final result = await WeekdayUtils.getWeekStartDay();
      expect(result, Weekday.wednesday);
    });

    test('getWeekStartDay returns default when no stored value', () async {
      final prefs = SharedPreferencesAsync();
      await prefs.clear();

      final result = await WeekdayUtils.getWeekStartDay();
      // Depending on test environment locale, this might be monday or sunday
      expect([Weekday.monday, Weekday.sunday].contains(result), true);
    });

    test('setWeekStartDay stores value correctly', () async {
      await WeekdayUtils.setWeekStartDay(Weekday.friday);
      final prefs = SharedPreferencesAsync();
      expect(await prefs.getInt('week_start_day'), Weekday.friday.value);
    });
  });
}
