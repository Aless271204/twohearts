"""Export only sewn caps over the original mascot measurements. No pet export."""
import bpy,json,sys,hashlib,importlib.util
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('materials_and_cap',ROOT/'scripts/blender-restart-wardrobe.py')
base=importlib.util.module_from_spec(spec);spec.loader.exec_module(base)
species=['penguin','bear','pig','chick']
if '--species' in sys.argv:species=[sys.argv[sys.argv.index('--species')+1]]
registry_path=ROOT/'assets/runner/restart/catalog.json';registry=json.loads(registry_path.read_text(encoding='utf-8'))
for sp in species:
 bpy.ops.wm.read_factory_settings(use_empty=True)
 data=json.loads((ROOT/'design/wardrobe-restart/fitting'/f'{sp}-original.json').read_text(encoding='utf-8'))
 coral=base.material('Algodón coral','#EC6276',.92,True)
 for node in coral.node_tree.nodes:
  if node.type=='NORMAL_MAP':node.inputs['Strength'].default_value=.75
 thread=base.material('Pespunte crema','#FFF1DD',.93)
 ivory=base.material('Corazón bordado crema','#FFF1DD',.93,True)
 gold=base.material('Hebilla de latón','#D6AD63',.40,metal=True)
 parts=base.build_cap(sp,data,coral,thread,ivory,gold)
 bpy.ops.object.select_all(action='DESELECT')
 for part in parts:part.select_set(True)
 bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();cap=parts[0];cap.name='Gorra corazón - algodón cosido original'
 path=ROOT/'assets/runner/accessories'/f'restart_cap_pink_{sp}.glb';stage=path.with_name(path.stem+'.building.glb')
 base.export_selected(stage,[cap],False);stage.replace(path)
 bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'design/wardrobe-restart/models'/f'GORRA-ORIGINAL-{sp}.blend'),compress=True)
 entry=next(v for v in registry['variants'] if v['species']==sp)
 entry.update(original_cap_asset=path.relative_to(ROOT).as_posix(),cap_sha256=hashlib.sha256(path.read_bytes()).hexdigest(),fit_status='pending_original_model_visual_review')
 print('ORIGINAL_CAP_EXPORTED',sp,flush=True)
registry_path.write_text(json.dumps(registry,ensure_ascii=False,indent=2),encoding='utf-8')
