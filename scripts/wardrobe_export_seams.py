"""Restore tiny triangles omitted while exporting a closed Blender cloth shell.

Only index topology changes: positions, UVs, normals, skin and texture bytes stay
identical. Deliberate garment openings have closed thickness; a larger gap is
an error, never silently capped. This is a digital export check, not print QA.
"""
import collections, json, math, struct

def attribute(doc, binary, index):
    a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
    fmt={5121:'B',5123:'H',5125:'I',5126:'f'}[a['componentType']]
    count={'SCALAR':1,'VEC3':3}[a['type']];size=struct.calcsize('<'+fmt*count)
    offset=v.get('byteOffset',0)+a.get('byteOffset',0)
    return [struct.unpack_from('<'+fmt*count,binary,offset+i*v.get('byteStride',size)) for i in range(a['count'])]

def repair_indices(points, indices):
    groups={};ids=[groups.setdefault(tuple(round(x,7) for x in p),len(groups)) for p in points]
    positions=list(groups);faces=[indices[i:i+3] for i in range(0,len(indices),3)]
    by_face=collections.defaultdict(list)
    for i,face in enumerate(faces):
        welded=[ids[v] for v in face]
        if len(set(welded))==3:by_face[tuple(sorted(welded))].append(i)
    removed=set()
    for matches in by_face.values():
        if len(matches)!=2:continue
        a,b=([ids[v] for v in faces[i]] for i in matches)
        # Opposite coincident faces are an internal, zero-thickness remesh fold.
        if any(b==[a[k],a[(k+2)%3],a[(k+1)%3]] for k in range(3)):removed.update(matches)
    kept=[f for i,f in enumerate(faces) if i not in removed]
    edges=collections.Counter();oriented={};representatives={}
    for face in kept:
        f=[ids[v] for v in face]
        if len(set(f))<3:continue
        for vertex,welded in zip(face,f):representatives.setdefault(welded,vertex)
        for a,b in zip(f,f[1:]+f[:1]):edge=tuple(sorted((a,b)));edges[edge]+=1;oriented[edge]=(a,b)
    if any(n>2 for n in edges.values()):raise ValueError('Export contains a nonmanifold cloth seam')
    remaining={e for e,n in edges.items() if n==1};added=[]
    while remaining:
        component={remaining.pop()};vertices=set(next(iter(component)))
        while True:
            more={e for e in remaining if vertices.intersection(e)}
            if not more:break
            remaining-=more;component|=more;vertices|={v for e in more for v in e}
        if len(component)!=3 or len(vertices)!=3:raise ValueError('Cloth export gap is not a tiny triangle')
        a,b=oriented[next(iter(component))];c=next(v for v in vertices if v not in (a,b))
        p,q,r=[positions[v] for v in (a,b,c)]
        u=[q[k]-p[k] for k in range(3)];v=[r[k]-p[k] for k in range(3)]
        area=.5*math.sqrt(sum(x*x for x in (u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0])))
        if area>1e-6 or max(math.dist(x,y) for x in (p,q,r) for y in (p,q,r))>.003:
            raise ValueError('Cloth export gap exceeds 1 mm² / 3 mm')
        triangle=[b,a,c]
        if any(oriented[tuple(sorted((x,y)))]!=(y,x) for x,y in zip(triangle,triangle[1:]+triangle[:1])):
            raise ValueError('Inconsistent winding on cloth seam')
        added.append([representatives[v] for v in triangle])
    return [v for face in kept+added for v in face],{'added_triangles':len(added),'removed_internal_faces':len(removed)}

def repair_export(path):
    blob=path.read_bytes();length=struct.unpack_from('<I',blob,12)[0]
    doc=json.loads(blob[20:20+length]);binary=bytearray(blob[28+length:]);changed=False;report=[]
    for mesh in doc['meshes']:
        if not mesh.get('name','').startswith('Patrón envolvente'):continue
        for primitive in mesh['primitives']:
            points=attribute(doc,binary,primitive['attributes']['POSITION'])
            previous=[v[0] for v in attribute(doc,binary,primitive['indices'])]
            indices,result=repair_indices(points,previous);report.append(result)
            if indices==previous:continue
            changed=True
            while len(binary)%4:binary.append(0)
            offset=len(binary);binary.extend(struct.pack('<'+'I'*len(indices),*indices))
            view=len(doc['bufferViews']);doc['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':len(indices)*4,'target':34963})
            index=len(doc['accessors']);doc['accessors'].append({'bufferView':view,'componentType':5125,'count':len(indices),'type':'SCALAR','min':[min(indices)],'max':[max(indices)]})
            primitive['indices']=index
        if changed:mesh.setdefault('extras',{})['nidoExportSeams']=report
    if changed:
        doc['buffers'][0]['byteLength']=len(binary)
        chunk=json.dumps(doc,separators=(',',':'),ensure_ascii=False).encode();chunk+=b' '*(-len(chunk)%4)
        path.write_bytes(struct.pack('<III',0x46546c67,2,28+len(chunk)+len(binary))+struct.pack('<II',len(chunk),0x4e4f534a)+chunk+struct.pack('<II',len(binary),0x004e4942)+binary)
    return report
