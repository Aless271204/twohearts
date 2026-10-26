import 'literary_quotes.g.dart';

// Author quotes are generated from data/quotes/literary.es.json.
const coupleQuoteCatalog = <Map<String, String>>[
  ...literaryQuoteCatalog,
  {
    'text': 'El amor es sufrido, es benigno.',
    'source': '1 Corintios 13:4 · Reina-Valera 1960',
    'url':
        'https://www.biblegateway.com/passage/?search=1+Corintios+13%3A4&version=RVR1960',
  },
  {
    'text': '¡Hasta el infinito y más allá!',
    'source': 'Buzz Lightyear · Toy Story (traducción de NIDO)',
    'url': 'https://news.disney.com/disney-pixar-quotes-to-inspire-your-day',
  },
  {
    'text': 'Él es su langosta.',
    'source': 'Phoebe Buffay · Friends, T2 E14 (traducción de NIDO)',
    'url': 'https://quotegeek.com/tv/friends/phoebe-see-he-s-her-lobster/',
  },
  {
    'text': 'Cada mensaje tuyo hace un poco más pequeña la distancia.',
    'source': 'NIDO · Frase original',
    'url': '',
  },
  {
    'text': 'Los pequeños cuidados también dicen te quiero.',
    'source': 'NIDO · Frase original',
    'url': '',
  },
  {
    'text': 'Hoy guardemos un recuerdo de esos que hacen sonreír.',
    'source': 'NIDO · Frase original',
    'url': '',
  },
  {
    'text': 'Nuestro lugar favorito se construye juntos.',
    'source': 'NIDO · Frase original',
    'url': '',
  },
  {
    'text': 'Que nunca nos falte un ratito para escucharnos.',
    'source': 'NIDO · Frase original',
    'url': '',
  },
  {
    'text': 'No hace falta un día perfecto para tener un momento bonito.',
    'source': 'NIDO · Frase original',
    'url': '',
  },
];
// Stable on Dart VM and web: multiplication remains below 2^53.
// A permutation gives every couple all quotes before repeating the cycle.
int coupleQuoteIndex(
  List<String> members,
  DateTime now, {
  int? quoteCount,
}) {
  quoteCount ??= coupleQuoteCatalog.length;
  if (quoteCount < 1) {
    throw ArgumentError.value(quoteCount, 'quoteCount', 'Must be positive');
  }
  final ids = members.where((id) => id.isNotEmpty).toSet().toList()..sort();
  final utc = now.toUtc();
  final day =
      DateTime.utc(utc.year, utc.month, utc.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
  var seed = 1;
  for (final code in ids.join(':').codeUnits) {
    seed = (seed * 31 + code) % 2147483647;
  }
  final order = List<int>.generate(quoteCount, (i) => i);
  for (var i = order.length - 1; i > 0; i--) {
    seed = (seed * 48271) % 2147483647;
    final j = seed % (i + 1);
    final value = order[i];
    order[i] = order[j];
    order[j] = value;
  }
  return order[day % order.length];
}
