"""Copy supplied originals without editing them; keep stable inventory identifiers."""
import hashlib
import json
import pathlib
import shutil
import struct

root = pathlib.Path(__file__).resolve().parents[1]
source = pathlib.Path('C:/Users/Lenovo/Desktop/NIDO APP/PRENDAS/cabeza/GBL')
mapping = {
    'cap_pink': 'Meshy_AI_Coral_Heart_Cap_1011015258_texture.glb',
    'hat_garden': 'Meshy_AI_Green_Straw_Hat_with__1011015320_texture.glb',
    'beanie_cloud': 'Meshy_AI_Heartfelt_Winter_Pom__1011015311_texture.glb',
    'beret_chic': 'Meshy_AI_Lavender_Heart_Beret_1011015331_texture.glb',
    'wig_pastel': 'Meshy_AI_Pink_Peach_Wavy_Wig_1011015512_texture.glb',
}
catalog = {x['item_key']: x for x in json.loads((root / 'assets/runner/accessory-catalog.json').read_text())}
profiles = json.loads((root / 'assets/runner/head-fit-profiles.json').read_text(encoding='utf-8'))
items = []
for key, original in mapping.items():
    data = (source / original).read_bytes()
    assert struct.unpack_from('<I', data)[0] == 0x46546c67
    document = json.loads(data[20:20 + struct.unpack_from('<I', data, 12)[0]])
    destination = 'assets/runner/accessories/' + key + '_meshy.glb'
    shutil.copyfile(source / original, root / destination)
    item = dict(catalog[key])
    item['appearance'] = dict(item['appearance'], model_asset=destination, normalize_head=True, preserve_proportions=True, head_fit=profiles[key])
    item['appearance']['conform_head'] = dict(band=0.09, clearance=0.008)
    item['appearance']['soft_fabric'] = True
    item['appearance']['smooth_mesh'] = key in ('wig_pastel', 'beret_chic')
    if key == 'cap_pink':
        item['appearance']['conform_head']['crown_height'] = 0.72
        item['appearance']['conform_head']['visor_length'] = 0.62
        item['appearance']['conform_head']['visor_flatten'] = 0.55
    elif key == 'beret_chic':
        item['appearance']['conform_head']['crown_height'] = 0.65
    elif key == 'hat_garden':
        item['appearance']['conform_head']['crown_height'] = 0.85
    elif key == 'wig_pastel':
        item['appearance']['conform_head']['depth_scale'] = 1.16
        item['appearance']['conform_head']['hair_lining'] = '#efa0ab'
        item['appearance']['conform_head']['contact'] = False
    item['source_file'] = original
    item['sha256'] = hashlib.sha256(data).hexdigest()
    item['triangles'] = sum(document['accessors'][p['indices']]['count'] // 3 for m in document['meshes'] for p in m['primitives'])
    item['fit_status'] = 'pending_visual_review'
    items.append(item)
(root / 'assets/runner/head-models.json').write_text(json.dumps(items, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps({'imported': len(items), 'triangles': {i['item_key']: i['triangles'] for i in items}}))
