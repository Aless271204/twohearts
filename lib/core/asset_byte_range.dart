/// Inclusive byte range for local media seeking. Invalid ranges produce HTTP 416.
({int start, int end}) parseAssetByteRange(String header, int length) {
  final match = RegExp(r'^bytes=(\d*)-(\d*)$').firstMatch(header.trim());
  if (match == null || length <= 0 ||
      (match[1]!.isEmpty && match[2]!.isEmpty)) {
    throw const FormatException('Invalid byte range');
  }
  if (match[1]!.isEmpty) {
    final suffix = int.tryParse(match[2]!);
    if (suffix == null || suffix <= 0) {
      throw const FormatException('Invalid suffix range');
    }
    return (start: suffix >= length ? 0 : length - suffix, end: length - 1);
  }
  final start = int.tryParse(match[1]!);
  final requestedEnd = match[2]!.isEmpty ? length - 1 : int.tryParse(match[2]!);
  if (start == null || requestedEnd == null ||
      start >= length || requestedEnd < start) {
    throw const FormatException('Unsatisfiable byte range');
  }
  return (start: start, end: requestedEnd >= length ? length - 1 : requestedEnd);
}
