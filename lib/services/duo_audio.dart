import 'package:just_audio/just_audio.dart';

/// One audio owner per game route, shared by training, couple and online modes.
class DuoAudio {
  final music = AudioPlayer(), effects = AudioPlayer();
  bool muted = false, _ready = false, _disposed = false, _wanted = false;
  int _generation = 0;
  Future<void> start() async {
    _wanted = true;
    final generation = ++_generation;
    try {
      if (!_ready) {
        await music.setAsset('assets/sounds/duo_theme.wav');
        await music.setLoopMode(LoopMode.one);
        await music.setVolume(.25);
        _ready = true;
      }
      if (_disposed || generation != _generation || !_wanted || muted) return;
      music.play().catchError((Object _) {});
    } catch (_) {
      /* Audio cannot prevent a game from starting. */
    }
  }

  Future<void> effect(String kind) async {
    if (muted ||
        _disposed ||
        !_wanted ||
        !['hit', 'score', 'miss'].contains(kind))
      return;
    try {
      await effects.setAsset('assets/sounds/duo_$kind.wav');
      if (!_disposed && !muted && _wanted)
        effects.play().catchError((Object _) {});
    } catch (_) {}
  }

  void toggle() {
    muted = !muted;
    if (muted) {
      music.pause();
      effects.pause();
    } else if (_wanted) {
      start();
    }
  }

  void pause() {
    _wanted = false;
    ++_generation;
    music.pause();
    effects.pause();
  }

  void dispose() {
    _disposed = true;
    _wanted = false;
    ++_generation;
    music.dispose();
    effects.dispose();
  }
}
