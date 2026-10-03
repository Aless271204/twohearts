/// Stub implementation for web platform — all methods are no-ops.
abstract class HomeWidgetBridge {
  static Future<void> updateWidgets({
    required int daysTogether,
    required int distanceKm,
    required String dailyQuote,
    required String myNickname,
    required String partnerNickname,
    String? latestPhotoUrl,
    String? latestTripCity,
  }) async {
    // No-op on web
  }
}
