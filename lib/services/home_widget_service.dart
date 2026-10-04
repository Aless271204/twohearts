import 'package:flutter/foundation.dart';

import 'home_widget_stub.dart' if (dart.library.io) 'home_widget_real.dart';

// Conditional import: home_widget only on non-web platforms

/// Service to update home screen widgets on Android and iOS.
/// On web, all methods are no-ops.
class HomeWidgetService {
  static HomeWidgetService? _instance;
  static HomeWidgetService get instance => _instance ??= HomeWidgetService._();
  HomeWidgetService._();

  /// Update all home screen widgets with current couple data.
  Future<void> updateAllWidgets({
    required int daysTogether,
    required int distanceKm,
    required String dailyQuote,
    required String myNickname,
    required String partnerNickname,
    String? latestPhotoUrl,
    String? latestTripCity,
  }) async {
    if (kIsWeb) return;
    try {
      await HomeWidgetBridge.updateWidgets(
        daysTogether: daysTogether,
        distanceKm: distanceKm,
        dailyQuote: dailyQuote,
        myNickname: myNickname,
        partnerNickname: partnerNickname,
        latestPhotoUrl: latestPhotoUrl,
        latestTripCity: latestTripCity,
      );
    } catch (_) {
      // Widget update is non-critical
    }
  }
}