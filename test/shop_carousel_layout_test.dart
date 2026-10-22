import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twohearts/presentation/shop_screen/inventory_screen.dart';
import 'package:twohearts/services/inventory_service.dart';
import 'package:twohearts/core/shop_economy_v2.dart';
import 'package:twohearts/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final channel in [
      'com.llfbandit.app_links/events',
      'com.llfbandit.app_links/messages',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channel), (_) async => null);
    }
    await Supabase.initialize(
      url: 'https://test.invalid',
      anonKey: 'test-public-key',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  testWidgets(
    'shop category carousels fit a phone and expose every item without pagination',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final inventory = InventoryService.instance;
      inventory.catalog = roomShopV2
          .where(
            (r) => r['item_key'].toString().startsWith('room_nursery_space_'),
          )
          .map(InventoryItem.new)
          .toList();
      inventory.bundles = [];
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          theme: AppTheme.lightTheme,
          home: const ShopScreen(initialScope: 'room', previewMode: true),
        ),
      );
      await tester.pumpAndSettle();
      final item = find.text(inventory.catalog.first.name);
      await tester.scrollUntilVisible(
        item,
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(item, findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.text('Siguiente'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'every bundle keeps its complete image when paging back and forth',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final inventory = InventoryService.instance;
      inventory.catalog = roomShopV2.map(InventoryItem.new).toList();
      inventory.bundles = [
        for (final theme in [
          'space',
          'gamer',
          'cars',
          'dolls',
          'castle',
          'worldcup',
          'knights',
          'cities',
        ])
          {
            'bundle_key': 'room_set_$theme',
            'scope': 'room',
            'name': 'Habitación $theme',
            'thumbnail_asset':
                'assets/images/products/children-rooms/room_nursery_${theme}_bed.webp',
            'items': inventory.catalog
                .where((i) => i.key.startsWith('room_nursery_${theme}_'))
                .map((i) => {'item_key': i.key})
                .toList(),
          },
      ];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const ShopScreen(initialScope: 'room', previewMode: true),
        ),
      );
      await tester.pumpAndSettle();
      final cover = tester.widget<Image>(
        find.byKey(const ValueKey('showcase-image-room_set_space')),
      );
      expect((cover.image as AssetImage).assetName, contains('showcases-v2/'));
      expect(cover.fit, BoxFit.contain);
      final pages = find.byType(PageView).first;
      for (final theme in [
        'space',
        'gamer',
        'cars',
        'dolls',
        'castle',
        'worldcup',
        'knights',
        'cities',
      ]) {
        expect(
          find.byKey(ValueKey('showcase-image-room_set_$theme')),
          findsOneWidget,
        );
        expect(find.byType(InventoryPreview), findsNothing);
        expect(tester.takeException(), isNull);
        if (theme != 'cities') {
          await tester.drag(pages, const Offset(-340, 0));
          await tester.pumpAndSettle();
        }
      }
      for (var i = 0; i < 7; i++) {
        await tester.drag(pages, const Offset(340, 0));
        await tester.pumpAndSettle();
      }
      expect(
        find.byKey(const ValueKey('showcase-image-room_set_space')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
