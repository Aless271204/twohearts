"""Author editable eyes, neck and footwear on the four app mannequins.

No screen overlays: every visible bead, frame, upper, sole and strap is a mesh.
Run Blender --background --python scripts/blender-build-complements.py.
"""
import importlib.util,json,math,hashlib,sys
from pathlib import Path
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('pattern_builder',ROOT/'scripts/blender-build-wardrobe.py')
B=importlib.util.module_from_spec(spec);spec.loader.exec_module(B)
from wardrobe_gltf import add_skin_attributes
source=json.loads((ROOT/'assets/runner/accessory-catalog.json').read_text(encoding='utf-8'))
items=[i for i in source if i['equip_slot'] in ('pet_eyes','pet_neck','pet_feet') and i.get('visible',True)]
if B.selected_items:items=[item for item in items if item['item_key'] in B.selected_items]
previous=json.loads((ROOT/'assets/runner/blender-complement-models.json').read_text(encoding='utf-8')) if B.partial else []
for i in items:
 for key in ('name','rarity','description'):
  if any(c in i.get(key,'') for c in ('Ã','Â')):
   try:i[key]=i[key].encode('latin1').decode('utf-8')
   except UnicodeError:pass
reports=[];materials={};fabric='cotton'
cream='#FFF2DF';pink='#F05280';gold='#E2B957';lavender='#BAA2DB';sage='#B8DCCB'
textile=B.material
def material(color):
 mode=('gold' if color==gold else fabric)
 if mode in ('cotton','knit','felt','wool','poplin','denim'):
  B.active_fabric=mode;return textile(color)
 key=(color,mode)
 if key in materials:return materials[key]
 m=bpy.data.materials.new(mode+' · '+color);m.use_nodes=True
 s=m.node_tree.nodes.get('Principled BSDF');s.inputs['Base Color'].default_value=(*[int(color[i:i+2],16)/255 for i in (1,3,5)],1)
 s.inputs['Metallic'].default_value=.72 if mode=='gold' else 0
 s.inputs['Roughness'].default_value=.24 if mode=='gold' else .42 if mode=='rubber' else .22
 if mode=='lens':s.inputs['Alpha'].default_value=.46;m.surface_render_method='DITHERED'
 materials[key]=m;return m
B.material=material

def ring(name,c,rx,ry,rz,r,col,color,horizontal=True):
 pts=[(c[0]+rx*math.sin(i*math.tau/64),c[1]+(0 if horizontal else ry*math.cos(i*math.tau/64)),c[2]+(rz*math.cos(i*math.tau/64) if horizontal else 0)) for i in range(64)]
 return B.curve(name,pts,r,col,color,True)

def badge(kind,c,size,col,color,project=None):
 if kind=='heart':return B.heart(c,size,col,color,project)
 pts=[]
 for i in range(10):
  a=math.pi/2+i*math.pi/5;r=size*(1 if i%2==0 else .46)
  p=(c[0]+r*math.cos(a),c[1]+r*math.sin(a),c[2]);pts.append(project(p) if project else p)
 o=B.mesh('Estrella',pts,[tuple(range(10))],col,color);B.solid(o,.006)
 bevel=o.modifiers.new('Puntas suaves','BEVEL');bevel.width=.002;bevel.segments=3;return o

def bow(c,size,col,color):
 for sign in (-1,1):
  pts=[];faces=[]
  for j in range(13):
   t=j/12;x=c[0]+sign*size*t;half=size*(.12+.38*math.sin(math.pi*t*.82))
   for k in range(7):
    v=-1+k/3;pts.append((x,c[1]+half*v,c[2]+size*.22*math.sin(math.pi*t)*(1-v*v)))
  for j in range(12):
   for k in range(6):a=j*7+k;faces.append((a,a+1,a+8,a+7))
  o=B.mesh('Lazo acolchado',pts,faces,col,color);B.solid(o,.006)
  B.curve('Pliegue del lazo',[(c[0]+sign*size*t,c[1],c[2]+size*.22*math.sin(math.pi*t)+.002) for t in [j/12 for j in range(13)]],.0014,col,cream)
 B.sphere('Nudo',(c[0],c[1],c[2]+.008),(size*.18,size*.25,size*.20),col,color)

def skin_tree(data):
 pts=[];faces=[]
 for m in data['meshes']:
  offset=len(pts);pts.extend(m['positions'][i:i+3] for i in range(0,len(m['positions']),3))
  faces.extend(tuple(offset+k for k in m['indices'][i:i+3]) for i in range(0,len(m['indices']),3))
 return BVHTree.FromPolygons([Vector(p) for p in pts],faces,all_triangles=True)

def frontal(tree,clearance):
 def project(p):
  hit,normal,_,_=tree.ray_cast(Vector((p[0],p[1],1.2)),Vector((0,0,-1)),2.5)
  return (p[0],p[1],hit.z+clearance) if hit is not None else p
 return project

def eyes(item,sp,col,data,tree):
 global fabric
 fabric='plastic';key=item['item_key'];p=B.heads[sp];rx=p['skull_radius'][0]
 low=data['head']['min'][1];height=data['head']['max'][1]-low
 y=low+height*dict(penguin=.36,bear=.43,pig=.32,chick=.38)[sp]
 x=rx*dict(penguin=.42,bear=.38,pig=.43,chick=.40)[sp];r=rx*.27
 project=frontal(tree,.016);color=item['appearance']['color'].upper()
 if key in ('patch_pirate','mask_sleep'):
  fabric='felt' if key=='patch_pirate' else 'cotton'
  if key=='patch_pirate':
   pos=project((x,y,.3));B.sphere('Parche acolchado',pos,(r*.95,r*.90,.023),col,'#35313D');badge('heart',(pos[0],pos[1],pos[2]+.024),r*.65,col,pink)
  else:
   # A padded mask follows the forehead instead of cutting through the eyes.
   points=[];faces=[]
   for j in range(9):
    for i in range(33):
     xx=(-1+i/16)*(x+r*.9);yy=y+(-1+j/4)*r*.72;points.append(project((xx,yy,.3)))
   for j in range(8):
    for i in range(32):a=j*33+i;faces.append((a,a+1,a+34,a+33))
   o=B.mesh('Máscara mullida',points,faces,col,color);B.solid(o,.026)
   for sign in (-1,1):
    B.curve('Ojito dormido',[project((sign*x+math.sin(a)*r*.47,y-.012-math.cos(a)*r*.17,.35)) for a in [-1.2+j*2.4/12 for j in range(13)]],.003,col,'#805364')
  c=p['skull_center'];B.curve('Cinta elástica',[(rx*1.01*math.sin(a),y+.008,c[2]+p['skull_radius'][2]*1.015*math.cos(a)) for a in [i*math.tau/96 for i in range(96)]],.006,col,color,True)
  return
 for sign in (-1,1):
  contour=[]
  for i in range(64):
   a=i*math.tau/64
   if key=='glasses_heart':u=16*math.sin(a)**3/17;v=(13*math.cos(a)-5*math.cos(2*a)-2*math.cos(3*a)-math.cos(4*a))/17
   elif key=='glasses_star':rr=1 if i%13<6 else .55;u=rr*math.sin(a);v=rr*math.cos(a)
   else:u=math.sin(a);v=math.cos(a)
   contour.append(project((sign*x+r*u,y+r*v,.3)))
  if key=='glasses_star':
   contour=[]
   for i in range(10):
    a=math.pi/2+i*math.pi/5;rr=r*(1 if i%2==0 else .47);contour.append(project((sign*x+rr*math.cos(a),y+rr*math.sin(a),.3)))
  fabric='gold' if key=='glasses_round' else 'plastic'
  B.curve('Montura',contour,.006 if key=='glasses_round' else .012,col,gold if key=='glasses_round' else color,True)
  if key!='glasses_round':
   fabric='lens';center=project((sign*x,y,.3));lenspts=[(q[0],q[1],q[2]-.003) for q in contour]+[center];n=len(contour)
   B.mesh('Lente ahumada',lenspts,[(n,i,(i+1)%n) for i in range(n)],col,'#59415B')
  fabric='gold' if key=='glasses_round' else 'plastic'
  outer=project((sign*(x+r),y,.3));B.curve('Patilla curva',[outer,(sign*(rx+.014),y+.004,p['skull_center'][2]+.12),(sign*(rx-.004),y-.02,p['skull_center'][2]-.12)],.005,col,gold if key=='glasses_round' else color)
 B.curve('Puente nasal',[project((-x+r*.90,y+.013,.3)),project((0,y+.038,.3)),project((x-r*.90,y+.013,.3))],.0045,col,gold if key=='glasses_round' else color)

def neck(item,sp,col,data,tree):
 global fabric
 key=item['item_key'];fabric='knit' if key=='scarf_hearts' else 'cotton'
 lo=data['body']['min'];hi=data['body']['max'];cx=(lo[0]+hi[0])/2;cz=(lo[2]+hi[2])/2
 y=hi[1]+B.config['species_fit'][sp].get('neck_extension',.010)-(.040 if sp=='penguin' else .025)
 def point(a,yy=y,pad=.060):
  direction=Vector((math.sin(a),0,math.cos(a)));origin=Vector((cx,yy,cz))
  # Cast inward from outside: the PG's inner lining is not its clothing surface.
  hit,_,_,dist=tree.ray_cast(origin+direction*1.5,-direction,3)
  # The neck ring must not include the separate arms in the torso's silhouette.
  # A full-skin ray otherwise creates loops extending across both shoulder caps.
  rx=max(.03,(hi[0]-lo[0])/2);rz=max(.03,(hi[2]-lo[2])/2)
  envelope=1/math.sqrt((math.sin(a)/rx)**2+(math.cos(a)/rz)**2)
  r=min(1.5-dist if hit is not None else envelope,envelope*1.02)+pad
  return (cx+r*math.sin(a),yy,cz+r*math.cos(a))
 front=point(0);color=item['appearance']['color'].upper()
 if key in ('scarf_hearts','bandana_sage'):
  pts=[];faces=[];N=80;M=10
  for j in range(M+1):
   t=j/M
   for i in range(N):
    a=i*math.tau/N;drop=(.043 if key=='scarf_hearts' else .115*max(0,math.cos(a))**6)
    yy=y+.026-(.085 if key=='scarf_hearts' else .018+drop)*t
    p=point(a,yy,.056+.014*math.sin(math.pi*t) if key=='scarf_hearts' else .045)
    pts.append(p)
  for j in range(M):
   for i in range(N):a=j*N+i;b=j*N+(i+1)%N;faces.append((a,b,b+N,a+N))
  o=B.mesh('Patrón cuello · '+key,pts,faces,col,color);B.solid(o,.018 if key=='scarf_hearts' else .005)
  project=B.surface_projector(o,.003)
  B.curve('Dobladillo del cuello',pts[-N:],.003,col,color if key=='scarf_hearts' else cream,True)
  if key=='scarf_hearts':
   front=point(0,y-.045,.067);x=front[0]+.075;z=front[2]+.014
   for i in range(48):
    a=i*math.tau/48;B.curve('Punto de bufanda',[project(point(a+offset,y+dy,.08)) for offset,dy in [(-.020,-.020),(0,-.036),(.020,-.020)]],.0018,col,color)
   # Rounded draped tail, with an actual ribbed fringe.
   tail=B.sphere('Cola mullida',(x,y-.12,z),(.044,.125,.017),col,color)
   for i in range(6):B.curve('Fleco',[(x-.034+i*.013,y-.21,z),(x-.038+i*.013,y-.26,z+.01)],.0038,col,color)
   badge('heart',(x,y-.10,z+.023),.032,col,cream)
  else:
   for xx,yy in [(-.055,y-.040),(.056,y-.056),(0,y-.097)]:B.flower((xx,yy,front[2]),.012,col,project)
   bow((.16,y+.007,point(math.pi/3)[2]+.015),.035,col,color)
 elif key=='bow_neck':
  B.curve('Banda de algodón',[point(i*math.tau/80,pad=.026) for i in range(80)],.010,col,color,True)
  front=point(0,pad=.026)
  bow((front[0],y-.012,front[2]+.012),.079,col,color)
 else:
  fabric='pearl' if key=='necklace_heart' else 'gold'
  centers=[point(i*math.tau/26,y+.004-.023*math.cos(i*math.tau/26),.034) for i in range(26)]
  for i,p in enumerate(centers):
   if key=='necklace_heart':B.sphere('Perla',p,(.017,.017,.017),col,cream if i%2 else '#F5BAC5')
   else:
    # Rotate each link about its own centre, never the scene origin.
    angle=(math.pi/3 if i%2 else -math.pi/3)
    link=[]
    for j in range(24):
     a=j*math.tau/24;u=.018*math.sin(a);v=.011*math.cos(a)
     link.append((p[0]+u*math.cos(angle),p[1]+v,p[2]+u*math.sin(angle)))
    B.curve('Eslabón',link,.0038,col,gold,True)
  pos=centers[0];ring('Anilla del dije',(pos[0],pos[1]-.033,pos[2]+.012),.010,.012,0,.003,col,gold,False)
  badge('heart' if key=='necklace_heart' else 'star',(pos[0],pos[1]-.068,pos[2]+.016),.052 if key=='necklace_heart' else .026,col,pink if key=='necklace_heart' else gold)

def footwear(item,sp,col,data):
 global fabric
 key=item['item_key'];color=item['appearance']['color'].upper()
 for side in ('Left','Right'):
  before=set(col.objects);f=data['feet'][side];lo=f['min'];hi=f['max'];cx=(lo[0]+hi[0])/2;cz=(lo[2]+hi[2])/2
  rx=(hi[0]-lo[0])*.57;rz=(hi[2]-lo[2])*.62;floor=lo[1]-.007;top=hi[1]+.023
  fabric='rubber';sole=B.sphere('Suela',(cx,floor+.013,cz+.010),(rx,.020,rz),col,cream if key!='sandals_summer' else '#EBA687')
  # Sole welt and thread wrap the same physical outline as the upper.
  ring('Ribete de suela',(cx,floor+.030,cz+.010),rx*.97,0,rz*.97,.003,col,cream)
  if key=='sandals_summer':
   fabric='plastic'
   for z in [cz+rz*.28,cz-rz*.25]:
    B.curve('Correa redondeada',[(cx+rx*math.sin(a)*.93,floor+.05+.040*math.cos(a),z) for a in [-math.pi/2+i*math.pi/24 for i in range(25)]],.013,col,color)
   B.curve('Talón',[(cx-rx*.90,floor+.045,cz-.01),(cx-rx*.75,top,cz-rz*.72),(cx,top+.009,cz-rz*.87),(cx+rx*.75,top,cz-rz*.72),(cx+rx*.9,floor+.045,cz-.01)],.011,col,color)
   for i in range(5):a=i*math.tau/5;B.sphere('Pétalo',(cx+.020*math.sin(a),floor+.109+.020*math.cos(a),cz+rz*.29),(.014,.016,.011),col,'#FFD2BE')
   B.sphere('Centro flor',(cx,floor+.109,cz+rz*.31),(.010,.010,.007),col,cream)
  else:
   fabric='wool' if key=='slippers_cloud' else 'plastic' if key=='boots_rain' else 'cotton'
   pts=[];faces=[];N=64;M=12
   boot=key=='boots_rain';high=top+.092 if boot else top+.025
   for j in range(M+1):
    t=j/M
    for i in range(N):
     a=i*math.tau/N
     # Full round toe narrows into the ankle opening, leaving the pet's leg free.
     width=rx*(1-.46*t**2);depth=rz*(1-.62*t**2)
     pts.append((cx+width*math.sin(a),floor+.036+(high-floor-.036)*t,cz+.012*(1-t)+depth*math.cos(a)-rz*.21*t**2))
   for j in range(M):
    for i in range(N):a=j*N+i;b=j*N+(i+1)%N;faces.append((a,b,b+N,a+N))
   upper=B.mesh('Empeine envolvente',pts,faces,col,color);B.solid(upper,.010 if key=='slippers_cloud' else .005)
   ring('Abertura acolchada',(cx,high,cz-rz*.21),rx*.54,0,rz*.38,.009 if not boot else .017,col,cream)
   front=cz+rz*.93
   if key=='shoes_heart':
    for j in range(4):yy=floor+.085+j*.012;zz=cz+rz*.35-j*.018;B.curve('Cordón de zapatilla',[(cx-rx*.42,yy,zz),(cx+rx*.42,yy+.006,zz-.011)],.0038,col,cream)
    badge('heart',(cx+rx*.73,floor+.070,front*.70),.038,col,pink)
    B.curve('Pespunte',[(p[0],p[1]+.008,p[2]) for p in pts[:N]],.0012,col,cream,True)
   elif key=='boots_rain':badge('heart',(cx,high-.033,front*.53),.038,col,cream)
   elif key=='slippers_cloud':
    fabric='wool'
    for i in range(30):
     a=i*math.pi*(3-math.sqrt(5));v=(i%6)/6;B.sphere('Borreguito',(cx+rx*.9*math.sin(a),floor+.056+.035*v,cz+rz*.85*math.cos(a)),(.016,.016,.016),col,cream)
    for sign in (-1,1):B.sphere('Oreja de pantufla',(cx+sign*rx*.44,floor+.088,cz+rz*.65),(.021,.023,.015),col,cream);fabric='plastic';B.sphere('Ojito',(cx+sign*rx*.25,floor+.054,front),(.005,.006,.004),col,'#53464C');fabric='wool'
    B.sphere('Nariz',(cx,floor+.041,front+.003),(.006,.005,.005),col,pink)
   else:
    B.curve('Correa Mary Jane',[(cx-rx*.88,floor+.063,cz),(cx,floor+.099,cz+.012),(cx+rx*.88,floor+.063,cz)],.009,col,color)
    ring('Hebilla',(cx+rx*.76,floor+.081,cz+.022),.013,.013,0,.003,col,gold,False)
    badge('heart',(cx,floor+.045,front),.031,col,cream)
  # One complete pair; rigid skin to the correct foot is retained on every detail.
  for o in set(col.objects)-before:o.name='Calzado · '+side+' · '+o.name

for sp in ('penguin','bear','pig','chick'):
 if B.selected_species and sp not in B.selected_species:continue
 data=json.loads((B.D/(sp+'.json')).read_text());tree=skin_tree(data)
 for item in items:
  key=item['item_key'];col=bpy.data.collections.new(key+' · '+sp);B.scene.collection.children.link(col)
  if item['equip_slot']=='pet_eyes':eyes(item,sp,col,data,tree)
  elif item['equip_slot']=='pet_neck':neck(item,sp,col,data,tree)
  else:footwear(item,sp,col,data)
  bpy.ops.object.select_all(action='DESELECT')
  for o in col.objects:o.select_set(True)
  bpy.context.view_layer.objects.active=list(col.objects)[0];bpy.ops.object.convert(target='MESH');bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
  for o in col.objects:o.data.name=o.name
  path=B.OUT/(key+'_'+sp+'_tailored.glb')
  bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
  if item['equip_slot']!='pet_eyes':add_skin_attributes(path,data)
  reports.append({'item_key':key,'species':sp,'path':'assets/runner/accessories/'+path.name,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
  col.hide_viewport=True
  for o in col.objects:o.hide_render=True
  print('COMPLEMENT',key,sp,flush=True)
master=B.D/'NIDO-complementos-prendas.blend'
if B.partial and master.exists():
 with bpy.data.libraries.load(str(master),link=False) as (old,new):new.collections=[name for name in old.collections if name not in bpy.data.collections]
 for collection in new.collections:
  if collection:B.scene.collection.children.link(collection)
B.save_editable_master(master)
catalog=[]
for item in items:
 v=[r for r in reports if r['item_key']==item['item_key']];appearance={**item['appearance'],'fitted_model_space':True,'species_models':{r['species']:r['path'] for r in v},'model_asset':v[0]['path']}
 if item['equip_slot']!='pet_eyes':appearance['skinned_model_space']=True
 appearance['asset_revision']=hashlib.sha256(''.join(r['sha256'] for r in v).encode()).hexdigest()[:16]
 catalog.append({**item,'appearance':appearance,'variants':v})
if B.partial:
 updated={i['item_key']:i for i in catalog};catalog=[updated.get(i['item_key'],i) for i in previous]
for item in catalog:
 for key in ('name','rarity','description'):
  if any(c in item.get(key,'') for c in ('Ã','Â')):
   try:item[key]=item[key].encode('latin1').decode('utf-8')
   except UnicodeError:pass
(ROOT/'assets/runner/blender-complement-models.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2),encoding='utf-8')
print('COMPLEMENTS_READY',len(reports),flush=True)
