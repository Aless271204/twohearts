"""Publish the tested Android build, retaining the established APK signer."""
import json,subprocess,urllib.request,urllib.error,urllib.parse,zipfile,hashlib,sys,shutil,os
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'test'))
from inspect_apk_signer import signer
RUN=39096682460;COMMIT='820b6214fe376ee1a649673a69c9d7765b6fee26';TAG='nido-1.2.9-prueba'
source=ROOT/'outputs/android-129/app-arm64-v8a-release.apk'
assert source.is_file(),'Download the signed build first'
identity=signer(source);assert identity=='6991bdb5af84789e9770c5cbe43b6bd0e9aec9a2d0a8c0947c1b8ee79cf908a5'
with zipfile.ZipFile(source) as z:
 manifest=z.read('AndroidManifest.xml');assert b'1.2.9' in manifest or '1.2.9'.encode('utf-16le') in manifest
 for name in ['game.js','difficulty.js','patterns.js','storm.js','adoption.js','pet-wardrobe-jump.js','guardian/main.js','guardian/network.js','guardian/engine.js','guardian/wardrobe.js']:
  assert z.read('assets/flutter_assets/assets/runner/'+name).replace(b'\r\n',b'\n')==(ROOT/'assets/runner'/name).read_bytes().replace(b'\r\n',b'\n'),name
 for species in ['penguin','bear','pig','chick']:
  for item in ['shirt_love','jacket_denim','coat_cloud','dress_petal','hoodie_nido']:
   name=f'assets/runner/accessories/sewn_{item}_{species}.glb'
   assert z.read('assets/flutter_assets/'+name)==(ROOT/name).read_bytes(),name
token=os.environ.get('GH_TOKEN')
if not token:
 c=subprocess.run(['git','credential','fill'],input='protocol=https\nhost=github.com\n\n',text=True,capture_output=True,check=True,timeout=30)
 token=dict(line.split('=',1) for line in c.stdout.splitlines() if '=' in line)['password']
headers={'Authorization':'Bearer '+token,'Accept':'application/vnd.github+json','X-GitHub-Api-Version':'2022-11-28','Content-Type':'application/json'}
base='https://api.github.com/repos/Aless271204/twohearts/'
def api(path,method='GET',data=None):
 request=urllib.request.Request(base+path,headers=headers,method=method,data=json.dumps(data).encode() if data is not None else None)
 with urllib.request.urlopen(request,timeout=60) as response:return json.load(response) if response.status!=204 else None
run=api(f'actions/runs/{RUN}');assert run['head_sha']==COMMIT and run['conclusion']=='success'
jobs=api(f'actions/runs/{RUN}/jobs')['jobs']
assert all(any(j['name']==name and j['conclusion']=='success' for j in jobs) for name in ['verify','android-smoke'])
notes='''NIDO 1.2.9 — versión para probar en Android de 64 bits.

Adopción después de enlazar las cuentas, bienvenida 3D, oro compartido, recompensas validadas y salas con Listo/Iniciar. Incluye mejoras de carrera y ropa, tormenta progresiva, power-ups de ping pong, referencia de dibujo oculta hasta iniciar, indicadores de pareja, Home y recordatorios opcionales.

Compilación, firma, pruebas de código y arranque Android comprobados. Conserva la firma anterior para actualizar sin desinstalar.

El ajuste experimental adicional del hombro del pollito no está incluido: conserva detalles pendientes de acabado. Esta versión es para pruebas; no supone publicación en Google Play ni habilita pagos reales. La bienvenida es una cinemática 3D en tiempo real.
'''
try:release=api('releases/tags/'+TAG)
except urllib.error.HTTPError as error:
 if error.code!=404:raise
 release=api('releases','POST',{'tag_name':TAG,'target_commitish':COMMIT,'name':'NIDO 1.2.9 · Prueba Android','body':notes,'draft':True,'prerelease':True})
assert release['target_commitish']==COMMIT
apk=ROOT/'outputs/NIDO-1.2.9-prueba.apk';shutil.copyfile(source,apk)
digest=hashlib.sha256(apk.read_bytes()).hexdigest();checksum=apk.with_suffix('.apk.sha256');checksum.write_text(f'{digest}  {apk.name}\n')
uploaded=[]
for path in [apk,checksum]:
 existing=next((a for a in release['assets'] if a['name']==path.name),None)
 if existing:
  assert existing['size']==path.stat().st_size,'Existing release asset differs; do not overwrite'
  uploaded.append(existing);continue
 url=release['upload_url'].split('{')[0]+'?'+urllib.parse.urlencode({'name':path.name})
 assert urllib.parse.urlparse(url).hostname=='uploads.github.com'
 with path.open('rb') as stream:
  request=urllib.request.Request(url,data=stream,method='POST',headers={**headers,'Content-Type':'application/octet-stream','Content-Length':str(path.stat().st_size)})
  with urllib.request.urlopen(request,timeout=600) as response:uploaded.append(json.load(response))
 print(json.dumps({'uploaded':path.name,'bytes':path.stat().st_size}),flush=True)
release=api(f'releases/{release["id"]}','PATCH',{'draft':False,'prerelease':True,'body':notes})
url=next(a['browser_download_url'] for a in uploaded if a['name']==apk.name)
report={'version':'1.2.9+24','commit':COMMIT,'run':RUN,'url':url,'release':release['html_url'],'bytes':apk.stat().st_size,'sha256':digest,'signer':identity,'android_smoke':'success'}
(ROOT/'outputs/delivery-129.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report),flush=True)
