import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/core/couple_daily_quote.dart';

void main() {
  test(
    'couple sees same daily quote regardless of device member order or timezone',
    () {
      final now = DateTime.utc(2026, 10, 17, 23);
      expect(
        coupleQuoteIndex(['a', 'b'], now),
        coupleQuoteIndex(['b', 'a'], now.toLocal()),
      );
      expect(
        coupleQuoteIndex(['a', 'b'], now),
        coupleQuoteIndex(['a', 'b'], DateTime.utc(2026, 10, 17, 1)),
      );
    },
  );
  test(
    'every day rotates through complete deck and couples have different sequences',
    () {
      final days = List.generate(12, (d) => DateTime.utc(2026, 10, 1 + d));
      expect(
        days.map((d) => coupleQuoteIndex(['a', 'b'], d)).toSet().length,
        12,
      );
      expect(
        days.map((d) => coupleQuoteIndex(['a', 'b'], d)).toList(),
        isNot(days.map((d) => coupleQuoteIndex(['a', 'c'], d)).toList()),
      );
      expect(coupleQuoteCatalog.every((q) => q['source']!.isNotEmpty), isTrue);
    },
  );
}
