// utils/step_calculator.dart
import 'package:dhealth/database/database.dart';
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
}
