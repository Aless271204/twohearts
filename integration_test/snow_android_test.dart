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
  final deadline = DateTime.now().add(const Duration(seconds: 120));
  while (DateTime.now().isBefore(deadline)) {
    try {
      final value = await controller.runJavaScriptReturningResult(expression);
      if (value == true || value == 'true') return;
    } catch (_) {}
    await tester.pump(const Duration(milliseconds: 500));
  }
  final body = await controller.runJavaScriptReturningResult(
    'document.body?.innerText',
  );
  fail('$label: $body');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android loads snow pets, starts training and advances the one-minute clock',
    (tester) async {
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
        r"/^0:[0-5][0-9]$/.test(document.getElementById('clock')?.textContent)",
        'One-minute simulation clock',
      );
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
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
