"""Fresh cloth bow and heart sneakers, tailored in actual species model space.
Uses original pet skin fields; never replaces the runner's animations.
"""
import bpy,bmesh,json,math,sys,hashlib,importlib.util,struct
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from wardrobe_gltf import add_skin_attributes, _attribute
spec=importlib.util.spec_from_file_location('base',ROOT/'scripts/blender-restart-wardrobe.py');base=importlib.util.module_from_spec(spec);spec.loader.exec_module(base)
OUT=ROOT/'assets/runner/accessories';MASTER=ROOT/'design/wardrobe-restart/models'
species=['penguin','bear','pig','chick']
if '--species' in sys.argv:species=[sys.argv[sys.argv.index('--species')+1]]
items=sys.argv[sys.argv.index('--items')+1].split(',') if '--items' in sys.argv else ['bow_neck','shoes_heart']
if any(key not in ('bow_neck','shoes_heart') for key in items):raise ValueError('Unsupported complement')

def soften(obj):
    bpy.context.view_layer.objects.active=obj
    mod=obj.modifiers.new('Forma textil suave','SUBSURF');mod.levels=1;bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj

def bow(center,size,mat):
    cx,cy,cz=center;parts=[]
    for sign in (-1,1):
        pts=[];faces=[];rows=32;n=48
        for j in range(rows+1):
            u=j/rows;height=.018+.035*math.sin(math.pi*u/2)**.85
            for i in range(n):
                a=i*math.tau/n
                x=.013+.104*u-.005*math.cos(a)**2*u**6
                y=height*math.cos(a)
                z=(.011+.008*u)*math.sin(a)+.005*math.sin(math.pi*u)*math.cos(3*a)*(1-u)
                pts.append((cx+sign*x*size,cy+y*size,cz+z*size))
        for j in range(rows):
            for i in range(n):faces.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
        faces.extend((tuple(reversed(range(n))),tuple(rows*n+i for i in range(n))))
        wing=base.mesh('Lazo de algodón · pliegues completos',pts,faces,mat)
        bm=bmesh.new();bm.from_mesh(wing.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(wing.data);bm.free();parts.append(wing)
        # Complete seam lines follow the upper and lower folded lobe edges.
        for a in (.10,math.pi-.10):
            line=[]
            for j in range(2,rows-1):
                u=j/rows;height=.018+.035*math.sin(math.pi*u/2)**.85
                line.append((cx+sign*(.013+.104*u-.005*math.cos(a)**2*u**6)*size,cy+height*math.cos(a)*size,cz+(.011+.008*u)*math.sin(a)*size+.0015))
            parts.append(base.tube('Pespunte del lazo',line,.0009,mat))
    bpy.ops.mesh.primitive_cube_add(size=1,location=base.C@Vector((cx,cy,cz+.007*size)))
    knot=bpy.context.object;knot.name='Nudo de cinta plegada';knot.scale=(.045*size,.040*size,.053*size)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    bevel=knot.modifiers.new('Esquinas de algodón doblado','BEVEL');bevel.width=.006*size;bevel.segments=5;bpy.ops.object.modifier_apply(modifier=bevel.name)
    knot.data.materials.append(mat)
    for face in knot.data.polygons:face.use_smooth=True
    parts.append(knot)
    return parts

def make_bow(data,coral,sp):
    # The head/body capture split is not the neck (especially on the bear).
    # Seat the tie on the actual authored shirt collar, independently per pet.
    raw=(OUT/f'sewn_shirt_love_{sp}.glb').read_bytes()
    length=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+length]);binary=raw[28+length:]
    points=[p for mesh in doc['meshes'] if 'Cuello' in mesh['name'] for prim in mesh['primitives'] for p in _attribute(doc,binary,prim['attributes']['POSITION'])]
    if not points:raise ValueError('Missing sewn collar '+sp)
    low=[min(p[k] for p in points) for k in range(3)];high=[max(p[k] for p in points) for k in range(3)]
    body=data['body'];y=high[1]-.015;z=high[2]+.014
    vertices=[];faces=[]
    for mesh in data['meshes']:
        offset=len(vertices);p=mesh['positions'];indices=mesh['indices']
        vertices.extend(Vector(p[i:i+3]) for i in range(0,len(p),3))
        faces.extend(tuple(offset+v for v in indices[i:i+3]) for i in range(0,len(indices),3))
    surface=BVHTree.FromPolygons(vertices,faces)
    hit,_,_,_=surface.ray_cast(Vector((0,y,1.5)),Vector((0,0,-1)))
    if hit is not None:z=max(z,hit.z+.021)
    size=min(1.25,max(.9,(body['max'][0]-body['min'][0])/.45))
    parts=bow((0,y,z),size,coral)
    # Follow the chin's slope while retaining each folded lobe's thickness.
    # This seats the upper edge in front of the chin rather than inside it.
    for part in parts:
        if part.type=='CURVE':
            for spline in part.data.splines:
                for p in spline.points:
                    q=base.CI@Vector(p.co[:3]);q.z+=.75*(q.y-y);p.co=(*tuple(base.C@q),p.co.w)
        else:
            for v in part.data.vertices:
                q=base.CI@(v.co+part.location);q.z+=.75*(q.y-y);v.co=base.C@q-part.location
    rx=(high[0]-low[0])/2-.006;rz=(high[2]-low[2])/2-.006
    cz=(high[2]+low[2])/2
    strap=[]
    for i in range(96):
        a=i*math.tau/96;strap.append((rx*math.sin(a),y,cz+rz*math.cos(a)))
    parts.append(base.tube('Cinta de cou · coton',strap,.008,coral,True))
    return parts

def shoe(side,bounds,coral,ivory,gold,species='penguin'):
    low,high=bounds['min'],bounds['max'];cx=(low[0]+high[0])/2;cz=(low[2]+high[2])/2+.006
    rx=(high[0]-low[0])/2+.006;rz=(high[2]-low[2])/2+.010
    # Proportion the upper to the measured foot, not a fixed tall shoe last.
    top=high[1]+.035
    ankle_radius=min(rx*.60,.071) if species=='penguin' else min(rx*.60,rz*.40,.071)
    parts=[]
    # A rounded molded sole with a flat contact patch, authored from this foot.
    rubber=bpy.data.materials.get('Goma marfil suave') or base.material('Goma marfil suave','#FFF1DD',.84)
    sole_points=[];sole_faces=[];count=64
    for y,factor in ((.002,.94),(.007,1.00),(.028,1.00),(.034,.96)):
        for i in range(count):
            a=i*math.tau/count;sole_points.append((cx+(rx+.006)*factor*math.cos(a),y,cz+(rz+.006)*factor*math.sin(a)))
    for row in range(3):
        for i in range(count):sole_faces.append((row*count+i,row*count+(i+1)%count,(row+1)*count+(i+1)%count,(row+1)*count+i))
    sole_faces.extend((tuple(reversed(range(count))),tuple(3*count+i for i in range(count))))
    sole=base.mesh('Suela marfil biselada',sole_points,sole_faces,rubber)
    bm=bmesh.new();bm.from_mesh(sole.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(sole.data);bm.free();parts.append(sole)
    # A shoe last: tall heel/quarter, eased instep and a lower rounded toe.
    # The former ellipsoid read as a slipper rather than a sewn sneaker.
    vertices=[];faces=[];rows=36;segments=48
    for j in range(rows+1):
        t=j/rows;z=cz+rz*(2*t-1)
        width=rx*max(.025,math.sin(math.pi*t)**.34)
        height=top*(1-.28*t**2)
        for i in range(segments):
            a=i*math.tau/segments
            vertices.append((cx+width*math.cos(a),.025+(height-.025)*(.5+.5*math.sin(a)),z))
    for j in range(rows):
        for i in range(segments):
            faces.append((j*segments+i,j*segments+(i+1)%segments,(j+1)*segments+(i+1)%segments,(j+1)*segments+i))
    faces.extend((tuple(reversed(range(segments))),tuple(rows*segments+i for i in range(segments))))
    upper=base.mesh('Empeine y laterales de lona',vertices,faces,coral)
    upper.data.materials.append(rubber)
    for face in upper.data.polygons:
        if sum((base.CI@upper.data.vertices[v].co).z for v in face.vertices)/len(face.vertices)>cz+rz*.56:face.material_index=1
    # Real ankle opening with inside walls, instead of a black painted circle.
    bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=ankle_radius,depth=.3,location=base.C@Vector((cx,top+.04,cz-rz*.35)))
    cut=bpy.context.object;base.subtract(upper,cut);bpy.data.objects.remove(cut,do_unlink=True);parts.append(upper)
    upper.data.update();tree=BVHTree.FromPolygons([base.CI@v.co+base.CI@upper.location for v in upper.data.vertices],[list(f.vertices) for f in upper.data.polygons])
    # Padded ankle binding follows the real opening; a raised tongue sits under
    # the laces, with enough thickness to remain legible on a mobile screen.
    ankle_z=cz-rz*.35
    collar=[]
    for i in range(64):
        a=i*math.tau/64;x=cx+(ankle_radius+.002)*math.cos(a);z=ankle_z+(ankle_radius+.002)*math.sin(a)
        hit,_,_,_=tree.ray_cast(Vector((x,top+.3,z)),Vector((0,-1,0)))
        if hit is not None:collar.append((x,hit.y+.003,z))
    if len(collar)>40:parts.append(base.tube('Borde acolchado del tobillo',collar,.0045,ivory,True))
    tongue=[];tongue_faces=[]
    for j in range(13):
        z=cz+rz*(.20+j/12*.36)
        for k in range(9):
            x=cx+rx*.30*(k/4-1)
            hit,_,_,_=tree.ray_cast(Vector((x,top+.3,z)),Vector((0,-1,0)))
            if hit is None:raise ValueError('La lengüeta debe apoyarse sobre el empeine')
            tongue.append((x,hit.y+.0035,z))
    for j in range(12):
        for k in range(8):tongue_faces.append((j*9+k,j*9+k+1,(j+1)*9+k+1,(j+1)*9+k))
    panel=base.mesh('Lengüeta acolchada',tongue,tongue_faces,coral);base.solid(panel,.004);parts.append(panel)
    for edge in (0,8):
        line=[tuple(Vector(tongue[j*9+edge])+Vector((0,.004,0))) for j in range(13)]
        parts.append(base.tube('Pespunte continuo de lengüeta',line,.0011,ivory))
    eyelets=[]
    for j in range(4):
        z=cz+rz*(.08+j*.145)
        pair=[]
        for sign in (-1,1):
            x=cx+sign*rx*.56;hit,_,_,_=tree.ray_cast(Vector((x,top+.3,z)),Vector((0,-1,0)))
            if hit is None:continue
            point=(x,hit.y+.004,z);pair.append(point)
            ring=[(x+.005*math.cos(i*math.tau/24),hit.y+.004,z+.005*math.sin(i*math.tau/24)) for i in range(24)]
            parts.append(base.tube('Ojal metálico cosido',ring,.0012,gold,True))
        if len(pair)==2:eyelets.append(pair)
    for j in range(len(eyelets)-1):
      for direction in (-1,1):
        a=Vector(eyelets[j][0 if direction<0 else 1]);b=Vector(eyelets[j+1][1 if direction<0 else 0]);line=[]
        for k in range(17):
            q=a.lerp(b,k/16);hit,_,_,_=tree.ray_cast(Vector((q.x,top+.3,q.z)),Vector((0,-1,0)))
            if hit is not None:line.append((q.x,hit.y+.006+(direction>0)*.001,q.z))
        if len(line)>1:parts.append(base.tube('Cordones cruzados de algodón',line,.0022,ivory))
    # Toe cap uses the same physical upper; thin folded piping remains attached.
    line=[]
    for i in range(41):
        a=-math.pi*.50+i/40*math.pi
        line.append((cx+(rx+.002)*math.sin(a),.040,cz+(rz+.002)*math.cos(a)))
    parts.append(base.tube('Costura de puntera',line,.002,ivory))
    seam=[];z=cz+rz*.56;width=rx*math.sin(math.pi*.78)**.34
    for i in range(49):
        x=cx+width*math.cos(i*math.pi/48)*.998
        hit,_,_,_=tree.ray_cast(Vector((x,top+.3,z)),Vector((0,-1,0)))
        if hit is not None:seam.append((x,hit.y+.003,z-.0015))
    parts.append(base.tube('Pespunte de separación de puntera',seam,.0013,ivory))
    # Raised side heart, centered on the outer flank of this real shoe.
    sign=1 if side=='Left' else -1;points=[];faces=[];count=48
    patch=base.sphere('Parche de lona marfil',(cx+sign*rx*.94,.082,cz),(.005,.032,.044),ivory);parts.append(patch)
    for vertex in patch.data.vertices:
        q=base.CI@(vertex.co+patch.location);depth=sign*(q.x-(cx+sign*rx*.94))
        hit,_,_,_=tree.ray_cast(Vector((cx+sign*(rx+.2),q.y,q.z)),Vector((-sign,0,0)))
        if hit is not None:q.x=hit.x+sign*(.002+depth)
        vertex.co=base.C@q-patch.location
    bm=bmesh.new();bm.from_mesh(patch.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(patch.data);bm.free()
    for i in range(count):
        a=i*math.tau/count;y=.082+.040*(13*math.cos(a)-5*math.cos(2*a)-2*math.cos(3*a)-math.cos(4*a))/32;z=cz+.040*16*math.sin(a)**3/32
        hit,_,_,_=tree.ray_cast(Vector((cx+sign*(rx+.2),y,z)),Vector((-sign,0,0)))
        points.append(((hit.x if hit is not None else cx+sign*rx*.94)+sign*.009,y,z))
    hit,_,_,_=tree.ray_cast(Vector((cx+sign*(rx+.2),.085,cz)),Vector((-sign,0,0)))
    points.append(((hit.x if hit is not None else cx+sign*rx*.94)+sign*.010,.085,cz));faces=[(count,i,(i+1)%count) for i in range(count)]
    heart=base.mesh('Corazón de la zapatilla',points,faces,coral);base.solid(heart,.003);parts.append(heart)
    for o in parts:
        o.name='Calzado · '+side+' · '+o.name;o.data.name=o.name
    return parts

reports=[]
for sp in species:
    source=ROOT/'design/wardrobe-restart/fitting'/f'{sp}-original.json'
    if not source.exists():raise ValueError('Falta la captura de la mascota original sin modificaciones')
    data=json.loads(source.read_text());bpy.ops.wm.read_factory_settings(use_empty=True)
    coral=base.material('Algodón coral nuevo','#EC6276',.92,True);ivory=base.material('Algodón cordón crema','#FFF1DD',.92,True);gold=base.material('Latón suave','#D6AD63',.4,metal=True)
    for key in items:
        parts=make_bow(data,coral,sp) if key=='bow_neck' else [*shoe('Left',data['feet']['Left'],coral,ivory,gold,sp),*shoe('Right',data['feet']['Right'],coral,ivory,gold,sp)]
        if key=='shoes_heart':
            merged=[]
            groups={side:[o for o in parts if o.name.startswith('Calzado · '+side+' ·')] for side in ('Left','Right')}
            for side in ('Left','Right'):
                group=groups[side]
                bpy.ops.object.select_all(action='DESELECT')
                for o in group:o.select_set(True)
                bpy.context.view_layer.objects.active=group[0];bpy.ops.object.join()
                group[0].name='Calzado · '+side+' · Zapatilla cosida completa';group[0].data.name=group[0].name;merged.append(group[0])
            parts=merged
        if key=='bow_neck':
            bpy.ops.object.select_all(action='DESELECT')
            for o in parts:o.select_set(True)
            bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();parts=[parts[0]];parts[0].name='Patrón cuello · Lazo coral nuevo';parts[0].data.name=parts[0].name
        data['rigid_garment_bone']='Neck' if key=='bow_neck' else None
        path=OUT/f'restart_{key}_{sp}.glb';staging=path.with_name(path.stem+'.building.glb');base.export_selected(staging,parts,False);add_skin_attributes(staging,data);staging.replace(path)
        reports.append({'item_key':key,'species':sp,'asset':path.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
        print('DETAIL_EXPORTED',key,sp,flush=True)
    master_name=f'LAZO-CUELLO-{sp}.blend' if items==['bow_neck'] else f'COMPLEMENTOS-NUEVOS-{sp}.blend'
    bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(MASTER/master_name),compress=True)
catalog_path=ROOT/'assets/runner/restart/details-catalog.json';old=json.loads(catalog_path.read_text()) if catalog_path.exists() else []
keys={(r['item_key'],r['species']) for r in reports};catalog_path.write_text(json.dumps(reports+[r for r in old if (r['item_key'],r['species']) not in keys],ensure_ascii=False,indent=2));print('DETAILS_READY',flush=True)
