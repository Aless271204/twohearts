"""New continuous sewn shirt, independently editable, on the R2 mascot rig.
No rejected meshes are reused. The surface is joined before cuffs are opened.
"""
import bpy,bmesh,json,math,hashlib,sys,importlib.util
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('restart',ROOT/'scripts/blender-restart-wardrobe.py')
base=importlib.util.module_from_spec(spec);spec.loader.exec_module(base)
pattern=json.loads((ROOT/'design/wardrobe-restart/garment-patterns.json').read_text())['shirt_love']
names=list(pattern['species'])
if '--species' in sys.argv:names=[sys.argv[sys.argv.index('--species')+1]]
OUT=ROOT/'assets/runner/restart';MASTER=ROOT/'design/wardrobe-restart/models'

def boundary_loops(obj):
    bm=bmesh.new();bm.from_mesh(obj.data);bm.verts.ensure_lookup_table()
    adjacent={}
    for e in bm.edges:
        if e.is_boundary:
            a,b=[v.index for v in e.verts];adjacent.setdefault(a,[]).append(b);adjacent.setdefault(b,[]).append(a)
    if any(len(v)!=2 for v in adjacent.values()):raise ValueError('Un borde de costura no forma una vuelta cerrada')
    seen=set();loops=[]
    for start in adjacent:
        if start in seen:continue
        chain=[];current=start;previous=None
        while current not in seen:
            seen.add(current);chain.append(tuple(base.CI@bm.verts[current].co))
            previous,current=current,next(v for v in adjacent[current] if v!=previous)
        if current!=start:raise ValueError('Costura incompleta')
        loops.append(chain)
    bm.free();return loops

def make_shirt(sp,p,cream,thread,coral):
    cx,cy,cz=p['center'];rx,ry,rz=p['radius']
    fabric=pattern.get('fabric',{});swatch=fabric.get('texture_swatch',.20)
    body=base.sphere('Patrón nuevo · torso',(cx,cy,cz),(rx,ry,rz),cream)
    sleeve_parts=[]
    for sign in (-1,1):
        sleeve=base.sphere('Manga integrada',(sign*p['shoulder_x'],p['shoulder_y'],p.get('cuff_center_z',cz)),tuple(p.get('sleeve_radius',(.083,.105,.085))),cream)
        # Orient the sleeve along the compact mascot arm, not a human shoulder.
        sleeve.rotation_mode='QUATERNION';sleeve.rotation_quaternion=(base.C@Vector((0,1,0))).rotation_difference(base.C@Vector((-sign*.5,.866,0)))
        bpy.context.view_layer.objects.active=sleeve;bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
        sleeve_parts.append(sleeve)
        if p.get('shoulder_lift'):
            bridge=base.sphere('Panel continuo de hombro',(sign*.19,.470,p.get('cuff_center_z',cz)),(.110,.074,.120),cream)
            sleeve_parts.append(bridge)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [body,*sleeve_parts]:obj.select_set(True)
    bpy.context.view_layer.objects.active=body;bpy.ops.object.join()
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    rounded=body.modifiers.new('Patrón de algodón redondeado','SUBSURF');rounded.levels=2
    bpy.ops.object.modifier_apply(modifier=rounded.name)
    remesh=body.modifiers.new('Unión continua de hombros y mangas','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.005;remesh.adaptivity=0;remesh.use_smooth_shade=True
    bpy.ops.object.modifier_apply(modifier=remesh.name)
    smooth=body.modifiers.new('Tela acolchada sin aristas','SMOOTH');smooth.factor=.55;smooth.iterations=5;bpy.ops.object.modifier_apply(modifier=smooth.name)
    # Open only the four intentional garment edges; shoulders remain connected.
    bm=bmesh.new();bm.from_mesh(body.data)
    def cut(point,normal,outer=False,inner=False):
        bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.000001,plane_co=base.C@Vector(point),plane_no=base.C@Vector(normal),clear_outer=outer,clear_inner=inner)
    cut((0,p['neck'],0),(0,1,0),outer=True)
    cut((0,p['hem'],0),(0,1,0),inner=True)
    for sign in (-1,1):cut((sign*p['cuff_x'],p['cuff_y'],cz),(sign,-.35,0),outer=True)
    # Taller real shoulders cross the neckline plane. Close their two top caps;
    # keep the central neck, hem and cuff openings as the four intended borders.
    if p.get('original_fit') and p.get('shoulder_lift'):
        remaining={e for e in bm.edges if e.is_boundary}
        while remaining:
            seed=remaining.pop();component={seed};stack=[seed]
            while stack:
                edge=stack.pop()
                for vertex in edge.verts:
                    for neighbor in vertex.link_edges:
                        if neighbor in remaining:remaining.remove(neighbor);component.add(neighbor);stack.append(neighbor)
            vertices={v for e in component for v in e.verts}
            center=sum((base.CI@v.co for v in vertices),Vector())/len(vertices)
            if abs(center.x)>.18 and center.y>p['neck']-.005:bmesh.ops.holes_fill(bm,edges=list(component),sides=0)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(body.data);bm.free()
    loops=boundary_loops(body)
    if len(loops)!=4:raise ValueError(f'{sp}: se esperaban cuello, bajo y dos puños; hay {len(loops)} bordes')
    # Close the roomy sleeve mouth onto the actual compact flipper section.
    # The cuff is a connected fabric loft, not a floating trim around a hole.
    points=[tuple(base.CI@v.co) for v in body.data.vertices];faces=[tuple(f.vertices) for f in body.data.polygons]
    if p.get('shoulder_lift'):
        for i,q in enumerate(points):
            q=Vector(q);blend=max(0,min(1,(abs(q.x)-.18)/.065))*max(0,min(1,(q.y-.465)/.04))
            q.y+=p['shoulder_lift']*blend;points[i]=tuple(q)
        # Keep boundary coordinates in sync with the adjusted shoulder surface.
        for v,q in zip(body.data.vertices,points):v.co=base.C@Vector(q)
        body.data.update();loops=boundary_loops(body)
    lookup=KDTree(len(points))
    for i,q in enumerate(points):lookup.insert(Vector(q),i)
    lookup.balance()
    rim_loops=[]
    for loop in loops:
        center=sum((Vector(q) for q in loop),Vector())/len(loop)
        if abs(center.x)<.10:
            rim_loops.append(loop);continue
        sign=1 if center.x>0 else -1
        original_indices=[lookup.find(Vector(q))[1] for q in loop]
        # Trim the low corners of the angled sleeve opening beneath the cuff.
        cuff_height=p['cuff_y']+.020
        for index in original_indices:
            q=Vector(points[index]);q.y=max(q.y,cuff_height);points[index]=tuple(q)
        loop=[points[index] for index in original_indices]
        previous=original_indices
        final=[]
        angles=[math.atan2(q[2]-center.z,q[1]-center.y) for q in loop]
        turn=sum((angles[(i+1)%len(angles)]-a+math.pi)%math.tau-math.pi for i,a in enumerate(angles))
        direction=1 if turn>0 else -1
        for step in range(1,5):
            t=step/4;row=[];final=[]
            for i,q in enumerate(loop):
                a=angles[0]+direction*i*math.tau/len(loop)
                crx,crz=p.get('cuff_radius',(.064,.083));ccz=p.get('cuff_center_z',cz)
                target=Vector((sign*(p['shoulder_x']+crx*math.cos(a)),p['cuff_y']+.020,ccz+crz*math.sin(a)))
                v=Vector(q).lerp(target,t)
                row.append(len(points));points.append(tuple(v));final.append(tuple(v))
            for i in range(len(loop)):faces.append((previous[i],previous[(i+1)%len(loop)],row[(i+1)%len(loop)],row[i]))
            previous=row
        rim_loops.append(final)
    replacement=base.mesh('Camiseta · mangas cerradas sobre las alas',points,faces,cream)
    bpy.data.objects.remove(body,do_unlink=True);body=replacement;loops=rim_loops
    bm=bmesh.new();bm.from_mesh(body.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(body.data);bm.free()
    if len(boundary_loops(body))!=4:raise ValueError('La manga nueva tiene una unión abierta')
    finish=body.modifiers.new('Unión suave del puño','SMOOTH');finish.factor=.35;finish.iterations=3
    bpy.context.view_layer.objects.active=body;bpy.ops.object.modifier_apply(modifier=finish.name)
    # Free-hanging lower panel: it bridges the belly instead of shrinking along it.
    # This is modeled drape, kept separate from bone attachment and cloth simulation.
    if 'loose_from' in p:
        for vertex in body.data.vertices:
            q=base.CI@vertex.co
            t=max(0,min(1,(p['loose_from']-q.y)/(p['loose_from']-p['hem'])))
            t=t*t*(3-2*t)
            r=math.sqrt(((q.x-cx)/rx)**2+((q.z-cz)/rz)**2)
            if t and r>.01:
                a=math.atan2((q.x-cx)/rx,(q.z-cz)/rz)
                fullness=1+p['hem_ease']+p['fold_depth']/rx*(math.sin(5*a+.35)+.4*math.sin(9*a))*t
                scale=1+(fullness/r-1)*t
                q.x=cx+(q.x-cx)*scale;q.z=cz+(q.z-cz)*scale
                q.y+=.0015*math.sin(3*a+.4)*t*t
                vertex.co=base.C@q
        body.data.update()
    loops=boundary_loops(body)
    body.name='Camiseta · hombros y mangas continuos'
    for f in body.data.polygons:f.use_smooth=True
    # Fabric UVs follow the rounded torso; no screen-space overlays.
    layer=body.data.uv_layers.new(name='UVMap')
    for f in body.data.polygons:
        angles=[]
        for i in f.vertices:
            q=base.CI@body.data.vertices[i].co;angles.append((math.atan2(q.x-cx,q.z-cz)/math.tau)%1)
        wraps=max(angles)-min(angles)>.5
        for li,a in zip(f.loop_indices,angles):
            q=base.CI@body.data.vertices[body.data.loops[li].vertex_index].co
            if wraps and a<.5:a+=1
            layer.data[li].uv=(a*math.tau*(rx+rz)/2/swatch,q.y/swatch)
    surface=BVHTree.FromPolygons([base.CI@v.co for v in body.data.vertices],[list(f.vertices) for f in body.data.polygons])
    def support(q):
        hit,normal,index,distance=surface.find_nearest(q)
        if hit is None:raise ValueError('El acabado no apoya en la tela')
        # Interpolated smooth normals prevent faceted offsets along a sewn band.
        smooth=Vector()
        for vi in body.data.polygons[index].vertices:
            v=body.data.vertices[vi]
            smooth+=(base.CI.to_3x3()@v.normal)/max(.000001,(base.CI@v.co-hit).length_squared)
        smooth.normalize()
        if smooth.dot(normal)<0:smooth=-smooth
        return hit,smooth
    thickness=fabric.get('thickness',.006)
    base.solid(body,thickness);parts=[body]
    for loop in loops:
        # A wide folded fabric band, not a cord stuck onto the garment edge.
        center=sum((Vector(q) for q in loop),Vector())/len(loop)
        sleeve_edge=abs(center.x)>.10
        width=fabric.get('cuff_width',.024) if sleeve_edge else fabric.get('band_width',.026)
        inward=Vector((0,-1 if not sleeve_edge and center.y>cy else 1,0))
        # Uniform spacing removes tiny irregular corners left by voxel cutting.
        original=[Vector(q) for q in loop];lengths=[(original[(i+1)%len(original)]-q).length for i,q in enumerate(original)]
        perimeter=sum(lengths);n=160;resampled=[];segment=0;travel=0
        for i in range(n):
            d=perimeter*i/n
            while segment<len(original)-1 and travel+lengths[segment]<d:travel+=lengths[segment];segment+=1
            resampled.append(original[segment].lerp(original[(segment+1)%len(original)],(d-travel)/max(.000001,lengths[segment])))
        for _ in range(2):resampled=[q*.6+(resampled[(i-1)%n]+resampled[(i+1)%n])*.2 for i,q in enumerate(resampled)]
        loop=resampled;rows=8;bp=[];bf=[];band_normals=[]
        for j in range(rows+1):
            t=j/rows
            for q in loop:
                if sleeve_edge:
                    sign=1 if center.x>0 else -1
                    crx,crz=p.get('cuff_radius',(.064,.083));ccz=p.get('cuff_center_z',cz)
                    a=math.atan2((q.z-ccz)/crz,(q.x-sign*p['shoulder_x'])/crx)
                    hit=Vector((sign*p['shoulder_x']+(crx+.008*t)*math.cos(a),p['cuff_y']+.020+width*t,ccz+(crz+.006*t)*math.sin(a)))
                    normal=Vector((math.cos(a),0,math.sin(a))).normalized()
                else:hit,normal=support(Vector(q)+inward*(width*t))
                offset=thickness/2+.002+fabric.get('band_loft',.004)*math.sin(math.pi*t)
                bp.append(tuple(hit+normal*offset));band_normals.append(normal)
        for j in range(rows):
            for i in range(n):bf.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
        band=base.mesh('Dobladillo ancho de algodón doblado',bp,bf,cream)
        uv=band.data.uv_layers.active
        for face in band.data.polygons:
            for li in face.loop_indices:
                vi=band.data.loops[li].vertex_index;row,col=divmod(vi,n)
                if col==0 and any(v%n==n-1 for v in face.vertices):col=n
                uv.data[li].uv=(perimeter*col/n/swatch,width*row/rows/swatch)
        base.solid(band,.003);parts.append(band)
        # Two complete parallel stitch lines on the folded band itself.
        stitch_points=[];stitch_faces=[]
        for row in (2,6):
            for i in range(n):
                a=Vector(bp[row*n+i]);b=Vector(bp[row*n+(i+1)%n])
                b=a.lerp(b,.55)
                normal=band_normals[row*n+i]
                a+=normal*.002;b+=normal*.002
                axis=(b-a).normalized();u=axis.cross(normal).normalized();v=axis.cross(u).normalized()
                radius=fabric.get('stitch_radius',.001);start=len(stitch_points);sides=8
                for end in (a,b):
                    for k in range(sides):stitch_points.append(tuple(end+radius*(u*math.cos(k*math.tau/sides)+v*math.sin(k*math.tau/sides))))
                for k in range(sides):stitch_faces.append((start+k,start+(k+1)%sides,start+sides+(k+1)%sides,start+sides+k))
                stitch_faces.extend((tuple(start+k for k in reversed(range(sides))),tuple(start+sides+k for k in range(sides))))
        parts.append(base.mesh('Doble pespunte regular del dobladillo',stitch_points,stitch_faces,thread))
    # A raised embroidered heart conforms to the actual shirt front.
    count=128;rings=10;hp=[];hf=[];heart_y=p.get('heart_y',cy+.01)
    for j in range(1,rings+1):
        r=j/rings
        for i in range(count):
            a=i*math.tau/count;x=.16*r*16*math.sin(a)**3/32
            y=heart_y+.16*r*(13*math.cos(a)-5*math.cos(2*a)-2*math.cos(3*a)-math.cos(4*a))/32
            hit,_,_,_=surface.ray_cast(Vector((x,y,cz+1)),Vector((0,0,-1)))
            if hit is None:raise ValueError('El bordado no apoya en la tela')
            hp.append((x,y,hit.z+thickness/2+.001+.0025*(1-r*r)))
    hf.append(tuple(reversed(range(count))))
    for j in range(rings-1):
        for i in range(count):hf.append((j*count+i,j*count+(i+1)%count,(j+1)*count+(i+1)%count,(j+1)*count+i))
    heart=base.mesh('Corazón bordado coral',hp,hf,coral);base.solid(heart,.002);parts.append(heart)
    edge=[tuple(Vector(v)+Vector((0,0,.001))) for v in hp[-count:]]
    parts.append(base.tube('Contorno bordado completo del corazón',edge,.0018,coral,True))
    for i in range(count):parts.append(base.tube('Hilo de bordado satinado',[tuple(Vector(hp[j*count+i])+Vector((0,0,.001))) for j in range(rings)],.00065,coral))
    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts:obj.select_set(True)
    bpy.context.view_layer.objects.active=body;bpy.ops.object.join()
    return body,{'edge_loops':len(loops),'vertices':len(body.data.vertices),'faces':len(body.data.polygons)}

reports=[]
for sp in names:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    pet_path=OUT/('pet_rig_r2_'+sp+'.glb');bpy.ops.import_scene.gltf(filepath=str(pet_path))
    rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
    if rig.animation_data:
        rig.animation_data.action=None
        for track in rig.animation_data.nla_tracks:track.mute=True
    bpy.context.scene.frame_set(0)
    cream=base.material('Algodón crema grueso',pattern['color'],.92,True)
    for node in cream.node_tree.nodes:
        if node.type=='NORMAL_MAP':node.inputs['Strength'].default_value=pattern.get('fabric',{}).get('normal_strength',.55)
    thread=base.material('Hilo de costura crema','#E2CFB7',.92)
    coral=base.material('Bordado coral suave','#F16B82',.9)
    p={**pattern['species'][sp]}
    if '--original-rig' in sys.argv:p.update(p.get('original_fit',{}))
    garment,qa=make_shirt(sp,p,cream,thread,coral)
    groups={name:garment.vertex_groups.new(name=name) for name in ('Body','LeftWing','RightWing')}
    for v in garment.data.vertices:
        q=base.CI@v.co
        x=max(0,min(1,(abs(q.x)-(p['shoulder_x']-.07))/.095))
        y=max(0,min(1,(q.y-(p['cuff_y']-.055))/.055))*max(0,min(1,(p['neck']-q.y)/.06))
        w=x*x*(3-2*x)*y
        groups['Body'].add([v.index],1-w,'REPLACE')
        if w>0:groups['LeftWing' if q.x>0 else 'RightWing'].add([v.index],w,'REPLACE')
    modifier=garment.modifiers.new('Mangas unidas al movimiento','ARMATURE');modifier.object=rig
    world=garment.matrix_world.copy();garment.parent=rig;garment.matrix_world=world
    original='--original-rig' in sys.argv
    path=OUT/('shirt_love_'+('originalfit_' if original else '')+'r2_'+sp+'.glb');base.export_selected(path,[rig,garment],False)
    bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(MASTER/('CAMISETA-'+('ORIGINALFIT-' if original else '')+'R2-'+sp+'.blend')),compress=True)
    report={'species':sp,'asset':path.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'qa':qa}
    if original:
        existing=json.loads((OUT/'catalog.json').read_text()).get('wardrobe',[])
        previous=next((v for entry in existing if entry['item_key']=='shirt_love' for v in entry['variants'] if v['species']==sp),None)
        if previous:report.update(asset=previous['asset'],sha256=previous['sha256'])
    if '--original-rig' in sys.argv:
        sys.path.insert(0,str(ROOT/'scripts'))
        from wardrobe_gltf import add_skin_attributes
        world=garment.matrix_world.copy();garment.parent=None;garment.matrix_world=world
        for modifier in list(garment.modifiers):
            if modifier.type=='ARMATURE':garment.modifiers.remove(modifier)
        garment.name='Patrón envolvente · Camiseta abrazo nueva'
        original_path=ROOT/'assets/runner/accessories'/('restart_shirt_love_'+sp+'.glb')
        base.export_selected(original_path,[garment],False)
        fitting_path=ROOT/'design/wardrobe-restart/fitting'/f'{sp}-original.json'
        if not fitting_path.exists():raise ValueError('Falta la captura del GLB original sin modificaciones')
        fitting=json.loads(fitting_path.read_text())
        add_skin_attributes(original_path,fitting)
        report.update(original_asset=original_path.relative_to(ROOT).as_posix(),original_sha256=hashlib.sha256(original_path.read_bytes()).hexdigest())
    reports.append(report)
    print('SHIRT_EXPORTED',sp,qa,flush=True)
catalog=json.loads((OUT/'catalog.json').read_text());items=catalog.setdefault('wardrobe',[])
item=next((i for i in items if i['item_key']=='shirt_love'),None)
if item is None:item={'item_key':'shirt_love','label':pattern['label'],'visible':False,'variants':[]};items.append(item)
item['variants']=[*reports,*[r for r in item['variants'] if r['species'] not in names]]
(OUT/'catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2))
print('SHIRT_READY',flush=True)
