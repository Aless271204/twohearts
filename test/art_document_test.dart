import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twohearts/core/art_document.dart';
import 'package:twohearts/widgets/art_studio.dart';
import 'package:twohearts/core/art_reference_catalog.dart';
import 'package:twohearts/presentation/games/art_game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> reviewFonts() async {
    if (Platform.isWindows && Platform.environment['NIDO_CAPTURE_ART'] == '1') {
      final loader = FontLoader('Roboto')
        ..addFont(
          File(
            'C:/Windows/Fonts/arial.ttf',
          ).readAsBytes().then((b) => ByteData.sublistView(b)),
        );
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          File(
            'C:/development/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytes().then((b) => ByteData.sublistView(b)),
        );
      await icons.load();
    }
  }

  test('blank art gets zero; identical nonempty art gets 100', () {
    final white = Uint8List.fromList(List.filled(64, 255));
    final ink = Uint8List.fromList(white);
    ink[0] = 30;
    ink[1] = 40;
    ink[2] = 50;
    expect(artSimilarity(white, ink)['total'], 0);
    expect(artSimilarity(ink, ink)['total'], 100);
    expect(() => artSimilarity(white, Uint8List(3)), throwsArgumentError);
  });
  testWidgets(
    'eraser clears current layer without damaging lower layers; undo and redo restore',
    (tester) async {
      final doc = ArtDocument();
      doc.add(const ArtMark(ArtTool.brush, Colors.red, 80, [Offset(100, 100)]));
      doc.active = 1;
      doc.add(
        const ArtMark(ArtTool.brush, Colors.blue, 60, [Offset(100, 100)]),
      );
      doc.add(
        const ArtMark(ArtTool.eraser, Colors.black, 40, [Offset(100, 100)]),
      );
      Future<Color> pixel() async {
        final img = await doc.render();
        final raw = (await img.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        img.dispose();
        final i = (100 * 512 + 100) * 4;
        return Color.fromARGB(raw[i + 3], raw[i], raw[i + 1], raw[i + 2]);
      }

      expect((await tester.runAsync(pixel))!.toARGB32(), Colors.red.toARGB32());
      doc.undo();
      expect(
        (await tester.runAsync(pixel))!.toARGB32(),
        Colors.blue.toARGB32(),
      );
      doc.redo();
      expect((await tester.runAsync(pixel))!.toARGB32(), Colors.red.toARGB32());
      doc.dispose();
    },
  );
  testWidgets('fill respects a closed outline and is undoable', (tester) async {
    final doc = ArtDocument();
    doc.add(
      const ArtMark(ArtTool.rectangle, Colors.black, 6, [
        Offset(100, 100),
        Offset(200, 200),
      ]),
    );
    await tester.runAsync(() => doc.fill(const Offset(150, 150), Colors.pink));
    final image = await tester.runAsync(() => doc.render());
    final data = await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    final bytes = data!.buffer.asUint8List();
    expect(bytes[(150 * 512 + 150) * 4], Colors.pink.r * 255);
    expect(bytes[(50 * 512 + 50) * 4], 255);
    doc.undo();
    expect(doc.layers.first.marks.length, 1);
    image!.dispose();
    doc.dispose();
  });
  testWidgets(
    'personal photos keep square dimensions in original, pixel, 3D and sketch modes',
    (tester) async {
      final source = (await rootBundle.load(
        'assets/images/art_references/rio.webp',
      )).buffer.asUint8List();
      final mascot = await tester.runAsync(() => loadArtPet(0));
      for (final style in ReferenceStyle.values) {
        final image = await tester.runAsync(
          () => prepareArtReference(
            source,
            style: style,
            difficulty: 1,
            mascot: mascot,
          ),
        );
        expect(image!.width, 512);
        expect(image.height, 512);
        if (Platform.environment['NIDO_CAPTURE_ART'] == '1')
          await tester.runAsync(() async {
            await Directory('outputs/art-review').create(recursive: true);
            await File(
              'outputs/art-review/reference-${style.name}.png',
            ).writeAsBytes(
              (await image.toByteData(
                format: ui.ImageByteFormat.png,
              ))!.buffer.asUint8List(),
            );
          });
        image.dispose();
      }
      mascot!.dispose();
    },
  );
  testWidgets(
    'phone canvas has all tools, draws with touch and produces actual review PNG',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(reviewFonts);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final doc = ArtDocument(), key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: ColoredBox(
                color: const Color(0xFFFFF7F5),
                child: SingleChildScrollView(
                  child: ArtStudio(document: doc, draftKey: 'test-draft'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final target = find.byKey(const Key('nido-art-canvas'));
      await tester.dragFrom(
        tester.getTopLeft(target) + const Offset(80, 100),
        const Offset(120, 70),
      );
      await tester.pumpAndSettle();
      expect(doc.layers.first.marks, isNotEmpty);
      expect(find.text('Pincel'), findsOneWidget);
      expect(find.text('Rellenar'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (Platform.environment['NIDO_CAPTURE_ART'] == '1') {
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!.buffer.asUint8List();
          await Directory('outputs/art-review').create(recursive: true);
          await File('outputs/art-review/studio-phone.png').writeAsBytes(bytes);
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
      doc.dispose();
    },
  );
  testWidgets(
    'drawing lobby shows the three difficulties and actual mascot reference',
    (tester) async {
      await tester.runAsync(reviewFonts);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(key: key, child: const ArtGameScreen()),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 350)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Fácil'), findsOneWidget);
      expect(find.text('Medio'), findsOneWidget);
      expect(find.text('Difícil'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (Platform.environment['NIDO_CAPTURE_ART'] == '1') {
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage();
          await Directory('outputs/art-review').create(recursive: true);
          await File('outputs/art-review/lobby-phone.png').writeAsBytes(
            (await image.toByteData(
              format: ui.ImageByteFormat.png,
            ))!.buffer.asUint8List(),
          );
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
}
