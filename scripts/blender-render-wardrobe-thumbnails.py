"""Photograph the exact exported shop models; never substitute concept images."""
import bpy,json,hashlib,math,sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
catalog=json.loads((ROOT/'assets/runner/accessory-catalog.json').read_text(encoding='utf-8'))
models={i['item_key']:i for file in ('blender-wardrobe-models.json','blender-complement-models.json') for i in json.loads((ROOT/'assets/runner'/file).read_text(encoding='utf-8'))}
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
selected=next((v.split('=',1)[1].split(',') for v in args if v.startswith('items=')),None)
report_path=ROOT/'assets/images/products/wardrobe-thumbnails.json'
report=json.loads(report_path.read_text(encoding='utf-8')) if selected and report_path.exists() else []
for item in catalog:
 model=models.get(item['item_key'])
 if not model or not item.get('visible',True) or (selected and item['item_key'] not in selected):continue
 variant=next(v for v in model['variants'] if v['species']=='penguin');source=ROOT/variant['path']
 if hashlib.sha256(source.read_bytes()).hexdigest()!=variant['sha256']:raise ValueError('Stale model '+str(source))
 bpy.ops.wm.read_factory_settings(use_empty=True);scene=bpy.context.scene
 bpy.ops.import_scene.gltf(filepath=str(source))
 objects=[o for o in scene.objects if o.type=='MESH']
 points=[o.matrix_world@Vector(p) for o in objects for p in o.bound_box]
 lo=Vector([min(p[k] for p in points) for k in range(3)]);hi=Vector([max(p[k] for p in points) for k in range(3)]);center=(lo+hi)/2;scale=.85/max(hi-lo)
 for o in objects:o.location=(o.location-center)*scale;o.scale*=scale
 world=bpy.data.worlds.new('Estudio cálido');world.use_nodes=True;world.node_tree.nodes['Background'].inputs['Color'].default_value=(1,.96,.95,1);world.node_tree.nodes['Background'].inputs['Strength'].default_value=.35;scene.world=world
 for name,position,energy,size in [('Luz principal',(-3,-4,5),180,4),('Relleno',(4,-1,3),70,4),('Contorno',(-1,3,4),110,3)]:
  data=bpy.data.lights.new(name,'AREA');data.energy=energy;data.shape='DISK';data.size=size;light=bpy.data.objects.new(name,data);scene.collection.objects.link(light);light.location=position;light.rotation_euler=(-light.location).to_track_quat('-Z','Y').to_euler()
 camera_data=bpy.data.cameras.new('Fotografía del producto');camera_data.type='ORTHO';camera_data.ortho_scale=1.20
 camera=bpy.data.objects.new('Cámara',camera_data);scene.collection.objects.link(camera);camera.location=(2.1,-6,2.5);camera.rotation_euler=(-camera.location).to_track_quat('-Z','Y').to_euler();scene.camera=camera
 # CPU rendering leaves the mobile/WebGL inspection usable on integrated GPUs.
 scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=32;scene.cycles.use_denoising=True;scene.cycles.max_bounces=6
 scene.render.resolution_x=512;scene.render.resolution_y=448;scene.render.resolution_percentage=100;scene.render.film_transparent=True
 scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA';scene.view_settings.view_transform='Standard'
 appearance=item['appearance'];filename=item['equip_slot']+'-'+appearance['style']+'-'+appearance['color'].lstrip('#').lower()+'.png';destination=ROOT/'assets/images/products'/filename
 scene.render.filepath=str(destination);bpy.ops.render.render(write_still=True)
 report=[r for r in report if r['item_key']!=item['item_key']]
 report.append({'item_key':item['item_key'],'model':variant['path'],'model_sha256':variant['sha256'],'thumbnail':'assets/images/products/'+filename,'thumbnail_sha256':hashlib.sha256(destination.read_bytes()).hexdigest()})
 report_path.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
 print('THUMBNAIL',item['item_key'],flush=True)
report_path.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print('THUMBNAILS_READY',len(report),flush=True)
