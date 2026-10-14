"""Share neck skinning across cut, binding and stitches; geometry stays exact."""
import json,struct,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
catalog_path=ROOT/'assets/runner/restart/catalog.json'
catalog=json.loads(catalog_path.read_text(encoding='utf-8'))
fits=json.loads((ROOT/'design/wardrobe-restart/sewn-species-fit.json').read_text(encoding='utf-8'))['species']
components={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}
sizes={5126:4,5123:2,5121:1,5125:4}
def offset(doc,index,i):
 a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
 return v.get('byteOffset',0)+a.get('byteOffset',0)+i*v.get('byteStride',sizes[a['componentType']]*components[a['type']])
for item in catalog['wardrobe']:
 for variant in item['variants']:
  sp=variant['species']
  if sp=='penguin':continue
  path=ROOT/variant['original_asset'];blob=path.read_bytes();length=struct.unpack_from('<I',blob,12)[0]
  doc=json.loads(blob[20:20+length]);binary=bytearray(blob[28+length:]);changed=0
  for mesh in doc['meshes']:
   names=mesh['extras']['nidoBoneNames'];torso=next(i for i,n in enumerate(names) if n.endswith('Spine2'));neck=next(i for i,n in enumerate(names) if n.endswith('Neck'))
   for p in mesh['primitives']:
    a=p['attributes'];assert doc['accessors'][a['POSITION']]['componentType']==5126
    for i in range(doc['accessors'][a['POSITION']]['count']):
     y=struct.unpack_from('<fff',binary,offset(doc,a['POSITION'],i))[1]
     if y<fits[sp]['collar_top']-.040:continue
     assert doc['accessors'][a['JOINTS_0']]['componentType']==5123 and doc['accessors'][a['WEIGHTS_0']]['componentType']==5126
     struct.pack_into('<HHHH',binary,offset(doc,a['JOINTS_0'],i),torso,neck,0,0)
     struct.pack_into('<ffff',binary,offset(doc,a['WEIGHTS_0'],i),.5,.5,0,0);changed+=1
  path.write_bytes(blob[:28+length]+binary)
  variant['original_sha256']=hashlib.sha256(path.read_bytes()).hexdigest()
  print(sp,item['item_key'],changed)
catalog_path.write_text(json.dumps(catalog,ensure_ascii=False,indent=2),encoding='utf-8')
