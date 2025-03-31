// lib/utils/weekday_utils.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

enum Weekday {
  monday(1, 'Monday'),
  tuesday(2, 'Tuesday'),
  wednesday(3, 'Wednesday'),
  thursday(4, 'Thursday'),
  friday(5, 'Friday'),
  saturday(6, 'Saturday'),
  sunday(7, 'Sunday');

  final int value;
  final String name;

  const Weekday(this.value, this.name);

  static Weekday fromValue(int value) {
    return values.firstWhere(
      (weekday) => weekday.value == value,
      orElse: () => Weekday.monday, // Default fallback
    );
  }
}

class WeekdayUtils {
  static const String _weekStartKey = 'week_start_day';

  static Future<Weekday> getWeekStartDay() async {
    try {
      // 1.1 Try to get from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedValue = prefs.getInt(_weekStartKey);

      if (storedValue != null) {
        return Weekday.fromValue(storedValue);
      }

      // 1.2 If not found, get from system locale using intl
      // Get first day of week based on current locale
      final locale = Intl.getCurrentLocale();
      // This is a simplified approach; actual implementation might vary
      // Many countries use Monday (1), US uses Sunday (7)
      final defaultDay = locale.startsWith('en_US') ? 7 : 1;
      return Weekday.fromValue(defaultDay);
    } catch (e) {
      // Fallback to Monday in case of any errors
      return Weekday.monday;
    }
  }

  // Optional: Method to set the week start day
  static Future<void> setWeekStartDay(Weekday weekday) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_weekStartKey, weekday.value);
  }
}

// Example usage
void main() async {
  final weekStart = await WeekdayUtils.getWeekStartDay();
  print('Week starts on: ${weekStart.name}');

  // Set new week start
  await WeekdayUtils.setWeekStartDay(Weekday.sunday);
}
