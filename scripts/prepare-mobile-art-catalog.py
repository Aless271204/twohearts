"""Package generated drawing references; retain untouched PNG masters outside runtime assets."""
import json, shutil
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
source=ROOT/'design/art-references/mobile-catalog-generated.json'
items=json.loads(source.read_text(encoding='utf-8-sig'))
by_id={item['id']:item for item in items}
for item_file in sorted((ROOT/'design/art-references/mobile-items').glob('*.json')):
    item=json.loads(item_file.read_text(encoding='utf-8-sig'))
    by_id[item['id']]=item
items=list(by_id.values())
runtime=ROOT/'assets/images/art_references/mobile'
masters=ROOT/'design/art-references/mobile-masters'
runtime.mkdir(parents=True,exist_ok=True)
masters.mkdir(parents=True,exist_ok=True)
manifest=[]
for item in items:
    name=item['level']+'-'+item['id']
    master=masters/(name+'.png')
    if not master.exists(): shutil.copy2(item['source'],master)
    target=runtime/(name+'.webp')
    if not target.exists():
        image=Image.open(master).convert('RGB')
        assert image.width==image.height, name
        image.thumbnail((768,768),Image.Resampling.LANCZOS)
        image.save(target,format='WEBP',quality=92,method=6)
    manifest.append({'id':name,'level':item['level'],'title':item['title'],'asset':'assets/images/art_references/mobile/'+target.name,'enabled':item.get('enabled',True),'category':item.get('category','scenery')})
(runtime/'catalog.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'images':len(manifest),'bytes':sum(x.stat().st_size for x in runtime.glob('*.webp')),'levels':{level:sum(x['level']==level for x in manifest) for level in ['easy','medium','hard']}}))
