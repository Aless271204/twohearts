"""Editable garment patterns authored on the four actual app mannequins.
Run with Blender --background --python scripts/blender-build-wardrobe.py.
This creates a review catalog, never approves products for sale.
"""
import bpy,bmesh,json,math,struct,hashlib,sys,shutil
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from mathutils import Vector,Matrix
from mathutils.bvhtree import BVHTree
from wardrobe_gltf import add_skin_attributes
from wardrobe_materials import make_material
from wardrobe_shells import repair_shell
R=Path(__file__).resolve().parents[1];D=R/'design/blender/fitting';OUT=R/'assets/runner/accessories'
config=json.loads((R/'design/blender/wardrobe-patterns.json').read_text(encoding='utf-8'))
selection=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
selected_species=next((v.split('=',1)[1].split(',') for v in selection if v.startswith('species=')),None)
selected_items=next((v.split('=',1)[1].split(',') for v in selection if v.startswith('items=')),None)
partial=bool(selected_species or selected_items)
previous_catalog=json.loads((R/'assets/runner/blender-wardrobe-models.json').read_text(encoding='utf-8')) if partial else []
heads=json.loads((R/'design/blender/head-tailoring.json').read_text(encoding='utf-8'))['pets']
C=Matrix.Rotation(math.pi/2,4,'X');CI=C.inverted();bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.name='TwoHearts · Patronaje'
materials={};reports=[];active_fabric='cotton'

def fabric_uv(d,planar=False):
 # UVs use physical model-space distances, with a local centre for each panel.
 # Blender exports per-loop UVs as split vertices at the cylindrical seam.
 points=[CI@v.co for v in d.vertices]
 if not points:return
 low=[min(p[k] for p in points) for k in range(3)];high=[max(p[k] for p in points) for k in range(3)]
 cx=(low[0]+high[0])/2;cz=(low[2]+high[2])/2
 circumference=math.tau*max(.005,((high[0]-low[0])+(high[2]-low[2]))/4)
 uv=d.uv_layers.get('UVMap') or d.uv_layers.new(name='UVMap')
 for face in d.polygons:
  values=[]
  for loop_id in face.loop_indices:
   p=points[d.loops[loop_id].vertex_index]
   u=p.x-low[0] if planar else (math.atan2(p.x-cx,p.z-cz)/math.tau+.5)*circumference
   values.append((loop_id,u,p.y-low[1]))
  crossing=not planar and max(v[1] for v in values)-min(v[1] for v in values)>circumference*.5
  for loop_id,u,v in values:
   if crossing and u<circumference*.5:u+=circumference
   uv.data[loop_id].uv=(u,v)
def material(color):
 fabric='wool' if color=='#FFF2DF' and active_fabric=='wool' else active_fabric
 key=(color,fabric)
 if key in materials:return materials[key]
 m=make_material(color,fabric,R/'design/blender/fabrics');materials[key]=m;return m
def mesh(name,points,faces,col,color):
 d=bpy.data.meshes.new(name);d.from_pydata([C@Vector(p) for p in points],[],faces);d.update()
 o=bpy.data.objects.new(name,d);col.objects.link(o);d.materials.append(material(color))
 for f in d.polygons:f.use_smooth=True
 fabric_uv(d,any(word in name for word in ('bordado','Panel','Visera')))
 return o
def curve(name,pts,radius,col,color,closed=False):
 d=bpy.data.curves.new(name,'CURVE');d.dimensions='3D';d.resolution_u=2;d.bevel_depth=radius;d.bevel_resolution=1
 s=d.splines.new('POLY');s.points.add(len(pts)-1)
 for q,p in zip(s.points,pts):q.co=(*tuple(C@Vector(p)),1)
 s.use_cyclic_u=closed;o=bpy.data.objects.new(name,d);col.objects.link(o);d.materials.append(material(color));return o
def sphere(name,center,scale,col,color):
 small=max(scale)<.03
 bpy.ops.mesh.primitive_uv_sphere_add(segments=12 if small else 24,ring_count=8 if small else 12,location=C@Vector(center));o=bpy.context.object
 for c in list(o.users_collection):c.objects.unlink(o)
 col.objects.link(o);o.name=name;o.scale=(scale[0],scale[2],scale[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(material(color))
 for f in o.data.polygons:f.use_smooth=True
 fabric_uv(o.data,True)
 return o
def stitches(name,pts,col,color):
 # Small discontinuous thread segments follow the existing seam contour.
 for i in range(0,len(pts)-2,3):curve(name,[pts[i],pts[i+1]],.0011,col,color)
def heart(center,size,col,color,project=None):
 pts=[]
 for i in range(64):
  a=i*math.tau/64;x=16*math.sin(a)**3;y=13*math.cos(a)-5*math.cos(2*a)-2*math.cos(3*a)-math.cos(4*a)
  pts.append((center[0]+x*size/32,center[1]+y*size/32,center[2]))
 # A fan alone bends poorly over the belly. Subdivide first, then seat the
 # complete embroidered patch on the garment, including its interior vertices.
 pts.append(center);faces=[(64,i,(i+1)%64) for i in range(64)]
 o=mesh('Corazón bordado',pts,faces,col,color)
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.subdivide_edges(bm,edges=list(bm.edges),cuts=3,use_grid_fill=True);bm.to_mesh(o.data);bm.free()
 if project:
  for v in o.data.vertices:
   p=Vector(project(tuple(CI@v.co)));p.z+=.018;v.co=C@p
  o.data.update();fabric_uv(o.data,True)
 solid=o.modifiers.new('Relieve del bordado','SOLIDIFY');solid.thickness=.003;solid.offset=0
 bevel=o.modifiers.new('Borde suave','BEVEL');bevel.width=.002;bevel.segments=3;return o
def solid(o,thickness=.006):
 bpy.context.view_layer.objects.active=o;o.select_set(True)
 mod=o.modifiers.new('Espesor de tela','SOLIDIFY');mod.thickness=thickness;mod.offset=0
 bpy.ops.object.modifier_apply(modifier=mod.name)
 # Sleeve lofts and torso lofts use opposite angular parameterizations. Once
 # thickened they are closed volumes: orient each outwards before Boolean union.
 # An inverted sleeve can make UNION retain only its operand, losing the torso.
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free();o.data.update()

def surface_projector(obj,clearance=.0025,frontal=True):
 tree=BVHTree.FromPolygons([CI@v.co for v in obj.data.vertices],[list(f.vertices) for f in obj.data.polygons])
 maximum=max((CI@v.co).z for v in obj.data.vertices)+.20
 def project(p):
  x,y,z=p;hit=None;normal=None
  if frontal:hit,normal,_,_=tree.ray_cast(Vector((x,y,maximum)),Vector((0,0,-1)),2)
  if hit is None:
   hit,normal,_,_=tree.find_nearest(Vector(p))
  return tuple(hit+normal*clearance) if hit is not None else p
 return project

def panel(name,x0,x1,y0,y1,z,col,color,project,steps=8):
 pts=[];faces=[]
 for j in range(steps+1):
  for i in range(steps+1):pts.append(project((x0+(x1-x0)*i/steps,y0+(y1-y0)*j/steps,z)))
 for j in range(steps):
  for i in range(steps):a=j*(steps+1)+i;faces.append((a,a+1,a+steps+2,a+steps+1))
 obj=mesh('Panel · '+name,pts,faces,col,color);solid(obj,.0025);return obj

def flower(center,size,col,project):
 def seated(p):q=Vector(project(p));q.z+=.005;return tuple(q)
 pts=[seated(center)]
 for i in range(40):
  a=i*math.tau/40;r=size*(.74+.26*math.cos(5*a));pts.append(seated((center[0]+r*math.sin(a),center[1]+r*math.cos(a),center[2])))
 obj=mesh('Flor bordada',pts,[(0,i+1,(i+1)%40+1) for i in range(40)],col,'#FFF2DF');solid(obj,.0015)
def collider(data,col):
 p=data['meshes'][0];pts=[p['positions'][i:i+3] for i in range(0,len(p['positions']),3)];faces=[p['indices'][i:i+3] for i in range(0,len(p['indices']),3)]
 o=mesh('Maniquí de encaje',pts,faces,col,'#D3D0D4');bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00002)
 # Crown feathers are tucked by the app when wearing a hat. Cutting a hat
 # against those feathers created overlapping Boolean faces inside the crown.
 if data['species'] in ('penguin','chick'):
  bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.000001,plane_co=C@Vector((0,1.055,0)),plane_no=C@Vector((0,1,0)),clear_outer=True,clear_inner=False)
 bmesh.ops.holes_fill(bm,edges=[e for e in bm.edges if e.is_boundary],sides=0);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free();o.data.update()
 tree=BVHTree.FromPolygons([CI@v.co for v in o.data.vertices],[list(f.vertices) for f in o.data.polygons])
 o.hide_render=True;o.hide_set(True);return o,tree
def head_piece(key,species,col,data,cutter):
 p=heads[species];cx,cy,cz=p['skull_center'];rx,ry,rz=p['skull_radius'];ry+=.016;rx+=.014;rz+=.014
 fit=config.get('species_fit',{}).get(species,{});cy+=fit.get('head_raise',0)
 beret_height=fit.get('beret_height',.76)
 beanie=key=='beanie_cloud';beret=key=='beret_chic';garden=key=='hat_garden';N=64;M=18 if beanie else 20;points=[]
 for j in range(M+1):
  t=.025+(1.50-.025)*j/M
  for i in range(N):
   a=math.tau*i/N;bulge=1.12 if beret else 1
   x=cx+rx*math.sin(t)*math.sin(a)*bulge
   z=cz+rz*math.sin(t)*math.cos(a)*bulge
   y=cy+ry*math.cos(t)*(beret_height if beret else 1.20 if beanie else 1)
   if beret:
    y=cy+ry*beret_height*math.cos(t)**.65-.10*(x-cx)
    x+=rx*.065*math.cos(t)**2
   points.append((x,y,z))
 faces=[]
 for j in range(M):
  for i in range(N):a=j*N+i;b=j*N+(i+1)%N;faces.append((a,b,b+N,a+N))
 faces.append(tuple(reversed(range(N))));o=mesh('Copa redondeada',points,faces,col,config['items'][key]['color']);solid(o,.012 if beanie or beret else .008)
 # Exact skull cut permits ears to protrude without flattening the crown.
 bpy.context.view_layer.objects.active=o;cutter.hide_set(False)
 mod=o.modifiers.new('Aberturas reales para orejas','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cutter
 bpy.ops.object.modifier_apply(modifier=mod.name);cutter.hide_set(True)
 head_front=surface_projector(o,.002)
 head_seam=surface_projector(o,.001,False)
 rim=points[-N:];curve('Banda inferior',rim,.008,col,config['items'][key]['color'],True)
 if key=='cap_pink':
  vs=[];fs=[]
  for j in range(9):
   t=j/8
   for i in range(33):
    a=-1.08+2.16*i/32;x=rx*math.sin(a)*(1+.13*t);vs.append((x,cy+.025-.035*t-.022*(abs(x)/(rx*math.sin(1.08)*1.13))**2,cz+rz*math.cos(a)+.105*t*math.cos(a*.8)))
  for j in range(8):
   for i in range(32):a=j*33+i;fs.append((a,a+1,a+34,a+33))
  visor=mesh('Visera curva',vs,fs,col,config['items'][key]['color']);solid(visor)
  for a in [0,math.pi/3,-math.pi/3,2*math.pi/3,-2*math.pi/3,math.pi]:
   curve('Costura de la copa',[head_seam((cx+(rx+.001)*math.sin(t)*math.sin(a),cy+(ry+.002)*math.cos(t),cz+(rz+.001)*math.sin(t)*math.cos(a))) for t in [.10+k*1.35/24 for k in range(25)]],.0012,col,'#F8A3B7')
  sphere('Botón superior',(cx,cy+ry+.005,cz),(.025,.011,.025),col,'#F05280');heart((0,cy+.14,cz+rz*.90+.008),.075,col,'#FFF2DF',head_front)
 elif beanie:
  fold_pts=[];fold_faces=[]
  for j in range(7):
   for x,y,z in rim:
    delta=Vector((x-cx,0,z-cz)).normalized()*(.012+.009*math.sin(math.pi*j/6));fold_pts.append((x+delta.x,y+.065*j/6,z+delta.z))
  for j in range(6):
   for i in range(N):a=j*N+i;b=j*N+(i+1)%N;fold_faces.append((a,b,b+N,a+N))
  fold=mesh('Dobladillo tejido',fold_pts,fold_faces,col,'#FFF2DF');solid(fold,.013)
  bpy.context.view_layer.objects.active=fold;cutter.hide_set(False);mod=fold.modifiers.new('Orejas en el dobladillo','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cutter;bpy.ops.object.modifier_apply(modifier=mod.name);cutter.hide_set(True)
  fold_project=surface_projector(fold,.002,False)
  for i in range(56):
   a=math.tau*i/56;curve('Canalé del dobladillo',[fold_project((cx+(rx+.025)*math.sin(a),rim[0][1]+.005+.055*j/8,cz+(rz+.025)*math.cos(a))) for j in range(9)],.0017,col,'#FFF2DF')
  for i in range(40):
   a=math.tau*i/40;curve('Punto tejido de la copa',[head_seam((cx+(rx+.002)*math.sin(t)*math.sin(a),cy+ry*1.20*math.cos(t),cz+(rz+.002)*math.sin(t)*math.cos(a))) for t in [.15+j*1.20/15 for j in range(16)]],.0015,col,'#FFF2DF')
  pom=sphere('Pompón',(cx,cy+ry*1.20+.055,cz),(.073,.070,.073),col,'#FFF2DF')
  for v in pom.data.vertices:
   n=v.co.normalized();v.co*=1+.02*math.sin(n.x*23)*math.sin(n.y*27)*math.cos(n.z*19)
  for i in range(48):
   y=1-2*(i+.5)/48;a=i*math.pi*(3-math.sqrt(5));r=math.sqrt(1-y*y);direction=Vector((math.cos(a)*r,y,math.sin(a)*r));pos=Vector((cx,cy+ry*1.20+.055,cz))+direction*.068
   puff=sphere('Bucle del pompón',pos,(.010,.010,.010),col,'#FFF2DF');dec=puff.modifiers.new('Detalle móvil','DECIMATE');dec.ratio=.24;bpy.context.view_layer.objects.active=puff;bpy.ops.object.modifier_apply(modifier=dec.name)
  heart((rx*.40,cy+.10,cz+rz*.94),.058,col,'#F05280',head_front)
 elif garden:
  pts=[];fs=[]
  for j in range(8):
   t=j/7
   for i in range(N):a=i*math.tau/N;pts.append((cx+(rx+.12*t)*math.sin(a),cy+.025-.025*t+.008*math.sin(a*2)*t,cz+(rz+.12*t)*math.cos(a)))
  for j in range(7):
   for i in range(N):a=j*N+i;b=j*N+(i+1)%N;fs.append((a,b,b+N,a+N))
  o=mesh('Ala de paja',pts,fs,col,'#B8DCCB');solid(o);curve('Borde del ala',pts[-N:],.004,col,'#829F83',True)
  for j in range(4):curve('Cinta coral',[(x,y+.025+j*.009,z) for x,y,z in rim],.006,col,'#F5A4B3',True)
  bow_x=rx*.73;bow_y=cy+.09;bow_z=cz+rz*.72
  for sign in [-1,1]:
   pts=[];fs=[]
   for j in range(9):
    t=j/8;x=bow_x+sign*.075*t;half=.007+.033*math.sin(math.pi*t*.85)
    for side in [-1,1]:pts.append((x,bow_y+side*half,bow_z+.012*math.sin(math.pi*t)))
   for j in range(8):a=j*2;fs.append((a,a+1,a+3,a+2))
   bow=mesh('Panel · Lazo jardín',pts,fs,col,'#F5A4B3');solid(bow,.005)
   tail=mesh('Panel · Cola del lazo',[(bow_x+sign*.010,bow_y-.015,bow_z),(bow_x+sign*.038,bow_y-.025,bow_z),(bow_x+sign*.058,bow_y-.13,bow_z+.015),(bow_x+sign*.030,bow_y-.115,bow_z+.015)],[(0,1,2,3)],col,'#F5A4B3');solid(tail,.004)
  sphere('Nudo jardín',(bow_x,bow_y,bow_z+.005),(.015,.021,.012),col,'#F5A4B3')
 else:
  sphere('Rabito de boina',(.025,cy+ry*beret_height+.024,cz),(.012,.03,.012),col,'#BAA2DB');heart((rx*.43,cy+.10,cz+rz*.98),.058,col,'#F7BEB3',head_front)
def body_piece(key,species,col,data,tree):
 low=data['body']['min'];high=data['body']['max'];center=[(a+b)/2 for a,b in zip(low,high)]
 bottom=max(.135,low[1]+.08);top=high[1]+config.get('species_fit',{}).get(species,{}).get('neck_extension',.010);N=64;M=32;points=[];rows=[]
 padding=max(config.get('species_fit',{}).get(species,{}).get('body_padding',.014),config['items'][key].get('padding',0))
 def radius(y,a):
  origin=Vector((center[0],y,center[2]));direction=Vector((math.sin(a),0,math.cos(a)));hit,_,_,dist=tree.ray_cast(origin,direction,1.5)
  rx=(high[0]-low[0])/2;rz=(high[2]-low[2])/2
  fallback=1/math.sqrt((math.sin(a)/rx)**2+(math.cos(a)/rz)**2)
  # Wing silhouettes must not inflate the body pattern sideways.
  distance=min(dist,fallback*1.2) if hit is not None else fallback*.95
  return distance+padding
 for j in range(M+1):
  y=bottom+(top-bottom)*j/M;row=[]
  for i in range(N):
   a=math.tau*i/N;r=radius(y,a)
   if key=='dress_petal':r+=.045*(1-j/M)**2*(1+.18*math.cos(a*12))
   # Raise the front/back of the neckline under the chin, while keeping the
   # shoulder line lower. A horizontal ring exposed the bear's entire chest.
   neck_lift=(.038 if species=='bear' else .008)*math.cos(a)**2*(j/M)**8
   row.append((center[0]+r*math.sin(a),y+neck_lift,center[2]+r*math.cos(a)))
  rows.append(row);points.extend(row)
 faces=[]
 for j in range(M):
  for i in range(N):
   a=math.tau*(i+.5)/N;y=bottom+(top-bottom)*(j+.5)/M
   # Open armholes instead of letting sleeves intersect wings or shoulders.
   armhole=False
   jacket=key in ('jacket_denim','coat_cloud') and abs(a-math.pi*2*(a>math.pi))<.10
   if not armhole and not jacket:
    v=j*N+i;w=j*N+(i+1)%N;faces.append((v,w,w+N,v+N))
 o=mesh('Patrón envolvente · '+key,points,faces,col,config['items'][key]['color']);solid(o,.012 if key in ('coat_cloud','hoodie_nido') else .007)
 garment=o;project=surface_projector(garment)
 # Reconstruct complete rounded sleeve panels from the posed arm sections.
 # Copying selected skin triangles left irregular shoulder boundaries.
 arm_points=[]
 for source in data['meshes']:
  if species=='penguin' and source['name'].endswith('RoundedWing'):
   arm_points.extend(Vector(source['positions'][i:i+3]) for i in range(0,len(source['positions']),3));continue
  if species=='penguin':continue
  if not source.get('skinWeight'):continue
  for i in range(len(source['positions'])//3):
   weight=sum(source['skinWeight'][i*4+j] for j in range(4) if data['boneNames'][source['skinIndex'][i*4+j]].endswith(('Arm','ForeArm')))
   if weight>.35:arm_points.append(Vector(source['positions'][i*3:i*3+3]))
 for sign in [-1,1]:
  samples=[p for p in arm_points if p.x*sign>.10]
  if not samples:continue
  sleeve_rows=[];verts=[];faces=[];segments=40;rings=12
  lower=top-(.155 if key in ('coat_cloud','hoodie_nido') else .11);upper=top-.010
  for j in range(rings+1):
   y=lower+(upper-lower)*j/rings
   nearby=[p for p in samples if abs(p.y-y)<.025]
   if len(nearby)<8:nearby=sorted(samples,key=lambda p:abs(p.y-y))[:24]
   x0=min(p.x for p in nearby);x1=max(p.x for p in nearby);z0=min(p.z for p in nearby);z1=max(p.z for p in nearby)
   sx=(x0+x1)/2;sz=(z0+z1)/2;rounding=1-.28*(j/rings)**6
   rx=((x1-x0)/2+padding+.008)*rounding;rz=((z1-z0)/2+padding+.008)*rounding
   row=[(sx+rx*math.cos(i*math.tau/segments),y,sz+rz*math.sin(i*math.tau/segments)) for i in range(segments)]
   sleeve_rows.append(row);verts.extend(row)
  for _ in range(2):
   sleeve_rows=[sleeve_rows[0]]+[[tuple((sleeve_rows[j-1][i][k]+2*sleeve_rows[j][i][k]+sleeve_rows[j+1][i][k])/4 for k in range(3)) for i in range(segments)] for j in range(1,rings)]+[sleeve_rows[-1]]
  verts=[p for row in sleeve_rows for p in row]
  for j in range(rings):
   for i in range(segments):a=j*segments+i;b=j*segments+(i+1)%segments;faces.append((a,b,b+segments,a+segments))
  # Rounded shoulder closes beneath the head; cuff remains open around the arm.
  row=sleeve_rows[-1];center_top=tuple(sum(p[k] for p in row)/segments for k in range(3));verts.append((center_top[0],center_top[1]+.015,center_top[2]));tip=len(verts)-1
  for i in range(segments):faces.append((rings*segments+i,rings*segments+(i+1)%segments,tip))
  sleeve=mesh('Manga adaptada · '+species+' · '+str(sign),verts,faces,col,config['items'][key]['color']);solid(sleeve,.012 if key in ('coat_cloud','hoodie_nido') else .007)
  # Union the two overlapping fabric volumes. Independent closed sleeves
  # looked torn at their shoulder seam and could drift during animation.
  bpy.context.view_layer.objects.active=garment
  join=garment.modifiers.new('Hombro continuo · '+str(sign),'BOOLEAN');join.operation='UNION';join.solver='EXACT';join.object=sleeve
  join.use_self=True;join.use_hole_tolerant=True
  bpy.ops.object.modifier_apply(modifier=join.name)
  if not garment.data.vertices:raise RuntimeError('Shoulder union removed the torso: '+species+' '+key)
  bpy.data.objects.remove(sleeve,do_unlink=True)
  curve('Puño suave',sleeve_rows[0],.0035,col,config['items'][key]['color'],True)
 # Round only the shoulder union: retain the neckline, open hem and pockets.
 weights=garment.vertex_groups.new(name='Suavizar hombros')
 for v in garment.data.vertices:
  p=CI@v.co
  weight=max(0,1-abs(p.y-(top-.045))/.070)*min(1,max(0,(abs(p.x)-.10)/.07))
  if weight>0:weights.add([v.index],weight,'REPLACE')
 bpy.context.view_layer.objects.active=garment
 soften=garment.modifiers.new('Hombros redondeados','SMOOTH');soften.factor=.48;soften.iterations=5;soften.vertex_group=weights.name
 bpy.ops.object.modifier_apply(modifier=soften.name)
 repair_shell(garment)
 project=surface_projector(garment)
 seam=surface_projector(garment,.0015,False)
 curve('Dobladillo',list(map(seam,rows[0])),.004,col,config['items'][key]['color'],True)
 curve('Cuello suave',list(map(seam,rows[-1])),.005 if key!='coat_cloud' else .010,col,config['items'][key]['color'] if key in ('jacket_denim','hoodie_nido') else '#FFF2DF',True)
 if key=='coat_cloud':
  for i in range(24):
   x,y,z=rows[-1][int(i*N/24)]
   puff=sphere('Bucle de borreguito',(x,y+.002,z),(.017,.017,.017),col,'#FFF2DF')
   # Low-detail curled tufts add silhouette volume without particle systems.
   dec=puff.modifiers.new('Detalle móvil','DECIMATE');dec.ratio=.35;bpy.context.view_layer.objects.active=puff;bpy.ops.object.modifier_apply(modifier=dec.name)
 stitches('Pespunte del bajo',[seam((x,y+.009,z)) for x,y,z in rows[0]],col,'#F4DCC7' if key=='shirt_love' else '#FFF2DF')
 stitches('Pespunte del cuello',[seam((x,y-.008,z)) for x,y,z in rows[-1]],col,'#FFF2DF')
 front=radius(center[1],0)+center[2]
 if key=='shirt_love':
  heart((center[0],center[1]+.01,front),.14,col,'#F05280',project)
 elif key in ('coat_cloud','jacket_denim'):
  for j in range(3):
   y=top-.055-j*(top-bottom)*.27;z=radius(y,0)+center[2];pos=project((center[0]+.035,y,z));sphere('Botón',(pos[0],pos[1],pos[2]+.004),(.012,.012,.005),col,'#D8B877')
  for sign in [-1,1]:
   x=sign*(high[0]-low[0])*.25;y=center[1]+.035;z=front;w=(high[0]-low[0])*.075
   panel('Bolsillo cosido',x-w,x+w,y-.03,y+.025,z,col,config['items'][key]['color'],project)
   outline=[(x-w,y+.025,z),(x-w,y-.030,z),(x+w,y-.030,z),(x+w,y+.025,z)]
   curve('Pespunte del bolsillo',[project(p) for p in outline],.0012,col,'#FFF2DF')
  if key=='jacket_denim':
   for sign in [-1,1]:
    x=sign*.045;outline=[(x,top-.020,front),(x+sign*.055,top-.025,front),(x+sign*.040,top-.09,front)]
    lapel=mesh('Panel · Solapa denim',[project(p) for p in outline],[(0,1,2)],col,'#91B6D6');solid(lapel,.003)
  else:
   for sign in [-1,1]:
    for j in range(14):
     y=bottom+(top-bottom)*j/13;pos=project((sign*.018,y,front));sphere('Ribete de borreguito',pos,(.012,.012,.009),col,'#FFF2DF')
 elif key=='dress_petal':
  waist_y=center[1]+.045
  waist=[seam((x,waist_y,z)) for x,_,z in rows[M//2]];curve('Cintura del vestido',waist,.004,col,'#F05280',True)
  for layer in range(2):
   upper=waist_y-layer*.075;lower=max(bottom-.008,upper-.12);pts=[];faces=[];ruffle_rows=[];segments=64;bands=10
   for j in range(bands+1):
    t=j/bands;y=upper+(lower-upper)*t;row=[]
    for i in range(segments):
     a=i*math.tau/segments;r=radius(y,a)+.008+.055*t+.007*math.sin(a*12)*t
     row.append((center[0]+r*math.sin(a),y+.004*math.cos(a*12)*t,center[2]+r*math.cos(a)))
    ruffle_rows.append(row);pts.extend(row)
   for j in range(bands):
    for i in range(segments):a=j*segments+i;b=j*segments+(i+1)%segments;faces.append((a,b,b+segments,a+segments))
   skirt=mesh('Volante pétalo · '+str(layer),pts,faces,col,config['items'][key]['color']);solid(skirt,.004)
   curve('Bajo del volante',ruffle_rows[-1],.0025,col,'#F5A4B3',True)
   skirt_project=surface_projector(skirt,.0015)
   for i in range(5):
    a=-.95+i*.475;y=(upper+lower)/2;r=radius(y,a)+.04
    flower((center[0]+r*math.sin(a),y,center[2]+r*math.cos(a)),.011,col,skirt_project)
  for sign in [-1,1]:
   pos=project((center[0]+sign*.026,waist_y+.006,front));sphere('Lazo de cintura',pos,(.029,.018,.009),col,'#F5A4B3')
  pos=project((center[0],waist_y+.006,front));sphere('Nudo del lazo',pos,(.010,.013,.009),col,'#F05280')
 else:
  for sign in [-1,1]:curve('Cordón',[project((sign*(.035+.003*j/12),top-.022-.078*j/12,front)) for j in range(13)],.002,col,'#FFF2DF')
  # A folded hood rests behind the neck rather than clipping through the head.
  sphere('Capucha recogida',(0,top-.035,center[2]-(high[2]-low[2])*.43),(.13,.07,.065),col,'#BAA2DB')
  pocket=panel('Bolsillo canguro',center[0]-.10,center[0]+.10,center[1]-.08,center[1]-.01,front,col,'#BAA2DB',project)
  heart((center[0],center[1]-.037,front),.050,col,'#F5A4B3',surface_projector(pocket,.002))
  curve('Bolsillo canguro',[project(p) for p in [(center[0]-.10,center[1]-.01,front),(center[0]-.10,center[1]-.08,front),(center[0]+.10,center[1]-.08,front),(center[0]+.10,center[1]-.01,front)]],.0011,col,'#FFF2DF')
def save_editable_master(path):
 # Blender blocks saving directly over an appended library's source file.
 # Every appended part is local; save atomically beside it and keep a backup.
 path=path.resolve()
 if any(Path(library.filepath).resolve()==path for library in bpy.data.libraries):
  temporary=path.with_name(path.stem+'-saving.blend')
  bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(temporary),compress=True)
  if path.exists():shutil.copy2(path,path.with_suffix('.blend1'))
  temporary.replace(path)
 else:
  bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(path),compress=True)

def build():
 global active_fabric,reports
 for species in ['penguin','bear','pig','chick']:
  if selected_species and species not in selected_species:continue
  data=json.loads((D/(species+'.json')).read_text());ref=bpy.data.collections.new(species+' · referencia');scene.collection.children.link(ref);cutter,tree=collider(data,ref)
  for key,item in config['items'].items():
   if selected_items and key not in selected_items:continue
   if not item.get('visible',True):continue
   active_fabric=item.get('fabric','cotton')
   col=bpy.data.collections.new(key+' · '+species);scene.collection.children.link(col)
   if item['slot']=='pet_head':head_piece(key,species,col,data,cutter)
   else:body_piece(key,species,col,data,tree)
   col['embroidery_clearance_v1']=True
   col['embroidery_clearance_v2']=True
   col['visor_curve_v1']=True
   bpy.ops.object.select_all(action='DESELECT')
   for o in col.objects:o.hide_set(False);o.select_set(True)
   bpy.context.view_layer.objects.active=list(col.objects)[0]
   bpy.ops.object.convert(target='MESH')
   bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
   for o in col.objects:
    if o.type!='MESH' or o.data.uv_layers:continue
    fabric_uv(o.data,True)
   path=OUT/(key+'_'+species+'_pattern.glb');bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
   if item['slot']=='pet_body':add_skin_attributes(path,data)
   reports.append({'item_key':key,'species':species,'path':'assets/runner/accessories/'+path.name,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
   col.hide_viewport=True
   for o in col.objects:o.hide_render=True
   print('PATTERN',key,species,flush=True)
  ref.hide_viewport=True
 scene['catalog']='design/blender/wardrobe-patterns.json';scene['status']='Experimental review; not approved for sale'
 # Open on a useful editable pattern, not an empty scene or overlapping outfits.
 for name in ['penguin · referencia','shirt_love · penguin']:
  col=bpy.data.collections.get(name)
  if not col:continue
  col.hide_viewport=False
  for o in col.objects:o.hide_set(False);o.hide_render=False
 for screen in bpy.data.screens:
  for area in screen.areas:
   if area.type=='VIEW_3D':
    area.spaces.active.shading.type='MATERIAL';view=area.spaces.active.region_3d;view.view_location=(0,0,.65);view.view_distance=2.4
 if partial:
  refreshed={(v['item_key'],v['species']) for v in reports}
  reports.extend(v for entry in previous_catalog for v in entry['variants'] if (v['item_key'],v['species']) not in refreshed)
  # Retain every unedited collection in the editable master on partial builds.
  master=D/'NIDO-patronaje-prendas.blend'
  if master.exists():
   with bpy.data.libraries.load(str(master),link=False) as (old,new):new.collections=[name for name in old.collections if name not in bpy.data.collections]
   for collection in new.collections:
    if collection:scene.collection.children.link(collection)
 save_editable_master(D/'NIDO-patronaje-prendas.blend')
 catalog=[]
 for key,item in config['items'].items():
  variants=[v for v in reports if v['item_key']==key]
  if not variants:continue
  appearance={'style':key,'color':item['color'],'species_models':{v['species']:v['path'] for v in variants},'model_asset':next(v['path'] for v in variants if v['species']=='penguin'),'fitted_model_space':True}
  if item['slot']=='pet_head':appearance['tuck_crown_tuft']=True
  else:appearance['skinned_model_space']=True
  catalog.append({'item_key':key,**item,'equip_slot':item['slot'],'appearance':appearance,'preview_only':True,'variants':variants})
 (R/'assets/runner/blender-wardrobe-models.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2),encoding='utf-8')
 print('WARDROBE_READY',len(reports),flush=True)

if __name__=='__main__':build()
