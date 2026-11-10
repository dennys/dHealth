// utils/step_calculator.dart
import 'package:dhealth/database/database.dart';
import 'package:intl/intl.dart';

class StepCalculator {
  /// 把 [steps] 補成 [startDate] 起共 [periods] 天的完整日期序列：缺的天補 0。
  ///
  /// 0 步的天在 DB 裡沒有列（`data_service` 只寫 steps > 0），若只取「有資料的
  /// 最後 N 列」，「最近 7 天」會變成「最近 7 個有步數的天」—— 平均與上一頁
  /// 比較都會高估（7 天裡 3 天 0 步時，平均最多高估 1.75 倍）。
  static List<DailyStep> calculateDailySteps(List<DailyStep> steps, DateTime startDate, int periods) {
    final byDate = <String, int>{};
    for (final step in steps) {
      if (DateTime.tryParse(step.date) == null || step.stepCount < 0) continue;
      byDate[step.date] = step.stepCount;
    }
    final fmt = DateFormat('yyyy-MM-dd');
    return List.generate(periods, (i) {
      final day = startDate.add(Duration(days: i));
      final key = fmt.format(day);
      return DailyStep(date: key, stepCount: byDate[key] ?? 0, lastUpdated: day, isComplete: true);
    });
  }

  /// 按週聚合（對齊週一），再補成 [startDate] 所在週起共 [periods] 週：缺的週補 0。
  static List<DailyStep> calculateWeeklySteps(List<DailyStep> steps, DateTime startDate, int periods) {
    final byWeek = <DateTime, int>{};
    for (final step in steps) {
      final date = DateTime.tryParse(step.date);
      if (date == null || step.stepCount < 0) continue;
      final weekStart = date.subtract(Duration(days: date.weekday - 1));
      byWeek[weekStart] = (byWeek[weekStart] ?? 0) + step.stepCount;
    }
    final fmt = DateFormat('yyyy-MM-dd');
    final firstWeek = startDate.subtract(Duration(days: startDate.weekday - 1));
    return List.generate(periods, (i) {
      final weekStart = firstWeek.add(Duration(days: 7 * i));
      return DailyStep(date: fmt.format(weekStart), stepCount: byWeek[weekStart] ?? 0, lastUpdated: DateTime.now(), isComplete: true);
    });
  }

  /// 按月聚合（對齊月初），再補成 [startDate] 所在月起共 [periods] 月：缺的月補 0。
  static List<DailyStep> calculateMonthlySteps(List<DailyStep> steps, DateTime startDate, int periods) {
    final byMonth = <DateTime, int>{};
    for (final step in steps) {
      final date = DateTime.tryParse(step.date);
      if (date == null || step.stepCount < 0) continue;
      final monthStart = DateTime(date.year, date.month, 1);
      byMonth[monthStart] = (byMonth[monthStart] ?? 0) + step.stepCount;
    }
    final fmt = DateFormat('yyyy-MM-dd');
    return List.generate(periods, (i) {
      final monthStart = DateTime(startDate.year, startDate.month + i, 1);
      return DailyStep(date: fmt.format(monthStart), stepCount: byMonth[monthStart] ?? 0, lastUpdated: DateTime.now(), isComplete: true);
    });
  }

  static double calculateAverageSteps(List<DailyStep> steps) {
    final validSteps = steps.where((step) => step.stepCount >= 0).toList();
    return validSteps.isEmpty ? 0 : validSteps.map((e) => e.stepCount).reduce((a, b) => a + b) / validSteps.length;
  }
}
