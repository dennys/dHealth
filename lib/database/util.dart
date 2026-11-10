import 'dart:io';

import 'package:drift/native.dart';
import 'package:dhealth/database/database.dart';
import 'package:dhealth/settings_keys.dart';
import 'package:dhealth/utils/log.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 本機資料庫的所在與備份/還原機制。
///
/// 這支檔案的重要性來自 manifest 的 `allowBackup="false"`（健康資料不進雲備份，
/// 這是對的）：於是「匯出」是使用者唯一的備份路，「匯入」是唯一的還原路。
/// 之前 exportToCSV() 是 `return null;` 的空殼、匯入檔案那邊只有一句 TODO，
/// 兩者卻都跳「成功」—— 等使用者真的需要還原時才發現什麼都沒有。
/// 所以這裡的每個函式都回傳成敗，呼叫端準則：**拿到失敗就要讓使用者看得見**。
const String databaseFileName = 'dHealth.sqlite';

/// 全案唯一決定資料庫檔案落在哪裡（main 的 GetIt 註冊與備份都用它）。
Future<File> stepDatabaseFile() async {
  final appDir = await getApplicationDocumentsDirectory();
  return File(p.join(appDir.path, databaseFileName));
}

// True when the previous file could not be opened and was set aside as
// `<name>.corrupt` so the app still starts (and the import screen stays reachable,
// which matters because allowBackup="false" makes export the only restore path).
bool databaseWasQuarantined = false;

/// Open the step database, surviving a file SQLite refuses to read.
///
/// The old code let this throw before `runApp`, so one half-written file turned
/// the app into a self-closing splash screen with no way to get the data back.
Future<StepDatabase> openStepDatabase() async {
  final file = await stepDatabaseFile();
  final database = StepDatabase(NativeDatabase(file));
  try {
    // SQLite only opens the file on the first statement, so probe it here.
    // busy_timeout: the WorkManager isolate writes through its own connection,
    // so a manual sync and a background sync really can overlap.
    await database.customStatement('PRAGMA busy_timeout = 4000');
    await database.getAllDailySteps();
    return database;
  } catch (error) {
    appError('openStepDatabase failed: keep the old file as *.corrupt, reopen a blank db', error);
    await database.close();
    await _setAsideCorruptFile(file);
    databaseWasQuarantined = true;
    return StepDatabase(NativeDatabase(await stepDatabaseFile()));
  }
}

/// Keep the unreadable file next to the new one instead of deleting it: it may
/// still hold health data the user cannot re-fetch.
Future<void> _setAsideCorruptFile(File file) async {
  final quarantined = File('${file.path}.corrupt');
  if (await quarantined.exists()) await quarantined.delete();
  await file.rename(quarantined.path);
  for (final suffix in const ['-wal', '-shm']) {
    final side = File('${file.path}$suffix');
    if (await side.exists()) await side.delete();
  }
}

/// 用 SQLite 的 `VACUUM INTO` 讓**活著的連線**自己寫出一份乾淨的快照。
///
/// 不能直接 copy 活著的 DB 檔：drift 那條連線可能正在寫，複製到一半就是一份開不起來的
/// 「備份」。而 `allowBackup="false"` 之後這條就是使用者唯一的備份路，不能賭運氣。
/// （bundled SQLite 3.4x 支援 VACUUM INTO；真的失敗再退回直接複製，並在 log 留痕。）
Future<void> _vacuumInto(StepDatabase database, String destPath) =>
    database.customStatement('VACUUM INTO ?', [destPath]);

Future<void> _writeSnapshot(StepDatabase database, File dest) async {
  if (await dest.exists()) await dest.delete();
  try {
    await _vacuumInto(database, dest.path);
  } catch (e) {
    appError('VACUUM INTO 不可用，退回直接複製資料庫檔（可能複製到寫一半的內容）', e);
    final live = await stepDatabaseFile();
    await live.copy(dest.path);
  }
}

/// 備份用的穩定快照（分享／送出用）。失敗回 null，呼叫端一定要讓使用者看得見。
Future<File?> createDatabaseSnapshot(StepDatabase database, String fileName) async {
  final cacheDir = await getTemporaryDirectory();
  final dest = File(p.join(cacheDir.path, fileName));

  try {
    await _writeSnapshot(database, dest);
    if (!await dest.exists()) return null;
    await markExported();
    return dest;
  } catch (e) {
    appError('建立資料庫快照失敗', e);
    return null;
  }
}

/// 記下「剛才真的匯出成功了」—— `allowBackup="false"` 之後匯出是唯一備份路，
/// 背景排程靠這個時間戳提醒「備份可能過期」（`BackgroundService._maybeRemindBackup`）。
/// 只在**成功寫出檔案**之後呼叫：記错了会让提醒永远不再出现。
Future<void> markExported({DateTime? at}) async {
  try {
    await SharedPreferencesAsync().setInt(Prefs.lastExportAt, (at ?? DateTime.now()).millisecondsSinceEpoch);
  } catch (e) {
    appError('記錄匯出時間失敗（只会让备份提醒变多，不影响匯出本身）', e);
  }
}

/// 把資料庫匯出成一份快照到使用者選定的目錄；回傳實際檔名，失敗回 null。
Future<String?> copyDatabaseToDirectory(StepDatabase database, String directoryPath) async {
  try {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      appLog('匯出目標目錄不存在：$directoryPath');
      return null;
    }
    if (!await stepDatabaseFile().then((f) => f.exists())) {
      appLog('資料庫檔案還不存在：${(await stepDatabaseFile()).path}');
      return null;
    }

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final dest = File(p.join(dir.path, '${databaseFileName}_$stamp'));
    await _writeSnapshot(database, dest);
    if (!await dest.exists()) return null;
    await markExported();
    return dest.path;
  } catch (e) {
    appError('匯出資料庫失敗', e);
    return null;
  }
}

/// 匯出 CSV（Date,StepCount,LastUpdated,IsComplete）到使用者選定的目錄。
/// 回傳實際檔名，失敗回 null。
Future<String?> exportStepsToCsv(StepDatabase database, String directoryPath) async {
  try {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      appLog('匯出目標目錄不存在：$directoryPath');
      return null;
    }

    final steps = await database.getAllDailySteps();
    final csv = StringBuffer('Date,StepCount,LastUpdated,IsComplete\n');
    for (final step in steps) {
      csv.writeln('${step.date},${step.stepCount},${step.lastUpdated.toUtc().toIso8601String()},${step.isComplete}');
    }

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'dHealth_steps_$stamp.csv';
    final dest = File(p.join(dir.path, fileName));
    await dest.writeAsString(csv.toString(), flush: true);

    if (!await dest.exists()) return null;
    await markExported();
    return dest.path;
  } catch (e) {
    appError('匯出 CSV 失敗', e);
    return null;
  }
}

/// 匯入失敗的原因（**不帶使用者文字**，翻譯見 `lib/utils/sync_reason.dart`）。
enum ImportFailure { fileNotFound, noData, readFailed }

/// 匯入結果：imported = 寫入的天數，null 代表整個匯入失敗（此時資料庫完全沒被動過）。
/// [detail] 是給 log 看的技術細節，不要直接顯示給使用者。
typedef StepImportResult = ({int? imported, ImportFailure? failure, Object? detail});

/// 從匯出檔還原：用**唯讀**連線讀來源檔，再把每天資料 upsert 進目前的資料庫。
///
/// 刻意不「把檔案蓋過去再重開連線」：那要先關掉活著的連線，關了之後若忘了重新註冊，
/// 整個 app 就繼續用一個已關閉的 DB。讀來源→寫本機這條路不需要動到連線，
/// 來源檔損毀也只會回失敗。
Future<StepImportResult> importStepsFromFile(StepDatabase database, String filePath, {bool replaceAll = false}) async {
  StepDatabase? source;
  try {
    final file = File(filePath);
    if (!await file.exists()) return (imported: null, failure: ImportFailure.fileNotFound, detail: filePath);

    // shortcut: drift 2.35 的 NativeDatabase 沒有 read-only 參數，開來源檔時 drift 會跑
    // 自己的 PRAGMA（user_version/foreign_keys），所以嚴格說「可能碰到那個檔案」
    // （頂多在旁邊產生 -wal/-shm）。要完全避免就得直接把 sqlite3 列成直接依賴用
    // OpenMode.readOnly —— 本案剛把一個 EOL 的 sqlite3 原生依賴拔掉了，不值得為了這一行再放進去。
    // 代價：匯入不會改到來源裡的資料，但來源檔旁邊可能多出輔助檔。
    source = StepDatabase(NativeDatabase(file));
    final rows = await source.getAllDailySteps(); // 不是我們的 sqlite 檔會在這裡炸，被下面接住
    if (rows.isEmpty) return (imported: null, failure: ImportFailure.noData, detail: filePath);

    var imported = 0;
    await database.transaction(() async {
      if (replaceAll) await database.deleteAllData();
      for (final row in rows) {
        await database.upsertDailyStep(row.date, row.stepCount, row.lastUpdated, isComplete: row.isComplete);
        imported++;
      }
    });
    return (imported: imported, failure: null, detail: null);
  } catch (e) {
    appError('從檔案匯入失敗', e);
    return (imported: null, failure: ImportFailure.readFailed, detail: e);
  } finally {
    await source?.close();
  }
}
