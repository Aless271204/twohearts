import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/core/asset_byte_range.dart';

void main() {
  test('media seeking supports bounded, open and suffix ranges', () {
    expect(parseAssetByteRange('bytes=10-19', 100), (start: 10, end: 19));
    expect(parseAssetByteRange('bytes=90-', 100), (start: 90, end: 99));
    expect(parseAssetByteRange('bytes=-8', 100), (start: 92, end: 99));
    expect(parseAssetByteRange('bytes=0-200', 100), (start: 0, end: 99));
    expect(parseAssetByteRange('bytes=-200', 100), (start: 0, end: 99));
  });
  test('malformed and unsatisfiable requests are rejected', () {
    for (final header in ['bytes=100-', 'bytes=20-10', 'bytes=-0',
      'bytes=-', 'bytes=0-1,4-5', 'items=0-10', 'bytes=a-b']) {
      expect(() => parseAssetByteRange(header, 100), throwsFormatException);
    }
    expect(() => parseAssetByteRange('bytes=0-', 0), throwsFormatException);
  });
}
