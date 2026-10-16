import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/services/couple_location_service.dart';
import 'package:twohearts/widgets/partner_link_card.dart';
import 'package:twohearts/presentation/home_screen/pet_room_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-key',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  test(
    'a disabled share retains its last point and cannot claim to be live',
    () {
      final location = SharedLocationPoint.parse({
        'sharing': false,
        'lat': -0.2,
        'lon': -78.5,
        'located_at': DateTime.now().toUtc().toIso8601String(),
      })!;
      expect(location.point!.latitude, -.2);
      expect(location.live, isFalse);
      expect(location.caption, startsWith('Última ubicación'));
      expect(
        SharedLocationPoint.parse({
          'sharing': true,
          'lat': 100,
          'lon': 0,
        })!.point,
        isNull,
      );
      final old = SharedLocationPoint.parse({
        'sharing': true,
        'lat': 1,
        'lon': 2,
        'located_at': DateTime.now()
            .subtract(const Duration(minutes: 5))
            .toIso8601String(),
      })!;
      expect(old.live, isFalse);
    },
  );
  test(
    'turning sharing off remains off after a network failure and app restart',
    () async {
      var online = false;
      final point = {
        'mine': {
          'sharing': true,
          'lat': 1,
          'lon': 2,
          'located_at': DateTime.now().toIso8601String(),
        },
        'partner': null,
      };
      Future<dynamic> request(String action, dynamic position) async {
        if (!online) throw StateError('offline');
        return point;
      }

      final service = CoupleLocationService(
        accountResolver: () => 'offline-test',
        request: request,
      );
      service.mine = SharedLocationPoint.parse(point['mine']);
      await service.setSharing(false);
      expect(service.sharing, isFalse);
      expect(service.mine!.point!.latitude, 1);
      expect(
        (await SharedPreferences.getInstance()).getBool(
          'location_enabled_offline-test',
        ),
        isFalse,
      );
      service.dispose();
      online = true;
      final restarted = CoupleLocationService(
        accountResolver: () => 'offline-test',
        request: request,
      );
      await restarted.start();
      expect(restarted.sharing, isFalse);
      expect(restarted.mine!.point!.longitude, 2);
      restarted.dispose();
    },
  );
  testWidgets('the account code entry opens the linking section', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PartnerLinkCard(onOpen: () => opened = true)),
      ),
    );
    await tester.tap(find.text('Código de pareja'));
    expect(opened, isTrue);
  });
  testWidgets(
    'room fills the viewport then divides evenly without recreating its scene',
    (tester) async {
      const sceneKey = ValueKey('room-scene');
      await tester.pumpWidget(
        const MaterialApp(
          home: PetRoomScreen(
            previewMode: true,
            roomScene: ColoredBox(key: sceneKey, color: Colors.white),
          ),
        ),
      );
      final full = tester.getSize(find.byType(PetRoomScreen)).height;
      expect(tester.getSize(find.byKey(sceneKey)).height, full);
      final sceneElement = tester.element(find.byKey(sceneKey));
      await tester.tap(find.byTooltip('Personalizar habitación'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 210));
      expect(
        tester.getSize(find.byKey(sceneKey)).height,
        greaterThan(full / 2),
      );
      await tester.pump(const Duration(milliseconds: 230));
      expect(
        tester.getSize(find.byKey(sceneKey)).height,
        closeTo(full / 2, .1),
      );
      expect(
        tester.getTopLeft(find.byType(RoomDecorationPanel)).dy,
        closeTo(full / 2, .1),
      );
      expect(tester.element(find.byKey(sceneKey)), same(sceneElement));
      await tester.tap(find.byTooltip('Nuestro cofre'));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(sceneKey)).height,
        closeTo(full / 2, .1),
      );
      expect(tester.element(find.byKey(sceneKey)), same(sceneElement));
      expect(find.byType(PetChest), findsOneWidget);
      expect(find.byTooltip('Volver al nido'), findsNothing);
      await tester.tap(find.byTooltip('Cerrar cofre'));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(sceneKey)).height, full);
      expect(tester.element(find.byKey(sceneKey)), same(sceneElement));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'decoration stays in a light half-screen panel with room categories',
    (tester) async {
      var closed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: 300,
                child: RoomDecorationPanel(
                  previewMode: true,
                  onClose: () => closed = true,
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(RoomDecorationPanel)).height, 300);
      expect(find.text('Techo'), findsOneWidget);
      expect(find.text('Pared'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(RoomDecorationPanel),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, const Color(0xFFFFF9FA));
      await tester.tap(find.byTooltip('Cerrar decoración'));
      expect(closed, isTrue);
    },
  );
}
