"""Original-pet neck and eyewear fitting; no legacy mannequin or pet export."""
import ast, importlib.util, json, math, sys, hashlib
from pathlib import Path
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts'))
from wardrobe_gltf import add_skin_attributes
spec=importlib.util.spec_from_file_location('pattern_tools',ROOT/'scripts/blender-build-wardrobe.py')
B=importlib.util.module_from_spec(spec);spec.loader.exec_module(B)
source=(ROOT/'scripts/blender-build-complements.py').read_text(encoding='utf-8')
functions=[n for n in ast.parse(source).body if isinstance(n,ast.FunctionDef) and n.name in ('material','ring','badge','bow','skin_tree','frontal','eyes','neck')]
fits=json.loads((ROOT/'design/wardrobe-restart/sewn-species-fit.json').read_text(encoding='utf-8'))['species']
ns={'B':B,'bpy':bpy,'math':math,'Vector':Vector,'BVHTree':BVHTree,'materials':{},'fabric':'cotton',
 'cream':'#FFF2DF','pink':'#F05280','gold':'#E2B957','textile':B.material,'fits':fits}
pattern='\n\n'.join(ast.get_source_segment(source,n) for n in functions)
pattern=pattern.replace("y=hi[1]+B.config['species_fit'][sp].get('neck_extension',.010)-(.040 if sp=='penguin' else .025)","y=fits[sp]['collar_top']-.018")
pattern=pattern.replace('r=rx*.27','r=rx*.30')
pattern=pattern.replace(".006 if key=='glasses_round' else .012",".006 if key=='glasses_round' else .014")
exec(compile(pattern,__file__,'exec'),ns);B.material=ns['material']
items=[i for i in json.loads((ROOT/'assets/runner/accessory-catalog.json').read_text(encoding='utf-8')) if i['equip_slot'] in ('pet_eyes','pet_neck') and i['item_key']!='bow_neck' and i.get('visible',True)]
species=['penguin','bear','pig','chick']
if '--species' in sys.argv:species=[sys.argv[sys.argv.index('--species')+1]]
reports=[]
for sp in species:
 data=json.loads((ROOT/f'design/wardrobe-restart/fitting/{sp}-original.json').read_text(encoding='utf-8'));tree=ns['skin_tree'](data)
 for item in items:
  key=item['item_key'];col=bpy.data.collections.new(key+' · '+sp);B.scene.collection.children.link(col)
  ns['eyes' if item['equip_slot']=='pet_eyes' else 'neck'](item,sp,col,data,tree)
  bpy.ops.object.select_all(action='DESELECT')
  for o in col.objects:o.select_set(True)
  bpy.context.view_layer.objects.active=list(col.objects)[0];bpy.ops.object.convert(target='MESH');bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
  for o in col.objects:o.data.name=o.name
  path=ROOT/f'assets/runner/accessories/restart_{key}_{sp}.glb';stage=path.with_suffix('.building.glb')
  bpy.ops.export_scene.gltf(filepath=str(stage),export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
  if item['equip_slot']=='pet_neck':
   data['rigid_garment_bone']='Neck';add_skin_attributes(stage,data)
  stage.replace(path)
  reports.append({'item_key':key,'species':sp,'asset':path.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'skinned_model_space':item['equip_slot']=='pet_neck'})
  col.hide_viewport=True
  for o in col.objects:o.hide_render=True
  print('ACCESSORY_EXPORTED',sp,key,flush=True)
B.save_editable_master(ROOT/'design/wardrobe-restart/models/CUELLO-OJOS-ORIGINAL.blend')
catalog=ROOT/'assets/runner/restart/details-catalog.json';old=json.loads(catalog.read_text(encoding='utf-8'))
updated={(r['species'],r['item_key']) for r in reports}
catalog.write_text(json.dumps(reports+[r for r in old if (r['species'],r['item_key']) not in updated],ensure_ascii=False,indent=2),encoding='utf-8')
print('ACCESSORIES_READY',flush=True)
