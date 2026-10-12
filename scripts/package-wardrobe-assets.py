"""Deduplicate exact PNG bytes across GLBs without reducing texture quality."""
import json,struct,hashlib
from pathlib import Path
R=Path(__file__).resolve().parents[1];folder=R/'assets/runner';saved=0
for name in ('blender-wardrobe-models.json','blender-complement-models.json'):
 catalog=json.loads((folder/name).read_text(encoding='utf-8'))
 for item in catalog:
  for v in item['variants']:
   path=R/v['path'];blob=path.read_bytes();length=struct.unpack_from('<I',blob,12)[0]
   doc=json.loads(blob[20:20+length]);binary=blob[28+length:];removed=set()
   for image in doc.get('images',[]):
    if 'bufferView' not in image:continue
    old=image.pop('bufferView');view=doc['bufferViews'][old];start=view.get('byteOffset',0);data=binary[start:start+view['byteLength']]
    if image['mimeType']!='image/png':raise ValueError('Expected lossless PNG')
    texture='fabric_tex_'+hashlib.sha256(data).hexdigest()[:24]+'.png'
    destination=path.parent/texture
    if destination.exists() and destination.read_bytes()!=data:raise ValueError('Texture hash collision')
    destination.write_bytes(data);image['uri']=texture;removed.add(old)
   if removed:
    # Repack every retained view verbatim, with aligned offsets and remapped IDs.
    output=bytearray();views=[];mapping={}
    for old,view in enumerate(doc['bufferViews']):
     if old in removed:continue
     while len(output)%4:output.append(0)
     offset=len(output);start=view.get('byteOffset',0);output.extend(binary[start:start+view['byteLength']]);mapping[old]=len(views)
     views.append({**view,'byteOffset':offset})
    for a in doc['accessors']:
     if 'bufferView' in a:a['bufferView']=mapping[a['bufferView']]
     for part in ('indices','values'):
      if part in a.get('sparse',{}):a['sparse'][part]['bufferView']=mapping[a['sparse'][part]['bufferView']]
    doc['bufferViews']=views;doc['buffers'][0]['byteLength']=len(output)
    chunk=json.dumps(doc,ensure_ascii=False,separators=(',',':')).encode();chunk+=b' '*(-len(chunk)%4)
    output+=b'\0'*(-len(output)%4)
    packed=struct.pack('<III',0x46546c67,2,28+len(chunk)+len(output))+struct.pack('<II',len(chunk),0x4e4f534a)+chunk+struct.pack('<II',len(output),0x004e4942)+output
    path.write_bytes(packed);saved+=len(blob)-len(packed)
   v['sha256']=hashlib.sha256(path.read_bytes()).hexdigest()
  item['appearance']['asset_revision']=hashlib.sha256(''.join(v['sha256'] for v in item['variants']).encode()).hexdigest()[:16]
 (folder/name).write_text(json.dumps(catalog,ensure_ascii=False,indent=2),encoding='utf-8')
print('Lossless shared textures; removed',round(saved/1048576,2),'MiB from GLB files')
