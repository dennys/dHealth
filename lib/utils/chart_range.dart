// utils/chart_range.dart
import 'package:intl/intl.dart';

/// 首頁圖表的日期區間，起訖皆為當地日期 00:00，含首尾。
class ChartRange {
  ChartRange._(this.start, this.end, this.presetDays);

  /// 以 [today] 為結尾的最近 [days] 天。
  factory ChartRange.preset(int days, DateTime today) {
    final end = _dateOnly(today);
    return ChartRange._(end.subtract(Duration(days: days - 1)), end, days);
  }

  factory ChartRange.custom(DateTime start, DateTime end) => ChartRange._(_dateOnly(start), _dateOnly(end), null);

  final DateTime start;
  final DateTime end;

  /// 預設區間的天數；自訂區間為 null。
  final int? presetDays;

  static const List<int> presets = [7, 30, 90];

  int get dayCount => end.difference(start).inDays + 1;

  /// 等長、緊接在 [start] 之前的區間，用來算「上一期平均」。
  ChartRange get previous => ChartRange._(start.subtract(Duration(days: dayCount)), start.subtract(const Duration(days: 1)), null);

  /// 預設區間存天數（如 `7`）；自訂區間存日期（如 `2024-01-01|2024-02-01`）。
  String encode() => presetDays != null ? '$presetDays' : '${_format(start)}|${_format(end)}';

  /// 解析失敗時回到最近 7 天。
  static ChartRange decode(String raw, DateTime today) {
    final parts = raw.split('|');
    if (parts.length == 2) {
      final start = DateTime.tryParse(parts[0]);
      final end = DateTime.tryParse(parts[1]);
      if (start != null && end != null && !start.isAfter(end)) return ChartRange.custom(start, end);
    }
    final days = int.tryParse(raw);
    if (days != null && days > 0) return ChartRange.preset(days, today);
    return ChartRange.preset(7, today);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _format(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
}
