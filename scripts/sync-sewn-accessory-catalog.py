"""Update visual models only. Ownership, visibility and prices stay canonical.

Edit accessory-catalog.json for inventory controls; edit fitting JSON/Blender
masters for shape. Dart is generated from that single inventory source.
"""
import json, hashlib, shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
path=ROOT/'assets/runner/accessory-catalog.json'
backup=ROOT/'design/wardrobe-restart/accessory-catalog-before-sewn-release.json'
if not backup.exists():shutil.copy2(path,backup)
items=json.loads(path.read_text(encoding='utf-8'))
catalog=json.loads((ROOT/'assets/runner/restart/catalog.json').read_text(encoding='utf-8'))
details=json.loads((ROOT/'assets/runner/restart/details-catalog.json').read_text(encoding='utf-8'))
species=('penguin','bear','pig','chick')
for item in items:
 if item.get('visible',True) is False:continue
 key=item['item_key'];models={};hashes={};coverage={};heads={}
 for sp in species:
  if key=='cap_pink':
   v=next(v for v in catalog['variants'] if v['species']==sp)
   model=v['original_cap_asset'];digest=v['cap_sha256']
   heads[sp]={**v['headwear_occlusion'],'hide_inside_crown':True}
  elif item['equip_slot']=='pet_body':
   v=next(v for row in catalog['wardrobe'] if row['item_key']==key for v in row['variants'] if v['species']==sp)
   model=v['original_asset'];digest=v['original_sha256'];coverage[sp]=v['coverage_asset']
  else:
   v=next(v for v in details if v['item_key']==key and v['species']==sp)
   model=v['asset'];digest=v['sha256']
  if hashlib.sha256((ROOT/model).read_bytes()).hexdigest()!=digest:raise ValueError('Stale variant '+key+'/'+sp)
  models[sp]=model;hashes[sp]=digest
 appearance={**item['appearance'],'model_asset':models['penguin'],'species_models':models,
  'species_model_hashes':hashes,'fitted_model_space':True,
  'skinned_model_space':item['equip_slot'] in ('pet_body','pet_neck','pet_feet')}
 for flag in ('normalize_head','conform_head','head_fit','smooth_mesh','soft_fabric','coverage_asset'):
  appearance.pop(flag,None)
 if coverage:appearance['coverage_assets']=coverage
 if heads:appearance['headwear_occlusions']=heads
 fingerprint=json.dumps({'models':hashes,'heads':heads,'coverage':{sp:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for sp,p in coverage.items()}},sort_keys=True)
 appearance['asset_revision']=hashlib.sha256(fingerprint.encode()).hexdigest()[:20]
 item['appearance']=appearance
path.write_text(json.dumps(items,ensure_ascii=False,indent=2),encoding='utf-8')
dart=ROOT/'lib/core/pet_accessory_catalog.dart'
loader="""
Future<void>? _loading;
Future<void> loadPetAccessoryCatalog() => _loading ??= _load();
Future<void> _load() async {
 final data=jsonDecode(await rootBundle.loadString('assets/runner/accessory-catalog.json')) as List;
 final items=data.map((e)=>Map<String,dynamic>.from(e as Map)).toList();
 if(items.map((e)=>e['item_key']).toSet().length!=items.length) { throw StateError('Duplicate accessory key'); }
 petAccessoryConcepts..clear()..addAll(items);
}
"""
dart.write_text("// Generated from assets/runner/accessory-catalog.json. Edit that inventory source.\nimport 'dart:convert';\nimport 'package:flutter/services.dart';\n\nfinal petAccessoryConcepts = (jsonDecode(r'''"+json.dumps(items,ensure_ascii=False,indent=2)+"''') as List).map((e) => Map<String, dynamic>.from(e)).toList();\n"+loader,encoding='utf-8')
print('Visual models synchronized; prices and ownership flags preserved.')
