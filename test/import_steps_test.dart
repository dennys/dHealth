import 'dart:io';

import 'package:drift/native.dart';
import 'package:dhealth/database/database.dart';
import 'package:dhealth/database/util.dart';
import 'package:test/test.dart';

/// importStepsFromFile 是唯一的還原路（allowBackup="false" 之後），
/// 以前它直接 GetIt.instance<StepDatabase>() —— 測試裡走不通。
/// 改成注入 DB 之後，成敗的每一條路都有測試。
void main() {
  late StepDatabase live;
  late Directory tempDir;
  late File sourceFile;

  setUp(() async {
    live = StepDatabase(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('dhealth_import_test');
    sourceFile = File('${tempDir.path}/source.sqlite');
  });

  tearDown(() async {
    await live.close();
    await tempDir.delete(recursive: true);
  });

  /// 寫一份「匯出檔」：合法 sqlite、[rows] 天的資料。
  Future<void> writeSource(List<(String, int)> rows) async {
    final source = StepDatabase(NativeDatabase(sourceFile));
    for (final (date, steps) in rows) {
      await source.upsertDailyStep(date, steps, DateTime(2025, 1, 1), isComplete: true);
    }
    await source.close();
  }

  test('匯入：來源檔的列進活庫，回傳寫入天數', () async {
    await writeSource([('2025-01-01', 100), ('2025-01-02', 200)]);

    final result = await importStepsFromFile(live, sourceFile.path);

    expect(result.imported, 2);
    expect(result.failure, isNull);
    expect((await live.getDailyStep(DateTime(2025, 1, 1)))?.stepCount, 100);
    expect((await live.getDailyStep(DateTime(2025, 1, 2)))?.stepCount, 200);
  });

  test('replaceAll：先清掉活庫既有資料再匯入', () async {
    await live.upsertDailyStep('2024-12-31', 999, DateTime(2024, 12, 31), isComplete: true);
    await writeSource([('2025-01-01', 100)]);

    final result = await importStepsFromFile(live, sourceFile.path, replaceAll: true);

    expect(result.imported, 1);
    expect(await live.getDailyStep(DateTime(2024, 12, 31)), isNull);
    expect((await live.getDailyStep(DateTime(2025, 1, 1)))?.stepCount, 100);
  });

  test('不 replaceAll：既有資料保留（upsert 合併）', () async {
    await live.upsertDailyStep('2024-12-31', 999, DateTime(2024, 12, 31), isComplete: true);
    await writeSource([('2025-01-01', 100)]);

    await importStepsFromFile(live, sourceFile.path);

    expect(await live.getDailyStep(DateTime(2024, 12, 31)), isNotNull);
    expect((await live.getDailyStep(DateTime(2025, 1, 1)))?.stepCount, 100);
  });

  test('檔不存在 → fileNotFound，活庫不被動過', () async {
    await live.upsertDailyStep('2024-12-31', 999, DateTime(2024, 12, 31), isComplete: true);

    final result = await importStepsFromFile(live, '${tempDir.path}/nope.sqlite');

    expect(result.failure, ImportFailure.fileNotFound);
    expect(await live.getDailyStep(DateTime(2024, 12, 31)), isNotNull);
  });

  test('空來源（合法 sqlite、0 列）→ noData', () async {
    final source = StepDatabase(NativeDatabase(sourceFile));
    await source.getAllDailySteps(); // 逼 drift 真的建檔（NativeDatabase 是 lazy 開檔）
    await source.close();

    final result = await importStepsFromFile(live, sourceFile.path);

    expect(result.failure, ImportFailure.noData);
  });

  test('不是 sqlite 檔 → readFailed（不能把活庫搞壞）', () async {
    await live.upsertDailyStep('2024-12-31', 999, DateTime(2024, 12, 31), isComplete: true);
    await sourceFile.writeAsString('this is not a database');

    final result = await importStepsFromFile(live, sourceFile.path);

    expect(result.failure, ImportFailure.readFailed);
    expect(await live.getDailyStep(DateTime(2024, 12, 31)), isNotNull);
  });
}