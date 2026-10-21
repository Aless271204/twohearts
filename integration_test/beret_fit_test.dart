import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:twohearts/widgets/forest_runner_native.dart';
import 'snow_android_test.dart' show waitFor;
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Small beret on original pets, real renderer and motion', (tester) async {
    final ready = Completer<WebViewController>();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ForestRunnerView(
      petOnly: true, onWebViewCreated: ready.complete,
    ))));
    await tester.pump(const Duration(seconds: 1));
    final controller = await ready.future.timeout(const Duration(seconds: 45));
    await waitFor(tester, controller, "document.body.classList.contains('pet-ready')", 'Initial pet');
    final raw = await controller.runJavaScriptReturningResult('location.href');
    final base = Uri.parse(raw.toString().startsWith('"') ? jsonDecode(raw.toString()) as String : raw.toString());
    final catalog = jsonDecode(await rootBundle.loadString('assets/runner/accessory-catalog.json')) as List;
    final source = Map<String, dynamic>.from((catalog.firstWhere((e) => e['item_key']=='beret_chic') as Map)['appearance'] as Map);
    for (final species in ['penguin', 'bear', 'pig', 'chick']) {
      final appearance = {...source,
        'model_asset': 'assets/runner/accessories/experimental_beret_chic_${species}_v8.glb',
        'species_models': {species: 'assets/runner/accessories/experimental_beret_chic_${species}_v8.glb'},
        'asset_revision': 'closed-small-v8',
      };
      for (final frame in [('Rest', 0), ('Rest', 90), ('Rest', 180), ('Running', 0), ('Regular_Jump', 0)]) {
        final uri = base.replace(queryParameters: {
          'pet':'1', 'species':species, 'review_angle':'${frame.$2}',
          if(frame.$1!='Rest') 'review_motion':frame.$1,
          if(frame.$1!='Rest') 'review_phase':'.35',
          'appearance':jsonEncode({'pet_head':appearance}),
        });
        await controller.loadRequest(uri);
        await waitFor(tester, controller, "document.body.classList.contains('pet-ready')", '$species ${frame.$1}');
        await tester.pump(const Duration(seconds: 2));
        // The CI host captures the actual Android screen, including the WebView.
        // ignore: avoid_print
        print('QA_FRAME=${species}_${frame.$1}_${frame.$2}');
        await tester.pump(const Duration(seconds: 4));
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 12)));
}
