import 'package:dhealth/settings_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _weekStartKey = Prefs.weekStartDay;

  /// 使用者存過的週首日；沒存過就用 [localeDefault]（呼叫端從
  /// `MaterialLocalizations.of(context).datePickerFirstDayOfTheWeek` 拿 —— 那個才是
  /// 本地化資料的正確來源），都沒有则退回週一。
  static Future<Weekday> getWeekStartDay({Weekday? localeDefault}) async {
    try {
      final stored = await SharedPreferencesAsync().getInt(_weekStartKey);
      if (stored != null) return Weekday.fromValue(stored);
      return localeDefault ?? Weekday.monday;
    } catch (_) {
      return Weekday.monday;
    }
  }

  // Optional: Method to set the week start day
  static Future<void> setWeekStartDay(Weekday weekday) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setInt(_weekStartKey, weekday.value);
  }
}

