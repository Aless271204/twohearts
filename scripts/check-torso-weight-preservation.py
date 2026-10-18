"""Compare corrected exports with their backups, without loading Blender."""
from pathlib import Path
import json, struct
import importlib.util

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('weights',ROOT/'scripts/fix-torso-weights.py')
weights=importlib.util.module_from_spec(spec);spec.loader.exec_module(weights)

def read(path):
    raw=path.read_bytes();size=struct.unpack_from('<I',raw,12)[0]
    return json.loads(raw[20:20+size]),raw[28+size:]

count=0
for backup in (ROOT/'outputs/cloth-weight-backups').glob('sewn_*.glb'):
    before,old=read(backup);after,new=read(ROOT/'assets/runner/accessories'/backup.name)
    assert after['extras']['nidoTorsoWeightConstraints']==1
    assert before.get('images')==after.get('images')
    assert before.get('materials')==after.get('materials')
    mutable=set()
    for mesh_a,mesh_b in zip(before['meshes'],after['meshes']):
        for a,b in zip(mesh_a['primitives'],mesh_b['primitives']):
            assert a==b
            for name,index in a['attributes'].items():
                if name in ('JOINTS_0','WEIGHTS_0'):
                    mutable.add(before['accessors'][index]['bufferView'])
                else:
                    assert weights.attribute(before,old,index)==weights.attribute(after,new,index),(backup.name,name)
    for i,view in enumerate(before['bufferViews']):
        if i not in mutable:
            start=view.get('byteOffset',0);end=start+view['byteLength']
            assert old[start:end]==new[start:end],(backup.name,i)
    count+=1
assert count==20,count
print('PASS: all 20 exports preserve geometry, UVs, normals, indices, textures and materials; only skin weights changed.')
