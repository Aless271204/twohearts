"""Build an editable source library. Run with Blender --background --python.
Rebuilding creates a NEW base library; never overwrites manual work.
"""
import bpy, json, sys, math, hashlib
from pathlib import Path
from mathutils import Matrix, Vector

REPO = Path(__file__).resolve().parents[1]
DIR = REPO / 'design' / 'blender'
manifest = json.loads((DIR / 'library.json').read_text(encoding='utf-8'))
destination = DIR / 'NIDO-biblioteca.blend'
if destination.exists():
    raise RuntimeError('La biblioteca ya existe. Guarda tus cambios y elige otro destino antes de reconstruir.')
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.name = 'NIDO · Taller 3D'
scene.unit_settings.system = 'METRIC'
scene['project_root'] = str(REPO)
scene['fit_status'] = 'Imported sources; visual fitting pending'
scene['axes'] = 'Blender Z up; GLB export converts to app Y up'
categories = {}
for key, label in [('pets','01 · Mascotas'),('meshy_heads','02 · Cabeza Meshy originales'),('accessories','03 · Prendas catálogo previo'),('room','04 · Objetos habitación'),('room_scene','05 · Habitación base'),('landscape','06 · Paisaje')]:
    col=bpy.data.collections.new(label);scene.collection.children.link(col);categories[key]=col

def bounds(objects):
    points=[o.matrix_world @ Vector(v) for o in objects if o.type=='MESH' and not o.get('rig_control_shape') for v in o.bound_box]
    if not points:return Vector((0,0,0)),Vector((1,1,1))
    return Vector(tuple(min(v[i] for v in points) for i in range(3))),Vector(tuple(max(v[i] for v in points) for i in range(3)))

report=[]
counts={}
for item in manifest['items']:
    category=item['category'];index=counts.get(category,0);counts[category]=index+1
    collection=bpy.data.collections.new(item['id']+' · '+item['name']);categories[category].children.link(collection)
    collection['item_key']=item['id'];collection['source_status']=item['status']
    if 'path' in item:
        source=REPO/item['path']
        if hashlib.sha256(source.read_bytes()).hexdigest()!=item['sha256']:raise RuntimeError('Origen modificado: '+str(source))
        before=set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=str(source),import_pack_images=True)
        objects=list(set(bpy.data.objects)-before)
        controls={bone.custom_shape for obj in objects if obj.type=='ARMATURE' for bone in obj.pose.bones if bone.custom_shape}
        for control in controls:
            control['rig_control_shape']=True;control.hide_render=True;control.hide_set(True)
        collection['source_asset']=item['path'];collection['source_sha256']=item['sha256']
        for obj in objects:
            for col in list(obj.users_collection):col.objects.unlink(obj)
            collection.objects.link(obj)
        # Preserve imported animation clips; the workshop starts in neutral rest.
        for obj in objects:
            if obj.animation_data and obj.animation_data.action:
                obj.animation_data.action.use_fake_user=True
                obj.animation_data.action=None
            if obj.animation_data:
                for track in obj.animation_data.nla_tracks:track.mute=True
    else:
        objects=[]
        conversion=Matrix.Rotation(math.pi/2,4,'X')
        for part_index,part in enumerate(item['meshes']):
            mesh=bpy.data.meshes.new(item['id']+'_'+str(part_index))
            vertices=[part['positions'][i:i+3] for i in range(0,len(part['positions']),3)]
            faces=[part['indices'][i:i+3] for i in range(0,len(part['indices']),3)]
            mesh.from_pydata(vertices,[],faces);mesh.update()
            if part['uv']:
                uv=mesh.uv_layers.new(name='UVMap')
                for loop in mesh.loops:uv.data[loop.index].uv=part['uv'][loop.vertex_index*2:loop.vertex_index*2+2]
            if part['normals']:
                mesh.normals_split_custom_set_from_vertices([part['normals'][i:i+3] for i in range(0,len(part['normals']),3)])
                for poly in mesh.polygons:poly.use_smooth=True
            mat=bpy.data.materials.new(item['id']+'_material_'+str(part_index));mat.use_nodes=True
            shader=mat.node_tree.nodes.get('Principled BSDF');shader.inputs['Base Color'].default_value=(*part['material']['color'],1)
            shader.inputs['Roughness'].default_value=part['material']['roughness'];shader.inputs['Metallic'].default_value=part['material']['metalness']
            mesh.materials.append(mat)
            obj=bpy.data.objects.new(mesh.name,mesh);collection.objects.link(obj)
            m=part['matrix'];obj.matrix_world=conversion @ Matrix([m[i::4] for i in range(4)])
            objects.append(obj)
    bpy.context.view_layer.update()
    root=bpy.data.objects.new(item['id']+'_EDIT_ROOT',None);collection.objects.link(root)
    root['item_key']=item['id'];root['fit_approved']=False
    for obj in objects:
        if obj.parent not in objects:
            matrix=obj.matrix_world.copy();obj.parent=root;obj.matrix_world=matrix
    low,high=bounds(objects);size=high-low
    desired=1.15 if category=='pets' else .7 if category in ('meshy_heads','accessories') else 2.2 if category=='landscape' else 1
    factor=desired/max(size.z,1e-5) if category=='pets' else desired/max(*size,1e-5) if category in ('meshy_heads','accessories','landscape') else 1
    root.scale=(factor,)*3
    center=(low+high)*.5
    origin=Vector((center.x,center.y,low.z))*factor
    base={'pets':(0,0,0),'meshy_heads':(0,3,0),'accessories':(0,6,0),'room':(0,12,0),'room_scene':(0,28,0),'landscape':(0,34,0)}[category]
    spacing=1.7 if category in ('pets','meshy_heads','accessories') else 5
    root.location=Vector((base[0]+(index%5)*spacing,base[1]+(index//5)*spacing,base[2]))-origin
    report.append({'id':item['id'],'category':category,'objects':len(objects),'meshes':sum(o.type=='MESH' for o in objects),'armatures':sum(o.type=='ARMATURE' for o in objects),'source':item.get('path','app geometry factory')})
    print('IMPORTED',item['id'],flush=True)

# Keep materials embedded so the blend file opens without external textures.
for action in bpy.data.actions:action.use_fake_user=True
bpy.ops.file.pack_all()
world=bpy.data.worlds.new('Luz cálida');scene.world=world;world.use_nodes=True
world.node_tree.nodes.get('Background').inputs[0].default_value=(.85,.78,.79,1)
world.node_tree.nodes.get('Background').inputs[1].default_value=.65
categories['meshy_heads'].hide_render=True
for name,location,energy,size in [('Key',(-3,-4,7),1000,5),('Fill',(7,-1,5),700,4)]:
    data=bpy.data.lights.new(name,'AREA');data.energy=energy;data.shape='DISK';data.size=size
    obj=bpy.data.objects.new(name,data);scene.collection.objects.link(obj);obj.location=location
    obj.rotation_euler=(Vector((2.5,0,.7))-obj.location).to_track_quat('-Z','Y').to_euler()
cam_data=bpy.data.cameras.new('Camera');cam=bpy.data.objects.new('Camera',cam_data);scene.collection.objects.link(cam)
cam.location=(2.55,-8,3.2);cam.rotation_euler=(Vector((2.55,0,.65))-cam.location).to_track_quat('-Z','Y').to_euler();cam_data.type='ORTHO';cam_data.ortho_scale=7.1;scene.camera=cam
scene.render.engine='BLENDER_EEVEE_NEXT';scene.render.resolution_x=1200;scene.render.resolution_y=600;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.film_transparent=False
scene.view_settings.view_transform='AgX'
for key in ['accessories','room','room_scene','landscape']:
    layer=scene.view_layers[0].layer_collection.children[categories[key].name];layer.exclude=True
bpy.ops.object.select_all(action='DESELECT')
pet_root=bpy.data.objects.get('penguin_EDIT_ROOT');pet_root.select_set(True);bpy.context.view_layer.objects.active=pet_root
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.shading.type='MATERIAL'
            area.spaces.active.region_3d.view_distance=8
            area.spaces.active.region_3d.view_location=(3,0,.7)
text=bpy.data.texts.new('LEEME · NIDO');text.write('Biblioteca editable de NIDO.\nColecciones 01: mascotas; 02: tus cinco GLB Meshy; 03: catálogo previo; 04: muebles; 05: habitación; 06: paisaje.\nActiva colecciones en el Outliner para verlas. Los originales no se modifican.\nEste archivo prepara el trabajo: aún no certifica el encaje de prendas.\nGuarda las adaptaciones con otro nombre antes de exportar. Exportaciones siempre a design/blender/exports, nunca a assets directamente.\n')
bpy.ops.wm.save_as_mainfile(filepath=str(destination),compress=True)
(DIR/'import-report.json').write_text(json.dumps({'blender':bpy.app.version_string,'items':report,'packed_images':len(bpy.data.images),'actions':len(bpy.data.actions),'fit_approved':False},ensure_ascii=False,indent=2),encoding='utf-8')
scene.render.filepath=str(DIR/'biblioteca-preview.png')
bpy.ops.render.render(write_still=True)
print('NIDO_PROJECT_READY',destination,flush=True)
