"""Bake anatomical clothing weights; preserve geometry, UVs and textures.

Run after blender-transfer-garment-motion.py when rebuilding garments. The
nearest original surface may be a thigh, head or hand behind the shirt's hem;
that is a fitting reference, not a suitable animation joint for torso fabric.
"""
from pathlib import Path
import json,struct,hashlib,shutil,re
ROOT=Path(__file__).resolve().parents[1]
def attribute(doc,binary,index):
 a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
 count={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]
 fmt={5121:'B',5123:'H',5125:'I',5126:'f'}[a['componentType']];size=struct.calcsize(fmt)*count
 start=v.get('byteOffset',0)+a.get('byteOffset',0);stride=v.get('byteStride',size)
 return [struct.unpack_from('<'+fmt*count,binary,start+i*stride) for i in range(a['count'])]
def put(doc,binary,index,rows):
 a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']];fmt={5121:'B',5123:'H',5125:'I',5126:'f'}[a['componentType']]
 start=v.get('byteOffset',0)+a.get('byteOffset',0);stride=v.get('byteStride',struct.calcsize(fmt)*4)
 for i,row in enumerate(rows):struct.pack_into('<'+fmt*4,binary,start+i*stride,*row)
def smooth(a,b,x):
 t=max(0,min(1,(x-a)/(b-a)));return t*t*(3-2*t)
def fix(path):
 original=path.read_bytes();length=struct.unpack_from('<I',original,12)[0];doc=json.loads(original[20:20+length]);binary=bytearray(original[28+length:])
 if doc.get('extras',{}).get('nidoTorsoWeightConstraints')==1:return None
 points=[p for m in doc['meshes'] if m.get('extras',{}).get('nidoSkinTransfer',{}).get('stage')=='primary' for prim in m['primitives'] for p in attribute(doc,binary,prim['attributes']['POSITION'])]
 if not points:return None
 top=max(p[1] for p in points);width=max(abs(p[0]) for p in points);changed=0;processed=set()
 for m in doc['meshes']:
  names=m.get('extras',{}).get('nidoBoneNames');transfer=m.get('extras',{}).get('nidoMotionTransfer')
  if not names or not transfer:continue
  hips=next(i for i,n in enumerate(names) if n.endswith('Hips'));spine=next(i for i,n in enumerate(names) if n.endswith('Spine2'))
  for prim in m['primitives']:
   a=prim['attributes'];identity=(a['JOINTS_0'],a['WEIGHTS_0'])
   if identity in processed:continue
   processed.add(identity)
   positions=attribute(doc,binary,a['POSITION']);joints=attribute(doc,binary,a['JOINTS_0']);weights=attribute(doc,binary,a['WEIGHTS_0']);outj=[];outw=[]
   for p,js,ws in zip(positions,joints,weights):
    torso=smooth(.045,.13,top-p[1])*(1-smooth(width*.64,width*.84,abs(p[0])));result={}
    for bone,weight in zip(js,ws):
     if weight<=0:continue
     name=names[bone]
     if re.search(r'(UpLeg|Leg|Foot|ToeBase|Toe_End)$',name):bone=hips
     elif re.search(r'(Head|Neck)$',name):
      redirect=1-smooth(top-.07,top-.02,p[1]);result[spine]=result.get(spine,0)+weight*redirect;weight*=1-redirect
     elif re.search(r'(Shoulder|Arm|ForeArm|Hand)$',name):
      result[spine]=result.get(spine,0)+weight*torso;weight*=1-torso
     result[bone]=result.get(bone,0)+weight
    values=sorted(((k,v) for k,v in result.items() if v>1e-9),key=lambda x:-x[1])[:4];total=sum(v for k,v in values)
    values+=[(0,0)]*(4-len(values));nj=tuple(k for k,v in values);nw=tuple(v/total for k,v in values)
    if nj!=js or any(abs(x-y)>1e-6 for x,y in zip(nw,ws)):changed+=1
    outj.append(nj);outw.append(nw)
   put(doc,binary,a['JOINTS_0'],outj);put(doc,binary,a['WEIGHTS_0'],outw)
 doc.setdefault('extras',{})['nidoTorsoWeightConstraints']=1
 backup=ROOT/'outputs/cloth-weight-backups'/path.name;backup.parent.mkdir(parents=True,exist_ok=True)
 if not backup.exists():shutil.copy2(path,backup)
 chunk=json.dumps(doc,separators=(',',':'),ensure_ascii=False).encode();chunk+=b' '*(-len(chunk)%4)
 path.write_bytes(struct.pack('<III',0x46546c67,2,28+len(chunk)+len(binary))+struct.pack('<II',len(chunk),0x4e4f534a)+chunk+struct.pack('<II',len(binary),0x004e4942)+binary)
 return {'asset':str(path.relative_to(ROOT)).replace('\\','/'),'changed_vertices':changed,'before':hashlib.sha256(original).hexdigest(),'after':hashlib.sha256(path.read_bytes()).hexdigest()}
if __name__=='__main__':
 report=[]
 for species in ['penguin','bear','pig','chick']:
  for item in ['shirt_love','jacket_denim','coat_cloud','dress_petal','hoodie_nido']:
   row=fix(ROOT/f'assets/runner/accessories/sewn_{item}_{species}.glb')
   if row:report.append(row);print(row['asset'],row['changed_vertices'],flush=True)
 (ROOT/'outputs/torso-weight-corrections.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
