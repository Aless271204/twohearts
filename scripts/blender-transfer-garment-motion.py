"""Transfer original mascot motion onto existing garment geometry, without remodeling."""
import bpy,json,struct,sys,hashlib,shutil
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
sys.path.insert(0,str(Path(__file__).resolve().parent))
from wardrobe_gltf import _attribute,barycentric,normalized_weights
ROOT=Path(__file__).resolve().parents[1]
args=sys.argv[sys.argv.index('--')+1:]
species=next((a.split('=',1)[1] for a in args if a.startswith('species=')),'bear')
keys=next((a.split('=',1)[1].split(',') for a in args if a.startswith('items=')),['shirt_love'])
catalog=json.loads((ROOT/'assets/runner/accessory-catalog.json').read_text(encoding='utf-8'))
data=json.loads((ROOT/f'design/wardrobe-restart/fitting/{species}-original.json').read_text(encoding='utf-8'))
points=[];triangles=[];source_weights=[]
for mesh in data['meshes']:
 offset=len(points)
 for i in range(len(mesh['positions'])//3):
  points.append(Vector(mesh['positions'][i*3:i*3+3]))
  source_weights.append({int(k):v for k,v in zip(mesh['skinIndex'][i*4:i*4+4],mesh['skinWeight'][i*4:i*4+4]) if v>0})
 triangles.extend(tuple(offset+k for k in mesh['indices'][i:i+3]) for i in range(0,len(mesh['indices']),3))
tree=BVHTree.FromPolygons(points,triangles,all_triangles=True)
for item in catalog:
 if item['item_key'] not in keys:continue
 path=ROOT/item['appearance']['species_models'][species]
 archive=ROOT/'design/wardrobe-restart/models/before-motion-transfer'/path.name;archive.parent.mkdir(parents=True,exist_ok=True)
 if not archive.exists():shutil.copy2(path,archive)
 blob=archive.read_bytes();length=struct.unpack_from('<I',blob,12)[0];doc=json.loads(blob[20:20+length]);binary=bytearray(blob[28+length:])
 def append(values,fmt,component,count,existing):
  raw=struct.pack('<'+fmt*len(values),*values)
  old=doc['accessors'][existing];view=doc['bufferViews'][old['bufferView']]
  if old['componentType']==component and not old.get('byteOffset') and not view.get('byteStride') and view['byteLength']==len(raw):
   begin=view.get('byteOffset',0);binary[begin:begin+len(raw)]=raw
   return existing
  binary.extend(b'\0'*(-len(binary)%4));offset=len(binary);raw=struct.pack('<'+fmt*len(values),*values);binary.extend(raw)
  v=len(doc['bufferViews']);doc['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':len(raw)})
  a=len(doc['accessors']);doc['accessors'].append({'bufferView':v,'componentType':component,'count':count,'type':'VEC4'})
  return a
 cache={};total=0
 for mesh in doc['meshes']:
  extras=mesh.setdefault('extras',{});names=extras['nidoBoneNames'];indices_by_name={n:i for i,n in enumerate(names)}
  extras['nidoMotionTransfer']={'version':1,'source':'original-mascot-surface','source_mesh':'Mesh_0','species':species,'preserve_geometry':True}
  for primitive in mesh['primitives']:
   attrs=primitive['attributes'];positions=_attribute(doc,binary,attrs['POSITION']);joints=[];weights=[]
   for p in positions:
    key=tuple(round(v,7) for v in p)
    if key not in cache:
     hit,_,index,_=tree.find_nearest(Vector(p));tri=triangles[index];factors=barycentric(hit,*[points[i] for i in tri]);combined={}
     for vertex,factor in zip(tri,factors):
      for bone,weight in source_weights[vertex].items():combined[bone]=combined.get(bone,0)+weight*max(0,factor)
     selected=normalized_weights(combined);mapping=[(indices_by_name[data['boneNames'][b]],w) for b,w in selected]
     cache[key]=mapping
    mapping=cache[key]
    joints.extend([b for b,w in mapping]+[0]*(4-len(mapping)));weights.extend([w for b,w in mapping]+[0]*(4-len(mapping)))
   attrs['JOINTS_0']=append(joints,'H',5123,len(positions),attrs['JOINTS_0']);attrs['WEIGHTS_0']=append(weights,'f',5126,len(positions),attrs['WEIGHTS_0']);total+=len(positions)
 doc['buffers'][0]['byteLength']=len(binary);binary.extend(b'\0'*(-len(binary)%4));chunk=json.dumps(doc,separators=(',',':'),ensure_ascii=False).encode();chunk+=b' '*(-len(chunk)%4)
 path.write_bytes(struct.pack('<III',0x46546c67,2,28+len(chunk)+len(binary))+struct.pack('<II',len(chunk),0x4e4f534a)+chunk+struct.pack('<II',len(binary),0x004e4942)+binary)
 print('MOTION_TRANSFER',species,item['item_key'],total,flush=True)
