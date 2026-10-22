import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/features/social/nido_ranking.dart';
import 'package:twohearts/features/social/social_screen.dart';
import 'package:twohearts/features/social/social_repository.dart';

void main() {
  test('scores preserve each game metric instead of comparing incompatible units', () {
    expect(rankingScore('pebble_runner', 1234), '1234 m');
    expect(rankingScore('guardian', 18001), '1:00');
    expect(rankingScore('maze', 999958), '42 pasos');
    expect(rankingScore('pong', 3), '3 victorias');
    expect(rankingScore('snow', 12), '12 puntos');
    expect(rankingScopes('snow').keys, ['scores']);
    expect(rankingScopes('guardian').length, 4);
    expect(rankingScopes('guardian').keys.every((key) => key.startsWith('hard:')), isTrue);
    expect(rankingScopes('maze').keys.every((key) => key.startsWith('hard:')), isTrue);
    expect(rankingScopes('art').keys, ['wins:2']);
  });
  testWidgets('weekly record and global filter load on a narrow screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final audiences = <String>[];
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: NidoRanking(loader: (game, audience, scope, visible) async {
      audiences.add(audience);
      return {'mine': {'score': 1500, 'rank': 2}, 'rows': [
        {'rank': 1, 'name': 'Amistad', 'score': 2000, 'is_me': false},
        {'rank': 2, 'name': 'Mi mascota', 'score': 1500, 'is_me': true},
      ], 'global_visible': false};
    }))));
    await tester.pumpAndSettle();
    expect(find.text('Tu récord semanal'), findsOneWidget);
    expect(find.text('Puesto 2'), findsOneWidget);
    await tester.tap(find.text('Global'));
    await tester.pumpAndSettle();
    expect(audiences, ['friends', 'global']);
    expect(find.text('Aparecer en Global'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Social separates Feed, Ranking and Noticias and their subfilters', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SocialScreen(repository: DemoSocialRepository())));
    await tester.pumpAndSettle();
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Amigos'), findsOneWidget);
    expect(find.text('Descubrir'), findsOneWidget);
    await tester.tap(find.text('Ranking')); await tester.pumpAndSettle();
    expect(find.text('Global'), findsOneWidget);
    expect(find.text('Descubrir'), findsNothing);
    await tester.tap(find.text('Noticias')); await tester.pumpAndSettle();
    expect(find.text('Actualizaciones'), findsOneWidget);
    expect(find.text('Guías'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
