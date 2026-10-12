"""Export one editable collection to staging, never directly to the app.
blender NIDO-biblioteca.blend -b --python scripts/blender-export.py -- --item meshy_cap_pink
"""
import bpy, sys, argparse, json
from pathlib import Path
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
parser=argparse.ArgumentParser();parser.add_argument('--item',required=True)
options=parser.parse_args(args)
repo=Path(__file__).resolve().parents[1]
matches=[c for c in bpy.data.collections if c.get('item_key')==options.item]
if len(matches)!=1:raise RuntimeError('Código de inventario inexistente o duplicado: '+options.item)
collection=matches[0]
# Temporarily expose excluded collections so selection is exportable.
def reveal(layer):
    layer.exclude=False;layer.hide_viewport=False
    for child in layer.children:reveal(child)
reveal(bpy.context.view_layer.layer_collection)
bpy.ops.object.select_all(action='DESELECT')
for obj in collection.all_objects:
    if obj.get('rig_control_shape'):continue
    obj.hide_set(False);obj.hide_viewport=False;obj.select_set(True)
root=bpy.data.objects.get(options.item+'_EDIT_ROOT')
if root:root.location=(0,0,0)
output=repo/'design'/'blender'/'exports';output.mkdir(parents=True,exist_ok=True)
path=output/(options.item+'.glb')
if path.exists():raise RuntimeError('La exportación ya existe; renómbrala antes de continuar: '+str(path))
bpy.context.view_layer.update()
bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=True,export_yup=True)
(output/(options.item+'.json')).write_text(json.dumps({'item_key':options.item,'source_blend':bpy.data.filepath,'source_asset':collection.get('source_asset'),'fit_approved':bool(root and root.get('fit_approved',False)),'status':'staging_only'},indent=2),encoding='utf-8')
print('NIDO_STAGING_EXPORT',path)
