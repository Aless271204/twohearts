import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Manages warm ambient background music throughout the app.
/// Uses a royalty-free ambient/lo-fi audio stream.
class AudioService {
  static AudioService? _instance;
  static AudioService get instance => _instance ??= AudioService._();
  AudioService._();

  AudioPlayer? _player;
  bool _initialized = false;
  bool _muted = false;

  bool get isMuted => _muted;
  bool get isPlaying => _player?.playing ?? false;

  // Warm ambient audio — royalty-free lo-fi/ambient stream
  // Using a publicly available ambient music URL
  static const String _ambientUrl =
      'https://cdn.pixabay.com/audio/2024/03/12/audio_c8e7e2e7e2.mp3';

  // Fallback: another warm ambient track
  static const String _fallbackUrl =
      'https://cdn.pixabay.com/audio/2023/10/30/audio_0625a5c6b7.mp3';

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _player = AudioPlayer();
      await _player!.setLoopMode(LoopMode.one);
      await _player!.setVolume(0.18); // Very subtle, non-intrusive
      try {
        await _player!.setUrl(_ambientUrl).timeout(const Duration(seconds: 5));
      } catch (_) {
        await _player!.setUrl(_fallbackUrl).timeout(const Duration(seconds: 5));
      }
      _initialized = true;
      // Playback begins only after user interaction.
    } catch (e) {
      debugPrint('AudioService init error: $e');
    }
  }

  Future<void> play() async {
    if (!_initialized) await initialize();
    if (!_muted) {
      try {
        await _player?.play();
      } catch (e) {
        debugPrint('AudioService play error: $e');
      }
    }
  }

  Future<void> pause() async {
    try {
      await _player?.pause();
    } catch (e) {
      debugPrint('AudioService pause error: $e');
    }
  }

  Future<void> toggleMute() async {
    _muted = !_muted;
    if (_muted) {
      await _player?.setVolume(0.0);
    } else {
      await _player?.setVolume(0.18);
      if (!(_player?.playing ?? false)) {
        await _player?.play();
      }
    }
  }

  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
    _initialized = false;
  }
}
