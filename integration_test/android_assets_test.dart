import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:twohearts/core/pet_model_catalog.dart';
import 'package:twohearts/services/supabase_service.dart';
import 'package:twohearts/widgets/pet_3d_viewer.dart';
import 'package:twohearts/widgets/forest_runner_native.dart';

Future<void> waitForJavaScript(
  WidgetTester tester,
  WebViewController controller,
  String expression,
  String description,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 90));
  while (DateTime.now().isBefore(deadline)) {
    try {
      final result = await controller.runJavaScriptReturningResult(expression);
      if (result == true || result == 'true') return;
    } catch (_) {
      // The first poll may precede navigation and DOM initialization.
    }
    await tester.pump(const Duration(milliseconds: 500));
  }
  final body = await controller.runJavaScriptReturningResult(
    'document.body ? document.body.innerText : "No document"',
  );
  fail('$description did not load in Android WebView: $body');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Pip loads and the native forest starts on Android', (
    tester,
  ) async {
    await SupabaseService.initialize();
    final pet = Completer<WebViewController>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Pet3DViewer(
            modelPath: PetModelCatalog.penguinModelPath,
            autoPlay: true,
            animationName: 'Idle_9',
            onWebViewCreated: pet.complete,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final petController = await pet.future.timeout(const Duration(seconds: 30));
    await waitForJavaScript(
      tester,
      petController,
      "document.querySelector('model-viewer')?.loaded === true",
      'Pip',
    );
    await waitForJavaScript(
      tester,
      petController,
      "['Running','Walking','Idle_9','Regular_Jump'].every(name => document.querySelector('model-viewer').availableAnimations.includes(name))",
      'Pip animations',
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));

    final forest = Completer<WebViewController>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ForestRunnerView(onWebViewCreated: forest.complete),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final controller = await forest.future.timeout(const Duration(seconds: 30));
    await waitForJavaScript(
      tester,
      controller,
      "document.getElementById('title')?.textContent === 'Un paseo con Pip' && !document.getElementById('start').disabled",
      'The complete forest, including the model with spaces in its name',
    );
    await controller.runJavaScript('''
      window.runnerEffectFrequencies = [];
      const audioPrototype = (window.AudioContext || window.webkitAudioContext).prototype;
      const originalOscillator = audioPrototype.createOscillator;
      audioPrototype.createOscillator = function() {
        const oscillator = originalOscillator.call(this);
        const originalSet = oscillator.frequency.setValueAtTime.bind(oscillator.frequency);
        oscillator.frequency.setValueAtTime = function(value, time) {
          window.runnerEffectFrequencies.push(value);
          return originalSet(value, time);
        };
        return oscillator;
      };
      document.getElementById('start').click();
    ''');
    await waitForJavaScript(
      tester,
      controller,
      "document.getElementById('panel').hidden && parseInt(document.getElementById('distance').textContent) > 0",
      'Starting a practice run through the native bridge',
    );
    await waitForJavaScript(
      tester,
      controller,
      'window.runnerEffectFrequencies.includes(880)',
      'Collecting a coin plays its sound',
    );
    await controller.runJavaScript("document.getElementById('jump').click()");
    await waitForJavaScript(
      tester,
      controller,
      'window.runnerEffectFrequencies.includes(240)',
      'Jumping plays its sound',
    );
    await waitForJavaScript(
      tester,
      controller,
      "window.runnerEffectFrequencies.includes(150) && document.getElementById('title').textContent === '¡Vuelve a intentarlo!'",
      'Collision plays its sound and ends the practice run',
    );
    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 5)));
}
