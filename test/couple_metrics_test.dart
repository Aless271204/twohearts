import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/core/couple_metrics.dart';

void main() {
  test(
    'months count completed calendar anniversaries, including short months',
    () {
      expect(coupleMonths(DateTime(2026, 1, 18), DateTime(2026, 10, 17)), 8);
      expect(coupleMonths(DateTime(2026, 1, 18), DateTime(2026, 10, 18)), 9);
      expect(coupleMonths(DateTime(2026, 1, 31), DateTime(2026, 2, 28)), 1);
      expect(coupleMonths(DateTime(2024, 2, 29), DateTime(2025, 2, 28)), 12);
      expect(coupleMonths(DateTime(2026, 10, 18), DateTime(2026, 10, 18)), 0);
      expect(coupleMonths(null, DateTime(2026, 10, 18)), isNull);
      expect(
        coupleMonths(DateTime(2026, 10, 19), DateTime(2026, 10, 18)),
        isNull,
      );
    },
  );
  test('calendar days do not depend on time of day or DST-length days', () {
    expect(
      coupleDays(DateTime(2026, 10, 16, 23, 55), DateTime(2026, 10, 17, 0, 5)),
      1,
    );
    expect(coupleDays(DateTime(2026, 10, 17), DateTime(2026, 10, 17, 23)), 0);
    expect(coupleDays(null, DateTime(2026, 10, 17)), isNull);
    expect(coupleDays(DateTime(2026, 10, 18), DateTime(2026, 10, 17)), isNull);
  });
  test('distance uses actual kilometres and preserves nearby positions', () {
    expect(coupleDistanceLabel(12.5), '12.5 km');
    expect(coupleDistanceLabel(.25), '250 m');
    expect(coupleDistanceLabel(9350), '9350 km');
    expect(coupleDistanceLabel(null), '—');
  });
}
