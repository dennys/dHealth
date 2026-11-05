import 'package:dhealth/database/database.dart';
import 'package:dhealth/utils/step_calculator.dart';
import 'package:test/test.dart';

void main() {
  group('StepCalculator', () {
    final testSteps = [
      DailyStep(date: '2025-03-01', stepCount: 1000, lastUpdated: DateTime.now(), isComplete: true),
      DailyStep(date: '2025-03-02', stepCount: 2000, lastUpdated: DateTime.now(), isComplete: true),
      DailyStep(date: '2025-03-10', stepCount: 1500, lastUpdated: DateTime.now(), isComplete: true),
      // DailyStep(date: '2025-03-30', stepCount: 10, lastUpdated: DateTime.now(), isComplete: true),
      DailyStep(date: '2025-04-01', stepCount: 3000, lastUpdated: DateTime.now(), isComplete: true),
    ];

    test('calculateDailySteps filters and limits correctly', () {
      final result = StepCalculator.calculateDailySteps(testSteps, DateTime(2025, 3, 9), 2);
      expect(result.length, 2);
      expect(result[0].date, '2025-03-10');
      expect(result[1].date, '2025-04-01');
    });

    test('calculateWeeklySteps groups by week correctly', () {
      final result = StepCalculator.calculateWeeklySteps(
        testSteps,
        DateTime(2025, 2, 24), // Start before March
        2,
      );
      expect(result.length, 2);
      // expect(result[0].stepCount, 4500); // Week of March 1: 1000 + 2000 + 1500
      expect(result[1].stepCount, 3000); // Week of April 1
      expect(DateTime.parse(result[0].date).weekday, 1); // Starts on Monday
    });

    test('calculateMonthlySteps groups by month correctly', () {
      final result = StepCalculator.calculateMonthlySteps(testSteps, DateTime(2025, 2, 1), 2);
      expect(result.length, 2);
      expect(result[0].date, '2025-03-01');
      expect(result[0].stepCount, 4500); // March: 1000 + 2000 + 1500
      expect(result[1].date, '2025-04-01');
      expect(result[1].stepCount, 3000); // April
    });

    test('calculateAverageSteps computes correctly', () {
      final steps = [
        DailyStep(date: '2025-03-01', stepCount: 1000, lastUpdated: DateTime.now(), isComplete: true),
        DailyStep(date: '2025-03-02', stepCount: 2000, lastUpdated: DateTime.now(), isComplete: true),
      ];
      expect(StepCalculator.calculateAverageSteps(steps), 1500.0);
      expect(StepCalculator.calculateAverageSteps([]), 0);
    });
  });
}
