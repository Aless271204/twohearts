"""Deliver this exact tested build with the established signing identity."""
import hashlib,importlib.util,json,os,shutil,subprocess,sys,urllib.error,urllib.parse,urllib.request,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
RUN=int(sys.argv[1]);COMMIT=sys.argv[2];TAG='nido-1.3.1'
source=ROOT/'outputs/android-131/app-arm64-v8a-release.apk'
assert source.is_file(),'Download the signed build first'
spec=importlib.util.spec_from_file_location('nido_apk_checks',ROOT/'scripts/verify-wardrobe-apk.py');checks=importlib.util.module_from_spec(spec);spec.loader.exec_module(checks)
assert checks.signer(source)=='6991bdb5af84789e9770c5cbe43b6bd0e9aec9a2d0a8c0947c1b8ee79cf908a5','APK signer changed'
with zipfile.ZipFile(source) as archive:
 assert checks.manifest_identity(archive.read('AndroidManifest.xml'))=={'package':'com.example.twohearts','versionName':'1.3.1','versionCode':2026}
 names=['adoption-story.js','adoption.html','game.js','seasons.js','seasonal-botany.js','scene-sound.js','penalties/scene.js','maze/scene.js']
 names.extend(path.relative_to(ROOT/'assets/runner').as_posix() for folder in ('guardian','penalties','maze') for path in (ROOT/'assets/runner'/folder).rglob('*') if path.is_file())
 for name in set(names):
  local=(ROOT/'assets/runner'/name).read_bytes();packed=archive.read('assets/flutter_assets/assets/runner/'+name)
  if Path(name).suffix in ('.js','.html','.json','.css'):local=local.replace(b'\r\n',b'\n');packed=packed.replace(b'\r\n',b'\n')
  assert local==packed,'Stale game asset: '+name
 for i in range(5):
  name=f'assets/images/ui/login-welcome-{i}-v4.webp';assert archive.read('assets/flutter_assets/'+name)==(ROOT/name).read_bytes()
 for species in ('penguin','bear','pig','chick'):
  for i in range(4):
   name=f'assets/images/ui/adoption-{species}-{i}-v3.webp';assert archive.read('assets/flutter_assets/'+name)==(ROOT/name).read_bytes()
checks.verify(source)

token=os.environ.get('GH_TOKEN')
if not token:
 result=subprocess.run(['git','credential','fill'],input='protocol=https\nhost=github.com\n\n',text=True,capture_output=True,check=True,timeout=30)
 token=dict(line.split('=',1) for line in result.stdout.splitlines() if '=' in line)['password']
headers={'Authorization':'Bearer '+token,'Accept':'application/vnd.github+json','X-GitHub-Api-Version':'2022-11-28','Content-Type':'application/json'}
base='https://api.github.com/repos/Aless271204/twohearts/'
def api(path,method='GET',data=None):
 request=urllib.request.Request(base+path,headers=headers,method=method,data=json.dumps(data).encode() if data is not None else None)
 with urllib.request.urlopen(request,timeout=60) as response:return json.load(response) if response.status!=204 else None
run=api(f'actions/runs/{RUN}');assert run['head_sha']==COMMIT and run['conclusion']=='success'
jobs=api(f'actions/runs/{RUN}/jobs')['jobs'];assert all(any(j['name']==name and j['conclusion']=='success' for j in jobs) for name in ('verify','android-smoke'))
notes='''NIDO 1.3.1 — actualización Android.

Rutas internas de Android corregidas y comprobadas para imágenes de adopción y sonidos de los juegos.

Bienvenida ilustrada al iniciar sesión y llegada de adopción independiente con cigüeña, cuatro mascotas y sonidos suaves. Juegos sin la antigua pestaña de Actividades. Penales con arco centrado, animaciones articuladas y público; Farolitos con puerta orientada, llaves y sonido de murciélagos. Carrera con estaciones y Guardianes con segundo mapa, ataques aéreos y peces en varias direcciones. Menús sin música; música y efectos dentro de los juegos. Mejoras artísticas en miniaturas e interfaces.

Guardianes entrega una moneda por cada diez puntos de botín; solitario mantiene la mitad. Los siete juegos añaden 10% al superar un récord anterior, con validación del servidor, límites diarios y sin abonos duplicados.

APK firmado con la identidad anterior para actualizar sin desinstalar. Compilación y prueba Android automatizada completadas. Esta descarga no supone publicación en Google Play ni activación de pagos reales. Persisten ajustes artísticos de vestuario y el trabajo Social por ID documentados en el repositorio.
'''
try:release=api('releases/tags/'+TAG)
except urllib.error.HTTPError as error:
 if error.code!=404:raise
 release=api('releases','POST',{'tag_name':TAG,'target_commitish':COMMIT,'name':'NIDO 1.3.1 · Android','body':notes,'draft':True,'prerelease':False})
assert release['target_commitish']==COMMIT,'Do not overwrite a different build'
apk=ROOT/'outputs/NIDO-1.3.1.apk';shutil.copyfile(source,apk)
digest=hashlib.sha256(apk.read_bytes()).hexdigest();checksum=apk.with_suffix('.apk.sha256');checksum.write_text(f'{digest}  {apk.name}\n')
uploaded=[]
for path in (apk,checksum):
 existing=next((a for a in release['assets'] if a['name']==path.name),None)
 if existing:
  assert existing['size']==path.stat().st_size and (not existing.get('digest') or existing['digest']=='sha256:'+hashlib.sha256(path.read_bytes()).hexdigest()),'Existing release asset differs'
  uploaded.append(existing);continue
 url=release['upload_url'].split('{')[0]+'?'+urllib.parse.urlencode({'name':path.name});assert urllib.parse.urlparse(url).hostname=='uploads.github.com'
 with path.open('rb') as stream:
  request=urllib.request.Request(url,data=stream,method='POST',headers={**headers,'Content-Type':'application/octet-stream','Content-Length':str(path.stat().st_size)})
  with urllib.request.urlopen(request,timeout=600) as response:uploaded.append(json.load(response))
 print(json.dumps({'uploaded':path.name,'bytes':path.stat().st_size}),flush=True)
release=api(f'releases/{release["id"]}','PATCH',{'draft':False,'prerelease':False,'body':notes})
url=next(a['browser_download_url'] for a in uploaded if a['name']==apk.name)
report={'version':'1.3.1+25','commit':COMMIT,'run':RUN,'smoke_run':RUN,'url':url,'release':release['html_url'],'bytes':apk.stat().st_size,'sha256':digest,'signer':checks.signer(source),'android_smoke':'success'}
(ROOT/'outputs/delivery-131.json').write_text(json.dumps(report,indent=2));print(json.dumps(report),flush=True)
