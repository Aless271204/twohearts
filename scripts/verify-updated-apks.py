import hashlib,importlib.util,json,shutil,subprocess,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('apk_identity',ROOT/'scripts/verify-wardrobe-apk.py');checks=importlib.util.module_from_spec(spec);spec.loader.exec_module(checks)
out=ROOT/'outputs/android-132';out.mkdir(parents=True,exist_ok=True);reports=[]
for abi,code,name in [('arm64-v8a',2027,'NIDO-1.3.2-android.apk'),('armeabi-v7a',1027,'NIDO-1.3.2-android-32.apk')]:
 source=ROOT/f'build/app/outputs/flutter-apk/app-{abi}-release.apk'
 assert checks.signer(source)=='6991bdb5af84789e9770c5cbe43b6bd0e9aec9a2d0a8c0947c1b8ee79cf908a5','Changed signing identity'
 with zipfile.ZipFile(source) as z:
  assert z.testzip() is None
  identity=checks.manifest_identity(z.read('AndroidManifest.xml'))
  assert identity=={'package':'com.example.twohearts','versionName':'1.3.2','versionCode':code},identity
  for folder in ('snow','guardian','penalties','maze'):
   for p in (ROOT/'assets/runner'/folder).iterdir():
    if p.is_file() and p.suffix in ('.js','.html','.webp','.mp3'):
     local=p.read_bytes();packed=z.read('assets/flutter_assets/'+p.relative_to(ROOT).as_posix())
     if p.suffix in ('.js','.html'):local=local.replace(b'\r\n',b'\n');packed=packed.replace(b'\r\n',b'\n')
     assert local==packed,'Stale game file: '+str(p)
 target=out/name;shutil.copyfile(source,target);digest=hashlib.sha256(target.read_bytes()).hexdigest()
 reports.append({'name':name,'bytes':target.stat().st_size,'sha256':digest,'identity':identity})
(out/'SHA256SUMS.txt').write_text(''.join(r['sha256']+'  '+r['name']+'\n' for r in reports),encoding='utf-8')
(out/'verification.json').write_text(json.dumps(reports,indent=2),encoding='utf-8');print(json.dumps(reports,indent=2))
