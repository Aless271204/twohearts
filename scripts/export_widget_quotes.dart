import 'dart:convert';
import 'dart:io';
import '../lib/core/couple_daily_quote.dart';

void main() {
  final file = File('android/app/src/main/assets/couple_quotes_es.json');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(coupleQuoteCatalog),
  );
  final vectors = <Map<String, dynamic>>[];
  for (final count in [59, 1000]) {
    for (final members in [
      <String>['demo-a', 'demo-b'],
      <String>['b', '', 'a', 'a'],
    ]) {
      for (final day in [0, 1, 19782, 20753, 22000]) {
        vectors.add({
          'members': members,
          'day': day,
          'count': count,
          'expected': coupleQuoteIndex(
            members,
            DateTime.utc(1970).add(Duration(days: day)),
            quoteCount: count,
          ),
        });
      }
    }
  }
  File(
    'data/quotes/widget-quote-vectors.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(vectors));
  stdout.writeln('Exported ${coupleQuoteCatalog.length} widget quotes');
}
