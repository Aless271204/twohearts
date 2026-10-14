"""Continuous torso/armhole/sleeve pattern on the immutable supplied penguin."""
import bpy,bmesh,json,math,sys,hashlib,importlib.util
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts'))
surface_wrap='--surface-wrap' in sys.argv
species=sys.argv[sys.argv.index('--species')+1] if '--species' in sys.argv else 'penguin'
item=sys.argv[sys.argv.index('--item')+1] if '--item' in sys.argv else 'shirt_love'
from wardrobe_gltf import add_skin_attributes
spec=importlib.util.spec_from_file_location('base',ROOT/'scripts/blender-restart-wardrobe.py')
base=importlib.util.module_from_spec(spec);spec.loader.exec_module(base)
if species=='penguin' and item!='shirt_love':
    from sewn_penguin_styles import build
    build(base,ROOT,item)
    raise SystemExit(0)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/runner/restart/shirt_love_r2_penguin.glb'))
embroidery=next(o for o in bpy.data.objects if o.type=='MESH' and o.name.startswith('Camiseta'))
world=embroidery.matrix_world.copy();embroidery.parent=None;embroidery.matrix_world=world
for m in list(embroidery.modifiers):embroidery.modifiers.remove(m)
cream=embroidery.data.materials[0];thread=embroidery.data.materials[1]
bm=bmesh.new();bm.from_mesh(embroidery.data)
bmesh.ops.delete(bm,geom=[f for f in bm.faces if f.material_index!=2],context='FACES')
bm.to_mesh(embroidery.data);bm.free();embroidery.name='Bordado corazón · tejido continuo'
data=json.loads((ROOT/'design/wardrobe-restart/fitting/penguin-original.json').read_text(encoding='utf-8'))
skin_points=[];skin_faces=[]
for m in data['meshes']:
    offset=len(skin_points);skin_points.extend(Vector(m['positions'][i:i+3]) for i in range(0,len(m['positions']),3))
    for i in range(0,len(m['indices']),3):
        tri=m['indices'][i:i+3];arm=0;head=0
        for v in tri:
            for j,w in zip(m['skinIndex'][v*4:v*4+4],m['skinWeight'][v*4:v*4+4]):
                name=data['boneNames'][j]
                if name.endswith(('Shoulder','Arm','ForeArm','Hand')):arm+=w/3
                if name.endswith('Head'):head+=w/3
        cy=sum(m['positions'][v*3+1] for v in tri)/3
        if arm<.60 and head<.5 and .20<cy<.49:skin_faces.append(tuple(offset+v for v in tri))
skin=BVHTree.FromPolygons(skin_points,skin_faces,all_triangles=True)
points=[];faces=[];field=[];n=128;rows=48;cz=-.025
def neck_weight(y):
    t=max(0,min(1,(y-.490)/.085));return t*t*(3-2*t)
for row in range(rows+1):
    y=.235+(.524-.235)*row/rows
    # Evaluate the whole contour at its physical height. Compressing Y after
    # calculating the radii left a broad raw edge outside the neck binding.
    # Recess the raw cut inside the 26 mm folded binding. Solidify adds
    # thickness along the sloping shoulder normal, including a vertical
    # component: a cut only 3 mm below the binding exposed its inner shell.
    t=(y-.235)/.340
    rx=.254-.032*t;rz=.265-.059*t
    rx+=.006*math.sin(t*math.pi);rz+=.008*math.sin(t*math.pi)
    # The supplied wing root joins the broad lower head. Add lateral ease
    # beneath that contour, while keeping the visible sleeve a sewn loft.
    rx+=.050*neck_weight(y)
    for col in range(n):
        a=col*math.tau/n;q=Vector((rx*math.sin(a),y,cz+rz*math.cos(a)))
        if .245<y<.49:
            origin=Vector((0,y,cz));radial=q-origin
            hit,_,_,distance=skin.ray_cast(origin,radial.normalized(),1)
            if hit is not None and radial.length<distance+.014:q=origin+radial.normalized()*(distance+.014)
        # Uniform physical rows avoid inverted shoulder faces at the neck.
        points.append(tuple(q));field.append([*q,0,0,neck_weight(q.y)])
# Rectangular domain patches become rounded armholes through a sewn loft.
lo=27;hi=46;half=10
for row in range(rows):
    for col in range(n):
        hole=lo<=row<hi and any(center-half<=col<center+half for center in (32,96))
        if not hole:faces.append((row*n+col,row*n+(col+1)%n,(row+1)*n+(col+1)%n,(row+1)*n+col))
cuffs=[];armholes=[]
for center,sign in ((32,1),(96,-1)):
    a=center-half;b=center+half
    boundary=[lo*n+c for c in range(a,b)]
    boundary += [r*n+b for r in range(lo,hi)]
    boundary += [hi*n+c for c in range(b,a,-1)]
    boundary += [r*n+a for r in range(hi,lo,-1)]
    # Recut the shared armhole to the fin's rounded attachment. Smoothing a
    # rectangular hole left a rectangular sleeve: its entire outline matters.
    root_center=Vector((sign*.21,.455,cz))
    angles=[math.atan2((points[i][2]-cz)/.130,(points[i][1]-.455)/.055) for i in boundary]
    loop=[]
    for angle in angles:
        yy=.455+.055*math.cos(angle);zz=cz+.130*math.sin(angle)
        t=(yy-.235)/.340
        rx=.254-.032*t+.006*math.sin(t*math.pi)+.050*neck_weight(yy)
        rz=.265-.059*t+.008*math.sin(t*math.pi)
        xx=sign*rx*math.sqrt(max(.01,1-((zz-cz)/rz)**2))
        loop.append(Vector((xx,yy,zz)))
    for index,q in zip(boundary,loop):
        points[index]=tuple(q);field[index][:3]=list(q);field[index][5]=neck_weight(q.y)
    armholes.append((sign,[Vector(points[i]) for i in boundary]))
    previous=boundary;count=len(boundary)
    for step in range(1,13):
        t=step/12;current=[]
        for i,index in enumerate(boundary):
            angle=angles[i]
            cuff=Vector((sign*(.267+.055*math.cos(angle)),.402+.012*math.cos(angle),-.012+.132*math.sin(angle)))
            root=Vector(points[index]);q=root.lerp(cuff,t)
            # A few millimetres of cloth ease, not spherical padding.
            q.x+=sign*.003*math.sin(t*math.pi)
            current.append(len(points));points.append(tuple(q))
            weight=t*t*(3-2*t);field.append([*q,sign,weight,neck_weight(root.y)*(1-t)])
        for i in range(count):faces.append((previous[i],previous[(i+1)%count],current[(i+1)%count],current[i]))
        previous=current
    cuffs.append([points[i] for i in previous])
cloth=base.mesh('Manga adaptada · Camiseta cosida continua',points,faces,cream)
used={v for face in faces for v in face};field=[field[i] for i in sorted(used)]
bm=bmesh.new();bm.from_mesh(cloth.data)
boundary={e for e in bm.edges if e.is_boundary}
if any(len([e for e in v.link_edges if e.is_boundary])!=2 for e in boundary for v in e.verts):raise ValueError('Unfinished seam in the continuous shirt')
loops=0
while boundary:
    stack=[boundary.pop()];loops+=1
    while stack:
        edge=stack.pop()
        for vertex in edge.verts:
            for neighbor in vertex.link_edges:
                if neighbor in boundary:boundary.remove(neighbor);stack.append(neighbor)
if loops!=4:raise ValueError('Only neckline, hem and two cuffs may be open')
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(cloth.data);bm.free()
surface=BVHTree.FromPolygons([Vector(p) for p in points],faces)
for v in embroidery.data.vertices:
    q=base.CI@v.co;origin=Vector((0,q.y,cz));radial=q-origin
    hit,normal,_,_=surface.ray_cast(origin,radial.normalized(),1)
    if hit is not None:
        if normal.dot(radial)<0:normal=-normal
        v.co=base.C@(hit+normal*.012)
embroidery.data.update()
# Cylinder UVs for the torso; local planar weave coordinates for the sleeves.
for f in cloth.data.polygons:
    for li in f.loop_indices:
        vi=cloth.data.loops[li].vertex_index;q=Vector(points[vi])
        if vi<(rows+1)*n:
            angle=(math.atan2(q.x,q.z-cz)/math.tau)%1
            cloth.data.uv_layers.active.data[li].uv=(angle*7.5,q.y/.20)
        else:cloth.data.uv_layers.active.data[li].uv=(q.z/.20,q.y/.20)
base.solid(cloth,.014);parts=[cloth,embroidery]
# A narrow concave binding across the upper fin, with an inset stitch.
# This is an actual cloth ribbon, not the old round piping around the armhole.
for center,sign in ((32,1),(96,-1)):
    arc=[]
    for sample in range(41):
        # Follow the fin's upper attachment: front lower root -> shoulder ->
        # rear lower root. It is an armhole arch, never a stripe across a sleeve.
        u=sample/40;angle=math.pi*u
        q=Vector((sign*.247,.435+.090*math.sin(angle),cz+.135*math.cos(angle)))
        hit,normal,_,_=surface.find_nearest(q)
        if normal.dot(Vector((hit.x,0,hit.z-cz)))<0:normal=-normal
        arc.append((hit,normal))
    ribbon=[];rf=[]
    for row in range(3):
        for hit,normal in arc:
            # Ribbon width perpendicular to the armhole contour in its plane.
            i=len(ribbon)%len(arc);angle=math.pi*i/(len(arc)-1)
            q=hit+Vector((0,math.sin(angle),math.cos(angle)))*((row-1)*.003)
            projected,norm,_,_=surface.find_nearest(q)
            if norm.dot(normal)<0:norm=-norm
            ribbon.append(tuple(projected+norm*.006))
    count=len(arc)
    for row in range(2):
        for i in range(count-1):
            face=(row*count+i,row*count+i+1,(row+1)*count+i+1,(row+1)*count+i)
            # Shoulder binding terminates under the collar's lower edge.
            if max(ribbon[v][1] for v in face)<.513:rf.append(face)
    rim=base.mesh('Bordillo cóncavo de hombro '+str(sign),ribbon,rf,cream)
    base.solid(rim,.003);parts.append(rim)
    line=[tuple(Vector(ribbon[count+i])+arc[i][1]*.002) for i in range(count)]
    runs=[];run=[]
    for q in line:
        if q[1]<.513:run.append(q)
        else:
            if len(run)>1:runs.append(run)
            run=[]
    if len(run)>1:runs.append(run)
    for i,run in enumerate(runs):parts.append(base.tube('Costura del hombro cóncavo '+str(sign)+' '+str(i),run,.0007,thread,False))
for sign,loop in armholes:
    # A sewn armhole, resting on the same continuous garment surface.
    # Round only the seam's corners; leave the approved collar and shirt intact.
    for iteration in range(2):
        rounded=[]
        for i,p in enumerate(loop):
            q=loop[(i+1)%len(loop)];rounded.extend((p.lerp(q,.25),p.lerp(q,.75)))
        loop=rounded
    line=[]
    for q in loop:
        hit,normal,_,_=surface.find_nearest(q)
        if hit is None:raise ValueError('The armhole seam must sit on the garment')
        outward=Vector((hit.x,0,hit.z-cz))
        if normal.dot(outward)<0:normal=-normal
        # Bury the top of the armhole binding beneath the collar binding so
        # their junction reads as one sewn finish, not stacked raised edges.
        blend=max(0,min(1,(hit.y-.495)/.040));blend=blend*blend*(3-2*blend)
        line.append(hit+normal*(.0095-.0065*blend))
    # The old continuous piping also crossed over the collar at the crown.
    # Keep its lower contour, leaving the hidden crown beneath the neck binding.
    start=next(i for i,p in enumerate(line) if p.y>=.511)
    ordered=line[start:]+line[:start];runs=[];run=[]
    for p in ordered:
        if p.y<.511:run.append(tuple(p))
        else:
            if len(run)>1:runs.append(run)
            run=[]
    if len(run)>1:runs.append(run)
    for i,run in enumerate(runs):parts.append(base.tube('Unión textil de la sisa '+str(sign)+' '+str(i),run,.0018,cream,False))
    lengths=[(line[(i+1)%len(line)]-p).length for i,p in enumerate(line)];total=sum(lengths)
    def at(distance):
        distance%=total
        for i,length in enumerate(lengths):
            if distance<=length:return line[i].lerp(line[(i+1)%len(line)],distance/max(length,1e-9))
            distance-=length
        return line[0]
    curve=bpy.data.curves.new('Pespunte continuo de sisa '+str(sign),'CURVE');curve.dimensions='3D'
    curve.bevel_depth=.0007;curve.bevel_resolution=2;curve.use_fill_caps=True
    for stitch in range(int(total/.006)):
        a=at(stitch*.006);b=at(stitch*.006+.0038)
        if max(a.y,b.y)>=.511:continue
        spline=curve.splines.new('POLY');spline.points.add(1)
        for target,q in zip(spline.points,(a,b)):
            radial=Vector((q.x,0,q.z-cz)).normalized();target.co=(*(base.C@(q+radial*.0017)),1)
    obj=bpy.data.objects.new('Pespunte cosido de sisa '+str(sign),curve);bpy.context.collection.objects.link(obj);curve.materials.append(thread)
    bpy.context.view_layer.objects.active=obj;bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.ops.object.convert(target='MESH');obj.select_set(False);parts.append(obj)
for label,y,width in [('Bajo',.235,.024),('Cuello',.514,.026)]:
    band=[];bf=[]
    if label=='Cuello':
        # A closed folded binding centred on the actual raw neckline. The cut
        # sits INSIDE this rounded section, never on its exposed upper lip.
        yy=.524;t=(yy-.235)/.340
        rx=.254-.032*t+.006*math.sin(t*math.pi)+.050*neck_weight(yy)
        rz=.265-.059*t+.008*math.sin(t*math.pi)
        sections=16
        for j in range(sections):
            phi=j*math.tau/sections
            for col in range(n):
                angle=col*math.tau/n
                normal=Vector((math.sin(angle)/rx,0,math.cos(angle)/rz)).normalized()
                q=Vector((rx*math.sin(angle),yy,cz+rz*math.cos(angle)))
                q+=normal*(.008+.011*math.cos(phi));q.y+=.014*math.sin(phi)
                band.append(tuple(q))
        for j in range(sections):
            for i in range(n):bf.append((j*n+i,j*n+(i+1)%n,((j+1)%sections)*n+(i+1)%n,((j+1)%sections)*n+i))
        parts.append(base.mesh('Dobladillo de algodón · Cuello',band,bf,cream))
        for phi in (-.60,.60):
            line=[]
            for col in range(n):
                angle=col*math.tau/n;normal=Vector((math.sin(angle)/rx,0,math.cos(angle)/rz)).normalized()
                q=Vector((rx*math.sin(angle),yy+.014*math.sin(phi),cz+rz*math.cos(angle)))+normal*(.008+.011*math.cos(phi)+.0012)
                line.append(tuple(q))
            parts.append(base.tube('Pespunte · Cuello',line,.00075,thread,True))
        continue
    for j in range(5):
        yy=y+j*width/4
        for col in range(n):
            angle=col*math.tau/n;origin=Vector((0,yy,cz));direction=Vector((math.sin(angle),0,math.cos(angle)))
            if label=='Cuello':
                t=(yy-.235)/.340
                rx=.254-.032*t+.006*math.sin(t*math.pi)+.050*neck_weight(yy)
                rz=.265-.059*t+.008*math.sin(t*math.pi)
                hit=Vector((rx*math.sin(angle),yy,cz+rz*math.cos(angle)))
                normal=Vector((math.sin(angle)/rx,0,math.cos(angle)/rz)).normalized()
            else:hit,normal,_,_=surface.ray_cast(origin,direction,1)
            if hit is None:hit=Vector((.222*math.sin(angle),yy,cz+.206*math.cos(angle)));normal=direction
            offset=(.011+.003*math.sin(j*math.pi/4)) if label=='Cuello' else .007
            band.append(tuple(hit+normal*offset))
    for j in range(4):
        for i in range(n):bf.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
    rim=base.mesh('Dobladillo de algodón · '+label,band,bf,cream);base.solid(rim,.008 if label=='Cuello' else .005);parts.append(rim)
    for j in (1,3):
        line=[]
        for i in range(n):
            q=Vector(band[j*n+i]);radial=Vector((q.x,0,q.z-cz)).normalized();line.append(tuple(q+radial*(.0045 if label=='Cuello' else .003)))
        parts.append(base.tube('Pespunte · '+label,line,.00075,thread,True))
for sign,loop in zip((1,-1),cuffs):
    band=[];bf=[];count=len(loop)
    for row in range(5):
        for p in loop:
            q=Vector(p);q.y+=row*.004
            radial=Vector((q.x-sign*.267,0,q.z+.012)).normalized();q+=radial*.007;band.append(tuple(q))
    for row in range(4):
        for i in range(count):bf.append((row*count+i,row*count+(i+1)%count,(row+1)*count+(i+1)%count,(row+1)*count+i))
    rim=base.mesh('Dobladillo de manga cosida '+str(sign),band,bf,cream);base.solid(rim,.005);parts.append(rim)
    line=[]
    for i in range(count):
        q=Vector(band[count+i]);radial=Vector((q.x-sign*.267,0,q.z+.012)).normalized();line.append(tuple(q+radial*.003))
    parts.append(base.tube('Pespunte manga '+str(sign),line,.00075,thread,True))
from sewn_wardrobe_patterns import finish_and_fit
parts,data,field,dimensions=finish_and_fit(base,parts,data,field,species,item,ROOT)
data['garment_skin_profile']={'shoulder_start':dimensions['shoulder_start'],'sleeve_full':dimensions['sleeve_full'],'sleeve_min_y':dimensions['sleeve_min_y'],'sleeve_fade_y':.06,
 'stable_torso':True,'preserve_torso_surface':True,'surface_sleeve_anchors':True,
 'volumetric_sleeves':dimensions['sleeve_volume'],'sewn_sleeve_field':field,'sewn_surface_skin':False,'sewn_neck_joint':True,'preserve_authored_sleeve_contact':True,
 'continuous_neck_binding':{'lower':dimensions['top']-.040,'upper':dimensions['top']}}
from approved_shirt_coverage import update
coverage=update(data,sewn=True,species=species,dimensions=dimensions,item=item)
# Interior textile lining follows the actual supplied torso/fin surface. The
# outer tailored panels have ease; their moving shoulder must not expose a void
# where the reversible wardrobe mask hides the original skin underneath.
for source in (data['meshes'] if surface_wrap else []):
    indices=coverage.get(source['name'],[])
    if not indices:continue
    vertices=[]
    for i in range(len(source['positions'])//3):
        q=Vector(source['positions'][i*3:i*3+3]);normal=Vector(source['normals'][i*3:i*3+3])
        vertices.append(tuple(q+normal*.003))
    lining=base.mesh('Forro interior cosido · '+source['name'],vertices,[tuple(indices[i:i+3]) for i in range(0,len(indices),3)],cream)
    for polygon in lining.data.polygons:
        for li in polygon.loop_indices:
            q=base.CI@lining.data.vertices[lining.data.loops[li].vertex_index].co
            lining.data.uv_layers.active.data[li].uv=(q.x/.20,q.y/.20)
    parts.append(lining)
suffix='_surface_experiment' if surface_wrap else ''
path=ROOT/f'assets/runner/accessories/sewn_{item}_{species}{suffix}.glb';staging=path.with_suffix('.building.glb')
base.export_selected(staging,parts,False);add_skin_attributes(staging,data)
if surface_wrap:
    from wardrobe_surface_wrap import add_surface_wrap
    add_surface_wrap(staging,data)
staging.replace(path)
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/f'design/wardrobe-restart/models/COSIDO-{item}-{species}{suffix}.blend'),compress=True)
registry_path=ROOT/'assets/runner/restart/catalog.json';registry=json.loads(registry_path.read_text(encoding='utf-8'))
entry=next((v for v in registry['wardrobe'] if v['item_key']==item),None)
if entry is None:
    entry={'item_key':item,'visible':False,'status':'experimental_pending_visual_review','variants':[]};registry['wardrobe'].append(entry)
variant=next((v for v in entry['variants'] if v['species']==species),None)
if variant is None:variant={'species':species};entry['variants'].append(variant)
if not surface_wrap:
    coverage_name=f'shirt-original-coverage-{species}.json' if item=='shirt_love' else f'sewn-coverage-{species}-{item}.json'
    variant.update(original_asset=path.relative_to(ROOT).as_posix(),original_sha256=hashlib.sha256(path.read_bytes()).hexdigest(),coverage_asset='assets/runner/restart/'+coverage_name,fit_status='continuous_sewn_pattern_in_review')
    registry_path.write_text(json.dumps(registry,ensure_ascii=False,indent=2),encoding='utf-8')
print('CONTINUOUS_SHIRT_EXPORTED',flush=True)
