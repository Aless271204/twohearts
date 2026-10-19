/// App navigation stays silent. Each game owns its soundtrack.
class AudioService {
  static final instance = AudioService._();
  AudioService._();
  bool _muted = false;
  bool get isMuted => _muted;
  bool get isPlaying => false;
  Future<void> initialize() async {}
  Future<void> play() async {}
  Future<void> pause() async {}
  Future<void> toggleMute() async {
    _muted = !_muted;
  }

  Future<void> dispose() async {}
}
