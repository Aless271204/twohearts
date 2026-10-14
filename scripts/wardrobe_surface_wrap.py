"""Opt-in cloth cage on immutable posed source triangles; GLB binary attributes."""
import json,struct
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree
from wardrobe_gltf import _attribute,barycentric

def add_surface_wrap(path,data):
    blob=path.read_bytes();length=struct.unpack_from('<I',blob,12)[0]
    doc=json.loads(blob[20:20+length]);binary=bytearray(blob[28+length:])
    points=[];triangles=[];sources=[]
    for mesh in data['meshes']:
        offset=len(points);points.extend(Vector(mesh['positions'][i:i+3]) for i in range(0,len(mesh['positions']),3))
        sources.append({'name':mesh['name'],'offset':offset,'count':len(mesh['positions'])//3})
        triangles.extend(tuple(offset+k for k in mesh['indices'][i:i+3]) for i in range(0,len(mesh['indices']),3))
    tree=BVHTree.FromPolygons(points,triangles,all_triangles=True)
    field=data['garment_skin_profile']['sewn_sleeve_field'];controls=KDTree(len(field))
    for i,entry in enumerate(field):controls.insert(Vector(entry[:3]),i)
    controls.balance()
    def attribute(values):
        binary.extend(b'\0'*(-len(binary)%4));offset=len(binary)
        binary.extend(struct.pack('<'+'f'*len(values),*values))
        view=len(doc['bufferViews']);doc['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':len(values)*4})
        index=len(doc['accessors']);doc['accessors'].append({'bufferView':view,'componentType':5126,'count':len(values)//3,'type':'VEC3'})
        return index
    for mesh in doc['meshes']:
        mesh.setdefault('extras',{})['nidoSurfaceWrap']={'version':2,'sources':sources,'offset_frame':'model'}
        for primitive in mesh['primitives']:
            positions=_attribute(doc,binary,primitive['attributes']['POSITION'])
            ids=[];weights=[];offsets=[];blend=[]
            for p in positions:
                q=Vector(p);hit,_,index,_=tree.find_nearest(q);tri=triangles[index]
                a,b,c=[points[i] for i in tri];tangent=(b-a).normalized();normal=(b-a).cross(c-a).normalized();across=normal.cross(tangent)
                delta=q-hit;ids.extend(tri);weights.extend(barycentric(hit,a,b,c));offsets.extend(delta)
                _,control,_=controls.find(q);blend.extend((field[control][4],0,0))
            attrs=primitive['attributes']
            for name,values in [('_NIDO_WRAP_INDICES',ids),('_NIDO_WRAP_WEIGHTS',weights),('_NIDO_WRAP_OFFSET',offsets),('_NIDO_WRAP_BLEND',blend)]:attrs[name]=attribute(values)
    doc['buffers'][0]['byteLength']=len(binary);chunk=json.dumps(doc,separators=(',',':')).encode();chunk+=b' '*(-len(chunk)%4)
    path.write_bytes(struct.pack('<III',0x46546c67,2,28+len(chunk)+len(binary))+struct.pack('<II',len(chunk),0x4e4f534a)+chunk+struct.pack('<II',len(binary),0x004e4942)+binary)
