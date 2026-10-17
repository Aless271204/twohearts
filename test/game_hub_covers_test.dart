import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twohearts/presentation/games/new_game_hub.dart';
import 'package:twohearts/widgets/animated_game_cover.dart';
import 'package:twohearts/theme/app_theme.dart';

void main() {
  testWidgets(
    'all five games have illustrated covers on a narrow mobile screen',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      GoogleFonts.config.allowRuntimeFetching = false;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      if (Platform.isWindows) {
        await tester.runAsync(() async {
          final loader = FontLoader('Roboto')
            ..addFont(
              File(
                'C:/Windows/Fonts/arial.ttf',
              ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
            );
          await loader.load();
          final icons = FontLoader('MaterialIcons')
            ..addFont(
              File(
                'C:/development/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
              ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
            );
          await icons.load();
        });
      }
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              disableAnimations: true,
            ),
            child: RepaintBoundary(
              key: key,
              child: const GameHubScreen(previewMode: true),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final seen = tester
          .widgetList<AnimatedGameCover>(find.byType(AnimatedGameCover))
          .map((cover) => cover.panel)
          .toSet();
      expect(tester.takeException(), isNull);
      if (Platform.environment['NIDO_CAPTURE_ART'] == '1') {
        await tester.runAsync(() async {
          final render =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await render.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('outputs/art-catalog-review').create(recursive: true);
          await File(
            'outputs/art-catalog-review/game-hub.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      for (var page = 0; page < 3; page++) {
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pump(const Duration(milliseconds: 500));
        for (final element in find.byType(AnimatedGameCover).evaluate()) {
          final cover = element.widget as AnimatedGameCover;
          seen.add(cover.panel);
          expect(tester.getSize(find.byWidget(cover)), const Size(350, 292));
        }
      }
      expect(seen, {0, 1, 2, 3, 4});
      expect(tester.takeException(), isNull);
      if (Platform.environment['NIDO_CAPTURE_ART'] == '1') {
        await tester.runAsync(() async {
          final render =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await render.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            'outputs/art-catalog-review/game-hub-bottom.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
