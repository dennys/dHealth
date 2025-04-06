// test/weekday_utils_test.dart
import 'package:dsteps/utils/weekday_utils.dart'; // Adjust import path
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('WeekdayUtils', () {
    setUp(() {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('week_start_day', Weekday.wednesday.value);

      final result = await WeekdayUtils.getWeekStartDay();
      expect(result, Weekday.wednesday);
    });

    test('getWeekStartDay returns default when no stored value', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final result = await WeekdayUtils.getWeekStartDay();
      // Depending on test environment locale, this might be monday or sunday
      expect([Weekday.monday, Weekday.sunday].contains(result), true);
    });

    test('setWeekStartDay stores value correctly', () async {
      await WeekdayUtils.setWeekStartDay(Weekday.friday);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('week_start_day'), Weekday.friday.value);
    });
  });
}
