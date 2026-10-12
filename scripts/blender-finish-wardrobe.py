"""Apply the final embroidery clearance and rounded visor to editable patterns."""
import bpy,json,importlib.util,hashlib,math
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('patterns',R/'scripts/blender-build-wardrobe.py');B=importlib.util.module_from_spec(spec);spec.loader.exec_module(B)
from wardrobe_gltf import add_skin_attributes
catalog=json.loads((R/'assets/runner/blender-wardrobe-models.json').read_text(encoding='utf-8'))
blend=R/'design/blender/fitting/NIDO-patronaje-prendas.blend';bpy.ops.wm.open_mainfile(filepath=str(blend))
for item in catalog:
 for variant in item['variants']:
  species=variant['species'];col=bpy.data.collections[item['item_key']+' · '+species];col.hide_viewport=False
  if not (col.get('embroidery_clearance_v1') and col.get('visor_curve_v1')):
   for o in col.objects:
    if o.type!='MESH':continue
    if not (col.get('embroidery_clearance_v1') or col.get('finish_clearance_v1')) and o.name.startswith(('Corazón bordado','Flor bordada')) and item['equip_slot']=='pet_body':
     delta=B.C@Vector((0,0,.008 if o.name.startswith('Corazón') else .005))
     for v in o.data.vertices:v.co+=delta
    if not (col.get('visor_curve_v1') or col.get('finish_clearance_v1')) and o.name.startswith('Visera curva'):
     points=[B.CI@v.co for v in o.data.vertices];maximum=max(abs(p.x) for p in points)
     for v,p in zip(o.data.vertices,points):p.y-=.022*(abs(p.x)/maximum)**2;v.co=B.C@p
    o.data.update()
   col['finish_clearance_v1']=True
   col['embroidery_clearance_v1']=True
   col['visor_curve_v1']=True
  bpy.ops.object.select_all(action='DESELECT')
  for o in col.objects:o.hide_set(False);o.select_set(True)
  bpy.context.view_layer.objects.active=list(col.objects)[0]
  path=R/variant['path'];bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
  if item['equip_slot']=='pet_body':add_skin_attributes(path,json.loads((B.D/(species+'.json')).read_text()))
  variant['sha256']=hashlib.sha256(path.read_bytes()).hexdigest()
  col.hide_viewport=True
  print('FINISHED',item['item_key'],species,flush=True)
bpy.data.collections['shirt_love · penguin'].hide_viewport=False
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(blend),compress=True)
(R/'assets/runner/blender-wardrobe-models.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2),encoding='utf-8')
print('FINISH_READY',flush=True)
