"""Lossless deduplication of repeated fitting metadata, never mesh reduction."""
import json,struct,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
registry_path=ROOT/'assets/runner/restart/catalog.json'
registry=json.loads(registry_path.read_text(encoding='utf-8'));results=[]
for item in registry['wardrobe']:
    for variant in item['variants']:
        if variant['species'] not in ('bear','pig','chick') or '/sewn_' not in variant.get('original_asset',''):continue
        path=ROOT/variant['original_asset'];original=path.read_bytes();length=struct.unpack_from('<I',original,12)[0]
        doc=json.loads(original[20:20+length]);binary=original[28+length:]
        profiles=[m['extras']['nidoSleeveFit'] for m in doc['meshes'] if 'nidoSleeveFit' in m.get('extras',{})]
        if not profiles:raise ValueError('Missing attachment profile '+str(path))
        if any(p!=profiles[0] for p in profiles):raise ValueError('Distinct profiles cannot be merged')
        target=next(m for m in doc['meshes'] if m['name'].startswith('Manga adaptada'))
        for mesh in doc['meshes']:mesh.get('extras',{}).pop('nidoSleeveFit',None)
        target['extras']['nidoSleeveFit']=profiles[0]
        chunk=json.dumps(doc,separators=(',',':')).encode();chunk+=b' '*(-len(chunk)%4)
        changed=struct.pack('<III',0x46546c67,2,28+len(chunk)+len(binary))+struct.pack('<II',len(chunk),0x4e4f534a)+chunk+struct.pack('<II',len(binary),0x004e4942)+binary
        assert changed[28+len(chunk):]==binary,'Every geometry/UV/normal/weight/texture byte must be preserved'
        path.write_bytes(changed);variant['original_sha256']=hashlib.sha256(changed).hexdigest()
        results.append({'item':item['item_key'],'species':variant['species'],'before':len(original),'after':len(changed),'binary_sha256':hashlib.sha256(binary).hexdigest()})
registry_path.write_text(json.dumps(registry,ensure_ascii=False,indent=2),encoding='utf-8')
(ROOT/'outputs/sewn-lossless-compaction.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
print(json.dumps({'variants':len(results),'before_MB':round(sum(r['before'] for r in results)/1048576,2),'after_MB':round(sum(r['after'] for r in results)/1048576,2),'geometry_and_textures':'byte_identical'}))
