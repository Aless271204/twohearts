import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/widgets/rose_ui.dart';
import 'package:twohearts/widgets/scene_status.dart';

void main() {
  testWidgets('Loading and retry fit a narrow screen with enlarged text', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var retries = 0;
    await tester.pumpWidget(MaterialApp(home: MediaQuery(data: const MediaQueryData(size: Size(320, 700), textScaler: TextScaler.linear(1.5), disableAnimations: true), child: Scaffold(body: SceneStatus(title: 'Tu colección', message: 'No pudimos cargar los objetos. Comprueba la conexión.', loading: false, onRetry: () => retries++)))));
    await tester.tap(find.text('Volver'));
    expect(retries, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: RoseLoading(label: 'Preparamos sus recuerdos…'))));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Preparamos sus recuerdos…'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Every generated illustration panel fits the card without overflow', (tester) async {
    for (var i=0; i<6; i++) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: SizedBox(width: 136, height: 120, child: ProductArt(panel: i))))));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    }
    for (var i=0; i<3; i++) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: SizedBox(width: 280, height: 320, child: GameArt(panel: i))))));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    }
  });
}
