import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/widgets/pet_load_status.dart';

void main() {
  testWidgets(
    'loading always offers retry after twenty seconds without a result',
    (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PetLoadStatus(onRetry: () => retries++)),
        ),
      );
      await tester.pump(const Duration(seconds: 21));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Volver a cargar'), findsOneWidget);
      await tester.tap(find.text('Volver a cargar'));
      await tester.pump();
      expect(retries, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('failed loading replaces spinner with a working retry action', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PetLoadStatus(onRetry: () => retried = true)),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PetLoadStatus(
            message: 'No pudimos cargar tu mascota.',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('Volver a cargar'));
    expect(retried, isTrue);
  });
}
