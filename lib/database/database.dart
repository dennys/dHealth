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

  Future<Map<DateTime, int>> getStepsMap(DateTime startDate, DateTime endDate) async {
    final formattedStart = formatDateKey(startDate);
    final formattedEnd = formatDateKey(endDate);
    final results = await (select(dailySteps)
          ..where((t) => t.date.isBiggerOrEqualValue(formattedStart) & t.date.isSmallerOrEqualValue(formattedEnd)))
        .get();

    return Map.fromEntries(results.map((entry) => MapEntry(DateTime.parse(entry.date), entry.stepCount)));
  }

  /// 區間内的日均（沒有資料的日子計入分母，才不會「只有三天走路」被算成那三天的高平均）。
  Future<int> getDailyAverageSteps(DateTime startDate, DateTime endDate) async {
    final daysInRange = endDate.difference(startDate).inDays + 1; // Includes both start and end dates
    if (daysInRange <= 0) return 0;

    final stepsMap = await getStepsMap(startDate, endDate);
    final totalSteps = stepsMap.values.fold(0, (sum, steps) => sum + steps);
    return (totalSteps / daysInRange).round();
  }

  /// 一律以週為單位加總（週的起始日由 [WeekdayUtils] 決定的是「顯示」用的星期標籤，
  /// 分組在這裡固定用 ISO 週一起算）。
  Future<List<MapEntry<DateTime, int>>> getAllWeeklySteps(DateTime startDate, DateTime endDate) async {
    final stepsMap = await getStepsMap(startDate, endDate);
    final results = <MapEntry<DateTime, int>>[];

    DateTime currentStart = startDate;
    while (currentStart.isBefore(endDate)) {
      final weekEnd = currentStart.add(const Duration(days: 6));
      final weekSteps = stepsMap.entries
          .where((entry) => !entry.key.isBefore(currentStart) && !entry.key.isAfter(weekEnd))
          .fold(0, (sum, entry) => sum + entry.value);

      if (weekSteps > 0) {
        results.add(MapEntry(currentStart, weekSteps));
      }
      currentStart = weekEnd.add(const Duration(days: 1));
    }

    return results;
  }

  Future<List<MapEntry<DateTime, int>>> getAllMonthlySteps(DateTime startDate, DateTime endDate) async {
    if (endDate.isBefore(startDate)) {
      throw ArgumentError('endDate must be after startDate');
    }

    final stepsMap = await getStepsMap(startDate, endDate);
    final results = <MapEntry<DateTime, int>>[];

    DateTime currentMonth = DateTime(startDate.year, startDate.month, 1);
    while (currentMonth.isBefore(endDate) || currentMonth.isAtSameMomentAs(endDate)) {
      final monthEnd = DateTime(currentMonth.year, currentMonth.month + 1, 0);
      final monthSteps = stepsMap.entries
          .where((entry) => !entry.key.isBefore(currentMonth) && !entry.key.isAfter(monthEnd))
          .fold(0, (sum, entry) => sum + entry.value);

      if (monthSteps > 0) {
        results.add(MapEntry(currentMonth, monthSteps));
      }
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    }

    return results;
  }
}
