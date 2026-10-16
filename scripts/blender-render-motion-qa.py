import bpy,json,sys,math,struct,re
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
args=sys.argv[sys.argv.index('--')+1:];source=ROOT/args[0];angle=float(args[1]) if len(args)>1 else 40
info=json.loads(source.read_text(encoding='utf-8'));bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene;materials={}
for asset in sorted({m['source'] for actor in info['actors'] for m in actor['meshes']}):
 path=ROOT/asset;raw=path.read_bytes();doc=json.loads(raw[20:20+struct.unpack_from('<I',raw,12)[0]])
 old=set(bpy.data.materials);before=set(scene.objects);bpy.ops.import_scene.gltf(filepath=str(path))
 added=set(bpy.data.materials)-old
 for i,mat in enumerate(doc.get('materials',[])):
  name=mat.get('name','Material_'+str(i));matches=[m for m in added if m.name==name or m.name.startswith(name+'.')]
  if not matches:matches=[m for m in bpy.data.materials if m.name==name]
  if matches:materials[(asset,i)]=matches[0]
 for obj in set(scene.objects)-before:bpy.data.objects.remove(obj,do_unlink=True)
for ai,actor in enumerate(info['actors']):
 parent=bpy.data.objects.new(actor['species'],None);scene.collection.objects.link(parent);parent.location.x=(ai-1.5)*1.24;parent.rotation_euler.z=math.radians(angle)
 for data in actor['meshes']:
  p=data['positions'];verts=[(p[i],-p[i+2],p[i+1]) for i in range(0,len(p),3)];ids=data['indices'];faces=[ids[i:i+3] for i in range(0,len(ids),3)]
  mesh=bpy.data.meshes.new(data['name']);mesh.from_pydata(verts,[],faces);mesh.update();obj=bpy.data.objects.new(data['name'],mesh);scene.collection.objects.link(obj);obj.parent=parent
  if data['uv']:
   uv=mesh.uv_layers.new(name='UVMap')
   for poly in mesh.polygons:
    poly.use_smooth=True
    for li in poly.loop_indices:
     vi=mesh.loops[li].vertex_index;uv.data[li].uv=(data['uv'][vi*2],1-data['uv'][vi*2+1])
  mat=materials.get((data['source'],data['material']))
  if mat:mesh.materials.append(mat)
world=bpy.data.worlds.new('Warm Studio');world.use_nodes=True;world.node_tree.nodes['Background'].inputs['Color'].default_value=(1,.96,.97,1);world.node_tree.nodes['Background'].inputs['Strength'].default_value=.45;scene.world=world
floor_mat=bpy.data.materials.new('Rosa claro');floor_mat.diffuse_color=(.95,.87,.88,1)
bpy.ops.mesh.primitive_plane_add(size=200);bpy.context.object.data.materials.append(floor_mat)
for name,pos,power,size in [('Key',(-3,-4,5),550,5),('Fill',(4,-1,3),200,4),('Rim',(0,3,4),450,4)]:
 data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size;obj=bpy.data.objects.new(name,data);scene.collection.objects.link(obj);obj.location=pos;obj.rotation_euler=(-obj.location).to_track_quat('-Z','Y').to_euler()
c=bpy.data.cameras.new('QA Camera');c.type='ORTHO';c.ortho_scale=5.6;camera=bpy.data.objects.new('QA Camera',c);scene.collection.objects.link(camera);camera.location=(0,-8,2.8);target=Vector((0,0,.65));camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler();scene.camera=camera
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=4;scene.cycles.use_denoising=True;scene.render.resolution_x=1600;scene.render.resolution_y=650;scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='AgX'
target=source.with_name(source.stem+'-'+str(int(angle))+'.png');scene.render.filepath=str(target);bpy.ops.render.render(write_still=True);print('POSE_RENDER',target,flush=True)
