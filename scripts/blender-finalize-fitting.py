"""Verify and open the editable workshop on the fitted penguin cap."""
import bpy,json
from pathlib import Path
from mathutils import Vector
repo=Path(__file__).resolve().parents[1];directory=repo/'design/blender/fitting'
report=json.loads((directory/'tailoring-report.json').read_text(encoding='utf-8'))
scene=bpy.context.scene
bpy.data.collections['00 · Originales conservados'].hide_viewport=True
work=bpy.data.collections['01 · Veinte combinaciones']
for collection in work.children:
    collection.hide_viewport=collection.name not in ('penguin · mascota de la app','cap_pink · penguin')
    for obj in collection.objects:obj.hide_render=collection.hide_viewport or obj.name.startswith('Cráneo')
for entry in report:
    collection=bpy.data.collections[entry['item_key']+' · '+entry['species']]
    collection['item_key']=entry['item_key'];collection['species']=entry['species'];collection['export_file']=entry['path'];collection['review_status']='browser_preview'
    assert any(o.type=='MESH' and len(o.data.polygons)>0 for o in collection.objects)
    for obj in collection.objects:
        assert obj.type=='MESH'
        assert not obj.data.validate(clean_customdata=False),'Geometry repair needed: '+collection.name
images=[i for i in bpy.data.images if i.source=='FILE']
assert all(i.packed_file or i.packed_files for i in images)
scene.camera.location=(0,-3,1.37);scene.camera.rotation_euler=(Vector((0,0,.72))-scene.camera.location).to_track_quat('-Z','Y').to_euler()
selected=bpy.data.collections['cap_pink · penguin'].objects[0]
bpy.ops.object.select_all(action='DESELECT');selected.hide_set(False);selected.select_set(True);bpy.context.view_layer.objects.active=selected
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.shading.type='MATERIAL'
            region=area.spaces.active.region_3d;region.view_location=(0,0,.72);region.view_distance=2.4;region.view_rotation=scene.camera.rotation_euler.to_quaternion();region.view_perspective='ORTHO'
scene['fit_catalog']='assets/runner/blender-head-models.json'
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath,compress=True)
print('NIDO_FIT_WORKSHOP_VERIFIED',len(report),'combinations',len(images),'packed images')
