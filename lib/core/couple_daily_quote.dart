// Short excerpts. Translations made for NIDO are identified, not attributed
// to a published Spanish edition. Sources remain available from the card.
const coupleQuoteCatalog = <Map<String, String>>[
  {
    'text': 'Por una mirada, un mundo; por una sonrisa, un cielo.',
    'source': 'Gustavo Adolfo Bécquer · Rima XXIII',
    'url': 'https://www.cervantesvirtual.com/nd/ark:/59851/bmc0706827',
  },
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
    'text': 'Debes permitirme decirte cuánto te admiro y te amo.',
    'source': 'Jane Austen · Orgullo y prejuicio, cap. 34 (traducción de NIDO)',
    'url': 'https://www.gutenberg.org/files/1342/1342-h/1342-h.htm',
  },
  {
    'text': '¿He de compararte con un día de verano?',
    'source': 'William Shakespeare · Soneto 18 (traducción de NIDO)',
    'url': 'https://www.gutenberg.org/files/100/100-h/100-h.htm',
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
int coupleQuoteIndex(List<String> members, DateTime now) {
  final ids = [...members]..sort();
  final utc = now.toUtc();
  final day =
      DateTime.utc(utc.year, utc.month, utc.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
  var hash = 2166136261;
  for (final code in ids.join(':').codeUnits) {
    hash = ((hash ^ code) * 16777619) & 0xffffffff;
  }
  // Each couple has its own stable offset and stride; both devices agree.
  final stride = [1, 5, 7, 11][hash % 4];
  return (hash + day * stride) % coupleQuoteCatalog.length;
}
