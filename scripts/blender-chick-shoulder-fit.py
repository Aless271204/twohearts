"""Lift the chick's sewn shoulder root under its real head, without padding.

Run after skin transfer/weight-field baking. All panels and stitches receive
the same smooth fit displacement; pet geometry is never opened or exported.
"""
import bpy,json,struct,sys,math,shutil,importlib.util
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('weights',ROOT/'scripts/fix-torso-weights.py')
w=importlib.util.module_from_spec(spec);spec.loader.exec_module(w)
args=sys.argv[sys.argv.index('--')+1:]
item=args[0] if args else 'shirt_love'
source_path=ROOT/f'assets/runner/accessories/sewn_{item}_chick.glb'
path=source_path if '--apply' in args else ROOT/f'design/wardrobe-restart/experiments/shoulder-{item}-chick.glb'
path.parent.mkdir(parents=True,exist_ok=True)
raw=source_path.read_bytes();length=struct.unpack_from('<I',raw,12)[0]
doc=json.loads(raw[20:20+length]);binary=bytearray(raw[28+length:])
if doc.get('extras',{}).get('nidoChickShoulderFit')==1:raise SystemExit('already fitted')
backup=ROOT/'outputs/before-chick-shoulder-fit'/path.name;backup.parent.mkdir(parents=True,exist_ok=True)
if not backup.exists():shutil.copy2(source_path,backup)

def put3(index,rows):
 a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']];start=v.get('byteOffset',0)+a.get('byteOffset',0);stride=v.get('byteStride',12)
 for i,p in enumerate(rows):struct.pack_into('<fff',binary,start+i*stride,*p)
 a['min']=[min(p[k] for p in rows) for k in range(3)];a['max']=[max(p[k] for p in rows) for k in range(3)]

done=set()
for mesh in doc['meshes']:
 for prim in mesh['primitives']:
  attrs=prim['attributes'];index=attrs['POSITION']
  if index in done:continue
  done.add(index);positions=w.attribute(doc,binary,index);points=[]
  for x,y,z in positions:
   lateral=math.exp(-((abs(x)-.235)/.075)**2)
   lift=.048*lateral*w.smooth(.405,.495,y)
   points.append((x,y+lift,z))
  put3(index,points)
  # Geometric normals after the fitting warp, keeping every UV unchanged.
  ids=[v[0] for v in w.attribute(doc,binary,prim['indices'])];normals=[Vector() for _ in points]
  for k in range(0,len(ids),3):
   a,b,c=ids[k:k+3];normal=(Vector(points[b])-Vector(points[a])).cross(Vector(points[c])-Vector(points[a]))
   normals[a]+=normal;normals[b]+=normal;normals[c]+=normal
  put3(attrs['NORMAL'],[tuple(n.normalized()) if n.length>1e-9 else (0,1,0) for n in normals])
doc.setdefault('extras',{})['nidoChickShoulderFit']=1
chunk=json.dumps(doc,separators=(',',':'),ensure_ascii=False).encode();chunk+=b' '*(-len(chunk)%4)
path.write_bytes(struct.pack('<III',0x46546c67,2,28+len(chunk)+len(binary))+struct.pack('<II',len(chunk),0x4e4f534a)+chunk+struct.pack('<II',len(binary),0x004e4942)+binary)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(path))
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/f'design/wardrobe-restart/models/CHICK-SHOULDER-{item}.blend'),compress=True)
print('CHICK_SHOULDER_FIT',item,flush=True)
