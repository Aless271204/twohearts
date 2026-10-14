"""Assemble the 20 current shoe variants as separate editable collections."""
import bpy,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
rows=json.loads((ROOT/'assets/runner/accessory-catalog.json').read_text(encoding='utf-8'))
for item in rows:
 if item['equip_slot']!='pet_feet' or item.get('visible',True) is False:continue
 for species,path in item['appearance']['species_models'].items():
  before=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=str(ROOT/path))
  col=bpy.data.collections.new(item['item_key']+' · '+species);bpy.context.scene.collection.children.link(col)
  for o in set(bpy.data.objects)-before:
   for owner in list(o.users_collection):owner.objects.unlink(o)
   col.objects.link(o)
  col.hide_render=True;col.hide_viewport=True
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'design/wardrobe-restart/models/CALZADO-COMPLETO-4-MASCOTAS.blend'),compress=True)
