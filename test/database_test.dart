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


  test('getDailyAverageSteps returns correct average', () async {
    final result = await db.getDailyAverageSteps(
      DateTime(2025, 3, 20),
      DateTime(2025, 3, 26), // 7 days: 20th to 26th inclusive
    );
    expect(result, 857); // 6000 steps over 7 days = 857.14 ≈ 857
  });


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

  test('getLastDate 回最新的一天', () async {
    expect(await db.getLastDate(), DateTime(2025, 3, 22));
  });

  // 空庫時必須回 null：舊版回 now-7d 的假日期，把上層「第一次同步取 30 天」的
  // 分支永遠蓋住，新裝置只補到 8 天。
  test('getLastDate 在空資料庫回 null', () async {
    final empty = StepDatabase(NativeDatabase.memory());
    addTearDown(empty.close);
    expect(await empty.getLastDate(), isNull);
  });

  test('deleteDataInRange 是閉區間（含 end 當天）', () async {
    await db.deleteDataInRange(DateTime(2025, 3, 13), DateTime(2025, 3, 15));
    expect(await db.getDailyStep(DateTime(2025, 3, 13)), isNull);
    expect(await db.getDailyStep(DateTime(2025, 3, 15)), isNull);
    expect(await db.getDailyStep(DateTime(2025, 3, 20)), isNotNull); // 隔天的不能一起刪掉
  });

  test('formatDateKey 補零', () {
    expect(formatDateKey(DateTime(2025, 1, 5)), '2025-01-05');
    expect(formatDateKey(DateTime(2025, 12, 31)), '2025-12-31');
  });
}
