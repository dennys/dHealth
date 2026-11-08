import 'package:dhealth/utils/chart_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2024, 3, 10, 15, 30); // 週日

  group('days', () {
    test('最近 N 天含今天', () {
      final w = ChartRange(7, 0, today).days();
      expect(w.from, DateTime(2024, 3, 4));
      expect(w.to, DateTime(2024, 3, 10));
      expect(w.periods, 7);
    });

    test('第 P 頁往回推整頁', () {
      final w = ChartRange(7, 2, today).days();
      expect(w.from, DateTime(2024, 2, 19));
      expect(w.to, DateTime(2024, 2, 25));
    });
  });

  group('weeks', () {
    test('起點對齊週一，涵蓋含今天的一週', () {
      final w = ChartRange(4, 0, today).weeks();
      expect(w.from.weekday, DateTime.monday); // 2/12
      expect(w.from, DateTime(2024, 2, 12));
      expect(w.to, DateTime(2024, 3, 10));
      expect(w.periods, 4);
    });

    test('第 P 頁往回推整頁（每週 = 7 天）', () {
      final w = ChartRange(4, 1, today).weeks();
      expect(w.from, DateTime(2024, 1, 15));
      expect(w.to, DateTime(2024, 2, 11));
    });
  });

  group('months', () {
    test('起點對齊月初，涵蓋含今天的一月', () {
      final w = ChartRange(3, 0, today).months();
      expect(w.from, DateTime(2024, 1, 1));
      expect(w.to, DateTime(2024, 3, 10));
      expect(w.periods, 3);
    });

    test('跨年度往回推', () {
      final w = ChartRange(3, 1, today).months();
      expect(w.from, DateTime(2023, 10, 1));
      expect(w.to, DateTime(2023, 12, 10));
    });
  });

  group('previous / encode / decode', () {
    test('previous 是往前一頁', () {
      expect(ChartRange(30, 0, today).previous.offset, 1);
    });

    test('存期數並可還原', () {
      expect(ChartRange(30, 0, today).encode(), '30');
      expect(ChartRange.decode('30', 2, today).periods, 30);
      expect(ChartRange.decode('30', 2, today).offset, 2);
    });

    test('無效或舊版日期區間的值回到 7 期', () {
      for (final raw in ['', 'abc', '0', '-3', '2024-01-05|2024-02-20']) {
        expect(ChartRange.decode(raw, 0, today).periods, 7, reason: raw);
      }
    });
  });
}
