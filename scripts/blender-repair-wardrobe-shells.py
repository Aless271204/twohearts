"""Repair selected editable cloth collections and reexport all their details.

Blender --background MASTER.blend --python this.py -- items=... species=...
"""
import bpy,json,hashlib,sys,shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts'))
from wardrobe_shells import repair_shell
from wardrobe_gltf import add_skin_attributes
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
items=next((v.split('=',1)[1].split(',') for v in args if v.startswith('items=')),None)
species=next((v.split('=',1)[1].split(',') for v in args if v.startswith('species=')),None)
path=ROOT/'assets/runner/blender-wardrobe-models.json';catalog=json.loads(path.read_text(encoding='utf-8'))
for item in catalog:
    if item['equip_slot']!='pet_body' or items and item['item_key'] not in items:continue
    for variant in item['variants']:
        sp=variant['species']
        if species and sp not in species:continue
        col=bpy.data.collections[item['item_key']+' · '+sp];col.hide_viewport=False
        for obj in col.objects:
            if obj.type=='MESH' and obj.name.startswith('Patrón envolvente'):repair_shell(obj)
        bpy.ops.object.select_all(action='DESELECT')
        for obj in col.objects:obj.hide_set(False);obj.select_set(True)
        output=ROOT/variant['path']
        bpy.ops.export_scene.gltf(filepath=str(output),export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
        data=json.loads((ROOT/'design/blender/fitting'/f'{sp}.json').read_text())
        add_skin_attributes(output,data);variant['sha256']=hashlib.sha256(output.read_bytes()).hexdigest()
        col.hide_viewport=True;print('SHELL_REPAIRED',item['item_key'],sp,flush=True)
path.write_text(json.dumps(catalog,ensure_ascii=False,indent=2),encoding='utf-8')
master=Path(bpy.data.filepath);shutil.copy2(master,master.with_suffix('.blend1'))
bpy.ops.wm.save_as_mainfile(filepath=str(master),compress=True)
print('SHELLS_READY',flush=True)
