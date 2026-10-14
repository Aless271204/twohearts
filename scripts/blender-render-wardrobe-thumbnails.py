"""Photograph the exact exported shop models; never substitute concept images."""
import bpy,json,hashlib,math,sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
catalog=json.loads((ROOT/'assets/runner/accessory-catalog.json').read_text(encoding='utf-8'))
models={i['item_key']:i for file in ('blender-wardrobe-models.json','blender-complement-models.json') for i in json.loads((ROOT/'assets/runner'/file).read_text(encoding='utf-8'))}
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
selected=next((v.split('=',1)[1].split(',') for v in args if v.startswith('items=')),None)
species=next((v.split('=',1)[1] for v in args if v.startswith('species=')),'penguin')
engine=next((v.split('=',1)[1] for v in args if v.startswith('engine=')),'cycles')
report_path=ROOT/'assets/images/products/wardrobe-thumbnails.json'
report=json.loads(report_path.read_text(encoding='utf-8')) if report_path.exists() else []
for item in catalog:
 model=models.get(item['item_key'])
 if not model or not item.get('visible',True) or (selected and item['item_key'] not in selected):continue
 appearance=item['appearance'];model_path=appearance.get('species_models',{}).get(species,appearance.get('model_asset'))
 if not model_path:continue
 source=ROOT/model_path;model_hash=appearance.get('species_model_hashes',{}).get(species)
 if hashlib.sha256(source.read_bytes()).hexdigest()!=model_hash:raise ValueError('Stale model '+str(source))
 bpy.ops.wm.read_factory_settings(use_empty=True);scene=bpy.context.scene
 bpy.ops.import_scene.gltf(filepath=str(source))
 objects=[o for o in scene.objects if o.type=='MESH']
 points=[o.matrix_world@Vector(p) for o in objects for p in o.bound_box]
 lo=Vector([min(p[k] for p in points) for k in range(3)]);hi=Vector([max(p[k] for p in points) for k in range(3)]);center=(lo+hi)/2;scale=.85/max(hi-lo)
 for o in objects:o.location=(o.location-center)*scale;o.scale*=scale
 # Photograph the real object on a warm studio floor. Contact shadows and
 # three-quarter framing reveal its thickness, folds and material relief.
 floor_z=(lo.z-center.z)*scale-.012
 bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,floor_z))
 floor=bpy.context.object;floor.name='Fondo de estudio'
 backdrop=bpy.data.materials.new('Blanco cálido');backdrop.use_nodes=True
 shader=backdrop.node_tree.nodes.get('Principled BSDF');shader.inputs['Base Color'].default_value=(.72,.62,.65,1);shader.inputs['Roughness'].default_value=.86
 floor.data.materials.append(backdrop)
 world=bpy.data.worlds.new('Estudio cálido');world.use_nodes=True;world.node_tree.nodes['Background'].inputs['Color'].default_value=(1,.96,.95,1);world.node_tree.nodes['Background'].inputs['Strength'].default_value=.35;scene.world=world
 for name,position,energy,size in [('Luz principal',(-2,-3,4),150,2.4),('Relleno',(4,-1,3),50,3.5),('Contorno',(-1,3,4),130,2.0)]:
  data=bpy.data.lights.new(name,'AREA');data.energy=energy;data.shape='DISK';data.size=size;light=bpy.data.objects.new(name,data);scene.collection.objects.link(light);light.location=position;light.rotation_euler=(-light.location).to_track_quat('-Z','Y').to_euler()
 camera_data=bpy.data.cameras.new('Fotografía del producto');camera_data.type='ORTHO';camera_data.ortho_scale=1.08
 camera=bpy.data.objects.new('Cámara',camera_data);scene.collection.objects.link(camera);camera.location=(2.7,-6,2.6);camera.rotation_euler=(-camera.location).to_track_quat('-Z','Y').to_euler();scene.camera=camera
 # CPU rendering leaves the mobile/WebGL inspection usable on integrated GPUs.
 if engine=='eevee':scene.render.engine='BLENDER_EEVEE_NEXT';scene.eevee.taa_render_samples=48
 else:scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24;scene.cycles.use_denoising=True;scene.cycles.max_bounces=6
 scene.render.resolution_x=512;scene.render.resolution_y=448;scene.render.resolution_percentage=100;scene.render.film_transparent=False
 scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA';scene.view_settings.view_transform='Standard'
 filename=item['equip_slot']+'-'+appearance['style']+'-'+appearance['color'].lstrip('#').lower()+'-'+species+'.png';destination=ROOT/'assets/images/products'/filename
 # Render to a sibling temporary file; UI/test readers may briefly hold the
 # previous image open on Windows. Swap only after Blender has finished.
 stage=destination.with_name(destination.stem+'.rendering.png')
 scene.render.filepath=str(stage);bpy.ops.render.render(write_still=True)
 import time
 for attempt in range(20):
  try:stage.replace(destination);break
  except PermissionError:
   if attempt==19:raise
   time.sleep(.15)
 report=[r for r in report if not(r['item_key']==item['item_key'] and r.get('species','penguin')==species)]
 report.append({'item_key':item['item_key'],'species':species,'model':model_path,'model_sha256':model_hash,'thumbnail':'assets/images/products/'+filename,'thumbnail_sha256':hashlib.sha256(destination.read_bytes()).hexdigest(),'render_style':'warm_studio_v2'})
 report_path.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
 print('THUMBNAIL',item['item_key'],flush=True)
report_path.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print('THUMBNAILS_READY',len(report),flush=True)
