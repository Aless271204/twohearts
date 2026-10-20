import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/features/social/nido_news.dart';

void main() {
  testWidgets('read a game tutorial and filter news on a narrow phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: NidoNews())));
    expect(find.text('Noticias y guías'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Guías'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tu pequeña guía de NIDO'));
    await tester.pumpAndSettle();
    expect(find.text('Empieza por su Nido'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Actualizaciones'));
    await tester.pumpAndSettle();
    expect(find.text('Las novedades tienen un lugar aquí'), findsOneWidget);
    expect(find.text('Tu pequeña guía de NIDO'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('every game has a dated guide and editorial ids are unique', () {
    expect(nidoArticles.map((a) => a.id).toSet().length, nidoArticles.length);
    expect(nidoArticles.map((a) => a.id), containsAll(
        ['runner', 'guardian', 'pong', 'quiz', 'art', 'penalties', 'maze']));
    expect(nidoArticles.every((a) => a.sections.isNotEmpty), isTrue);
  });
}
