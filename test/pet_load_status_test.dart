import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/widgets/pet_load_status.dart';

void main() {
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
