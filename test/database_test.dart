import 'package:drift/native.dart';
import 'package:dhealth/database/database.dart';
import 'package:test/test.dart';

void main() {
  late StepDatabase db;

  setUp(() async {
    // Use NativeDatabase.memory() for in-memory testing
    db = StepDatabase(NativeDatabase.memory());

    // Insert test data
    await db.upsertDailyStep('2025-02-13', 40, DateTime.now(), isComplete: true);
    await db.upsertDailyStep('2025-02-14', 60, DateTime.now(), isComplete: true);
    await db.upsertDailyStep('2025-02-15', 20, DateTime.now(), isComplete: true);
    await db.upsertDailyStep('2025-03-13', 10, DateTime.now(), isComplete: true);
    await db.upsertDailyStep('2025-03-14', 20, DateTime.now(), isComplete: true);
    await db.upsertDailyStep('2025-03-15', 30, DateTime.now(), isComplete: true);
    await db.upsertDailyStep('2025-03-20', 1000, DateTime.now(), isComplete: true);
    await db.upsertDailyStep('2025-03-21', 2000, DateTime.now(), isComplete: true);
    await db.upsertDailyStep('2025-03-22', 3000, DateTime.now(), isComplete: true);
  });

  tearDown(() async {
    await db.close();
  });

  // test('getDailyAverageSteps returns correct average', () async {
  //   final result = await db.getDailyAverageSteps(DateTime(2025, 3, 20), DateTime(2025, 4, 2));
  //   expect(result[DateTime(2025, 3, 20)], 857);
  // });

  test('getDailyAverageSteps returns correct average', () async {
    final result = await db.getDailyAverageSteps(
      DateTime(2025, 3, 20),
      DateTime(2025, 3, 26), // 7 days: 20th to 26th inclusive
    );
    expect(result, 857); // 6000 steps over 7 days = 857.14 ≈ 857
  });

  // test('getDailyAverageSteps throws exception for invalid period', () async {
  //   expect(() => db.getDailyAverageSteps(DateTime(2025, 3, 20), DateTime(2025, 3, 22)), throwsException);
  // });

  test('getAllWeeklySteps returns correct weekly totals', () async {
    final result = await db.getAllWeeklySteps(DateTime(2025, 3, 13), DateTime(2025, 3, 22));
    expect(result[0].key, DateTime(2025, 3, 13));
    expect(result[0].value, 60);
    expect(result[1].key, DateTime(2025, 3, 20));
    expect(result[1].value, 6000);
  });

  test('getAllMonthlySteps returns correct monthly totals', () async {
    final result = await db.getAllMonthlySteps(DateTime(2025, 2, 1), DateTime(2025, 3, 31));
    expect(result[0].key, DateTime(2025, 2, 1));
    expect(result[0].value, 120);
    expect(result[1].key, DateTime(2025, 3, 1));
    expect(result[1].value, 6060);
  });

  test('getAllYearlySteps returns correct yearly total', () async {
    final result = await db.getAllYearlySteps();
    expect(result[0].key, DateTime(2025, 1, 1));
    expect(result[0].value, 6180);
  });
}
