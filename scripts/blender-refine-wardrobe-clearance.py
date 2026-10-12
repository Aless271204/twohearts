"""Raise embroidered patches on the editable cloth, preserving all patterns."""
import bpy,json,sys,hashlib,math
from pathlib import Path
from mathutils import Vector,Matrix
R=Path(__file__).resolve().parents[1];sys.path.insert(0,str(R/'scripts'))
from wardrobe_gltf import add_skin_attributes
C=Matrix.Rotation(math.pi/2,4,'X')
catalog_path=R/'assets/runner/blender-wardrobe-models.json'
catalog=json.loads(catalog_path.read_text(encoding='utf-8'))
blend=R/'design/blender/fitting/NIDO-patronaje-prendas.blend'
bpy.ops.wm.open_mainfile(filepath=str(blend))
for item in catalog:
 if item['item_key'] not in ('shirt_love','hoodie_nido'):continue
 for variant in item['variants']:
  species=variant['species'];col=bpy.data.collections[item['item_key']+' · '+species]
  if not col.get('embroidery_clearance_v2'):
   for o in col.objects:
    if o.type=='MESH' and o.name.startswith('Corazón bordado'):
     for v in o.data.vertices:v.co+=C@Vector((0,0,.010))
     o.data.update()
   col['embroidery_clearance_v2']=True
  col.hide_viewport=False;bpy.ops.object.select_all(action='DESELECT')
  for o in col.objects:o.hide_set(False);o.select_set(True)
  bpy.context.view_layer.objects.active=list(col.objects)[0]
  path=R/variant['path'];bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
  add_skin_attributes(path,json.loads((R/'design/blender/fitting'/f'{species}.json').read_text()))
  variant['sha256']=hashlib.sha256(path.read_bytes()).hexdigest();col.hide_viewport=True
  print('EMBROIDERY',item['item_key'],species,flush=True)
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(blend),compress=True)
catalog_path.write_text(json.dumps(catalog,ensure_ascii=False,indent=2),encoding='utf-8')
print('EMBROIDERY_READY',flush=True)
