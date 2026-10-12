"""Refresh wardrobe weights without rebuilding manually edited geometry.
Run with Blender --background --python scripts/blender-refresh-wardrobe-skin.py.
Preserves geometry while updating body and neck variants in the two catalogs.
"""
import json,hashlib,sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'scripts'))
from wardrobe_gltf import add_skin_attributes
catalogs={root/'assets/runner'/filename:json.loads((root/'assets/runner'/filename).read_text(encoding='utf-8'))
          for filename in ('blender-wardrobe-models.json','blender-complement-models.json')}
catalog=[item for entries in catalogs.values() for item in entries]
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
selected_items=next((v.split('=',1)[1].split(',') for v in args if v.startswith('items=')),None)
selected_species=next((v.split('=',1)[1].split(',') for v in args if v.startswith('species=')),None)
for species in ('penguin','bear','pig','chick'):
 if selected_species and species not in selected_species:continue
 data=json.loads((root/'design/blender/fitting'/f'{species}.json').read_text())
 for item in catalog:
  if selected_items and item['item_key'] not in selected_items:continue
  if item['equip_slot'] not in ('pet_body','pet_neck'):continue
  variant=next(v for v in item['variants'] if v['species']==species)
  path=root/variant['path']
  add_skin_attributes(path,data)
  variant['sha256']=hashlib.sha256(path.read_bytes()).hexdigest()
  print('SKIN',item['item_key'],species,flush=True)
for path,entries in catalogs.items():path.write_text(json.dumps(entries,ensure_ascii=False,indent=2),encoding='utf-8')
print('WARDROBE_SKIN_READY',flush=True)
