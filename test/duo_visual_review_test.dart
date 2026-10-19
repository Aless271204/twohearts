import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twohearts/presentation/games/duo_game_screen.dart';
import 'package:twohearts/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://test.invalid',
      anonKey: 'test-public-key',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  for (final game in ['pong', 'quiz']) {
    testWidgets(
      '$game portrait artwork, readable controls and response confirmation',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        GoogleFonts.config.allowRuntimeFetching = false;
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('com.ryanheise.just_audio.methods'),
              (call) async => <String, dynamic>{},
            );
        await tester.runAsync(() async {
          for (final font in const [
            ('NidoSans', 'assets/fonts/DMSans[opsz,wght].ttf'),
            ('NidoSerif', 'assets/fonts/PlayfairDisplay[wght].ttf'),
            (
              'MaterialIcons',
              'C:/development/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
            ),
          ]) {
            final loader = FontLoader(font.$1)
              ..addFont(File(font.$2).readAsBytes().then(ByteData.sublistView));
            await loader.load();
          }
        });
        final boundary = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: RepaintBoundary(
              key: boundary,
              child: DuoGameScreen(game: game, mode: 'train'),
            ),
          ),
        );
        for (var i = 0; i < 28; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 600)),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        if (game == 'quiz') {
          final option = find.byKey(const ValueKey('quiz-option-0'));
          await tester.ensureVisible(option);
          await tester.tap(option);
          await tester.pump();
          expect(
            find.text('Respuesta guardada. Esperando a tu pareja…'),
            findsNothing,
          );
          final confirm = find.byKey(const ValueKey('quiz-confirm'));
          await tester.ensureVisible(confirm);
          await tester.pump();
          expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
          await capture(tester, boundary, 'quiz-selected');
          await tester.tap(confirm);
          await tester.pump();
          expect(tester.takeException(), isNull);
        } else {
          expect(find.text('Paleta XL'), findsOneWidget);
          await capture(tester, boundary, 'pong-playing');
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  }
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  if (Platform.environment['NIDO_CAPTURE_ART'] != '1') return;
  await tester.runAsync(() async {
    final render =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('outputs/duo-visual-review').create(recursive: true);
    await File(
      'outputs/duo-visual-review/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
