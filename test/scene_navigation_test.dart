import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twohearts/widgets/immersive_game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:twohearts/widgets/app_scaffold.dart';
import 'package:twohearts/widgets/app_navigation.dart';

void main() {
  testWidgets('Fullscreen modes cover navigation and restore it on return at narrow widths', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('nido/game_display'), (call) async { calls.add(call); return null; });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('nido/game_display'), null));
    final router = GoRouter(initialLocation: '/tab2', routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppScaffold(navigationShell: shell),
        branches: [for (var i = 0; i < 5; i++) StatefulShellBranch(routes: [
          GoRoute(path: '/tab$i', builder: (context, state) => Scaffold(body: Center(child: FilledButton(
            child: const Text('Abrir modo'),
            onPressed: () => Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(builder: (context) => ImmersiveGame(child: Scaffold(body: Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Salir del modo'))))))),
          )))),
        ])],
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.byType(AppNavigation), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Abrir modo'));
    await tester.pumpAndSettle();
    expect(find.byType(AppNavigation), findsNothing);
    expect(find.byIcon(Icons.music_note_rounded), findsNothing);
    expect(calls.last.arguments, true);
    await tester.tap(find.text('Salir del modo'));
    await tester.pumpAndSettle();
    expect(find.byType(AppNavigation), findsOneWidget);
    expect(calls.last.arguments, false);
    expect(tester.takeException(), isNull);
  });
}
