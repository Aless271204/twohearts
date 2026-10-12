"""Inspect exported fabric shells after welding duplicated UV seam positions.

This read-only audit separates real holes from animation/shading artifacts.
"""
import collections, json, struct, sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

def attribute(doc, binary, index):
    a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
    fmt={5121:'B',5123:'H',5125:'I',5126:'f'}[a['componentType']]
    size={'SCALAR':1,'VEC3':3}[a['type']]
    length=struct.calcsize('<'+fmt*size);stride=v.get('byteStride',length)
    offset=v.get('byteOffset',0)+a.get('byteOffset',0)
    return [struct.unpack_from('<'+fmt*size,binary,offset+i*stride) for i in range(a['count'])]

def inspect(path):
    blob=path.read_bytes();n=struct.unpack_from('<I',blob,12)[0]
    doc=json.loads(blob[20:20+n]);binary=blob[28+n:];results=[]
    for mesh in doc['meshes']:
        if not mesh.get('name','').startswith('Patrón envolvente'):continue
        for primitive in mesh['primitives']:
            points=attribute(doc,binary,primitive['attributes']['POSITION'])
            groups={};ids=[groups.setdefault(tuple(round(x,7) for x in p),len(groups)) for p in points]
            indices=[v[0] for v in attribute(doc,binary,primitive['indices'])]
            edges=collections.Counter();degenerate=0
            for i in range(0,len(indices),3):
                face=[ids[j] for j in indices[i:i+3]]
                if len(set(face))<3:degenerate+=1;continue
                for a,b in zip(face,face[1:]+face[:1]):edges[tuple(sorted((a,b)))]+=1
            results.append({'mesh':mesh['name'],'boundary_edges':sum(n==1 for n in edges.values()),
                            'nonmanifold_edges':sum(n>2 for n in edges.values()),'collapsed_faces_at_0_1um':degenerate})
    return results

if __name__=='__main__':
    data=json.loads((ROOT/'assets/runner/blender-wardrobe-models.json').read_text(encoding='utf-8'))
    report=[{'item':item['item_key'],'species':v['species'],'shells':inspect(ROOT/v['path'])}
            for item in data if item['equip_slot']=='pet_body' for v in item['variants']]
    target=ROOT/'outputs/wardrobe-topology-audit.json';target.parent.mkdir(exist_ok=True)
    target.write_text(json.dumps(report,indent=2),encoding='utf-8')
    bad=[r for r in report if any(s['boundary_edges'] or s['nonmanifold_edges'] for s in r['shells'])]
    print(json.dumps({'variants':len(report),'invalid_shells':len(bad),'report':str(target)}))
    if '--strict' in sys.argv and bad:raise ValueError('Unrepaired cloth shells: '+str([(r['item'],r['species']) for r in bad]))
