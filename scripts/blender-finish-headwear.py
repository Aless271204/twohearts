"""Round the exposed fabric cuts without flattening crowns or touching pets."""
import bpy, json, sys, hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
source=json.loads((ROOT/'assets/runner/blender-wardrobe-models.json').read_text(encoding='utf-8'))
reports=[]
for item in source:
 if item['item_key'] not in ('beanie_cloud','hat_garden','beret_chic'):continue
 for variant in item['variants']:
  sp=variant['species'];key=item['item_key']
  bpy.ops.wm.read_factory_settings(use_empty=True)
  bpy.ops.import_scene.gltf(filepath=str(ROOT/variant['path']))
  objects=[o for o in bpy.data.objects if o.type=='MESH']
  for obj in objects:
   if not any(k in obj.name.replace('_',' ') for k in ('Copa','Dobladillo','Ala de paja')):continue
   bpy.context.view_layer.objects.active=obj
   bevel=obj.modifiers.new('Acabado textil suave de corte','BEVEL')
   bevel.width=.0025;bevel.segments=3;bevel.limit_method='ANGLE';bevel.angle_limit=.70
   bevel.use_clamp_overlap=True
   bpy.ops.object.modifier_apply(modifier=bevel.name)
   for face in obj.data.polygons:face.use_smooth=True
  bpy.ops.object.select_all(action='DESELECT')
  for obj in objects:obj.select_set(True)
  path=ROOT/f'assets/runner/accessories/restart_headfinish_{key}_{sp}.glb';stage=path.with_suffix('.building.glb')
  bpy.ops.export_scene.gltf(filepath=str(stage),export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
  stage.replace(path)
  bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/f'design/wardrobe-restart/models/ACABADO-{key}-{sp}.blend'),compress=True)
  reports.append({'item_key':key,'species':sp,'asset':path.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'skinned_model_space':False})
  print('HEADWEAR_FINISHED',key,sp,flush=True)
catalog=ROOT/'assets/runner/restart/details-catalog.json';old=json.loads(catalog.read_text(encoding='utf-8'))
updated={(r['species'],r['item_key']) for r in reports}
catalog.write_text(json.dumps(reports+[r for r in old if (r['species'],r['item_key']) not in updated],ensure_ascii=False,indent=2),encoding='utf-8')
