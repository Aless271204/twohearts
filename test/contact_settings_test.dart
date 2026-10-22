import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/widgets/contact_settings.dart';

void main() {
  testWidgets('suggestions open an encoded draft, never an empty message', (
    tester,
  ) async {
    Uri? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ContactSettings(
              openMail: (uri) async {
                opened = uri;
                return true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Recomendación'));
    await tester.pumpAndSettle();
    final button = find.widgetWithText(
      FilledButton,
      'Enviar sugerencia por correo',
    );
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.enterText(
      find.byType(TextField),
      '  Más ropa & juegos + emoción\nGracias  ',
    );
    await tester.pump();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(opened!.scheme, 'mailto');
    expect(opened!.path, ContactSettings.email);
    expect(opened!.queryParameters['subject'], 'Sugerencia para Nido');
    expect(
      opened!.queryParameters['body'],
      'Más ropa & juegos + emoción\nGracias',
    );
  });
  testWidgets(
    'work opens CV draft; unavailable email offers copy without losing text',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Uri? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ContactSettings(
                openMail: (uri) async {
                  opened = uri;
                  return false;
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Trabaja con nosotros'));
      await tester.pumpAndSettle();
      expect(opened!.path, ContactSettings.email);
      expect(opened!.queryParameters['body'], contains('Adjunto mi CV'));
      expect(find.text('Copiar correo'), findsOneWidget);
      expect(find.text('Copiar mensaje'), findsOneWidget);
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recomendación'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Mi idea');
      await tester.pump();
      await tester.tap(find.text('Enviar sugerencia por correo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      expect(find.text('Mi idea'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
