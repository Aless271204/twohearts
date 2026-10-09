import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final voiceReady = await const MethodChannel('nido/pet_voice').invokeMethod<bool>('prepare').timeout(const Duration(seconds: 30));
    expect(voiceReady, isA<bool>());
    if (voiceReady == true) {
      await const MethodChannel('nido/pet_voice').invokeMethod('speak', {'text': 'Hola, soy Pip.'}).timeout(const Duration(seconds: 20));
    }
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

    final fittedPet = Completer<WebViewController>();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ForestRunnerView(
      petOnly: true,
      petOrbit: true,
      animationName: 'Running',
      appearance: '{"pet_head":{"style":"crown","color":"#f6ce68"},"pet_neck":{"style":"scarf","color":"#e6546a"},"pet_back":{"style":"backpack","color":"#538ee5"}}',
      onWebViewCreated: fittedPet.complete,
    ))));
    await tester.pump(const Duration(seconds: 1));
    final fittedController = await fittedPet.future.timeout(const Duration(seconds: 30));
    await waitForJavaScript(tester, fittedController,
      "document.body.classList.contains('pet-only') && ['Head','Neck','Spine2'].every(name => document.body.dataset.petAnchors?.includes(name)) && document.body.dataset.petAnimation === 'Running'",
      'The actual pet renderer attaches accessories to the animated original rig offline');
    final idleUrl = Uri.parse((await fittedController.currentUrl())!).replace(queryParameters: {'pet': '1', 'orbit': '0', 'animation': 'Idle_9'});
    await fittedController.loadRequest(idleUrl);
    await waitForJavaScript(tester, fittedController,
      "document.body.dataset.petAnimation === 'Natural_Rest' && document.body.dataset.petShape === 'delicate' && document.body.dataset.petPose === 'standing' && document.body.dataset.petGrounded === 'true'",
      'The room uses the original idle pose and a grounded pet');
    await fittedController.runJavaScript("""
      const fixedPosition = document.body.dataset.petPosition;
      const canvas = document.querySelector('canvas');
      canvas.dispatchEvent(new PointerEvent('pointerdown', {clientX: 100, clientY: 200}));
      canvas.dispatchEvent(new PointerEvent('pointermove', {clientX: 260, clientY: 400}));
      canvas.dispatchEvent(new PointerEvent('pointerup', {clientX: 260, clientY: 400}));
      setTimeout(() => { window.petStableIdleValid = document.body.dataset.petPosition === fixedPosition && document.body.dataset.petAnimation === 'Natural_Rest'; }, 1500);
    """);
    await waitForJavaScript(tester, fittedController, 'window.petStableIdleValid === true',
      'Idle pose remains fixed after touch input and elapsed time');

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
      "document.getElementById('title')?.textContent === 'Un paseo con tu mascota' && !document.getElementById('start').disabled",
      'The complete forest, including the model with spaces in its name',
    );
    await waitForJavaScript(tester, controller,
      "document.querySelector('canvas') !== null && document.getElementById('forest-background-video') === null",
      'The unified 3D forest loads offline without a video layer');
    await controller.runJavaScript('''
      window.runnerMediaRangeValid = false;
      fetch('forest-kingdom-loop.mp4', {headers: {Range: 'bytes=0-31'}})
        .then(async response => {
          const data = new Uint8Array(await response.arrayBuffer());
          window.runnerMediaRangeValid = response.status === 206 && data.length === 32 &&
            String.fromCharCode(...data.slice(4, 8)) === 'ftyp';
        });
    ''');
    await waitForJavaScript(tester, controller,
      'window.runnerMediaRangeValid === true', 'Local video byte-range delivery');
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
      // Send both controls inside the WebView at the first running frame. Host
      // polling can be delayed by software rendering and miss this window.
      const earlyControls = setInterval(() => {
        if (document.getElementById('panel').hidden &&
            parseInt(document.getElementById('distance').textContent) > 0) {
          document.getElementById('jump').click();
          document.getElementById('left').click();
          document.getElementById('pause').click();
          window.runnerEarlyControlsValid = window.runnerEffectFrequencies.includes(240) &&
            true &&
            !document.getElementById('panel').hidden;
          clearInterval(earlyControls);
        }
      }, 16);
      document.getElementById('start').click();
    ''');
    await waitForJavaScript(
      tester,
      controller,
      'window.runnerEarlyControlsValid === true',
      'Starting, jumping and pausing the native run pauses its scene',
    );
    await controller.runJavaScript('''
      document.getElementById('start').click();
      document.getElementById('right').click(); // Return from the lane-change check to the opening coin lane.
      window.runnerResumeValid = true &&
        document.getElementById('panel').hidden;
    ''');
    await waitForJavaScript(tester, controller,
      'window.runnerResumeValid === true',
      'Resuming restarts the scene');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await waitForJavaScript(tester, controller,
      "window.runnerAudioState() === 'suspended' && !document.getElementById('panel').hidden",
      'Backgrounding the native app suspends music and pauses the run');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await controller.runJavaScript("document.getElementById('start').click();");
    await waitForJavaScript(
      tester,
      controller,
      "window.runnerEffectFrequencies.includes(880) && parseInt(document.getElementById('coins').textContent.replace(/[^0-9]/g,'')) > 0",
      'Collecting a coin plays its sound',
    );
    await waitForJavaScript(
      tester,
      controller,
      "window.runnerEffectFrequencies.includes(150) && document.getElementById('title').textContent === '¡Vuelve a intentarlo!'",
      'Collision plays its sound and ends the practice run',
    );
    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 7)));
}

