/// Decode each URL segment once before looking up a bundled runner asset.
/// Reject separators and traversal inside a decoded segment.
String? runnerAssetPath(Uri uri) {
  final segments = uri.pathSegments;
  if (segments.length < 3 ||
      segments[0] != 'assets' ||
      segments[1] != 'runner' ||
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
  return segments.join('/');
}
