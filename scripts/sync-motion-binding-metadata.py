from pathlib import Path
import json,hashlib
ROOT=Path(__file__).resolve().parents[1]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
p=ROOT/'assets/runner/accessory-catalog.json';catalog=json.loads(p.read_text(encoding='utf-8'));changed={}
for item in catalog:
 if item.get('visible',True)==False:continue
 a=item['appearance'];hashes={sp:sha(ROOT/name) for sp,name in a['species_models'].items()};changed.update({name:hashes[sp] for sp,name in a['species_models'].items()});a['species_model_hashes']=hashes;a['asset_revision']=hashlib.sha256(''.join(hashes.values()).encode()).hexdigest()[:20]
p.write_text(json.dumps(catalog,ensure_ascii=False,indent=2),encoding='utf-8')
for name in ['assets/runner/restart/catalog.json','assets/runner/restart/details-catalog.json','assets/runner/blender-wardrobe-models.json','assets/runner/blender-complement-models.json']:
 p=ROOT/name;data=json.loads(p.read_text(encoding='utf-8'))
 def visit(o):
  if isinstance(o,dict):
   for key,digest in [('path','sha256'),('asset','sha256'),('original_asset','original_sha256'),('original_cap_asset','cap_sha256')]:
    if o.get(key) in changed:o[digest]=changed[o[key]]
   if isinstance(o.get('species_models'),dict):o['species_model_hashes']={sp:changed.get(path,sha(ROOT/path)) for sp,path in o['species_models'].items()}
   for v in o.values():visit(v)
  elif isinstance(o,list):
   for v in o:visit(v)
 visit(data);p.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
p=ROOT/'assets/images/products/wardrobe-thumbnails.json';report=json.loads(p.read_text(encoding='utf-8'))
for r in report:
 if r['model'] in changed:r['model_sha256']=changed[r['model']]
 if '/sewn_' in r['model'] or any(r['item_key']==i['item_key'] and i['equip_slot']=='pet_neck' for i in catalog):r['motion_binding_revision']='original_skin_1';r.pop('container_optimization',None)
p.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
p=ROOT/'lib/core/pet_accessory_catalog.dart';s=p.read_text(encoding='utf-8');a=s.index("r'''")+4;b=s.index("'''",a);s=s[:a]+json.dumps(catalog,ensure_ascii=False,indent=2)+s[b:];p.write_text(s,encoding='utf-8');print('Motion catalog synchronized')
