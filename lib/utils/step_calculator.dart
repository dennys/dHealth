// utils/step_calculator.dart
import 'package:dhealth/database/database.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';

class StepCalculator {
  static List<DailyStep> calculateDailySteps(List<DailyStep> steps, DateTime startDate, int periods) {
    final filteredSteps =
        steps.where((step) {
            try {
              final date = DateTime.parse(step.date);
              return date.isAfter(startDate.subtract(const Duration(days: 1))) && step.stepCount >= 0;
            } catch (e) {
              return false; // 無效日期則排除
            }
          }).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return filteredSteps.length > periods ? filteredSteps.sublist(filteredSteps.length - periods) : filteredSteps;
  }

  static List<DailyStep> calculateWeeklySteps(List<DailyStep> steps, DateTime startDate, int periods) {
    final filteredSteps =
        steps.where((step) {
          try {
            final date = DateTime.parse(step.date);
            return date.isAfter(startDate.subtract(const Duration(days: 1))) && step.stepCount >= 0;
          } catch (e) {
            return false; // 無效日期則排除
          }
        }).toList();

    final Map<DateTime, int> weeklySteps = <DateTime, int>{};
    for (final DailyStep step in filteredSteps) {
      final DateTime date = DateTime.parse(step.date);
      final DateTime weekStart = date.subtract(Duration(days: date.weekday - 1));
      weeklySteps[weekStart] = (weeklySteps[weekStart] ?? 0) + step.stepCount;
    }

    final List<DailyStep> sortedWeeks =
        weeklySteps.entries
            .map((e) => DailyStep(date: DateFormat('yyyy-MM-dd').format(e.key), stepCount: e.value, lastUpdated: DateTime.now(), isComplete: true))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return sortedWeeks.length > periods ? sortedWeeks.sublist(sortedWeeks.length - periods) : sortedWeeks;
  }

  static List<DailyStep> calculateMonthlySteps(List<DailyStep> steps, DateTime startDate, int periods) {
    final filteredSteps =
        steps.where((step) {
          try {
            final date = DateTime.parse(step.date);
            return date.isAfter(startDate.subtract(const Duration(days: 1))) && step.stepCount >= 0;
          } catch (e) {
            return false;
          }
        }).toList();

    final Map<DateTime, int> monthlySteps = <DateTime, int>{};
    for (final DailyStep step in filteredSteps) {
      final DateTime date = DateTime.parse(step.date);
      final DateTime monthStart = DateTime(date.year, date.month, 1);
      monthlySteps[monthStart] = (monthlySteps[monthStart] ?? 0) + step.stepCount;
    }

    final List<DailyStep> sortedMonths =
        monthlySteps.entries
            .map((e) => DailyStep(date: DateFormat('yyyy-MM-dd').format(e.key), stepCount: e.value, lastUpdated: DateTime.now(), isComplete: true))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return sortedMonths.length > periods ? sortedMonths.sublist(sortedMonths.length - periods) : sortedMonths;
  }

  static double calculateAverageSteps(List<DailyStep> steps) {
    final validSteps = steps.where((step) => step.stepCount >= 0).toList();
    return validSteps.isEmpty ? 0 : validSteps.map((e) => e.stepCount).reduce((a, b) => a + b) / validSteps.length;
  }

  /// 把每個步數資料點依時間攤到它涵蓋的幾個小時（跳小時按秒數比例分配）。
  /// 小於 [todayStart] 的資料點不計（小時圖只看今天）。
  static Map<int, int> hourlyDistribution(List<HealthDataPoint> points, DateTime todayStart) {
    final distribution = <int, int>{for (var i = 0; i < 24; i++) i: 0};

    void add(int hour, int steps) => distribution[hour] = (distribution[hour] ?? 0) + steps;

    for (final data in points) {
      if (data.type != HealthDataType.STEPS) continue;
      final value = data.value;
      if (value is! NumericHealthValue) continue;
      if (data.dateFrom.isBefore(todayStart)) continue;

      final steps = value.numericValue.toInt();
      if (steps == 0) continue;

      final totalSeconds = data.dateTo.difference(data.dateFrom).inSeconds;
      if (data.dateFrom.hour == data.dateTo.hour || totalSeconds <= 0) {
        add(data.dateFrom.hour, steps);
        continue;
      }

      var current = data.dateFrom;
      var remaining = steps;
      while (current.isBefore(data.dateTo)) {
        var hourEnd = DateTime(current.year, current.month, current.day, current.hour, 59, 59);
        if (hourEnd.isAfter(data.dateTo)) hourEnd = data.dateTo;
        final share = (hourEnd.difference(current).inSeconds / totalSeconds * steps).round();
        add(current.hour, share);
        remaining -= share;
        current = hourEnd.add(const Duration(seconds: 1));
      }
      if (remaining > 0) add(data.dateTo.hour, remaining);
    }
    return distribution;
  }
}
