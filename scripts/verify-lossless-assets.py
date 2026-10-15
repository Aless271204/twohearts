"""Prove texture sharing preserves every garment geometry buffer and source image."""
import json,struct,hashlib,subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[1]
def glb(p):
 b=p.read_bytes() if isinstance(p,Path) else p;n=struct.unpack_from('<I',b,12)[0];return json.loads(b[20:20+n]),b[28+n:]
def view(d,b,i):
 v=d['bufferViews'][i];return b[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']]
items=json.loads((root/'assets/runner/accessory-catalog.json').read_text(encoding='utf8'))
paths={p for item in items if item.get('visible',True) for p in item['appearance'].get('species_models',{}).values()}
textures=set()
for name in sorted(paths):
 p=root/name;source=root/'design/wardrobe-restart/models/before-lossless-packaging'/p.name
 original,old=glb(source if source.exists() else subprocess.check_output(['git','show','a7d4079:'+name],cwd=root));current,new=glb(p)
 for k in ['meshes','nodes','skins','animations','materials','textures','samplers']:
  assert original.get(k)==current.get(k),(name,k)
 for a,b in zip(original.get('accessors',[]),current.get('accessors',[]),strict=True):
  assert {k:v for k,v in a.items() if k!='bufferView'}=={k:v for k,v in b.items() if k!='bufferView'},name
  if 'bufferView' in a:assert view(original,old,a['bufferView'])==view(current,new,b['bufferView']),name
 for a,b in zip(original.get('images',[]),current.get('images',[]),strict=True):
  raw=view(original,old,a['bufferView']) if 'bufferView' in a else (p.parent/a['uri']).read_bytes()
  packed=(p.parent/b['uri']).read_bytes();assert raw==packed,name
  assert hashlib.sha256(packed).hexdigest()==Path(b['uri']).stem
  textures.add((p.parent/b['uri']).relative_to(root).as_posix())
manifest=(root/'pubspec.yaml').read_text(encoding='utf8')
for name in paths|textures:assert '    - '+name+'\n' in manifest,name
assert '    - assets/runner/accessories/\n' not in manifest
print('LOSSLESS_ASSETS_VERIFIED',len(paths),'models',len(textures),'shared textures')
