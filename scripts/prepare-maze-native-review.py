from pathlib import Path
import shutil,sys
root=Path.cwd();target=Path(sys.argv[1]);shutil.copy2(root/'tools/native-fit-review/main.dart',target/'lib/main.dart');p=target/'lib/main.dart';s=p.read_text(encoding='utf-8').replace("/assets/runner/index.html?pet=1","/assets/runner/maze/index.html");p.write_text(s,encoding='utf-8')
shutil.copytree(root/'assets/runner',target/'assets/runner',dirs_exist_ok=True)
assets=['assets/runner/']+[str(p.relative_to(target)).replace('\\','/')+'/' for p in (target/'assets/runner').rglob('*') if p.is_dir()]
(target/'pubspec.yaml').write_text("name: nido_fit_review\nenvironment:\n  sdk: '>=3.9.0 <4.0.0'\ndependencies:\n  flutter:\n    sdk: flutter\n  webview_flutter: ^4.13.0\ndev_dependencies:\n  flutter_test:\n    sdk: flutter\n  integration_test:\n    sdk: flutter\nflutter:\n  uses-material-design: true\n  assets:\n"+''.join('    - '+p+'\n' for p in assets),encoding='utf-8')
(target/'integration_test').mkdir(exist_ok=True);shutil.copy2(root/'integration_test/maze_android_test.dart',target/'integration_test/maze_android_test.dart')
manifest=target/'android/app/src/main/AndroidManifest.xml';manifest.write_text(manifest.read_text().replace('<application','<application android:usesCleartextTraffic="true"',1),encoding='utf-8')
