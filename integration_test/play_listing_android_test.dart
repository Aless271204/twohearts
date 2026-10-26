import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../lib/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('capture real Android entry screens without personal data', (tester) async {
    final originalErrorBuilder = ErrorWidget.builder;
    addTearDown(() => ErrorWidget.builder = originalErrorBuilder);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    app.main();
    for (var i=0;i<30;i++) {
      await tester.pump(const Duration(milliseconds:100));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds:200)));
    }
    expect(find.text('Comenzar'), findsOneWidget);
    print('QA_FRAME=nido_welcome');
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds:3)));
    await tester.tap(find.text('¿Ya tienes cuenta? Inicia sesión'));
    for(var i=0;i<8;i++) await tester.pump(const Duration(milliseconds:100));
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.byType(TextField).evaluate().isNotEmpty || find.byType(TextFormField).evaluate().isNotEmpty,isTrue);
    print('QA_FRAME=nido_login');
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds:3)));
    ErrorWidget.builder = originalErrorBuilder;
  });
}
