"""Inventory actual garment exports; structural checks are not visual approval."""
import json,hashlib,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
rows=[]
for filename in ('blender-wardrobe-models.json','blender-complement-models.json'):
    catalog=json.loads((ROOT/'assets/runner'/filename).read_text(encoding='utf-8'))
    for item in catalog:
        if item.get('visible') is False:continue
        for variant in item['variants']:
            path=ROOT/variant['path'];errors=[]
            row={'item_key':item['item_key'],'name':item['name'],'species':variant['species'],'asset':variant['path'],'visual_status':'pending','rest':'pending','run':'pending','jump':'pending'}
            if not path.exists():errors.append('missing_asset')
            else:
                blob=path.read_bytes();row['bytes']=len(blob);row['sha256']=hashlib.sha256(blob).hexdigest()
                if variant.get('sha256')!=row['sha256']:errors.append('stale_registry_hash')
                if blob[:4]!=b'glTF' or struct.unpack_from('<I',blob,8)[0]!=len(blob):errors.append('invalid_glb')
                else:
                    length=struct.unpack_from('<I',blob,12)[0];doc=json.loads(blob[20:20+length]);row['mesh_count']=len(doc.get('meshes',[]));row['materials']=len(doc.get('materials',[]));row['textures']=len(doc.get('textures',[]))
                    fit=json.loads((ROOT/'design/wardrobe-restart/fitting'/f"{variant['species']}-original.json").read_text(encoding='utf-8'));known=set(fit['boneNames'])|{'NidoLeftSleeve','NidoRightSleeve'}
                    missing=sorted({name for mesh in doc['meshes'] for name in mesh.get('extras',{}).get('nidoBoneNames',[]) if name not in known})
                    if missing:errors.append({'unknown_attachment_bones':missing})
                    row['vertices']=sum(doc['accessors'][p['attributes']['POSITION']]['count'] for mesh in doc['meshes'] for p in mesh['primitives'])
            row['structural_errors']=errors;rows.append(row)
report={'scope':'24 inventory items, 4 original mascots; visual review required independently','rows':rows,'count':len(rows),'structural_failures':sum(bool(r['structural_errors']) for r in rows),'restart_note':'The approved penguin tee and new Dulce details are experimental overrides; this audits shop exports without activating or replacing them.'}
out=ROOT/'outputs/current-wardrobe-audit.json';out.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'variants':len(rows),'structural_failures':report['structural_failures'],'visual_approval':'pending'}))
