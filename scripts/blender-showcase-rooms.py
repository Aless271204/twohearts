"""Persistent offline showroom images from the exact exported app furniture."""
import bpy,json,math,hashlib,sys
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[1]
records=json.loads((R/'design/room-themes-v2/models/manifest.json').read_text(encoding='utf-8'))
out=R/'design/store-showcases';out.mkdir(exist_ok=True)
positions={'bed':[-.98,0,-.78],'chair':[.98,0,-1.05],'desk':[1.23,0,.25],'dresser':[.88,0,-2.06],'plant':[-1.35,0,-1.75],'lamp':[1.58,0,-1.5],'frame':[.9,1.63,-2.33],'shelf':[.9,1.17,-2.23],'rug':[0,0,.05],'curtain':[-.92,1.83,-2.30],'chest':[-1.6,0,.65],'toy':[1.65,0,.85],'special_one':[-1.65,0,-.65],'special_two':[1.65,0,-.65],'wall':[0,0,0],'floor':[0,0,0],'pendant':[0,2.6,-1]}
for theme in dict.fromkeys(r['theme'] for r in records):
 if any(a.startswith('only=') for a in sys.argv) and theme!=next(a.split('=',1)[1] for a in sys.argv if a.startswith('only=')):continue
 group=[r for r in records if r['theme']==theme];key='room_set_'+theme
 signature=hashlib.sha256(json.dumps({'sources':[r['sha256'] for r in group],'layout':positions,'render':2},sort_keys=True).encode()).hexdigest()
 receipt=out/(key+'.json');png=out/(key+'.png')
 if receipt.exists() and png.exists() and json.loads(receipt.read_text()).get('signature')==signature:continue
 bpy.ops.wm.read_factory_settings(use_empty=True);scene=bpy.context.scene
 for item in group:
  before=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=str(R/item['glb']))
  x,y,z=positions[item['part']]
  for o in set(bpy.data.objects)-before:
   if o.parent not in set(bpy.data.objects)-before:o.location+=Vector((x,-z,y))
 world=bpy.data.worlds.new('Estudio cálido');world.use_nodes=True;world.node_tree.nodes['Background'].inputs['Color'].default_value=(.95,.88,.81,1);world.node_tree.nodes['Background'].inputs['Strength'].default_value=.65;scene.world=world
 mat=bpy.data.materials.new('Fondo crema');mat.diffuse_color=(.94,.88,.82,1)
 bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.045));bpy.context.object.data.materials.append(mat)
 target=Vector((0,.15,1.15))
 for name,pos,power,size in [('Principal',(-3,-4,7),650,5),('Relleno',(4,-2,5),420,4),('Ventana',(-1,3,4),350,3)]:
  l=bpy.data.lights.new(name,'AREA');l.energy=power;l.size=size;o=bpy.data.objects.new(name,l);scene.collection.objects.link(o);o.location=pos;o.rotation_euler=(target-o.location).to_track_quat('-Z','Y').to_euler()
 c=bpy.data.cameras.new('Habitación completa');c.type='ORTHO';c.ortho_scale=6.3;cam=bpy.data.objects.new('Habitación completa',c);scene.collection.objects.link(cam);cam.location=(.7,-8,5.2);cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();scene.camera=cam
 scene.render.engine='CYCLES';scene.cycles.samples=8;scene.cycles.use_denoising=True
 scene.render.resolution_x=768;scene.render.resolution_y=576;scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='AgX';scene.render.filepath=str(png)
 bpy.ops.wm.save_as_mainfile(filepath=str(out/(key+'.blend')),compress=True);bpy.ops.render.render(write_still=True)
 receipt.write_text(json.dumps({'signature':signature,'theme':theme,'pieces':len(group),'source':'actual app geometry; offline Blender render','png':str(png.relative_to(R))},indent=2))
 print('SHOWCASE_COMPLETE',key,flush=True)
