import 'package:drift/native.dart';
import 'package:dhealth/database/database.dart';
import 'package:test/test.dart';

void main() {
  late StepDatabase db;

  setUp(() {
    db = StepDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('小時快取：寫入後能讀回，0 步也會保留', () async {
    final today = DateTime(2026, 5, 1);
    await db.upsertHourlySteps(today, {8: 120, 9: 0, 10: 450});

    expect(await db.getHourlySteps(today), {8: 120, 9: 0, 10: 450});
  });

  test('小時快取：再次寫入只覆蓋讀到的小時，其他小時保留', () async {
    final today = DateTime(2026, 5, 1);
    await db.upsertHourlySteps(today, {8: 120, 9: 300});
    await db.upsertHourlySteps(today, {9: 350, 10: 80});

    expect(await db.getHourlySteps(today), {8: 120, 9: 350, 10: 80});
  });

  test('小時快取：寫入新的一天時清掉舊日期', () async {
    await db.upsertHourlySteps(DateTime(2026, 4, 30), {8: 999});
    await db.upsertHourlySteps(DateTime(2026, 5, 1), {8: 120});

    expect(await db.getHourlySteps(DateTime(2026, 4, 30)), isEmpty);
    expect(await db.getHourlySteps(DateTime(2026, 5, 1)), {8: 120});
  });
}
