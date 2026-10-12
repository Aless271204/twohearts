"""Replace only the approved working penguin cap in the shared editable workshop."""
import bpy
from pathlib import Path
r=Path(__file__).resolve().parents[1];d=r/'design/blender/fitting'
bpy.ops.wm.open_mainfile(filepath=str(d/'NIDO-cabeza-encaje.blend'))
key='cap_pink · penguin';col=bpy.data.collections.get(key)
if col:
 for o in list(col.objects):bpy.data.objects.remove(o,do_unlink=True)
 bpy.data.collections.remove(col)
with bpy.data.libraries.load(str(d/'NIDO-gorra-pinguino.blend'),link=False) as (source,target):target.collections=[key]
for col in target.collections:
 bpy.data.collections['01 · Veinte combinaciones'].children.link(col);col.hide_viewport=False
 for o in col.objects:o.hide_render=False;o.hide_set(False)
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(d/'NIDO-cabeza-encaje.blend'),compress=True)
print('PENGUIN_CAP_WORKSHOP_UPDATED')
