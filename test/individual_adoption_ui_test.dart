import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twohearts/services/shared_pet_service.dart';
import 'package:twohearts/widgets/pet_adoption_welcome.dart';
import 'package:twohearts/widgets/pet_family_sheet.dart';
import 'package:twohearts/widgets/twohearts_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://preview.invalid',
      anonKey: 'local-preview-not-a-key',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
    );
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader(
      'NidoPreview',
    )..addFont(rootBundle.load('assets/fonts/DMSans[opsz,wght].ttf'))).load();
  });
  testWidgets(
    'unpaired user can see linking and the 4000 gold purchase route',
    (tester) async {
      tester.view.physicalSize = const Size(720, 1560);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPetService.instance.data = {
        'members': ['preview-user'],
        'pets': [],
        'selection_confirmed': false,
      };
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            fontFamily: 'NidoPreview',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFF05280),
            ),
          ),
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              backgroundColor: const Color(0xFFFFF9FA),
              body: const SafeArea(child: PetAdoptionWelcome()),
              bottomNavigationBar: HeartNavigation(
                selected: 3,
                onSelect: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Adoptar · 4.000 de oro'), findsOneWidget);
      expect(find.text('Enlazar nuestras cuentas'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('outputs/performance-135').create(recursive: true);
        await File(
          'outputs/performance-135/individual-adoption-preview.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    },
  );
  testWidgets('two pets of the same species remain separate choices', (
    tester,
  ) async {
    SharedPetService.instance.data = {
      'members': ['a', 'b'],
      'species': 'chick',
      'name': 'Luz',
      'selection_confirmed': true,
      'active_pet_id': 'pet-a',
      'pets': [
        {'id': 'pet-a', 'species': 'chick', 'name': 'Luz', 'level': 1},
        {'id': 'pet-b', 'species': 'chick', 'name': 'Sol', 'level': 2},
      ],
    };
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PetFamilySheet())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Luz · Pollito'), findsOneWidget);
    expect(find.text('Sol · Pollito'), findsOneWidget);
    await tester.tap(find.text('Sol · Pollito'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Sol',
    );
    expect(tester.takeException(), isNull);
  });
}
