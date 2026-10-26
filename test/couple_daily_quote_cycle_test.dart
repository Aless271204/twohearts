import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/core/couple_daily_quote.dart';

void main() {
  test('partners agree across member order and timezone', () {
    final now = DateTime.parse('2026-10-26T01:00:00Z');
    expect(
      coupleQuoteIndex(['a', 'b'], now),
      coupleQuoteIndex(['b', 'a'], now.toLocal()),
    );
  });
  test('every quote appears exactly once per complete cycle', () {
    final seen = <int>{};
    for (var day = 0; day < coupleQuoteCatalog.length; day++) {
      seen.add(
        coupleQuoteIndex([
          'a',
          'b',
        ], DateTime.utc(2026, 1, 1).add(Duration(days: day))),
      );
    }
    expect(seen.length, coupleQuoteCatalog.length);
  });
  test('couples have different sequences', () {
    final start = DateTime.utc(2026, 1, 1);
    final a = List.generate(
      12,
      (i) => coupleQuoteIndex(['a', 'b'], start.add(Duration(days: i))),
    );
    final b = List.generate(
      12,
      (i) => coupleQuoteIndex(['c', 'd'], start.add(Duration(days: i))),
    );
    expect(a, isNot(equals(b)));
  });
  test('future 1000-entry catalog visits every entry, including leap day', () {
    final start = DateTime.utc(2028, 2, 28);
    final seen = <int>{};
    for (var day = 0; day < 1000; day++) {
      seen.add(
        coupleQuoteIndex(
          ['a', 'b'],
          start.add(Duration(days: day)),
          quoteCount: 1000,
        ),
      );
    }
    expect(seen.length, 1000);
  });
  test('duplicates and empty member IDs do not change the couple', () {
    final now = DateTime.utc(2026, 10, 26);
    expect(
      coupleQuoteIndex(['a', '', 'b', 'a'], now),
      coupleQuoteIndex(['b', 'a'], now),
    );
  });
  test('literary entries have visible authors, works and HTTPS sources', () {
    final literary = coupleQuoteCatalog.where(
      (q) => q['category'] == 'literature',
    );
    expect(literary.length, 50);
    for (final quote in literary) {
      expect(quote['source'], '${quote['author']} · ${quote['work']}');
      expect(Uri.parse(quote['url']!).scheme, 'https');
    }
  });
}
