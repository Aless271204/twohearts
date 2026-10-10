import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage extends ChangeNotifier {
  static final instance = AppLanguage();
  static const names = {'es': 'Español', 'en': 'English', 'pt': 'Português'};
  String _code = 'es';
  String get code => _code;
  Locale get locale => Locale(_code);
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final candidate = prefs.getString('app_language') ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    _code = names.containsKey(candidate) ? candidate : 'es';
  }
  Future<void> select(String code) async {
    if (!names.containsKey(code)) return;
    _code = code;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setString('app_language', code);
  }
  String text(String es, String en, String pt) => _code == 'en' ? en : _code == 'pt' ? pt : es;
  // Original phrases with aligned translations: the day's phrase is unchanged
  // when the language changes. No invented author attribution.
  List<Map<String,String>> get quotes => [
    ['Cada mensaje tuyo hace que la distancia sea un poco más pequeña.', 'Every message from you makes the distance a little smaller.', 'Cada mensagem sua deixa a distância um pouco menor.'],
    ['Nuestro lugar favorito es cualquier lugar donde estemos juntos.', 'Our favorite place is wherever we are together.', 'Nosso lugar favorito é onde estamos juntos.'],
    ['Los pequeños cuidados también dicen te quiero.', 'Small acts of care say I love you, too.', 'Os pequenos cuidados também dizem eu te amo.'],
    ['Hoy quiero compartir contigo algo que me haga sonreír.', 'Today I want to share something with you that makes me smile.', 'Hoje quero compartilhar com você algo que me faça sorrir.'],
    ['No hace falta un día perfecto para crear un bonito recuerdo.', 'We do not need a perfect day to make a beautiful memory.', 'Não precisamos de um dia perfeito para criar uma linda lembrança.'],
    ['Nuestra historia se construye con momentos pequeños.', 'Our story is built from little moments.', 'Nossa história é feita de pequenos momentos.'],
    ['Que siempre encontremos tiempo para escucharnos.', 'May we always find time to listen to each other.', 'Que sempre encontremos tempo para ouvir um ao outro.'],
    ['Hoy también elijo cuidar lo que estamos construyendo.', 'Today I choose to care for what we are building, too.', 'Hoje também escolho cuidar do que estamos construindo.'],
  ].map((q) => {'text': text(q[0],q[1],q[2]), 'source': 'TwoHearts', 'type': text('Frase','Quote','Frase')}).toList();
}
