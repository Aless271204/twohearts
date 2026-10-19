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

  test('adoption and game audio resolve without exposing unrelated app assets', () {
    for (final path in [
      '/assets/images/ui/adoption-bear-0-v3.webp',
      '/assets/sounds/adoption_baby_bear_v3.mp3',
      '/assets/sounds/penalty_crowd_goal.mp3',
      '/assets/sounds/maze_theme.mp3',
    ]) {
      expect(runnerAssetPath(Uri.parse(path)), path.substring(1));
    }
    for (final path in ['/assets/images/ui/private.json', '/assets/sounds/env.json',
      '/assets/images/other/photo.png', '/assets/images/ui/%2e%2e/env.json']) {
      expect(runnerAssetPath(Uri.parse(path)), isNull);
    }
  });
}
