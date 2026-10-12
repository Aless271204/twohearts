"""Reopen verification and cleanup of importer-created bone control shapes."""
import bpy, json, math, hashlib
from pathlib import Path
from mathutils import Vector
repo=Path(__file__).resolve().parents[1];directory=repo/'design'/'blender'
manifest=json.loads((directory/'library.json').read_text(encoding='utf-8'))
results=[]
for item in manifest['items']:
    collection=next(c for c in bpy.data.collections if c.get('item_key')==item['id'])
    if item.get('path'):
        assert hashlib.sha256((repo/item['path']).read_bytes()).hexdigest()==item['sha256']
    controls={bone.custom_shape for obj in collection.all_objects if obj.type=='ARMATURE' for bone in obj.pose.bones if bone.custom_shape}
    for control in controls:control['rig_control_shape']=True;control.hide_render=True;control.hide_set(True)
    meshes=[obj for obj in collection.all_objects if obj.type=='MESH' and obj not in controls]
    assert meshes,'No mesh: '+item['id']
    for obj in meshes:
        assert all(math.isfinite(v) for vertex in obj.data.vertices for v in vertex.co)
    results.append({'id':item['id'],'meshes':len(meshes),'materials':sum(len(o.data.materials) for o in meshes),'source_unchanged':bool(item.get('path'))})
    if item['category']=='pets':
        root=bpy.data.objects[item['id']+'_EDIT_ROOT'];root.location=(0,0,0);root.scale=(1,1,1);bpy.context.view_layer.update()
        points=[o.matrix_world@Vector(v) for o in meshes for v in o.bound_box]
        low=Vector(tuple(min(v[i] for v in points) for i in range(3)));high=Vector(tuple(max(v[i] for v in points) for i in range(3)))
        factor=1.15/(high.z-low.z);center=(low+high)*.5
        index=['penguin','bear','pig','chick'].index(item['id'])
        root.scale=(factor,)*3;root.location=Vector((index*1.7,0,0))-Vector((center.x,center.y,low.z))*factor
for c in bpy.data.collections:
    if c.name.startswith('02 ·'):c.hide_render=True
images=[i for i in bpy.data.images if i.source=='FILE']
assert all(i.packed_file or i.packed_files for i in images),'External texture found'
assert sum(o.type=='ARMATURE' for o in bpy.data.objects)>=4
assert len(results)==66
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath,compress=True)
(directory/'verification.json').write_text(json.dumps({'blender':bpy.app.version_string,'items':len(results),'packed_texture_images':len(images),'animation_actions':len(bpy.data.actions),'original_hashes_verified':True,'results':results},ensure_ascii=False,indent=2),encoding='utf-8')
bpy.context.scene.render.filepath=str(directory/'biblioteca-preview.png')
bpy.ops.render.render(write_still=True)
print('NIDO_VERIFIED',len(results),len(images),len(bpy.data.actions))
