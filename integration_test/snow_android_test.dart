import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:twohearts/services/supabase_service.dart';
import 'package:twohearts/widgets/forest_runner_native.dart';

Future<void> waitFor(
  WidgetTester tester,
  WebViewController controller,
  String expression,
  String label,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 240));
  while (DateTime.now().isBefore(deadline)) {
    try {
      final value = await controller.runJavaScriptReturningResult(expression);
      if (value == true || value == 'true') return;
    } catch (_) {}
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
  }
  final body = await controller.runJavaScriptReturningResult(
    'document.body?.innerText',
  );
  fail('$label: $body');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android loads snow pets, starts training and advances the three-minute round, countdown, controls and final result',
    (tester) async {
      final originalErrorBuilder = ErrorWidget.builder;
      addTearDown(() => ErrorWidget.builder = originalErrorBuilder);
      await SupabaseService.initialize();
      final ready = Completer<WebViewController>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ForestRunnerView(
              snow: true,
              petSpecies: 'bear',
              onWebViewCreated: ready.complete,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      final controller = await ready.future.timeout(
        const Duration(seconds: 45),
      );
      await waitFor(
        tester,
        controller,
        "typeof document.getElementById('practice')?.onclick==='function'",
        'Snow menu',
      );
      print('QA_FRAME=snow_menu');
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds:2)));
      await controller.runJavaScript(
        "document.getElementById('mapChoice').value='1';document.getElementById('practice').click();",
      );
      await waitFor(
        tester,
        controller,
        "document.getElementById('hud')?.hidden===false && document.getElementById('controls')?.hidden===false",
        'Original 3D pets and training',
      );
      await waitFor(
        tester,
        controller,
        r"/^2:5[0-9]$/.test(document.getElementById('clock')?.textContent)",
        'Three-minute clock running after countdown',
      );
      print('QA_FRAME=snow_running');
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds:2)));
      final error = await controller.runJavaScriptReturningResult(
        "document.body.innerText.includes('No se pudo preparar la nieve')",
      );
      expect(error, isNot(true));
      await controller.runJavaScript(
        "document.getElementById('settingsButton').click();document.getElementById('controlMode').value='joystick';document.getElementById('controlMode').dispatchEvent(new Event('change'));document.getElementById('resume').click();",
      );
      await waitFor(
        tester,
        controller,
        "!document.getElementById('joystick').hidden && document.getElementById('arrows').hidden",
        'Joystick configuration',
      );
      await waitFor(tester, controller,
        "document.getElementById('clock')?.classList.contains('urgent')===true",
        'Last ten seconds visibly urgent');
      print('QA_FRAME=snow_final_ten');
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds:2)));
      await waitFor(tester, controller,
        "document.getElementById('result')?.hidden===false",
        'Full three-minute round finishes');
      print('QA_FRAME=snow_result');
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds:2)));
      ErrorWidget.builder = originalErrorBuilder;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}