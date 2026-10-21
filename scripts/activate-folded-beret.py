"""Activate the fitted beret only after actual native screenshots were reviewed."""
import hashlib,json,shutil
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1]
receipt=json.loads((root/'outputs/native-beret-fit/validated.json').read_text(encoding='utf-8'))
assert receipt['visual_reviewed'] is True and len(receipt['frames'])==20
assert receipt['asset_commit']=='c648c5102d2388817c3503978b858c756f0409bc'
path=root/'assets/runner/accessory-catalog.json'
catalog=json.loads(path.read_text(encoding='utf-8'))
item=next(i for i in catalog if i['item_key']=='beret_chic')
appearance=item['appearance'];models={};hashes={}
for species in ['penguin','bear','pig','chick']:
    source=root/f'assets/runner/accessories/experimental_beret_chic_{species}_v9.glb'
    target=root/appearance['species_models'][species]
    backup=root/f'design/wardrobe-restart/experiments/beret-fit-v9/sources/{species}.glb'
    backup.parent.mkdir(parents=True,exist_ok=True)
    if not backup.exists(): shutil.copy2(target,backup)
    digest=hashlib.sha256(source.read_bytes()).hexdigest()
    assert receipt['models'][species]==digest
    shutil.copy2(source,target)
    models[species]=str(target.relative_to(root)).replace('\\','/')
    hashes[species]=digest
appearance.update(model_asset=models['penguin'],species_models=models,
    species_model_hashes=hashes,
    asset_revision=hashlib.sha256(json.dumps(hashes,sort_keys=True).encode()).hexdigest()[:20])
path.write_text(json.dumps(catalog,ensure_ascii=False,indent=2),encoding='utf-8')
dart=root/'lib/core/pet_accessory_catalog.dart';text=dart.read_text(encoding='utf-8')
start=text.index("r'''")+4;end=text.index("'''",start)
dart.write_text(text[:start]+json.dumps(catalog,ensure_ascii=False,indent=2)+text[end:],encoding='utf-8')
image=root/'outputs/outfit-showcases/chic-folded/pig-Rest-0-before-0.png'
Image.open(image).save(root/'assets/images/products/showcases/outfit_chic.webp',quality=90,method=4)
test=root/'test/small_beret_test.mjs';text=test.read_text(encoding='utf-8')
text=text.replace('const source=`assets/runner/accessories/experimental_beret_chic_${species}_v9.glb`;', 'const source=appearance.species_models[species];')
text=text.replace('loadPet(`../accessories/experimental_beret_chic_${species}_v9.glb`)', "loadPet(source.replace('assets/runner/','../'))")
test.write_text(text,encoding='utf-8')
print('Activated four validated small folded berets; original pets unchanged.')
