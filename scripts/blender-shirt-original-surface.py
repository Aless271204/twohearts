"""Build a garment pattern from the actual original mascot surface.
Edits only the new cloth. Never edits or exports a replacement pet.
"""
import bpy,bmesh,json,math,sys,hashlib,importlib.util
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts'))
from wardrobe_gltf import add_skin_attributes
spec=importlib.util.spec_from_file_location('base',ROOT/'scripts/blender-restart-wardrobe.py');base=importlib.util.module_from_spec(spec);spec.loader.exec_module(base)
sp=sys.argv[sys.argv.index('--species')+1] if '--species' in sys.argv else 'penguin'
data=json.loads((ROOT/'design/wardrobe-restart/fitting'/f'{sp}-original.json').read_text(encoding='utf-8'))
patterns=json.loads((ROOT/'design/wardrobe-restart/original-shirt-patterns.json').read_text(encoding='utf-8'));pattern=patterns['species'][sp]
bpy.ops.wm.read_factory_settings(use_empty=True)
cream=base.material('AlgodÃ³n crema grueso','#FFF1DD',.92,True);thread=base.material('Pespunte crema','#DCCAB1',.93);coral=base.material('Bordado coral','#EC6276',.93)
points=[];faces=[]
for m in data['meshes']:
    offset=len(points);points.extend(tuple(m['positions'][i:i+3]) for i in range(0,len(m['positions']),3));faces.extend(tuple(offset+k for k in m['indices'][i:i+3]) for i in range(0,len(m['indices']),3))
hem=pattern['hem'];neck=pattern['neck'];cuff=pattern['cuff_cut_x'];body_half=max(abs(data['body']['min'][0]),abs(data['body']['max'][0]))+.010
# Sew a smooth eased torso from the original dimensions, rather than duplicating
# the mascot's arm/leg junctions into cloth. This leaves the pet completely intact.
cz=(data['body']['min'][2]+data['body']['max'][2])/2
if pattern.get('sleeve_shape')=='casual':
    vertices=[];polygons=[];rows=40;segments=80
    for j in range(rows+1):
        t=j/rows;y=hem-.025+t*(neck+.018-(hem-.025))
        width=pattern['torso_half_width']*(.96+.04*math.sin(math.pi*t))
        depth=pattern['torso_depth_radius']*(1-.10*t*t)
        for i in range(segments):
            a=i*math.tau/segments;vertices.append((width*math.cos(a),y,cz+depth*math.sin(a)))
    for j in range(rows):
        for i in range(segments):polygons.append((j*segments+i,(j+1)*segments+i,(j+1)*segments+(i+1)%segments,j*segments+(i+1)%segments))
    polygons.extend((tuple(range(segments)),tuple(reversed([rows*segments+i for i in range(segments)]))))
    cloth=base.mesh('Torso de camiseta casual con hombros caídos',vertices,polygons,cream)
else:
    cloth=base.sphere('Molde textil del torso original',(0,pattern['torso_y'],cz),(pattern['torso_half_width'],pattern['torso_height_radius'],pattern['torso_depth_radius']),cream)
bpy.context.view_layer.objects.active=cloth;sub=cloth.modifiers.new('Volumen de algodón suave','SUBSURF');sub.levels=2;bpy.ops.object.modifier_apply(modifier=sub.name)
# Independently tailored upper sleeves provide actual enclosed armholes.
parts=[cloth]
for sign in (-1,1):
    if pattern.get('sleeve_shape')=='casual':
        start=Vector(pattern['sleeve_start']);end=Vector(pattern['sleeve_end'])
        axis=(end-start).normalized();cross=Vector((-axis.y,axis.x,0)).normalized()
        vertices=[];polygons=[];rows=32;segments=48
        for j in range(rows+1):
            t=j/rows;center=start.lerp(end,t)
            # A relaxed, slightly tapered sleeve, not a spherical shoulder pad.
            taper=(1-.12*t)*max(.02,min(1,t/.14,(1-t)/.12))**.5
            for i in range(segments):
                a=i*math.tau/segments
                point=center+cross*(pattern['sleeve_width']*taper*math.cos(a))+Vector((0,0,pattern['sleeve_depth']*taper*math.sin(a)))
                vertices.append((sign*point.x,point.y,point.z))
        for j in range(rows):
            for i in range(segments):polygons.append((j*segments+i,j*segments+(i+1)%segments,(j+1)*segments+(i+1)%segments,(j+1)*segments+i))
        polygons.extend((tuple(reversed(range(segments))),tuple(rows*segments+i for i in range(segments))))
        if sign<0:polygons=[tuple(reversed(face)) for face in polygons]
        parts.append(base.mesh('Manga corta casual de algodón',vertices,polygons,cream))
    else:
        parts.append(base.sphere('Manga con holgura sobre brazo original',(sign*pattern['sleeve_center'][0],*pattern['sleeve_center'][1:]),tuple(pattern['sleeve_radius']),cream))
bpy.ops.object.select_all(action='DESELECT')
for part in parts:part.select_set(True)
bpy.context.view_layer.objects.active=cloth;bpy.ops.object.join();bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
remesh=cloth.modifiers.new('Molde continuo exclusivamente de tela','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.006;remesh.use_smooth_shade=True;bpy.ops.object.modifier_apply(modifier=remesh.name)
smooth=cloth.modifiers.new('Caída suave del algodón','SMOOTH');smooth.factor=.45;smooth.iterations=4;bpy.ops.object.modifier_apply(modifier=smooth.name)
print('CLOTH_MOULD',len(cloth.data.vertices),len(cloth.data.polygons),flush=True)
# Cut the central neck only; preserve the round, closed crowns of the sleeves.
bpy.ops.mesh.primitive_cylinder_add(vertices=64,radius=pattern['neck_cut_radius'],depth=1.5,location=base.C@Vector((0,neck+.75,cz)))
neck_cutter=bpy.context.object;base.subtract(cloth,neck_cutter);bpy.data.objects.remove(neck_cutter,do_unlink=True)
bm=bmesh.new();bm.from_mesh(cloth.data)
def open_edge(point,normal,outer=True):
    bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.000001,plane_co=base.C@Vector(point),plane_no=base.C@Vector(normal),clear_outer=outer,clear_inner=not outer)
open_edge((0,hem,0),(0,1,0),False)
neck_caps={f for f in bm.faces if all(abs((base.CI@v.co).y-neck)<.00003 for v in f.verts)}
central=[]
while neck_caps:
    seed=neck_caps.pop();component={seed};stack=[seed]
    while stack:
        face=stack.pop()
        for edge in face.edges:
            for other in edge.link_faces:
                if other in neck_caps:neck_caps.remove(other);component.add(other);stack.append(other)
    verts={v for f in component for v in f.verts}
    if min(v.co.x for v in verts)<0<max(v.co.x for v in verts):central.extend(component)
bmesh.ops.delete(bm,geom=central,context='FACES')
casual_axis=(Vector(pattern['sleeve_end'])-Vector(pattern['sleeve_start'])).normalized() if pattern.get('sleeve_shape')=='casual' else None
for sign in (-1,1):
    normal=(sign,-.65,0)
    open_edge((sign*cuff,pattern['cuff_cut_y'],0),normal)
bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00002);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(cloth.data);bm.free();cloth.data.update()
# Offset and free the lower panel. This changes the garment, never the pet.
torso_faces=[];source_offset=0
for source in data['meshes']:
    for i in range(0,len(source['indices']),3):
        tri=source['indices'][i:i+3];weight=0;limb_weight=0
        for index in tri:
            weight+=sum(w for bone,w in zip(source['skinIndex'][index*4:index*4+4],source['skinWeight'][index*4:index*4+4]) if data['boneNames'][bone].endswith(('Hips','Spine','Spine1','Spine2','Neck')))/3
            limb_weight+=sum(w for bone,w in zip(source['skinIndex'][index*4:index*4+4],source['skinWeight'][index*4:index*4+4]) if data['boneNames'][bone].endswith(('Arm','ForeArm','Hand','HandMiddle','Leg','UpLeg','Foot','ToeBase')))/3
        center_y=sum(source['positions'][index*3+1] for index in tri)/3
        # A wing at the same height is not part of the chest's cloth mould.
        # Including it pulled isolated sleeve/hem vertices into pointed flaps.
        if limb_weight<.25 and (weight>.45 or hem-.04<center_y<neck+.035):torso_faces.append(tuple(index+source_offset for index in tri))
    source_offset+=len(source['positions'])//3
torso_tree=BVHTree.FromPolygons([Vector(q) for q in points],torso_faces,all_triangles=True)
cloth_normals=[v.normal.copy() for v in cloth.data.vertices]
for v,n_original in zip(cloth.data.vertices,cloth_normals):
    original=base.CI@v.co;q=original.copy();n=base.CI.to_3x3()@n_original;q+=n*(.027 if abs(original.x)<body_half else .014)
    if abs(original.y-neck)<.00003:q.y=neck+.003
    if abs(original.y-hem)<.00003:q.y=hem-.002
    if abs(q.x)<body_half+.004 and q.y<.405:
        t=max(0,min(1,(.405-q.y)/(.405-hem)));t=t*t*(3-2*t);cz=(data['body']['min'][2]+data['body']['max'][2])/2
        rx=pattern['torso_half_width']+.016;rz=pattern['torso_depth_radius']+.008;r=math.sqrt((q.x/rx)**2+((q.z-cz)/rz)**2)
        if r>.01:scale=1+(1/r-1)*t;q.x*=scale;q.z=cz+(q.z-cz)*scale
    # Minimum clearance from the real textured torso, preserving the garment's
    # existing ease. Ray sampling keeps neck/hem heights and intentional holes.
    if not casual_axis and abs(q.x)<pattern['sleeve_full'] and q.y<=neck+.006:
        origin=Vector((0,q.y,cz));radial=q-origin
        if radial.length>.01:
            direction=radial.normalized();hit,_,_,distance=torso_tree.ray_cast(origin,direction,1)
            if hit is not None and radial.length<distance+.024:q=origin+direction*(distance+.024)
    v.co=base.C@q
cloth.data.update()
# Ease the interior after clearance sampling, keeping all four rims fixed.
bm=bmesh.new();bm.from_mesh(cloth.data)
interior=[v for v in bm.verts if not v.is_boundary]
for _ in range(4):bmesh.ops.smooth_vert(bm,verts=interior,factor=.25,use_axis_x=True,use_axis_y=True,use_axis_z=True)
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(cloth.data);bm.free();cloth.data.update()
# Close minute voxel punctures after offset, when their contours are measurable.
bm=bmesh.new();bm.from_mesh(cloth.data);remaining={e for e in bm.edges if e.is_boundary}
while remaining:
    seed=remaining.pop();component={seed};stack=[seed]
    while stack:
        edge=stack.pop()
        for v in edge.verts:
            for other in v.link_edges:
                if other in remaining:remaining.remove(other);component.add(other);stack.append(other)
    verts={v for e in component for v in e.verts}
    if max(max(v.co[k] for v in verts)-min(v.co[k] for v in verts) for k in range(3))<.002:
        first=next(iter(verts));current=first;previous=None;ordered=[]
        while True:
            ordered.append(current)
            nxt=next(e.other_vert(current) for e in current.link_edges if e in component and e.other_vert(current)!=previous)
            previous,current=current,nxt
            if current==first:break
        linked={f for v in ordered for f in v.link_faces}
        if linked and all(set(f.verts).issubset(set(ordered)) for f in linked):
            bmesh.ops.delete(bm,geom=ordered,context='VERTS')
        else:
            bm.faces.new(ordered)
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(cloth.data);bm.free();cloth.data.update()
bm=bmesh.new();bm.from_mesh(cloth.data);bm.verts.ensure_lookup_table();remaining={e for e in bm.edges if e.is_boundary};loops=[]
while remaining:
    seed=remaining.pop();component={seed};stack=[seed]
    while stack:
        e=stack.pop()
        for v in e.verts:
            for other in v.link_edges:
                if other in remaining:remaining.remove(other);component.add(other);stack.append(other)
    vertices={v for e in component for v in e.verts}
    if any(sum(e in component for e in v.link_edges)!=2 for v in vertices):raise ValueError('El patrÃ³n original presenta una costura rota')
    first=next(iter(vertices));current=first;previous=None;loop=[]
    while True:
        loop.append(tuple(base.CI@current.co));next_vertex=next(e.other_vert(current) for e in current.link_edges if e in component and e.other_vert(current)!=previous)
        previous,current=current,next_vertex
        if current==first:break
        if len(loop)>len(vertices):raise ValueError('Borde de tejido no cerrado')
    loops.append(loop)
bm.free()
print('ORIGINAL_PATTERN_LOOPS',len(loops),[len(l) for l in loops],flush=True)
for l in loops:print('LOOP_BOUNDS', [min(p[k] for p in l) for k in range(3)],[max(p[k] for p in l) for k in range(3)],flush=True)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'outputs'/f'original-pattern-debug-{sp}.blend'),compress=True)
if len(loops)!=4:raise ValueError('Se requieren cuello, bajo y dos puÃ±os sin bordes adicionales')
# Tailor the mouths along the flipper, not out of the side of the head.
# Move the final sleeve section continuously; never leave a detached cuff ring.
cuff_areas=[]
for loop in loops:
    old_center=sum((Vector(q) for q in loop),Vector())/len(loop)
    if abs(old_center.x)<.25:continue
    sign=1 if old_center.x>0 else -1
    if casual_axis:
        cuff_areas.append({'center':list(old_center),'normal':list(Vector((sign,-.65,0)).normalized())})
        continue
    old_normal=Vector((sign,-.65,0)).normalized();new_normal=Vector((sign*.35,-1,0)).normalized()
    turn=old_normal.rotation_difference(new_normal);new_center=Vector((sign*pattern['cuff_center'][0],*pattern['cuff_center'][1:]))
    boundary={tuple(round(value,6) for value in q) for q in loop}
    for vertex in cloth.data.vertices:
        q=base.CI@vertex.co
        if sign*q.x<.235:continue
        distance=(q-old_center).dot(old_normal)
        amount=max(0.0,min(1.0,(.085+distance)/.085));amount=amount*amount*(3-2*amount)
        target=new_center+turn@(q-old_center)
        if tuple(round(value,6) for value in q) in boundary:
            amount=1;target-=new_normal*(target-new_center).dot(new_normal)
        if amount:q=q.lerp(target,amount);vertex.co=base.C@q
    cuff_areas.append({'center':list(new_center),'normal':list(new_normal)})
cloth.data.update()
bm=bmesh.new();bm.from_mesh(cloth.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(cloth.data);bm.free()
# Refresh rim positions for the folded hem and double stitching.
loops=[];bm=bmesh.new();bm.from_mesh(cloth.data);remaining={e for e in bm.edges if e.is_boundary}
while remaining:
    seed=remaining.pop();component={seed};stack=[seed]
    while stack:
        edge=stack.pop()
        for v in edge.verts:
            for other in v.link_edges:
                if other in remaining:remaining.remove(other);component.add(other);stack.append(other)
    first=seed.verts[0];current=first;previous=None;loop=[]
    while True:
        loop.append(tuple(base.CI@current.co));nxt=next(e.other_vert(current) for e in current.link_edges if e in component and e.other_vert(current)!=previous)
        previous,current=current,nxt
        if current==first:break
    loops.append(loop)
bm.free()
uv=cloth.data.uv_layers.active or cloth.data.uv_layers.new(name='UVMap')
for f in cloth.data.polygons:
    for li in f.loop_indices:
        q=base.CI@cloth.data.vertices[cloth.data.loops[li].vertex_index].co;uv.data[li].uv=(math.atan2(q.x,q.z+.025)*.23/.32,q.y/.32)
# Clothing coverage is measured against the actual closed outer envelope.
# It never edits the pet file: only fully covered triangles may be skipped
# while this item is equipped, and the renderer restores them on removal.
envelope=bmesh.new();envelope.from_mesh(cloth.data)
bmesh.ops.holes_fill(envelope,edges=[e for e in envelope.edges if e.is_boundary],sides=0)
envelope_tree=BVHTree.FromBMesh(envelope);ray=(base.C@Vector((.973,.19,.11))).normalized()
def inside_garment(point):
    origin=base.C@Vector(point);hits=0
    for _ in range(16):
        hit,_,_,_=envelope_tree.ray_cast(origin,ray,3)
        if hit is None:return hits%2==1
        hits+=1;origin=hit+ray*.00005
    raise ValueError('Invalid garment envelope ray')
coverage={}
for source in data['meshes']:
    contained=[inside_garment(source['positions'][i:i+3]) for i in range(0,len(source['positions']),3)]
    triangles=[]
    for i in range(0,len(source['indices']),3):
        tri=source['indices'][i:i+3]
        arm_weight=0.0
        for vertex in tri:
            for bone,weight in zip(source['skinIndex'][vertex*4:vertex*4+4],source['skinWeight'][vertex*4:vertex*4+4]):
                if data['boneNames'][bone].endswith(('Arm','ForeArm')):arm_weight+=weight/3
        if all(contained[k] for k in tri) or arm_weight>.30 and any(contained[k] for k in tri):triangles.extend(tri)
    coverage[source['name']]=triangles
envelope.free()
print('GEOMETRIC_COVERAGE', {k:len(v)//3 for k,v in coverage.items()},flush=True)
(ROOT/'assets/runner/restart'/f'shirt-original-coverage-{sp}.json').write_text(json.dumps(coverage),encoding='utf-8')
surface_positions=[base.CI@v.co for v in cloth.data.vertices]
surface_normals=[base.CI.to_3x3()@v.normal for v in cloth.data.vertices]
surface_faces=[list(f.vertices) for f in cloth.data.polygons]
tree=BVHTree.FromPolygons(surface_positions,surface_faces);base.solid(cloth,.010);parts=[cloth];stitch_segments=[]
for loop in loops:
    cy=sum(q[1] for q in loop)/len(loop);cx=sum(q[0] for q in loop)/len(loop)
    inward=Vector((-1 if cx>0 else 1,.65,0)).normalized() if abs(cx)>.25 else Vector((0,-1 if cy>.49 else 1,0))
    bp=[];bn=[];bf=[];n=len(loop);rows=6
    for row in range(rows+1):
        t=row/rows
        for q in loop:
            target=Vector(q)+inward*.024*t
            if abs(cx)<.25:
                origin=Vector((0,target.y,cz));direction=Vector((q[0],0,q[2]-cz)).normalized()
                hit,normal,face_index,_=tree.ray_cast(origin,direction,1)
                if hit is None:hit,normal,face_index,_=tree.find_nearest(target)
            else:hit,normal,face_index,_=tree.find_nearest(target)
            # Interpolate smooth vertex normals. Using each voxel face normal
            # extruded alternating triangles into a jagged, frayed-looking rim.
            smooth_normal=Vector();total=0.0
            for vi in surface_faces[face_index]:
                distance=(surface_positions[vi]-hit).length
                weight=1/max(.00001,distance)
                smooth_normal+=surface_normals[vi]*weight;total+=weight
            normal=(smooth_normal/total).normalized()
            # The underside of a 3 mm binding must clear the outer 5 mm half
            # of the cloth shell. Overlap here caused flickering torn edges.
            bp.append(tuple(hit+normal*(.010+.003*math.sin(math.pi*t))));bn.append(normal)
    for row in range(rows):
        for i in range(n):bf.append((row*n+i,row*n+(i+1)%n,(row+1)*n+(i+1)%n,(row+1)*n+i))
    band=base.mesh('Dobladillo ancho adaptado',bp,bf,cream);base.solid(band,.003);parts.append(band)
    for row in (1,5):
        for i in range(0,n,3):
            stitch_segments.append([tuple(Vector(bp[row*n+k])+bn[row*n+k]*.0025) for k in (i,(i+1)%n)])
curve=bpy.data.curves.new('Pespuntes dobles completos','CURVE');curve.dimensions='3D';curve.bevel_depth=.001;curve.bevel_resolution=2
for segment in stitch_segments:
    spline=curve.splines.new('POLY');spline.points.add(1)
    for point,position in zip(spline.points,segment):point.co=(*(base.C@Vector(position)),1)
stitches=bpy.data.objects.new('Hilo continuo de acabados',curve);bpy.context.collection.objects.link(stitches);curve.materials.append(thread)
bpy.ops.object.select_all(action='DESELECT');stitches.select_set(True);bpy.context.view_layer.objects.active=stitches;bpy.ops.object.convert(target='MESH');parts.append(stitches)
# Raised heart: support every ring on the new cloth, not on a screen plane.
count=64;rings=7;hp=[];hf=[]
for row in range(1,rings+1):
    r=row/rings
    for i in range(count):
        a=i*math.tau/count;x=.16*r*16*math.sin(a)**3/32;y=pattern['heart_y']+.16*r*(13*math.cos(a)-5*math.cos(2*a)-2*math.cos(3*a)-math.cos(4*a))/32;hit,_,_,_=tree.ray_cast(Vector((x,y,1)),Vector((0,0,-1)))
        if hit is None:raise ValueError('CorazÃ³n fuera del tejido original')
        hp.append((x,y,hit.z+.007+.002*(1-r*r)))
hf.append(tuple(reversed(range(count))))
for row in range(rings-1):
    for i in range(count):hf.append((row*count+i,row*count+(i+1)%count,(row+1)*count+(i+1)%count,(row+1)*count+i))
heart=base.mesh('CorazÃ³n bordado',hp,hf,coral);base.solid(heart,.003);parts.append(heart)
# Keep textile and decorations separate: the latter inherit the cloth's field.
cloth.name='Manga adaptada - Camiseta original continua';cloth.data.name=cloth.name
bm=bmesh.new();bm.from_mesh(cloth.data)
invalid=[e for e in bm.edges if not e.is_manifold]
if invalid:raise ValueError('La tela con grosor tiene bordes abiertos o no manifold: '+str(len(invalid)))
bm.free()
data['garment_skin_profile']={'shoulder_start':pattern['shoulder_start'],'sleeve_full':pattern['sleeve_full'],'sleeve_min_y':pattern['sleeve_min_y'],'sleeve_fade_y':.06,'preserve_torso_surface':True,'stable_torso':True,'sleeve_original_surface':False,'surface_sleeve_anchors':True,'volumetric_sleeves':{'center':pattern['sleeve_center'],'radius':pattern['sleeve_radius']},'cuff_areas':cuff_areas}
path=ROOT/'assets/runner/accessories'/f'original_surface_shirt_{sp}.glb'
staging=path.with_name(path.stem+'.building.glb');base.export_selected(staging,parts,False);add_skin_attributes(staging,data);staging.replace(path)
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'design/wardrobe-restart/models'/f'CAMISETA-SUPERFICIE-ORIGINAL-{sp}.blend'),compress=True)
(ROOT/'outputs'/f'original-surface-shirt-{sp}.json').write_text(json.dumps({'asset':path.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'edge_loops':len(loops),'vertices':len(cloth.data.vertices)},indent=2));print('ORIGINAL_SURFACE_SHIRT_READY',flush=True)

registry_path=ROOT/'assets/runner/restart/catalog.json'
registry=json.loads(registry_path.read_text(encoding='utf-8'))
entry=next(i for i in registry['wardrobe'] if i['item_key']=='shirt_love')
variant=next((v for v in entry['variants'] if v['species']==sp),None)
if variant is None:variant={'species':sp};entry['variants'].append(variant)
variant.update(original_asset=path.relative_to(ROOT).as_posix(),original_sha256=hashlib.sha256(path.read_bytes()).hexdigest(),fit_status='experimental_pending_visual_review',coverage_asset=f'assets/runner/restart/shirt-original-coverage-{sp}.json')
registry_path.write_text(json.dumps(registry,ensure_ascii=False,indent=2),encoding='utf-8')
