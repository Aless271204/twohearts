"""Register Blender-tailored species variants for app-renderer preview.
Does not approve them for sale or replace the production inventory.
"""
import json
from pathlib import Path
repo=Path(__file__).resolve().parents[1]
report=json.loads((repo/'design/blender/fitting/tailoring-report.json').read_text(encoding='utf-8'))
source=json.loads((repo/'assets/runner/head-models.json').read_text(encoding='utf-8'))
result=[]
for original in source:
    variants=[r for r in report if r['item_key']==original['item_key']]
    if len(variants)!=4:continue
    item={k:v for k,v in original.items() if k not in ('appearance','sha256','triangles')}
    item['fit_status']='blender_visual_review';item['preview_only']=True
    item['appearance']={k:original['appearance'][k] for k in ('style','color')}
    item['appearance'].update({'model_asset':next(r['path'] for r in variants if r['species']=='penguin'),'species_models':{r['species']:r['path'] for r in variants},'fitted_model_space':True,'tuck_crown_tuft':True})
    item['blender_variants']=variants
    result.append(item)
(repo/'assets/runner/blender-head-models.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print('Registered',len(result),'heads with four species variants each.')
