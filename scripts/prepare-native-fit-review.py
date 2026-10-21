"""Assemble a small QA host; same renderer/assets, no full-app plugin downloads."""
from pathlib import Path
import shutil,sys
root=Path.cwd();target=Path(sys.argv[1])
shutil.copy2(root/'tools/native-fit-review/main.dart',target/'lib/main.dart')
shutil.copytree(root/'assets/runner',target/'assets/runner',dirs_exist_ok=True)
assets=['assets/runner/']+[str(p.relative_to(target)).replace('\\','/')+'/' for p in (target/'assets/runner').rglob('*') if p.is_dir()]
(target/'pubspec.yaml').write_text('''name: nido_fit_review
environment:
  sdk: '>=3.9.0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
  webview_flutter: ^4.13.0
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
flutter:
  uses-material-design: true
  assets:
'''+''.join('    - '+p+'\n' for p in assets),encoding='utf-8')
s=(root/'integration_test/beret_fit_test.dart').read_text(encoding='utf-8')
s=s.replace("import 'package:twohearts/widgets/forest_runner_native.dart';", "import '../lib/main.dart';")
s=s.replace("import 'snow_android_test.dart' show waitFor;",'')
s=s.replace("import 'package:twohearts/services/supabase_service.dart';",'').replace('    await SupabaseService.initialize();','')
a=s.index('    await tester.pumpWidget(');b=s.index('    await tester.pump(const Duration(seconds: 1));',a)
s=s[:a]+'    await tester.pumpWidget(FitReview(ready));\n'+s[b:]
s=s.replace('_v8.glb','_v9.glb').replace('closed-small-v8','folded-small-v9')
s+='''
Future<void> waitFor(WidgetTester tester, WebViewController controller, String expression, String label) async {
 final end=DateTime.now().add(const Duration(seconds:90));
 while(DateTime.now().isBefore(end)) {
  try {final value=await controller.runJavaScriptReturningResult(expression);if(value==true||value=='true')return;}catch(_){}
  await tester.pump(const Duration(milliseconds:500));
 }
 fail('$label: ${await controller.runJavaScriptReturningResult("document.body.innerText")}');
}
'''
(target/'integration_test').mkdir(exist_ok=True);(target/'integration_test/beret_fit_test.dart').write_text(s,encoding='utf-8')

manifest=target/'android/app/src/main/AndroidManifest.xml'
if manifest.exists():manifest.write_text(manifest.read_text().replace('<application','<application android:usesCleartextTraffic="true"',1),encoding='utf-8')
