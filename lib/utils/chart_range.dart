// utils/chart_range.dart

/// 首頁圖表的期數 N 與頁碼 P：顯示「往前第 P 頁、每頁 N 期」。
/// 「期」由每張圖自己解讀 —— 日圖是 N 天、週圖是 N 週、月圖是 N 個月。
class ChartRange {
  const ChartRange(this.periods, this.offset, this.today);

  static const List<int> presets = [7, 30, 90];

  /// 每頁的期數。
  final int periods;

  /// 0 = 最近一頁，1 = 往前一頁（每頁往回 [periods] 期）。
  final int offset;

  final DateTime today;

  /// 往前一頁，用來算「上一期平均」。
  ChartRange get previous => ChartRange(periods, offset + 1, today);

  ChartRange shifted(int newOffset) => ChartRange(periods, newOffset, today);

  /// 往前 [offset] 頁、共 [periods] 天（含首尾）。
  ({DateTime from, DateTime to, int periods}) days() {
    final to = _dateOnly(today).subtract(Duration(days: periods * offset));
    return (from: to.subtract(Duration(days: periods - 1)), to: to, periods: periods);
  }

  /// 往前 [offset] 頁、共 [periods] 週（起點對齊週一）。
  ({DateTime from, DateTime to, int periods}) weeks() {
    final to = _dateOnly(today).subtract(Duration(days: 7 * periods * offset));
    final from = to.subtract(Duration(days: 7 * (periods - 1) + to.weekday - 1));
    return (from: from, to: to, periods: periods);
  }

  /// 往前 [offset] 頁、共 [periods] 個月（起點對齊月初）。
  ({DateTime from, DateTime to, int periods}) months() {
    final t = _dateOnly(today);
    final to = DateTime(t.year, t.month - periods * offset, t.day);
    return (from: DateTime(to.year, to.month - periods + 1, 1), to: to, periods: periods);
  }

  String encode() => '$periods';

  /// 解析失敗（含舊版存的日期區間 `a|b`）時回到最近 7 期。
  static ChartRange decode(String raw, int offset, DateTime today) {
    final periods = int.tryParse(raw);
    return ChartRange(periods != null && periods > 0 ? periods : 7, offset, today);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
