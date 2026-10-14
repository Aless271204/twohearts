"""Footwear fitted to the immutable source pets, in the isolated review catalog.

Shares the editable accessory motifs, but measures only the original rest-pose
captures and uses flat soles with anatomical clearance, never old mannequins.
"""
import ast, importlib.util, json, math, sys, hashlib
from pathlib import Path
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from wardrobe_gltf import add_skin_attributes
spec=importlib.util.spec_from_file_location('pattern_tools',ROOT/'scripts/blender-build-wardrobe.py')
B=importlib.util.module_from_spec(spec);spec.loader.exec_module(B)
source=(ROOT/'scripts/blender-build-complements.py').read_text(encoding='utf-8')
# Reuse the motif functions, without executing their legacy scene/export loop.
functions=[n for n in ast.parse(source).body if isinstance(n,ast.FunctionDef) and n.name in ('material','ring','badge','footwear')]
ns={'B':B,'bpy':bpy,'math':math,'Vector':Vector,'BVHTree':BVHTree,'materials':{},'fabric':'cotton',
    'cream':'#FFF2DF','pink':'#F05280','gold':'#E2B957','textile':B.material}
pattern='\n\n'.join(ast.get_source_segment(source,n) for n in functions)
pattern=pattern.replace("rx=(hi[0]-lo[0])*.57;rz=(hi[2]-lo[2])*.62;floor=lo[1]-.007;top=hi[1]+.023",
    "rx=(hi[0]-lo[0])*.5+.006;rz=(hi[2]-lo[2])*.5+.010;floor=0.002;top=hi[1]+.020")
pattern=pattern.replace('high=top+.092 if boot else top+.025','high=top+.060 if boot else top+.018')
pattern=pattern.replace("upper=B.mesh('Empeine envolvente',pts,faces,col,color);B.solid(upper,.010 if key=='slippers_cloud' else .005)",
"""upper=B.mesh('Empeine envolvente',pts,faces,col,color);B.solid(upper,.010 if key=='slippers_cloud' else .005)
   shoe_surface=BVHTree.FromPolygons([B.CI@v.co for v in upper.data.vertices],[list(f.vertices) for f in upper.data.polygons])
   def shoe_front(p):
    hit,_,_,_=shoe_surface.ray_cast(Vector((p[0],p[1],cz+rz+.3)),Vector((0,0,-1)),1)
    return (p[0],p[1],hit.z+.006) if hit is not None else p
   def shoe_top(p):
    hit,_,_,_=shoe_surface.ray_cast(Vector((p[0],high+.3,p[2])),Vector((0,-1,0)),1)
    return (p[0],hit.y+.008 if hit is not None else high-.008,p[2])""")
pattern=pattern.replace("badge('heart',(cx,high-.033,front*.53),.038,col,cream)","badge('heart',(cx,high-.033,front*.53),.032,col,cream,shoe_front)")
pattern=pattern.replace("badge('heart',(cx,floor+.045,front),.031,col,cream)","badge('heart',(cx,floor+.070,front),.026,col,cream,shoe_front)")
pattern=pattern.replace("[(cx-rx*.88,floor+.063,cz),(cx,floor+.099,cz+.012),(cx+rx*.88,floor+.063,cz)]",
    "[shoe_top((cx+rx*.88*(-1+2*i/40),floor+.099,cz+.012)) for i in range(41)]")
pattern=pattern.replace("(cx+sign*rx*.25,floor+.054,front),(.005,.006,.004)","shoe_front((cx+sign*rx*.25,floor+.062,front)),(.005,.006,.004)")
pattern=pattern.replace("(cx,floor+.041,front+.003),(.006,.005,.005)","shoe_front((cx,floor+.049,front+.003)),(.006,.005,.005)")
pattern=pattern.replace("floor+.109+.020*math.cos(a),cz+rz*.29","floor+.088+.020*math.cos(a),cz+rz*.28+.017")
pattern=pattern.replace("(cx,floor+.109,cz+rz*.31)","(cx,floor+.088,cz+rz*.28+.024)")
pattern=pattern.replace("fabric='rubber';sole=B.sphere('Suela',(cx,floor+.013,cz+.010),(rx,.020,rz),col,cream if key!='sandals_summer' else '#EBA687')",
"""fabric='rubber';solepts=[];solefaces=[];sn=64
  for yy,scale in ((floor,.94),(floor+.005,1),(floor+.023,1),(floor+.029,.97)):
   for i in range(sn):
    a=i*math.tau/sn;solepts.append((cx+rx*scale*math.sin(a),yy,cz+.010+rz*scale*math.cos(a)))
  for row in range(3):
   for i in range(sn):solefaces.append((row*sn+i,row*sn+(i+1)%sn,(row+1)*sn+(i+1)%sn,(row+1)*sn+i))
  solefaces.extend((tuple(reversed(range(sn))),tuple(3*sn+i for i in range(sn))))
  sole=B.mesh('Suela plana biselada',solepts,solefaces,col,cream if key!='sandals_summer' else '#EBA687')""")
exec(compile(pattern,__file__,'exec'),ns)
B.material=ns['material']
items=json.loads((ROOT/'assets/runner/accessory-catalog.json').read_text(encoding='utf-8'))
selected=['boots_rain','slippers_cloud','shoes_chic','sandals_summer']
if '--items' in sys.argv:selected=sys.argv[sys.argv.index('--items')+1].split(',')
species=['penguin','bear','pig','chick']
if '--species' in sys.argv:species=[sys.argv[sys.argv.index('--species')+1]]
reports=[]
for sp in species:
 data=json.loads((ROOT/f'design/wardrobe-restart/fitting/{sp}-original.json').read_text(encoding='utf-8'))
 # One stable blend per exposed paw. Per-vertex cloth weights on a rigid sole
 # produced spikes when original Leg and Foot rotations differed sharply.
 blends={}
 for side in ('Left','Right'):
  bounds=data['feet'][side];weights={};count=0
  for mesh in data['meshes']:
   for vi in range(len(mesh['positions'])//3):
    x,y,z=mesh['positions'][vi*3:vi*3+3]
    if not (.003<y<.075 and bounds['min'][0]<=x<=bounds['max'][0] and bounds['min'][2]<=z<=bounds['max'][2]):continue
    entries=list(zip(mesh['skinIndex'][vi*4:vi*4+4],mesh['skinWeight'][vi*4:vi*4+4]))
    if sum(w for bone,w in entries if side in data['boneNames'][bone])<.5:continue
    for bone,w in entries:weights[bone]=weights.get(bone,0)+w
    count+=1
  if not count:raise ValueError('Missing original paw weights '+sp+'/'+side)
  total=sum(weights.values());blends[side]={bone:w/total for bone,w in weights.items()}
 data['footwear_blends']=blends
 for key in selected:
  item=next(i for i in items if i['item_key']==key)
  col=bpy.data.collections.new(key+' · '+sp);B.scene.collection.children.link(col)
  if key=='sandals_summer':
   from wardrobe_sandals import build
   build(B,ns,item,sp,col,data)
  else:ns['footwear'](item,sp,col,data)
  bpy.ops.object.select_all(action='DESELECT')
  for o in col.objects:o.select_set(True)
  bpy.context.view_layer.objects.active=list(col.objects)[0]
  bpy.ops.object.convert(target='MESH');bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
  # Join only within each foot; every surface keeps that foot's rigid joint.
  for side in ('Left','Right'):
   group=[o for o in col.objects if o.name.startswith('Calzado · '+side+' ·')]
   bpy.ops.object.select_all(action='DESELECT')
   for o in group:o.select_set(True)
   bpy.context.view_layer.objects.active=group[0];bpy.ops.object.join()
   group[0].name='Calzado · '+side+' · '+key;group[0].data.name=group[0].name
  bpy.ops.object.select_all(action='DESELECT')
  for o in col.objects:o.select_set(True)
  path=ROOT/f'assets/runner/accessories/restart_{key}_{sp}.glb';stage=path.with_suffix('.building.glb')
  bpy.ops.export_scene.gltf(filepath=str(stage),export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
  data['surface_footwear']=key=='sandals_summer'
  add_skin_attributes(stage,data);stage.replace(path)
  reports.append({'item_key':key,'species':sp,'asset':path.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
  print('FOOTWEAR_EXPORTED',sp,key,flush=True)
  col.hide_viewport=True
  for o in col.objects:o.hide_render=True
master=ROOT/'design/wardrobe-restart/models/CALZADO-ORIGINAL.blend'
B.save_editable_master(master)
catalog=ROOT/'assets/runner/restart/details-catalog.json';old=json.loads(catalog.read_text(encoding='utf-8'))
updated={(r['species'],r['item_key']) for r in reports}
catalog.write_text(json.dumps(reports+[r for r in old if (r['species'],r['item_key']) not in updated],ensure_ascii=False,indent=2),encoding='utf-8')
print('FOOTWEAR_READY',flush=True)
