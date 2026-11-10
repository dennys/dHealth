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

    test('calculateDailySteps 補零：缺的天補 0，而不是只取有資料的列', () {
      final result = StepCalculator.calculateDailySteps(testSteps, DateTime(2025, 3, 9), 2);
      expect(result.length, 2);
      expect(result[0].date, '2025-03-09');
      expect(result[0].stepCount, 0); // 03-09 沒有列 → 補 0
      expect(result[1].date, '2025-03-10');
      expect(result[1].stepCount, 1500);
    });

    // REVIEW #3 的 1.75× 案例：最近 7 天只有 4 天有步數（3 天 0 步沒有列）。
    // 舊行為只取 4 列 → 平均 2500；補零後是 7 根柱子、平均 10000/7。
    test('calculateDailySteps：7 天裡 3 天缺列 → 7 根柱子、平均按 7 天算', () {
      final steps = [
        DailyStep(date: '2025-03-05', stepCount: 1000, lastUpdated: DateTime.now(), isComplete: true),
        DailyStep(date: '2025-03-06', stepCount: 2000, lastUpdated: DateTime.now(), isComplete: true),
        DailyStep(date: '2025-03-08', stepCount: 3000, lastUpdated: DateTime.now(), isComplete: true),
        DailyStep(date: '2025-03-11', stepCount: 4000, lastUpdated: DateTime.now(), isComplete: true),
      ];
      final result = StepCalculator.calculateDailySteps(steps, DateTime(2025, 3, 5), 7);
      expect(result.length, 7);
      expect(result.map((s) => s.stepCount).toList(), [1000, 2000, 0, 3000, 0, 0, 4000]);
      expect(StepCalculator.calculateAverageSteps(result), 10000 / 7);
    });

    test('calculateWeeklySteps 補零：缺的週補 0（對齊週一）', () {
      final result = StepCalculator.calculateWeeklySteps(testSteps, DateTime(2025, 2, 24), 3);
      expect(result.length, 3);
      expect(result[0].date, '2025-02-24'); // 週一
      expect(result[0].stepCount, 3000); // 03-01 + 03-02
      expect(result[1].date, '2025-03-03');
      expect(result[1].stepCount, 0); // 該週沒有列 → 補 0
      expect(result[2].date, '2025-03-10');
      expect(result[2].stepCount, 1500);
    });

    test('calculateMonthlySteps 補零：缺的月補 0（對齊月初）', () {
      final result = StepCalculator.calculateMonthlySteps(testSteps, DateTime(2025, 2, 1), 3);
      expect(result.length, 3);
      expect(result[0].date, '2025-02-01');
      expect(result[0].stepCount, 0); // 二月沒有列 → 補 0
      expect(result[1].date, '2025-03-01');
      expect(result[1].stepCount, 4500); // 1000 + 2000 + 1500
      expect(result[2].date, '2025-04-01');
      expect(result[2].stepCount, 3000);
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
