import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Owns system bars for a game route, restoring the app on exit.
class ImmersiveGame extends StatefulWidget {
  final Widget child;
  const ImmersiveGame({super.key, required this.child});
  @override
  State<ImmersiveGame> createState() => _ImmersiveGameState();
}

class _ImmersiveGameState extends State<ImmersiveGame>
    with WidgetsBindingObserver {
  static const _native = MethodChannel('nido/game_display');
  Future<void> _setFullscreen(bool enabled) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _native.invokeMethod<void>('fullscreen', enabled);
        return;
      } on MissingPluginException {
        // Web and widget tests use Flutter's implementation.
      }
    }
    await SystemChrome.setEnabledSystemUIMode(enabled
        ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge);
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setFullscreen(true);
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setFullscreen(true);
    }
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setFullscreen(false);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => widget.child;
}
