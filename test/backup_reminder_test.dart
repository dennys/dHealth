import 'package:dhealth/services/background_service.dart';
import 'package:dhealth/settings_keys.dart';
import 'package:test/test.dart';

/// 匯出提醒的天數算法。`allowBackup="false"` 之後匯出是使用者唯一的備份路，
/// 「該不該念這一句」不能靠真機測出來才發現怪。
void main() {
  final now = DateTime(2026, 11, 9, 12);
  int ms(DateTime d) => d.millisecondsSinceEpoch;
  const threshold = PrefsDefaults.backupStaleDays;

  test('從沒匯出過 → 直接到門檻（由呼叫端再決定有沒有資料可備份）', () {
    expect(BackgroundService.daysSinceExport(lastExportAtMs: null, now: now), threshold);
  });

  test('剛匯出過 → 0 天，不念', () {
    expect(BackgroundService.daysSinceExport(lastExportAtMs: ms(now), now: now), 0);
  });

  test('差一天到門檻：13 天不念、14 天念', () {
    final ago = now.subtract(const Duration(days: 13));
    expect(BackgroundService.daysSinceExport(lastExportAtMs: ms(ago), now: now), 13);
    expect(BackgroundService.daysSinceExport(lastExportAtMs: ms(ago), now: now) >= threshold, isFalse);
    final justEnough = now.subtract(const Duration(days: 14));
    expect(BackgroundService.daysSinceExport(lastExportAtMs: ms(justEnough), now: now) >= threshold, isTrue);
  });

  // 時鐘被往後調過 → 上次匯出看起來在「未來」，這屬于脏資料，寧可不念也不能天天騷擾
  test('時間是負的（使用者調過時鐘）當作剛剛匯出過', () {
    final future = now.add(const Duration(days: 30));
    expect(BackgroundService.daysSinceExport(lastExportAtMs: ms(future), now: now), 0);
  });
}
