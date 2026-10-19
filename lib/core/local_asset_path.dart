/// Serve only the game and its public image/audio resources from the bundle.
/// Reject separators and traversal inside a decoded segment.
String? runnerAssetPath(Uri uri) {
  final segments = uri.pathSegments;
  if (segments.length < 3 ||
      segments[0] != 'assets' ||
      segments.any(
        (segment) =>
            segment.isEmpty ||
            segment == '.' ||
            segment == '..' ||
            segment.contains('/') ||
            segment.contains('\\'),
      )) {
    return null;
  }
  final runner = segments[1] == 'runner';
  final uiImage = segments.length == 4 && segments[1] == 'images' &&
      segments[2] == 'ui' && RegExp(r'\.(?:webp|png|jpe?g)$').hasMatch(segments.last);
  final audio = segments.length == 3 && segments[1] == 'sounds' &&
      RegExp(r'\.(?:mp3|ogg|wav)$').hasMatch(segments.last);
  if (!runner && !uiImage && !audio) return null;
  return segments.join('/');
}
