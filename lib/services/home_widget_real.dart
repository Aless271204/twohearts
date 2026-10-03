import 'package:home_widget/home_widget.dart';

/// Real implementation using home_widget package for Android/iOS.
abstract class HomeWidgetBridge {
  static const String _androidWidgetProvider =
      'com.flutter_template.app.TwoHeartsWidgetProvider';
  static const String _iOSWidgetKind = 'TwoHeartsWidget';

  static Future<void> updateWidgets({
    required int daysTogether,
    required int distanceKm,
    required String dailyQuote,
    required String myNickname,
    required String partnerNickname,
    String? latestPhotoUrl,
    String? latestTripCity,
  }) async {
    // Save data to widget storage
    await HomeWidget.saveWidgetData<int>('days_together', daysTogether);
    await HomeWidget.saveWidgetData<int>('distance_km', distanceKm);
    await HomeWidget.saveWidgetData<String>('daily_quote', dailyQuote);
    await HomeWidget.saveWidgetData<String>('my_nickname', myNickname);
    await HomeWidget.saveWidgetData<String>(
      'partner_nickname',
      partnerNickname,
    );
    if (latestPhotoUrl != null) {
      await HomeWidget.saveWidgetData<String>('latest_photo', latestPhotoUrl);
    }
    if (latestTripCity != null) {
      await HomeWidget.saveWidgetData<String>('latest_trip', latestTripCity);
    }

    // Trigger widget refresh
    await HomeWidget.updateWidget(
      androidName: _androidWidgetProvider,
      iOSName: _iOSWidgetKind,
    );
  }
}
