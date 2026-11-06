import 'package:dhealth/database/database.dart';
import 'package:dhealth/utils/step_calculator.dart';
import 'package:health/health.dart';
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

  group('hourlyDistribution', () {
    final today = DateTime(2025, 3, 10);

    HealthDataPoint point(DateTime from, DateTime to, int steps, {HealthDataType type = HealthDataType.STEPS}) => HealthDataPoint(
      uuid: '\$from-\$steps',
      value: NumericHealthValue(numericValue: steps),
      type: type,
      unit: HealthDataUnit.COUNT,
      dateFrom: from,
      dateTo: to,
      sourcePlatform: HealthPlatformType.googleHealthConnect,
      sourceDeviceId: 'd',
      sourceId: 's',
      sourceName: 'app',
      recordingMethod: RecordingMethod.automatic,
      workoutSummary: null,
    );

    test('同一小時內直接計入', () {
      final result = StepCalculator.hourlyDistribution([point(DateTime(2025, 3, 10, 8, 5), DateTime(2025, 3, 10, 8, 40), 120)], today);
      expect(result[8], 120);
      expect(result.values.where((v) => v > 0).length, 1);
    });

    test('跨小時按秒數比例分配（2 小時走 300 步 → 每小時 150）', () {
      final result = StepCalculator.hourlyDistribution([point(DateTime(2025, 3, 10, 8, 0), DateTime(2025, 3, 10, 10, 0), 300)], today);
      expect(result[8], 150);
      expect(result[9], 150);
      expect(result.values.fold(0, (a, b) => a + b), 300);
    });

    test('今天以前的資料點不計、非 STEPS 類型不計', () {
      final result = StepCalculator.hourlyDistribution([
        point(DateTime(2025, 3, 9, 8), DateTime(2025, 3, 9, 9), 999),
        point(DateTime(2025, 3, 10, 7), DateTime(2025, 3, 10, 7, 30), 50, type: HealthDataType.HEART_RATE),
      ], today);
      expect(result.values.every((v) => v == 0), isTrue);
    });

    test('零長度的資料點不會炸掉（除以 0）', () {
      final at = DateTime(2025, 3, 10, 12);
      final result = StepCalculator.hourlyDistribution([point(at, at, 42)], today);
      expect(result[12], 42);
    });
  });
}
