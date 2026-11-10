import 'dart:async';

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
/// [todaySkipped] = 這次「今天的步數讀不到、只跳過今天」（見 [_fetchDailySteps]）：
/// 同步成功後 DB 若沒有今天的列，那代表「未知」而不是「0 步」，
/// 背景通知端（`background_service.dart`）靠這個決定要不要走例外通知路。
typedef StepSyncResult = ({StepSyncStatus status, Object? detail, bool todaySkipped});

/// 步數的唯一寫入路徑：從 Health Connect 讀 → 依日聚合 → 覆蓋寫進 [StepDatabase]。
class StepDataService {
  final Health health = GetIt.I<Health>();
  final StepDatabase database = GetIt.I<StepDatabase>();

  /// 一批併發的 Health Connect 呼叫數量。
  /// 串行 24 次（小時）/ 365 次（匯入一年）IPC 是冷啟動慢的主因；一次全發在慢的機器上
  /// 會變成排隊 + 一起逾時，6 是兩邊都不至于爆的折衰值。
  static const _concurrency = 6;

  /// Serialises syncs *inside this isolate*. The WorkManager task runs in another
  /// isolate with its own StepDataService, so it cannot share this queue: that pair
  /// is kept safe by SQLite transactions plus `PRAGMA busy_timeout` (see
  /// openStepDatabase), not by this mutex.
  Future<void> _tail = Future<void>.value();

  Future<T> _serialized<T>(Future<T> Function() body) {
    final previous = _tail;
    final done = Completer<void>();
    _tail = done.future;
    return previous.then((_) => body()).whenComplete(done.complete);
  }

  /// 分批 `Future.wait`（一次 [_concurrency] 個），结果順序與輸入一致。
  Future<List<T>> _batchedWait<T>(List<Future<T> Function()> tasks) async {
    final results = <T>[];
    for (var i = 0; i < tasks.length; i += _concurrency) {
      final slice = tasks.sublist(i, (i + _concurrency).clamp(0, tasks.length));
      results.addAll(await Future.wait(slice.map((t) => t())));
    }
    return results;
  }

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
  Future<({Map<String, int> days, Set<String> skipped})?> _fetchDailySteps(DateTime start, DateTime end) async {
    try {
      if (!await _hasReadPermission()) {
        appLog('未取得健康資料讀取權限，跳過同步（未刪除任何資料）');
        return null;
      }
      final days = <String, int>{};
      final last = DateTime(end.year, end.month, end.day);
      final dayList = <DateTime>[
        for (var day = DateTime(start.year, start.month, start.day); !day.isAfter(last); day = DateTime(day.year, day.month, day.day + 1)) day,
      ];
      final totals = await _batchedWait(dayList.map((day) {
        final (from, to) = _dayBounds(day, day);
        return () => health.getTotalStepsInInterval(from, to);
      }).toList());
      final todayKey = formatDateKey(DateTime.now());
      final skipped = <String>{};
      for (var i = 0; i < dayList.length; i++) {
        final steps = totals[i];
        final key = formatDateKey(dayList[i]);
        if (steps == null) {
          // 今天讀不到只跳過今天（寫入時保留它原有的列）；過去的日子讀不到仍整個不動資料庫，
          // 把 null 當成 0 就是拿使用者的真實資料去換一個好看的進度條。
          if (key == todayKey) {
            skipped.add(key);
            appLog('今天的步數讀不到，只跳過今天（保留既有資料）');
            continue;
          }
          throw StateError('getTotalStepsInInterval 回傳 null（$key）');
        }
        if (steps > 0) days[key] = steps;
      }
      return (days: days, skipped: skipped);
    } catch (error) {
      appError('讀取健康資料失敗（未刪除任何資料）', error);
      return null;
    }
  }

  /// 用 Health Connect 的資料覆蓋 [start]..[end]（含兩端）這一段。
  ///
  /// 順序固定是「**全部讀成功 → 才動資料庫**」，而且刪除與寫入在同一個 transaction 裡：
  /// 任何一步出錯，資料庫都維持原本的樣子。
  Future<StepSyncResult> syncRange(DateTime start, DateTime end, {bool clearAllFirst = false}) =>
      _serialized(() => _syncRange(start, end, clearAllFirst: clearAllFirst));

  Future<StepSyncResult> _syncRange(DateTime start, DateTime end, {bool clearAllFirst = false}) async {
    if (end.isBefore(start)) {
      return (status: StepSyncStatus.invalidRange, detail: 'endDate $end is before startDate $start', todaySkipped: false);
    }

    final read = await _readDays(start, end);
    final failure = read.failure;
    if (failure != null) return (status: failure, detail: read.detail, todaySkipped: false);

    await _writeDays(start, end, read.days!, skipped: read.skipped, clearAllFirst: clearAllFirst);
    // skipped 只可能含今天（其他日子讀不到會整個失敗），所以 isNotEmpty 即「今天被跳過」。
    return (status: StepSyncStatus.success, detail: null, todaySkipped: read.skipped.isNotEmpty);
  }

  /// 讀一段區間並聚合。回傳的 failure 非 null 時代表「這次沒讀到」，
  /// 呼叫端**絕對不能**拿去動資料庫。
  Future<_ReadResult> _readDays(DateTime start, DateTime end) async {
    final fetched = await _fetchDailySteps(start, end);
    if (fetched == null) {
      final denied = await _permissionDenied();
      return (days: null, skipped: const <String>{}, failure: denied ? StepSyncStatus.permissionDenied : StepSyncStatus.unavailable, detail: null);
    }
    return (days: fetched.days, skipped: fetched.skipped, failure: null, detail: null);
  }

  /// 起訖補到「當天 00:00:00 ~ 23:59:59.999」，讓「含尾日」成立。
  /// （舊版是把 end 直接 +1 天再拿去刪，而刪除是閉區間，等於多刪一天的資料。）
  (DateTime, DateTime) _dayBounds(DateTime start, DateTime end) => (
        DateTime(start.year, start.month, start.day),
        DateTime(end.year, end.month, end.day, 23, 59, 59, 999),
      );

  /// 唯一的寫入路徑：先刪這段（或全部）再寫，整個動作在同一個 transaction 內。
  /// [skipped] 是這次讀不到、必須保留原狀的日子（目前只有「今天」）：刪除前先記下它們的列，寫完再放回去。
  Future<void> _writeDays(DateTime start, DateTime end, Map<String, int> days, {Set<String> skipped = const {}, bool clearAllFirst = false}) async {
    final (from, to) = _dayBounds(start, end);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    await database.transaction(() async {
      final preserved = <DailyStep>[];
      for (final key in skipped) {
        final row = await database.getDailyStep(DateTime.parse(key));
        if (row != null) preserved.add(row);
      }

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
      for (final row in preserved) {
        await database.upsertDailyStep(row.date, row.stepCount, row.lastUpdated, isComplete: row.isComplete);
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
  }) =>
      _serialized(() => _importFromPhone(startDate: startDate, endDate: endDate, clearAllFirst: clearAllFirst, onProgress: onProgress));

  Future<StepSyncResult> _importFromPhone({
    required DateTime startDate,
    required DateTime endDate,
    bool clearAllFirst = false,
    void Function(double progress)? onProgress,
  }) async {
    if (endDate.isBefore(startDate)) {
      return (status: StepSyncStatus.invalidRange, detail: 'endDate $endDate is before startDate $startDate', todaySkipped: false);
    }

    const chunkSize = 30;
    final totalChunks = endDate.difference(startDate).inDays ~/ chunkSize + 1;
    final merged = <String, int>{};
    final skipped = <String>{};

    for (var i = 0; i < totalChunks; i++) {
      final chunkStart = startDate.add(Duration(days: i * chunkSize));
      if (chunkStart.isAfter(endDate)) break;
      final candidate = chunkStart.add(const Duration(days: chunkSize - 1));
      final chunkEnd = candidate.isAfter(endDate) ? endDate : candidate;

      final read = await _readDays(chunkStart, chunkEnd);
      final failure = read.failure;
      if (failure != null) return (status: failure, detail: read.detail, todaySkipped: false); // 資料庫一個字節都沒動過
      merged.addAll(read.days!);
      skipped.addAll(read.skipped);
      onProgress?.call((i + 1) / totalChunks);
    }

    await _writeDays(startDate, endDate, merged, skipped: skipped, clearAllFirst: clearAllFirst);
    return (status: StepSyncStatus.success, detail: null, todaySkipped: skipped.isNotEmpty);
  }

  /// 給小時圖表用：今天 0 點到現在，每個小時的步數（去重後的聚合值，不寫 DB）。
  ///
  /// 回傳 null 是「讀不到」，map 內的 0 才是「該小時真的 0 步」——兩者必須分開，
  /// 否則 Health Connect 一晃眼，主畫面就畫出一條 0 步的線，看起來像「今天沒走路」。
  ///
  /// 單個小時的容忍：**讀不到的那一個補插一次，還是 null 就只省略那個小時**，
  /// 不再像舊版一样把 23 個好小時一起丢 throw 掉（一個小時的抖動牺牲整天）。
  /// 全部小時都讀不到 = 真的讀不到，那时才回 null 讓圖表畫「讀不到」。
  /// （圖表對缺的那格本來就畫 0，所以缺一格不會看起來壞掉。）
  Future<Map<int, int>?> fetchHourlyTotals(DateTime now) async {
    try {
      if (!await _hasReadPermission()) return null;
      final today = DateTime(now.year, now.month, now.day);
      final hours = List.generate(now.hour + 1, (h) => h);
      final totals = await _batchedWait(hours.map((hour) { return () async {
        final from = today.add(Duration(hours: hour));
        final to = hour == now.hour ? now : DateTime(today.year, today.month, today.day, hour, 59, 59, 999);
        final once = await _hourSteps(from, to);
        return once ?? await _hourSteps(from, to);
      }; }).toList());

      final result = <int, int>{};
      for (var i = 0; i < hours.length; i++) {
        final steps = totals[i];
        if (steps == null) {
          appLog('第 ${hours[i]} 小時的步數讀不到，這一格留空（不影響其他 23 小時）');
          continue;
        }
        result[hours[i]] = steps;
      }
      return result.isEmpty ? null : result;
    } catch (error) {
      appError('讀取小時步數失敗', error);
      return null;
    }
  }

  /// 單小時查詢：例外當成一時讀不到（回 null）處理，否則一個小時抛例外就把整張圖帶走。
  Future<int?> _hourSteps(DateTime from, DateTime to) async {
    try {
      return await health.getTotalStepsInInterval(from, to);
    } catch (e) {
      appError('單小時步數查詢失敗', e);
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
typedef _ReadResult = ({Map<String, int>? days, Set<String> skipped, StepSyncStatus? failure, Object? detail});