import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/widgets/game_launch_menu.dart';

void main() {
  for (final game in ['pong', 'quiz']) {
    testWidgets(
      '$game launcher fits a phone and returns the selected room mode',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        String? selected;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  child: const Text('Abrir'),
                  onPressed: () async {
                    selected = await showDialog<String>(
                      context: context,
                      builder: (_) => GameLaunchMenu(game: game),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Abrir'));
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          find.text(game == 'pong' ? 'Ping pong' : '¿Cuánto nos conocemos?'),
          findsOneWidget,
        );
        expect(find.text('Crear sala'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Crear sala'));
        await tester.pump(const Duration(milliseconds: 400));
        expect(selected, 'create');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
