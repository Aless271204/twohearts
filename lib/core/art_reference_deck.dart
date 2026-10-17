import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CatalogDrawing {
  final String id, level, title, asset;
  const CatalogDrawing(this.id, this.level, this.title, this.asset);
  factory CatalogDrawing.fromJson(Map<String, dynamic> json) => CatalogDrawing(
    json['id'] as String,
    json['level'] as String,
    json['title'] as String,
    json['asset'] as String,
  );
}

/// A separate shuffled bag per difficulty, persisted across sessions.
/// The selected bitmap is sent through the existing private couple-room protocol.
class ArtReferenceDeck {
  static Future<CatalogDrawing> draw(int difficulty, {Random? random}) async {
    final raw =
        jsonDecode(
              await rootBundle.loadString(
                'assets/images/art_references/mobile/catalog.json',
              ),
            )
            as List;
    final level = ['easy', 'medium', 'hard'][difficulty.clamp(0, 2)];
    final entries = raw
        .cast<Map<String, dynamic>>()
        .where((item) => item['enabled'] != false && item['level'] == level)
        .map(CatalogDrawing.fromJson)
        .toList();
    return drawFrom(entries, level, random: random);
  }

  static Future<CatalogDrawing> drawFrom(
    List<CatalogDrawing> entries,
    String level, {
    Random? random,
  }) async {
    if (entries.isEmpty) throw StateError('No drawings enabled for $level');
    final prefs = await SharedPreferences.getInstance();
    final key = 'art-reference-bag-v1-$level';
    final byId = {for (final entry in entries) entry.id: entry};
    var bag = (prefs.getStringList(key) ?? <String>[])
        .where(byId.containsKey)
        .toSet()
        .toList();
    if (bag.isEmpty) {
      bag = byId.keys.toList()..shuffle(random ?? Random());
      final last = prefs.getString('$key-last');
      if (bag.length > 1 && bag.first == last) {
        final first = bag.first;
        bag[0] = bag.last;
        bag[bag.length - 1] = first;
      }
    }
    final chosen = bag.removeAt(0);
    await prefs.setStringList(key, bag);
    await prefs.setString('$key-last', chosen);
    return byId[chosen]!;
  }
}
