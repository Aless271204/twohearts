"""Closed textile underlay at the rear shoulder/neck join; original pet untouched."""
import json,struct,sys,shutil
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
args=sys.argv[sys.argv.index('--')+1:];species=args[0];key=args[1]
catalog=json.loads((ROOT/'assets/runner/accessory-catalog.json').read_text(encoding='utf-8'));item=next(i for i in catalog if i['item_key']==key);path=ROOT/item['appearance']['species_models'][species]
archive=ROOT/'design/wardrobe-restart/models/before-shoulder-lining'/path.name;archive.parent.mkdir(parents=True,exist_ok=True)
if not archive.exists():shutil.copy2(path,archive)
blob=archive.read_bytes();n=struct.unpack_from('<I',blob,12)[0];doc=json.loads(blob[20:20+n]);binary=bytearray(blob[28+n:]);data=json.loads((ROOT/f'design/wardrobe-restart/fitting/{species}-original.json').read_text(encoding='utf-8'));source=data['meshes'][0]
vertices=[Vector(source['positions'][i:i+3]) for i in range(0,len(source['positions']),3)];top=data['head']['min'][1]+.035;bottom=top-.13;inner=data['body']['max'][0]*.55;outer=max(abs(data['head']['min'][0]),data['head']['max'][0])*.91
triangles=[];normals=[Vector() for p in vertices]
for k in range(0,len(source['indices']),3):
 ids=source['indices'][k:k+3];a,b,c=[vertices[i] for i in ids];normal=(b-a).cross(c-a)
 for i in ids:normals[i]+=normal
 center=(a+b+c)/3
 if inner<abs(center.x)<outer and bottom<center.y<top and center.z<.08:triangles.append(ids)
used=sorted({i for tri in triangles for i in tri});mapping={i:j for j,i in enumerate(used)};positions=[];normal_data=[];uv=[];joints=[];weights=[]
for inside in [False,True]:
 for i in used:
  normal=normals[i].normalized();q=vertices[i]+normal*(.006 if not inside else -.002);positions.extend(q);normal_data.extend(normal*(-1 if inside else 1));uv.extend((q.x/.20,q.y/.20));joints.extend(source['skinIndex'][4*i:4*i+4]);weights.extend(source['skinWeight'][4*i:4*i+4])
faces=[];edges={};size=len(used)
for tri in triangles:
 ids=[mapping[i] for i in tri];faces.extend(ids);faces.extend([ids[2]+size,ids[1]+size,ids[0]+size])
 for a,b in zip(ids,ids[1:]+ids[:1]):edges.setdefault(tuple(sorted((a,b))),[]).append((a,b))
for values in edges.values():
 if len(values)==1:
  a,b=values[0];faces.extend((a,a+size,b+size,a,b+size,b))
def attr(values,fmt,ctype,width,kind):
 binary.extend(b'\0'*(-len(binary)%4));offset=len(binary);raw=struct.pack('<'+fmt*len(values),*values);binary.extend(raw);view=len(doc['bufferViews']);doc['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':len(raw)});i=len(doc['accessors']);a={'bufferView':view,'componentType':ctype,'count':len(values)//width,'type':kind}
 if kind=='VEC3' and fmt=='f':a.update(min=[min(values[j::3]) for j in range(3)],max=[max(values[j::3]) for j in range(3)])
 doc['accessors'].append(a);return i
attributes={'POSITION':attr(positions,'f',5126,3,'VEC3'),'NORMAL':attr(normal_data,'f',5126,3,'VEC3'),'TEXCOORD_0':attr(uv,'f',5126,2,'VEC2'),'JOINTS_0':attr(joints,'H',5123,4,'VEC4'),'WEIGHTS_0':attr(weights,'f',5126,4,'VEC4')}
primary=next(m for m in doc['meshes'] if m.get('extras',{}).get('nidoSkinTransfer',{}).get('stage')=='primary');material=primary['primitives'][0]['material'];extras={'nidoBoneNames':primary['extras']['nidoBoneNames'],'nidoMotionTransfer':{'version':1,'source':'original-mascot-surface','source_mesh':'Mesh_0','species':species},'nidoSkinTransfer':{'method':'original_surface_lining','stage':'lining'},'nidoShoulderLining':True}
mesh=len(doc['meshes']);doc['meshes'].append({'name':'Forro cerrado de unión de hombro','primitives':[{'attributes':attributes,'indices':attr(faces,'I',5125,1,'SCALAR'),'material':material}],'extras':extras});node=len(doc['nodes']);doc['nodes'].append({'name':'Forro cerrado de unión de hombro','mesh':mesh});doc['scenes'][doc.get('scene',0)]['nodes'].append(node)
doc['buffers'][0]['byteLength']=len(binary);binary.extend(b'\0'*(-len(binary)%4));chunk=json.dumps(doc,separators=(',',':'),ensure_ascii=False).encode();chunk+=b' '*(-len(chunk)%4)
path.write_bytes(struct.pack('<III',0x46546c67,2,28+len(chunk)+len(binary))+struct.pack('<II',len(chunk),0x4e4f534a)+chunk+struct.pack('<II',len(binary),0x004e4942)+binary);print('SHOULDER_LINING',species,key,len(used),flush=True)
