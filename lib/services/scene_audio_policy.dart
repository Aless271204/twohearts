import 'package:flutter/widgets.dart';

/// Indexed tabs remain mounted: visibility, rather than dispose, owns audio.
class SceneAudioPolicy extends ChangeNotifier with WidgetsBindingObserver {
  static final instance = SceneAudioPolicy();
  SceneAudioPolicy() { WidgetsBinding.instance.addObserver(this); }
  bool _foreground = true, _covered = false;
  int _tab = 2;
  bool get activitiesVisible => _foreground && !_covered && _tab == 4;
  void update({int? tab, bool? covered}) {
    final before = activitiesVisible;
    _tab = tab ?? _tab;
    _covered = covered ?? _covered;
    if (before != activitiesVisible) notifyListeners();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final before = activitiesVisible;
    _foreground = state == AppLifecycleState.resumed;
    if (before != activitiesVisible) notifyListeners();
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }
}

class SceneAudioRouteObserver extends NavigatorObserver {
  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    SceneAudioPolicy.instance.update(covered: !topRoute.isFirst);
  }
}
