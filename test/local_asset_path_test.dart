import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/core/local_asset_path.dart';

void main() {
  test('a browser-encoded model name resolves to the real bundled file', () {
    final uri = Uri.parse(
      'http://localhost:1234/assets/runner/models/SENDERO%20DE%20TIERRA.glb',
    );
    expect(uri.path, contains('%20'));
    expect(runnerAssetPath(uri), 'assets/runner/models/SENDERO DE TIERRA.glb');
    expect(
      runnerAssetPath(Uri.parse('/assets/runner/models/Ping%C3%BCino.glb?v=2')),
      'assets/runner/models/Pingüino.glb',
    );
  });

  test('decoded traversal and separators cannot escape runner assets', () {
    for (final path in [
      '/assets/models/pip.glb',
      '/assets/runner/%2e%2e/env.json',
      '/assets/runner/models%2Fsecret.glb',
      '/assets/runner/models%5Csecret.glb',
      '/assets/runner//pip.glb',
    ]) {
      expect(runnerAssetPath(Uri.parse(path)), isNull, reason: path);
    }
  });
}
