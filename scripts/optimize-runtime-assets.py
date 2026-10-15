"""Lossless wardrobe texture deduplication and explicit production assets.

Pet originals are untouched. Archive a garment before changing its container;
preserve every non-image buffer view byte, material, animation and accessor.
Run again after Blender exports, then sync the canonical catalog/thumbnail hashes.
"""
import json,struct,hashlib,shutil,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def sha(b):return hashlib.sha256(b).hexdigest()
def optimize(path):
 raw=path.read_bytes();length=struct.unpack_from('<I',raw,12)[0]
 doc=json.loads(raw[20:20+length]);binary=raw[28+length:]
 embedded=[im for im in doc.get('images',[]) if 'bufferView' in im]
 if not embedded:return
 archive=ROOT/'design/wardrobe-restart/models/before-lossless-packaging'/path.name
 archive.parent.mkdir(parents=True,exist_ok=True)
 if not archive.exists():shutil.copy2(path,archive)
 old_images={im['bufferView'] for im in embedded}
 images_before=[]
 for im in embedded:
  v=doc['bufferViews'][im['bufferView']];data=binary[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']]
  ext='jpg' if im.get('mimeType')=='image/jpeg' else 'png'
  name=sha(data)+'.'+ext;target=path.parent/'textures'/name;target.parent.mkdir(exist_ok=True)
  if target.exists():assert target.read_bytes()==data
  else:target.write_bytes(data)
  images_before.append(sha(data));im.pop('bufferView');im['uri']='textures/'+name
 referenced=set()
 def find(o):
  if isinstance(o,dict):
   for k,v in o.items():
    if k=='bufferView' and isinstance(v,int):referenced.add(v)
    else:find(v)
  elif isinstance(o,list):
   for v in o:find(v)
 find(doc)
 out=bytearray();views=[];mapping={}
 for i,v in enumerate(doc['bufferViews']):
  if i in old_images and i not in referenced:continue
  data=binary[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']]
  out.extend(b'\0'*((-len(out))%4));mapping[i]=len(views)
  views.append({**v,'byteOffset':len(out)});out.extend(data)
  assert bytes(out[views[-1]['byteOffset']:views[-1]['byteOffset']+v['byteLength']])==data
 def remap(o):
  if isinstance(o,dict):
   for k,v in o.items():
    if k=='bufferView' and isinstance(v,int):o[k]=mapping[v]
    else:remap(v)
  elif isinstance(o,list):
   for v in o:remap(v)
 remap(doc);doc['bufferViews']=views;doc['buffers'][0]['byteLength']=len(out)
 encoded=json.dumps(doc,ensure_ascii=False,separators=(',',':')).encode();encoded+=b' '*((-len(encoded))%4)
 out.extend(b'\0'*((-len(out))%4))
 result=struct.pack('<III',0x46546c67,2,28+len(encoded)+len(out))+struct.pack('<II',len(encoded),0x4e4f534a)+encoded+struct.pack('<II',len(out),0x004e4942)+out
 path.write_bytes(result)
 for im in embedded:assert sha((path.parent/im['uri']).read_bytes())==Path(im['uri']).stem

catalog=json.loads((ROOT/'assets/runner/accessory-catalog.json').read_text(encoding='utf-8'))
current={ROOT/p for i in catalog if i.get('visible',True) for p in i['appearance'].get('species_models',{}).values()}
before=sum(p.stat().st_size for p in current)
for p in sorted(current):optimize(p)
# Maintain provenance registries without replacing the artist's original master.
for name in ['assets/runner/restart/catalog.json','assets/runner/restart/details-catalog.json']:
 p=ROOT/name;data=json.loads(p.read_text(encoding='utf-8'))
 def hashes(o):
  if isinstance(o,dict):
   for k,digest in [('original_cap_asset','cap_sha256'),('original_asset','original_sha256'),('asset','sha256')]:
    if isinstance(o.get(k),str) and ROOT/o[k] in current:o[digest]=sha((ROOT/o[k]).read_bytes())
   for v in o.values():hashes(v)
  elif isinstance(o,list):
   for v in o:hashes(v)
 hashes(data);p.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
p=ROOT/'assets/images/products/wardrobe-thumbnails.json';report=json.loads(p.read_text(encoding='utf-8'))
for entry in report:
 if ROOT/entry['model'] in current:entry['model_sha256']=sha((ROOT/entry['model']).read_bytes());entry['container_optimization']='identical_geometry_and_image_bytes_shared_textures'
p.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
runtime={p.relative_to(ROOT).as_posix() for p in current}
for p in current:
 b=p.read_bytes();d=json.loads(b[20:20+struct.unpack_from('<I',b,12)[0]])
 for im in d.get('images',[]):
  if 'uri' in im:runtime.add((p.parent/im['uri']).relative_to(ROOT).as_posix())
spec=ROOT/'pubspec.yaml';s=spec.read_text(encoding='utf-8')
s=re.sub(r'^    - assets/runner/accessories/[^\n]*\n', '', s, flags=re.M)
marker='    - assets/runner/play-models/\n'
assert marker in s
s=s.replace(marker, ''.join('    - '+p+'\n' for p in sorted(runtime))+marker)
s=s.replace('    - assets/models/\n','')
s=s.replace('    - assets/images/\n',''.join('    - '+p.relative_to(ROOT).as_posix()+'\n' for p in sorted((ROOT/'assets/images').iterdir()) if p.is_file() and p.suffix.lower()!='.glb'))
spec.write_text(s,encoding='utf-8')
print(json.dumps({'current_models':len(current),'before_bytes':before,'after_model_bytes':sum(p.stat().st_size for p in current),'shared_texture_bytes':sum((ROOT/p).stat().st_size for p in runtime if not p.endswith('.glb')),'runtime_files':len(runtime)}))
