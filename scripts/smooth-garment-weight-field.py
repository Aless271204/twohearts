"""Bake one continuous spatial weight field across fabric and stitched trim.

No per-frame smoothing; positions, UVs, images and materials remain unchanged.
"""
from pathlib import Path
import importlib.util,json,struct,sys,hashlib
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('weights',ROOT/'scripts/fix-torso-weights.py')
w=importlib.util.module_from_spec(spec);spec.loader.exec_module(w)

def fix(path):
 raw=path.read_bytes();length=struct.unpack_from('<I',raw,12)[0]
 doc=json.loads(raw[20:20+length]);binary=bytearray(raw[28+length:])
 if doc.get('extras',{}).get('nidoSpatialWeightField')==2:return
 parts=[];seen=set();allp=[];allj=[];allw=[]
 for mesh in doc['meshes']:
  if not mesh.get('extras',{}).get('nidoMotionTransfer'):continue
  for prim in mesh['primitives']:
   a=prim['attributes'];key=(a['JOINTS_0'],a['WEIGHTS_0'])
   if key in seen:continue
   seen.add(key)
   p=np.array(w.attribute(doc,binary,a['POSITION']));j=np.array(w.attribute(doc,binary,a['JOINTS_0']));v=np.array(w.attribute(doc,binary,a['WEIGHTS_0']))
   parts.append((a,len(p)));allp.append(p);allj.append(j);allw.append(v)
 p=np.concatenate(allp);j=np.concatenate(allj);v=np.concatenate(allw)
 # Common lattice makes coincident seams use exactly the same influences.
 step=.012;coords=np.floor(p/step).astype(np.int64);lo=coords.min(axis=0)-2;dims=coords.max(axis=0)-lo+4
 stride=np.array([dims[1]*dims[2],dims[2],1]);keys=(coords-lo)@stride
 unique,inverse=np.unique(keys,return_inverse=True);bones=int(j.max())+1
 field=np.zeros((len(unique),bones));counts=np.bincount(inverse)
 for k in range(4):np.add.at(field,(inverse,j[:,k]),v[:,k])
 field/=counts[:,None]
 for _ in range(3):
  acc=field*4;denom=np.full(len(unique),4.)
  for axis in range(3):
   for sign in [-1,1]:
    desired=unique+stride[axis]*sign;idx=np.searchsorted(unique,desired);valid=idx<len(unique);safe=np.minimum(idx,len(unique)-1);valid&=unique[safe]==desired
    acc[valid]+=field[safe[valid]];denom[valid]+=1
  field=acc/denom[:,None]
 sample=p/step-.5;base=np.floor(sample).astype(np.int64);fraction=sample-base
 dense=np.zeros((len(p),bones));totals=np.zeros(len(p))
 for dx in [0,1]:
  for dy in [0,1]:
   for dz in [0,1]:
    corner=np.array([dx,dy,dz]);desired=(base+corner-lo)@stride;idx=np.searchsorted(unique,desired);safe=np.minimum(idx,len(unique)-1);valid=(idx<len(unique))&(unique[safe]==desired)
    influence=np.prod(np.where(corner,fraction,1-fraction),axis=1)*valid
    dense+=field[safe]*influence[:,None];totals+=influence
 dense[totals<1e-8]=field[inverse[totals<1e-8]];indices=np.argsort(dense,axis=1)[:,-4:][:,::-1];values=np.take_along_axis(dense,indices,axis=1);values/=values.sum(axis=1)[:,None]
 offset=0
 for a,count in parts:
  w.put(doc,binary,a['JOINTS_0'],indices[offset:offset+count].tolist());w.put(doc,binary,a['WEIGHTS_0'],values[offset:offset+count].tolist());offset+=count
 doc.setdefault('extras',{})['nidoSpatialWeightField']=2
 chunk=json.dumps(doc,separators=(',',':'),ensure_ascii=False).encode();chunk+=b' '*(-len(chunk)%4)
 path.write_bytes(struct.pack('<III',0x46546c67,2,28+len(chunk)+len(binary))+struct.pack('<II',len(chunk),0x4e4f534a)+chunk+struct.pack('<II',len(binary),0x004e4942)+binary)
 print(path.name,len(p),hashlib.sha256(path.read_bytes()).hexdigest(),flush=True)

for species in (sys.argv[1:] or ['penguin','bear','pig','chick']):
 for item in ['shirt_love','jacket_denim','coat_cloud','dress_petal','hoodie_nido']:
  fix(ROOT/f'assets/runner/accessories/sewn_{item}_{species}.glb')
