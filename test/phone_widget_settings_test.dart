import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/widgets/phone_widget_settings.dart';

void main() {
  testWidgets('Android settings opens the permanent widget editor', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    const channel = MethodChannel('nido/art');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return true;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PhoneWidgetSettings())),
    );
    await tester.tap(find.text('Widgets del teléfono'));
    await tester.pump();
    expect(calls.single.method, 'openWidgetSettings');
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
