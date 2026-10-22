from pathlib import Path
import shutil,sys
root=Path.cwd();target=Path(sys.argv[1]);shutil.copy2(root/'tools/native-fit-review/main.dart',target/'lib/main.dart');p=target/'lib/main.dart';s=p.read_text(encoding='utf-8').replace("/assets/runner/index.html?pet=1","/assets/runner/maze/index.html");s=s.replace("!path.startsWith('/assets/runner/')","(!path.startsWith('/assets/runner/') && !path.startsWith('/assets/sounds/'))");p.write_text(s,encoding='utf-8')
# Copy only the game's actual dependencies, rather than hundreds of unrelated GLBs.
for folder in ['maze','vendor','play-models']:
 shutil.copytree(root/'assets/runner'/folder,target/'assets/runner'/folder,dirs_exist_ok=True)
for file in ['scene-sound.js','pet-rest-pose.js','pet-jump-heading.js','texture_budget.js','game-menu.css']:
 shutil.copy2(root/'assets/runner'/file,target/'assets/runner'/file)
(target/'assets/sounds').mkdir(parents=True,exist_ok=True)
for source in (root/'assets/sounds').glob('maze*.mp3'):shutil.copy2(source,target/'assets/sounds'/source.name)
assets=['assets/sounds/','assets/runner/']+[str(p.relative_to(target)).replace('\\','/')+'/' for p in (target/'assets/runner').rglob('*') if p.is_dir()]
(target/'pubspec.yaml').write_text("name: nido_fit_review\nenvironment:\n  sdk: '>=3.9.0 <4.0.0'\ndependencies:\n  flutter:\n    sdk: flutter\n  webview_flutter: ^4.13.0\ndev_dependencies:\n  flutter_test:\n    sdk: flutter\n  integration_test:\n    sdk: flutter\nflutter:\n  uses-material-design: true\n  assets:\n"+''.join('    - '+p+'\n' for p in assets),encoding='utf-8')
(target/'integration_test').mkdir(exist_ok=True)
test_source=(root/'integration_test/maze_android_test.dart').read_text(encoding='utf-8').replace("../tools/native-fit-review/main.dart","../lib/main.dart")
(target/'integration_test/maze_android_test.dart').write_text(test_source,encoding='utf-8')
manifest=target/'android/app/src/main/AndroidManifest.xml';manifest.write_text(manifest.read_text().replace('<application','<application android:usesCleartextTraffic="true"',1),encoding='utf-8')
