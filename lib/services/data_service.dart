import 'package:dhealth/database/database.dart';
import 'package:dhealth/settings_keys.dart';
import 'package:get_it/get_it.dart';
import 'package:health/health.dart';

import 'permission_service.dart';
import '../utils/log.dart';

/// 同步的結果原因。**這裡不放使用者文字** —— 服務層吐字串會讓英文介面混出中文
/// （之前 `message` 就是硬編的中文直接進 SnackBar 與通知）。
/// 要顯示給使用者看的話，用 `lib/utils/sync_reason.dart` 的 label 擴充取字串。
enum StepSyncStatus {
  success, // 有照使用者授權讀到資料，並寫進 DB
  permissionDenied, // 沒拿到讀步數的授權 —— 這不是你我能修好的，要叫使用者去開
  unavailable, // Health Connect 讀不到（未安裝、ROM 沒 GMS、呼叫失敗）
  invalidRange, // 使用者選的日期區間本身不合法
}

/// 一次同步的結果。失敗時**資料庫完全沒被動過**（見 [StepDataService.syncRange] 的註解）。
/// [detail] 是給 log 看的技術細節（例外內容），不要拿去顯示。
typedef StepSyncResult = ({StepSyncStatus status, Object? detail});

/// 步數的唯一寫入路徑：從 Health Connect 讀 → 依日聚合 → 覆蓋寫進 [StepDatabase]。
class StepDataService {
  final Health health = GetIt.I<Health>();
  final StepDatabase database = GetIt.I<StepDatabase>();

  /// 讀取步數是否已授權。
  Future<bool> _hasReadPermission() async => await health.hasPermissions(stepTypes, permissions: stepPermissions) == true;

  /// 逐日讀取 [start]..[end]（含兩端）的步數。
  ///
  /// 用 Health Connect 的聚合 API（`getTotalStepsInInterval`）而不是把原始資料點加總：
  /// 手機、手錶、Google Fit 等來源會寫入重疊的步數紀錄，聚合 API 會在 Health Connect 端去重，
  /// 逐點加總則會把每個來源都算一次（實際值的約兩倍）。
  ///
  /// 回傳 null = 這次**沒讀到**（沒權限或 Health Connect 出錯）；
  /// 回傳的 map 只含步數 > 0 的日子。null 與「0 步」在資料庫層意義完全不同：
  /// 前者絕對不能刪資料，後者才應該把該段覆蓋成空。
  Future<Map<String, int>?> _fetchDailySteps(DateTime start, DateTime end) async {
    try {
      if (!await _hasReadPermission()) {
        appLog('未取得健康資料讀取權限，跳過同步（未刪除任何資料）');
        return null;
      }
      final days = <String, int>{};
      final last = DateTime(end.year, end.month, end.day);
      for (var day = DateTime(start.year, start.month, start.day); !day.isAfter(last); day = DateTime(day.year, day.month, day.day + 1)) {
        final (from, to) = _dayBounds(day, day);
        final steps = await health.getTotalStepsInInterval(from, to);
        if (steps == null) throw StateError('getTotalStepsInInterval 回傳 null（${formatDateKey(day)}）');
        if (steps > 0) days[formatDateKey(day)] = steps;
      }
      return days;
    } catch (error) {
      appError('讀取健康資料失敗（未刪除任何資料）', error);
      return null;
    }
  }

  /// 用 Health Connect 的資料覆蓋 [start]..[end]（含兩端）這一段。
  ///
  /// 順序固定是「**全部讀成功 → 才動資料庫**」，而且刪除與寫入在同一個 transaction 裡：
  /// 任何一步出錯，資料庫都維持原本的樣子。
  Future<StepSyncResult> syncRange(DateTime start, DateTime end, {bool clearAllFirst = false}) async {
    if (end.isBefore(start)) {
      return (status: StepSyncStatus.invalidRange, detail: 'endDate $end is before startDate $start');
    }

    final read = await _readDays(start, end);
    final failure = read.failure;
    if (failure != null) return (status: failure, detail: read.detail);

    await _writeDays(start, end, read.days!, clearAllFirst: clearAllFirst);
    return (status: StepSyncStatus.success, detail: null);
  }

  /// 讀一段區間並聚合。回傳的 failure 非 null 時代表「這次沒讀到」，
  /// 呼叫端**絕對不能**拿去動資料庫。
  Future<_ReadResult> _readDays(DateTime start, DateTime end) async {
    final days = await _fetchDailySteps(start, end);
    if (days == null) {
      final denied = await _permissionDenied();
      return (days: null, failure: denied ? StepSyncStatus.permissionDenied : StepSyncStatus.unavailable, detail: null);
    }
    return (days: days, failure: null, detail: null);
  }

  /// 起訖補到「當天 00:00:00 ~ 23:59:59.999」，讓「含尾日」成立。
  /// （舊版是把 end 直接 +1 天再拿去刪，而刪除是閉區間，等於多刪一天的資料。）
  (DateTime, DateTime) _dayBounds(DateTime start, DateTime end) => (
        DateTime(start.year, start.month, start.day),
        DateTime(end.year, end.month, end.day, 23, 59, 59, 999),
      );

  /// 唯一的寫入路徑：先刪這段（或全部）再寫，整個動作在同一個 transaction 內。
  Future<void> _writeDays(DateTime start, DateTime end, Map<String, int> days, {bool clearAllFirst = false}) async {
    final (from, to) = _dayBounds(start, end);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    await database.transaction(() async {
      if (clearAllFirst) {
        await database.deleteAllData();
      } else {
        await database.deleteDataInRange(from, to);
      }
      for (final entry in days.entries) {
        final day = DateTime.parse(entry.key);
        await database.upsertDailyStep(
          entry.key,
          entry.value,
          now,
          isComplete: day.isBefore(todayStart), // 只有「已經過去的日子」才算定案
        );
      }
    });
  }

  /// 從手機匯入：分段讀（Health Connect 一次給太多會超時），**全部讀完才一次寫入**。
  ///
  /// 之前是邊讀邊寫，而且勾了「匯入前清除」時第一段就把整張表清空：於是第 2 段讀取失敗
  /// （Health Connect 常見）時，使用者看到的是「匯入失敗」，實際上資料庫已經被清空、
  /// 只剩第一段那種資料 —— 這是本案最危險的一條路，因為這裡就是資料的唯一來源。
  Future<StepSyncResult> importFromPhone({
    required DateTime startDate,
    required DateTime endDate,
    bool clearAllFirst = false,
    void Function(double progress)? onProgress,
  }) async {
    if (endDate.isBefore(startDate)) {
      return (status: StepSyncStatus.invalidRange, detail: 'endDate $endDate is before startDate $startDate');
    }

    const chunkSize = 30;
    final totalChunks = endDate.difference(startDate).inDays ~/ chunkSize + 1;
    final merged = <String, int>{};

    for (var i = 0; i < totalChunks; i++) {
      final chunkStart = startDate.add(Duration(days: i * chunkSize));
      if (chunkStart.isAfter(endDate)) break;
      final candidate = chunkStart.add(const Duration(days: chunkSize - 1));
      final chunkEnd = candidate.isAfter(endDate) ? endDate : candidate;

      final read = await _readDays(chunkStart, chunkEnd);
      final failure = read.failure;
      if (failure != null) return (status: failure, detail: read.detail); // 資料庫一個字節都沒動過
      merged.addAll(read.days!);
      onProgress?.call((i + 1) / totalChunks);
    }

    await _writeDays(startDate, endDate, merged, clearAllFirst: clearAllFirst);
    return (status: StepSyncStatus.success, detail: null);
  }

  /// 給小時圖表用：今天 0 點到現在，每個小時的步數（去重後的聚合值，不寫 DB）。
  ///
  /// 回傳 null 是「讀不到」，map 內的 0 才是「該小時真的 0 步」——兩者必須分開，
  /// 否則 Health Connect 一晃眼，主畫面就畫出一條 0 步的線，看起來像「今天沒走路」。
  Future<Map<int, int>?> fetchHourlyTotals(DateTime now) async {
    try {
      if (!await _hasReadPermission()) return null;
      final today = DateTime(now.year, now.month, now.day);
      final totals = <int, int>{};
      for (var hour = 0; hour <= now.hour; hour++) {
        final from = today.add(Duration(hours: hour));
        final to = hour == now.hour ? now : DateTime(today.year, today.month, today.day, hour, 59, 59, 999);
        final steps = await health.getTotalStepsInInterval(from, to);
        if (steps == null) throw StateError('getTotalStepsInInterval 回傳 null（$hour 時）');
        totals[hour] = steps;
      }
      return totals;
    } catch (error) {
      appError('讀取小時步數失敗', error);
      return null;
    }
  }

  Future<bool> _permissionDenied() async {
    try {
      return !await _hasReadPermission();
    } catch (e) {
      return false;
    }
  }

  /// 從資料庫最後一笔的前一天開始補（多回來一天處理跨午夜與時區邊界）。
  /// 資料庫全空時往回取 [PrefsDefaults.firstSyncLookbackDays] 天。
  Future<StepSyncResult> syncNewData() async {
    final now = DateTime.now();
    final lastDate = await database.getLastDate();
    final start = lastDate?.subtract(const Duration(days: 1)) ?? now.subtract(const Duration(days: PrefsDefaults.firstSyncLookbackDays));
    return syncRange(start, now);
  }

}

/// 一次「讀取＋聚合」的結果：failure 非 null 時 days 是 null，且呼叫端不得動資料庫。
typedef _ReadResult = ({Map<String, int>? days, StepSyncStatus? failure, Object? detail});