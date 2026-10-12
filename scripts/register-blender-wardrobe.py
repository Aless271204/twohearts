"""Sync reviewed Blender asset paths with the existing inventory identities.

Does not grant ownership, change prices or publish products in Supabase.
Visibility and prices remain editable in assets/runner/accessory-catalog.json.
"""
import json,hashlib,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
path=ROOT/'assets/runner/accessory-catalog.json'
catalog=json.loads(path.read_text(encoding='utf-8'))
models=[]
for name in ('blender-wardrobe-models.json','blender-complement-models.json'):
 models.extend(json.loads((path.parent/name).read_text(encoding='utf-8')))
index={item['item_key']:item for item in models}
patterns=json.loads((ROOT/'design/blender/wardrobe-patterns.json').read_text(encoding='utf-8'))
for model in models:
 if model['equip_slot']!='pet_body':continue
 coverage={}
 for species in ('penguin','bear','pig','chick'):
  fit=json.loads((ROOT/'design/blender/fitting'/f'{species}.json').read_text())
  top=fit['body']['max'][1]+patterns.get('species_fit',{}).get(species,{}).get('neck_extension',.010)
  depth=.155 if model['item_key'] in ('coat_cloud','hoodie_nido') else .110
  coverage[species]={'min_y':top-depth-.012,'max_y':top+.010}
 model['appearance']['sleeve_coverage']=coverage
for file in ('blender-wardrobe-models.json','blender-complement-models.json'):
 model_path=path.parent/file;keys={i['item_key'] for i in json.loads(model_path.read_text(encoding='utf-8'))}
 model_path.write_text(json.dumps([model for model in models if model['item_key'] in keys],ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def clean(value):
 if isinstance(value,list):return [clean(v) for v in value]
 if isinstance(value,dict):return {k:clean(v) for k,v in value.items()}
 if isinstance(value,str) and any(c in value for c in ('Ã','Â','â')):
  for encoding in ('latin1','cp1252'):
   try:return value.encode(encoding).decode('utf-8')
   except (UnicodeError,LookupError):pass
 return value
catalog=clean(catalog)
for item in catalog:
 model=index.get(item['item_key'])
 if not model:continue
 if {v['species'] for v in model['variants']}!={'penguin','bear','pig','chick'}:raise ValueError('Incomplete species set')
 for variant in model['variants']:
  b=(ROOT/variant['path']).read_bytes()
  if hashlib.sha256(b).hexdigest()!=variant['sha256']:raise ValueError('Stale asset: '+variant['path'])
 # Keep the existing style, colour and inventory key, including thumbnail naming.
 old=item['appearance'];updated={**old,**model['appearance'],'style':old['style']}
 for legacy in ('normalize_head','smooth_mesh','soft_fabric','conform_head','head_fit','preserve_proportions'):
  updated.pop(legacy,None)
 updated['asset_revision']=hashlib.sha256(''.join(v['sha256'] for v in model['variants']).encode()).hexdigest()[:16]
 item['appearance']=updated
 item['description']='Modelo 3D adaptado a pingüino, oso, cerdito y pollito.'
 if model.get('fabric'):item['fabric']=model['fabric']
path.write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
dart=ROOT/'lib/core/pet_accessory_catalog.dart';text=dart.read_text(encoding='utf-8')
start=text.index("jsonDecode(r'''")+len("jsonDecode(r'''");end=text.index("''') as List",start)
dart.write_text(text[:start]+json.dumps(catalog,ensure_ascii=True,separators=(',',':'))+text[end:],encoding='utf-8')
print('Registered',len(index),'items; inventory prices and ownership preserved')
