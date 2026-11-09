import 'package:drift/drift.dart';

part 'database.g.dart';

/// 日期在資料庫裡的唯一表示法（YYYY-MM-DD，當主鍵用）。
/// 之前 data_service 與 database 各有一份 `_formatDate`，雨過天晴就會分岔。
String formatDateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// 每天的步數一筆。
class DailySteps extends Table {
  // Primary key - date stored as text in format YYYY-MM-DD
  TextColumn get date => text()();
  // Total step count for the day
  IntColumn get stepCount => integer()();
  // Last update timestamp to track when this record was last modified
  DateTimeColumn get lastUpdated => dateTime()();
  // Flag to indicate if this data is considered complete/final
  BoolColumn get isComplete => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {date};
}

@DriftDatabase(tables: [DailySteps])
class StepDatabase extends _$StepDatabase {
  StepDatabase(super.e);

  @override
  int get schemaVersion => 1;

  /// 下次改 schema（加欄位）時，老安裝升級不會直接崩潰 —— 沒有 onUpgrade 時 drift
  /// 對版本不符的資料庫直接丟例外，而本案 `allowBackup="false"`，崩了就等於沒資料。
  ///
  /// 現階段（測試期，人類 2026-11-09 同意資料可遺失）：整張表砍掉重建，下次同步會從
  /// Health Connect 補回來，換得好記。
  /// **上架前要改成逐版 `ALTER TABLE`**：那時候使用者手上只有一份資料，
  /// 不能靠重抓補回來。
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          for (final table in allTables) {
            await m.deleteTable(table.actualTableName);
            await m.createTable(table);
          }
        },
      );

  // Get all daily step records
  Future<List<DailyStep>> getAllDailySteps() => select(dailySteps).get();

  // Get a specific day's step data
  Future<DailyStep?> getDailyStep(DateTime date) {
    return (select(dailySteps)..where((t) => t.date.equals(formatDateKey(date)))).getSingleOrNull();
  }

  /// 資料庫裡最新的一天；完全沒資料回 null（呼叫端決定要往回取幾天）。
  ///
  /// 舊版在空資料庫時回 `now - 7 days`，於是上層「第一次同步取 30 天」的分支
  /// 在正式環境永遠走不到，新裝置只補到 7+1 天。空就是空，別在資料層猜使用者想要幾天。
  Future<DateTime?> getLastDate() async {
    final query = select(dailySteps)
      ..orderBy([(t) => OrderingTerm.desc(t.date)])
      ..limit(1);
    final result = await query.getSingleOrNull();
    return result == null ? null : DateTime.parse(result.date);
  }

  // Insert or update a daily step entry
  Future<void> upsertDailyStep(String date, int steps, DateTime lastUpdated, {bool isComplete = false}) async {
    await into(dailySteps).insertOnConflictUpdate(
      DailyStepsCompanion(
        date: Value(date),
        stepCount: Value(steps),
        lastUpdated: Value(lastUpdated),
        isComplete: Value(isComplete),
      ),
    );
  }

  // Delete all data (for complete refresh)
  Future<void> deleteAllData() async {
    await delete(dailySteps).go();
  }

  /// 刪除 [start]..[end]（**閉區間**，含 end 當天）。
  Future<void> deleteDataInRange(DateTime start, DateTime end) async {
    final startDate = formatDateKey(start);
    final endDate = formatDateKey(end);
    await (delete(dailySteps)
          ..where((t) => t.date.isBiggerOrEqualValue(startDate) & t.date.isSmallerOrEqualValue(endDate)))
        .go();
  }
}
