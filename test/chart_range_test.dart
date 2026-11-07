import 'package:dhealth/utils/chart_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2024, 3, 10, 15, 30);

  group('ChartRange.preset', () {
    test('以今天為結尾的最近 N 天（含今天）', () {
      final range = ChartRange.preset(7, today);
      expect(range.start, DateTime(2024, 3, 4));
      expect(range.end, DateTime(2024, 3, 10));
      expect(range.dayCount, 7);
      expect(range.presetDays, 7);
    });
  });

  group('ChartRange.custom', () {
    test('去掉時分秒，dayCount 含首尾', () {
      final range = ChartRange.custom(DateTime(2024, 2, 1, 9), DateTime(2024, 2, 29, 23));
      expect(range.start, DateTime(2024, 2, 1));
      expect(range.end, DateTime(2024, 2, 29));
      expect(range.dayCount, 29);
      expect(range.presetDays, isNull);
    });
  });

  group('ChartRange.previous', () {
    test('是等長、緊接在 start 之前的區間', () {
      final prev = ChartRange.preset(7, today).previous;
      expect(prev.start, DateTime(2024, 2, 26));
      expect(prev.end, DateTime(2024, 3, 3));
      expect(prev.dayCount, 7);
    });
  });

  group('encode / decode', () {
    test('預設區間存天數並可還原', () {
      final encoded = ChartRange.preset(30, today).encode();
      expect(encoded, '30');
      final decoded = ChartRange.decode(encoded, today);
      expect(decoded.presetDays, 30);
      expect(decoded.start, DateTime(2024, 2, 10));
    });

    test('自訂區間存日期並可還原', () {
      final original = ChartRange.custom(DateTime(2024, 1, 5), DateTime(2024, 2, 20));
      final encoded = original.encode();
      expect(encoded, '2024-01-05|2024-02-20');
      final decoded = ChartRange.decode(encoded, today);
      expect(decoded.start, DateTime(2024, 1, 5));
      expect(decoded.end, DateTime(2024, 2, 20));
      expect(decoded.presetDays, isNull);
    });

    test('無效或倒置的值回到最近 7 天', () {
      for (final raw in ['', 'abc', '0', '-3', '2024-03-01|2024-02-01', 'x|y']) {
        final decoded = ChartRange.decode(raw, today);
        expect(decoded.presetDays, 7, reason: raw);
      }
    });
  });
}
