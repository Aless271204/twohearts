import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twohearts/services/geographic_location_service.dart';
import 'package:twohearts/widgets/place_search_sheet.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('GeoJSON uses longitude then latitude and rejects invalid positions', () {
    Map<String, dynamic> feature(dynamic coordinates, {String type = 'Point'}) => {
      'geometry': {'type': type, 'coordinates': coordinates},
      'properties': {'name': 'Quito', 'city': 'Quito', 'country': 'Ecuador'},
    };
    final places = GeographicLocationService.parseResponse({'features': [
      feature([-78.512, -0.22]), feature([-78.512, -0.22]),
      feature([10, 95]), feature(['wrong', 0]), feature([0]),
      feature([0, 0], type: 'LineString'), null,
    ]});
    expect(places, hasLength(1));
    expect(places.single.label, 'Quito, Ecuador');
    expect(places.single.point.latitude, -0.22);
    expect(places.single.point.longitude, -78.512);
  });
  test('Chosen registered place persists without an additional network request', () async {
    final service = GeographicLocationService(client: MockClient((_) async => throw StateError('Must use saved choice')));
    await service.remember('  Quito ', const GeoPlace('Quito, Ecuador', LatLng(-0.22, -78.512)));
    expect((await service.resolve('quito'))!.label, 'Quito, Ecuador');
    expect((await service.resolve('Quito, Ecuador'))!.point.longitude, -78.512);
    expect(await service.resolve(''), isNull);
  });
  testWidgets('Unresolved address never receives invented default coordinates', (tester) async {
    await tester.runAsync(() async {
    SharedPreferences.setMockInitialValues({});
    final service = GeographicLocationService(client: MockClient((_) async => http.Response(jsonEncode({'features': []}), 200)));
    expect(await service.resolve('unknown place'), isNull);
    expect(await service.cached('unknown place'), isNull);
    });
  });
  testWidgets('Location picker remains scrollable with keyboard and large text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: MediaQuery(
      data: MediaQueryData(size: Size(320, 640), viewInsets: EdgeInsets.only(bottom: 280), textScaler: TextScaler.linear(1.4)),
      child: Scaffold(body: PlaceSearchSheet()),
    )));
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
