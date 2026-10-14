"""New, reversible prototype: a sewn cap and a seven-bone cartoon pet rig.

Uses the actual posed/UV-mapped pet surfaces, never the rejected clothing.
No production catalog is modified. All dimensions below are normalized metres.
"""
import bpy, bmesh, json, math, hashlib, sys, tempfile
from pathlib import Path
from mathutils import Vector, Matrix, Quaternion
from mathutils.bvhtree import BVHTree
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/runner/restart'
MASTER = ROOT / 'design/wardrobe-restart/models'
OUT.mkdir(parents=True, exist_ok=True)
MASTER.mkdir(parents=True, exist_ok=True)
TEMP = ROOT / 'outputs/blender-temp'
TEMP.mkdir(parents=True,exist_ok=True)
tempfile.tempdir=str(TEMP)
C = Matrix.Rotation(math.pi / 2, 4, 'X')
CI = C.inverted()
fits = json.loads((ROOT / 'design/blender/head-tailoring.json').read_text())['pets']
species_names = {'penguin':'Pingüino', 'bear':'Oso', 'pig':'Cerdito', 'chick':'Pollito'}
if '--species' in sys.argv:
    requested=sys.argv[sys.argv.index('--species')+1]
    species_names={requested:species_names[requested]}

def linear(c):
    return c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4

def material(name, color, roughness=.8, textile=False, metal=False):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    shader = m.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = (*[linear(int(color[i:i+2],16)/255) for i in (1,3,5)],1)
    shader.inputs['Roughness'].default_value = roughness
    shader.inputs['Metallic'].default_value = .75 if metal else 0
    if textile:
        # Baked cotton PBR: interlaced round threads, twisted fibers and matte pores.
        # Color detail is necessary too: a normal-only flat color looked like plastic.
        size=1024;yy,xx=np.mgrid[0:size,0:size]/size
        rng=np.random.default_rng(2712);fiber=rng.normal(0,1,(size,size))
        # Soft fibers, not harsh per-pixel bumps that resemble molded plastic.
        fiber=sum(np.roll(np.roll(fiber,dy,axis=0),dx,axis=1) for dy in (-1,0,1) for dx in (-1,0,1))/3
        u=xx*28+.025*np.sin(math.tau*yy*84)
        v=yy*28+.025*np.sin(math.tau*xx*84)
        warp=(.5+.5*np.cos(math.tau*u))**2
        weft=(.5+.5*np.cos(math.tau*v))**2
        over=.5+.5*np.sin(math.pi*u)*np.sin(math.pi*v)
        height=.28*warp*(.6+.4*over)+.28*weft*(1-.4*over)+.006*fiber
        dy,dx=np.gradient(height)
        normals=np.stack((-dx*4,-dy*4,np.ones_like(height)),axis=-1)
        normals/=np.linalg.norm(normals,axis=-1,keepdims=True)
        base=np.array([int(color[i:i+2],16)/255 for i in (1,3,5)])
        albedo=np.clip(base[None,None,:]*(.96+.08*(height/.56))[...,None]+.004*fiber[...,None],0,1)
        rough=np.clip(.84+.12*(1-height/.56)+.008*fiber,.82,.99)
        cotton_source=MASTER/'cotton-coral-albedo-ai-v1.png'
        if name.startswith('Algodón ') and cotton_source.exists():
            # ImageGen-created cotton is the actual diffuse map, not a mockup.
            # Luminance-derived relief is approximate; it is not a scanned PBR set.
            source=bpy.data.images.load(str(cotton_source));source.colorspace_settings.name='Non-Color'
            if source.size[0]!=source.size[1]:raise ValueError('La muestra de algodón debe ser cuadrada')
            if name!='Algodón coral':source.scale(1024,1024)
            size=source.size[0]
            albedo=np.asarray(source.pixels[:],dtype=np.float32).reshape(size,size,4)[:,:,:3].copy()
            luminance=albedo@np.array((.2126,.7152,.0722))
            height=(luminance-np.percentile(luminance,5))/max(.01,np.percentile(luminance,95)-np.percentile(luminance,5))
            height=np.clip(height,0,1)
            if name!='Algodón coral':
                shade=luminance/max(.01,luminance.mean())
                albedo=np.clip(shade[:,:,None]*base[None,None,:],0,1)
            # Cotton yarn has a soft rounded relief with irregular individual fibers.
            dx=(np.roll(height,-1,axis=1)-np.roll(height,1,axis=1))/2
            dy=(np.roll(height,-1,axis=0)-np.roll(height,1,axis=0))/2
            normals=np.stack((-dx*7,-dy*7,np.ones_like(height)),axis=-1)
            normals/=np.linalg.norm(normals,axis=-1,keepdims=True)
            rough=.82+.15*(1-height)
            bpy.data.images.remove(source)
        def bake(label,rgb,srgb=False):
            rgba=np.concatenate((rgb,np.ones((size,size,1))),axis=-1).astype(np.float32)
            path=MASTER/(name.replace(' ','-')+'-'+label+'.png')
            raw=bpy.data.images.new(name+' '+label,size,size,alpha=True)
            raw.colorspace_settings.name='Non-Color';raw.pixels.foreach_set(rgba.ravel())
            raw.filepath_raw=str(path);raw.file_format='PNG';raw.save();bpy.data.images.remove(raw)
            image=bpy.data.images.load(str(path));image.colorspace_settings.name='sRGB' if srgb else 'Non-Color';image.pack()
            tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image;tex.label=label
            return tex
        color_map=bake('algodon-color',albedo,True)
        normal_map=bake('algodon-normal',normals*.5+.5)
        rough_map=bake('algodon-rugosidad',np.stack((rough,rough,rough),axis=-1))
        shader.inputs['Base Color'].default_value=(1,1,1,1)
        shader.inputs['Specular IOR Level'].default_value=.2
        # The exporter reads the sheen tint; white tint had washed out the coral.
        shader.inputs['Sheen Weight'].default_value=.4
        shader.inputs['Sheen Tint'].default_value=(*[linear(c)*.22 for c in base],1)
        shader.inputs['Sheen Roughness'].default_value=.8
        normal=m.node_tree.nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.55
        separate=m.node_tree.nodes.new('ShaderNodeSeparateColor');separate.mode='RGB'
        m.node_tree.links.new(color_map.outputs['Color'],shader.inputs['Base Color'])
        m.node_tree.links.new(rough_map.outputs['Color'],separate.inputs['Color'])
        m.node_tree.links.new(separate.outputs['Green'],shader.inputs['Roughness'])
        m.node_tree.links.new(normal_map.outputs['Color'],normal.inputs['Color'])
        m.node_tree.links.new(normal.outputs['Normal'],shader.inputs['Normal'])
    return m

def mesh(name, points, faces, mat, uv=True):
    data=bpy.data.meshes.new(name)
    data.from_pydata([C@Vector(p) for p in points],[],faces);data.update()
    obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj)
    if mat:data.materials.append(mat)
    for face in data.polygons:face.use_smooth=True
    if uv:
        layer=data.uv_layers.new(name='UVMap')
        for face in data.polygons:
            for loop in face.loop_indices:
                p=points[data.loops[loop].vertex_index]
                # A physical 20 cm cotton swatch: visible woven fibers at close range.
                layer.data[loop].uv=(p[0]*5,p[1]*5+p[2]*3)
    return obj

def tube(name, points, radius, mat, cyclic=False):
    curve=bpy.data.curves.new(name,'CURVE');curve.dimensions='3D'
    curve.bevel_depth=radius;curve.bevel_resolution=2;curve.resolution_u=1
    line=curve.splines.new('POLY');line.points.add(len(points)-1)
    for q,p in zip(line.points,points):q.co=(*(C@Vector(p)),1)
    line.use_cyclic_u=cyclic
    obj=bpy.data.objects.new(name,curve);bpy.context.collection.objects.link(obj)
    curve.materials.append(mat)
    bpy.context.view_layer.objects.active=obj;obj.select_set(True)
    bpy.ops.object.convert(target='MESH');obj.select_set(False)
    return obj

def solid(obj, thickness):
    bpy.context.view_layer.objects.active=obj
    mod=obj.modifiers.new('Tela con espesor','SOLIDIFY');mod.thickness=thickness;mod.offset=0
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bm=bmesh.new();bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(obj.data);bm.free()

def subtract(obj, cutter):
    bpy.context.view_layer.objects.active=obj
    mod=obj.modifiers.new('Abertura terminada','BOOLEAN');mod.solver='EXACT'
    mod.operation='DIFFERENCE';mod.object=cutter
    bpy.ops.object.modifier_apply(modifier=mod.name)

def sphere(name,p,scale,mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=16,location=C@Vector(p))
    obj=bpy.context.object;obj.name=name;obj.scale=(scale[0],scale[2],scale[1])
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if mat:obj.data.materials.append(mat)
    for f in obj.data.polygons:f.use_smooth=True
    return obj

def build_cap(sp, data, coral, thread, ivory, gold):
    p=fits[sp];cx,cy,cz=p['skull_center'];rx,ry,rz=p['skull_radius']
    rx+=.014;ry+=.013;rz+=.014
    n=144;rows=40;tmax=1.43
    raw=data['meshes'][0]
    head_surface=BVHTree.FromPolygons([Vector(p) for p in np.asarray(raw['positions']).reshape(-1,3)],np.asarray(raw['indices']).reshape(-1,3).tolist())
    def point(a,t,offset=0):
        fraction=t/tmax
        base=cy+.045-.034*(1-math.cos(a))/2-.012*math.sin(a)**2
        theta=math.acos((base-cy)/ry)*fraction
        # Six softly full sewn panels: the seams pinch the fabric, not the skull.
        seam=-.008*math.exp(-(math.sin(a*3)/.17)**2)
        fullness=.005*math.sin(a*3)**2
        wrinkle=.0035*math.sin(a*22+.5)*math.sin(fraction*math.pi)**2*max(0,(fraction-.65)/.35)
        relief=(seam+fullness+wrinkle)*math.sin(theta)
        q=Vector((cx+(rx+offset+relief)*math.sin(theta)*math.sin(a),cy+(ry+offset)*math.cos(theta),cz+(rz+offset+relief)*math.sin(theta)*math.cos(a)))
        # The lower crown follows the REAL posed head surface, not a generic dome.
        # Cast from inside the skull so isolated ears/tufts do not enlarge the rim.
        direction=Vector((math.sin(a),0,math.cos(a)))
        hit,_,_,distance=head_surface.ray_cast(Vector((cx,q.y,cz)),direction)
        if hit is not None and .08<distance<.55:
            s=max(0,min(1,(fraction-.60)/.40));weight=s*s*(3-2*s)
            if sp!='penguin':
                # Ears are independently occluded while worn. Letting a radial
                # hit on an ear shape the crown created flat tabs in the hem.
                # Preserve the measured skull ellipse and only accept small
                # contact corrections, never the protruding ear envelope.
                ellipse_radius=math.sqrt(max(.01,1-((q.y-cy)/ry)**2))/math.sqrt((direction.x/rx)**2+(direction.z/rz)**2)
                distance=max(ellipse_radius-.004,min(distance,ellipse_radius+.006))
                hit=Vector((cx,q.y,cz))+direction*distance
            target=hit+direction*(.006+offset)
            q.x=q.x*(1-weight)+target.x*weight
            q.z=q.z*(1-weight)+target.z*weight
        return tuple(q)
    pts=[point(math.tau*i/n,.012+(tmax-.012)*j/rows) for j in range(rows+1) for i in range(n)]
    faces=[(j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i) for j in range(rows) for i in range(n)]
    faces.append(tuple(reversed(range(n))))
    crown=mesh('Copa · seis paneles cosidos',pts,faces,coral)
    # Cylindrical/polar UVs wrap the weave over the crown instead of stretching
    # a planar projection across its sides. One UV tile is a 20 cm fabric swatch.
    textile_swatch=.28
    circumference=math.tau*(rx+rz)/2/textile_swatch
    for face in crown.data.polygons:
        wraps=any(v%n==n-1 for v in face.vertices) and any(v%n==0 for v in face.vertices)
        for lp in face.loop_indices:
            vertex=crown.data.loops[lp].vertex_index;i=vertex%n;j=vertex//n
            u=(1 if wraps and i==0 else i/n)*circumference
            crown.data.uv_layers.active.data[lp].uv=(u,j/rows*math.pi/2*ry/textile_swatch)
    solid(crown,.012)
    parts=[crown]
    # Continuous crown: protruding tuft/ear surfaces are hidden only while worn.
    # Never punch ear holes in this variant or flatten/deform the pet's anatomy.
    back_hit,_,_,_=head_surface.ray_cast(Vector((cx,cy+.055,cz-1)),Vector((0,0,1)))
    opening_z=back_hit.z-.006 if back_hit is not None else cz-rz
    opening=sphere('Hueco posterior',(cx,cy+.055,opening_z),(.075,.057,.085),None)
    subtract(crown,opening)
    bpy.data.objects.remove(opening,do_unlink=True)
    # Round the cut fabric thickness instead of leaving a raw jagged Boolean edge.
    bevel=crown.modifiers.new('Borde redondeado de tela','BEVEL');bevel.width=.0025;bevel.segments=3
    bevel.limit_method='ANGLE';bevel.angle_limit=.45
    bpy.context.view_layer.objects.active=crown;bpy.ops.object.modifier_apply(modifier=bevel.name)
    # Finish the real outer contours (hem and openings) with softly rounded binding.
    bm=bmesh.new();bm.from_mesh(crown.data);bm.normal_update();bm.verts.ensure_lookup_table()
    center=C@Vector((cx,cy,cz))
    outer={f:f.normal.dot((f.calc_center_median()-center).normalized())>.72 for f in bm.faces}
    edges=[e for e in bm.edges if len(e.link_faces)==2 and outer[e.link_faces[0]]!=outer[e.link_faces[1]]]
    adjacent={}
    for e in edges:
        a,b=[v.index for v in e.verts];adjacent.setdefault(a,[]).append(b);adjacent.setdefault(b,[]).append(a)
    visited=set()
    for start in adjacent:
        if start in visited:continue
        chain=[];current=start;previous=None
        while current not in visited:
            visited.add(current);chain.append(tuple(CI@bm.verts[current].co))
            candidates=[k for k in adjacent[current] if k!=previous]
            if not candidates:break
            previous,current=current,candidates[0]
        if len(chain)>8:parts.append(tube('Ribete de tela terminado',chain,.0028,coral,cyclic=current==start))
    bm.free()
    tree=BVHTree.FromPolygons([CI@v.co for v in crown.data.vertices],[list(f.vertices) for f in crown.data.polygons])
    def seated(pt):
        q=Vector(pt);hit,normal,_,distance=tree.find_nearest(q)
        return tuple(hit+normal*.0016) if hit is not None and distance<.025 else None
    # Broken stitches naturally stop at ear/rear openings, never bridge holes.
    for k in range(6):
        a=k*math.tau/6
        seamline=[seated(point(a,tmax*j/80,.002)) for j in range(5,79)]
        segment=[]
        for q in seamline:
            if q:segment.append(q)
            else:
                if len(segment)>1:parts.append(tube('Costura acolchada',segment,.0022,coral))
                segment=[]
        if len(segment)>1:parts.append(tube('Costura acolchada',segment,.0022,coral))
        for shift in (-.018,.018):
            for j in range(5,78,2):
                points=[seated(point(a+shift,tmax*j/80,.002)),seated(point(a+shift,tmax*(j+.9)/80,.002))]
                if all(points):parts.append(tube('Puntada de panel',points,.0012,thread))
    # Flexible shaped brim; curved across its width and softly downturned at tip.
    br=[];bf=[];ns=64;rs=12
    for j in range(rs+1):
        t=j/rs
        for i in range(ns+1):
            a=-.95+1.9*i/ns
            root=point(a,tmax)
            x=root[0]*(1+.08*t)
            # Rolled visor: downturned sides, padded central arch and soft tip.
            y=root[1]+.018*math.sin(math.pi*t)+.020*t-.065*math.sin(a)**2*t
            z=root[2]+.110*t*math.cos(a*.7)
            br.append((x,y,z))
    for j in range(rs):
        for i in range(ns):
            v=j*(ns+1)+i;bf.append((v,v+1,v+ns+2,v+ns+1))
    brim=mesh('Visera de algodón curvada',br,bf,coral)
    for lp in brim.data.loops:
        x,y,z=br[lp.vertex_index];brim.data.uv_layers.active.data[lp.index].uv=(x/textile_swatch,z/textile_swatch)
    solid(brim,.014)
    bevel=brim.modifiers.new('Canto de visera suave','BEVEL');bevel.width=.004;bevel.segments=3;bevel.limit_method='ANGLE';bevel.angle_limit=.55
    bpy.context.view_layer.objects.active=brim;bpy.ops.object.modifier_apply(modifier=bevel.name);parts.append(brim)
    edge=[(x,y+.001,z) for x,y,z in br[rs*(ns+1):(rs+1)*(ns+1)]]
    parts.append(tube('Ribete redondeado de la visera',edge,.004,coral))
    for j in (rs-2,rs-1):
        row=[(x,y+.008,z) for x,y,z in br[j*(ns+1):(j+1)*(ns+1)]]
        for i in range(0,ns-1,3):parts.append(tube('Doble pespunte de visera',row[i:i+2],.0012,thread))
    # Small volumetric embroidered heart seated on the crown, not a floating fan.
    heartpts=[];rings=8;count=128
    hc=(cx,cy+ry*.43,cz+rz*.90)
    for j in range(1,rings+1):
        r=j/rings
        for i in range(count):
            a=i*math.tau/count
            x=hc[0]+.11*r*16*math.sin(a)**3/32
            y=hc[1]+.11*r*(13*math.cos(a)-5*math.cos(2*a)-2*math.cos(3*a)-math.cos(4*a))/32
            hit,_,_,_=tree.ray_cast(Vector((x,y,cz+1)),Vector((0,0,-1)))
            fabric_z=hit.z if hit is not None else cz+rz*math.sqrt(max(.01,1-((x-cx)/rx)**2-((y-cy)/ry)**2))
            z=fabric_z+.002+.012*(1-r*r)
            heartpts.append((x,y,z))
    hf=[tuple(reversed(range(count)))]
    hf.extend((j*count+i,j*count+(i+1)%count,(j+1)*count+(i+1)%count,(j+1)*count+i) for j in range(rings-1) for i in range(count))
    heart=mesh('Corazón bordado acolchado',heartpts,hf,ivory);solid(heart,.004);parts.append(heart)
    for i in range(count):
        stitch=[Vector(heartpts[j*count+i])+Vector((0,0,.001)) for j in range(rings)]
        parts.append(tube('Hilo bordado del corazón',[tuple(p) for p in stitch],.00055,thread))
    parts.append(sphere('Botón forrado',(cx,cy+ry+.008,cz-.036),(.019,.010,.019),coral))
    # Embroidered ventilation eyelets sit on the actual fabric normal.
    for a in (-1.12,1.12,2.15,-2.15):
        q=point(a,.58);hit,normal,_,_=tree.find_nearest(Vector(q))
        tangent=normal.cross(Vector((0,1,0))).normalized();up=normal.cross(tangent).normalized()
        pts=[tuple(hit+normal*.002+tangent*(.008*math.cos(i*math.tau/32))+up*(.008*math.sin(i*math.tau/32))) for i in range(32)]
        parts.append(tube('Ojal bordado',pts,.0017,thread,True))
    # Adjustable rear strap and buckle, placed at the rear rather than on the face.
    by=cy+.026
    def strap_point(x,y,offset=0):
        # A curved, padded fabric band follows the head instead of floating flat.
        hit,_,_,_=head_surface.ray_cast(Vector((x,y,cz-1)),Vector((0,0,1)))
        back=hit.z-.006-offset if hit is not None else cz-(rz-.003)*math.sqrt(max(.01,1-((x-cx)/rx)**2-((y-cy)/ry)**2))-.003-offset
        return (x,y,back)
    strap_points=[strap_point(cx-.105+.210*i/48,by+dy) for dy in (-.015,.015) for i in range(49)]
    strap_faces=[(i,i+1,50+i,49+i) for i in range(48)]
    strap=mesh('Cinta posterior de algodón acolchada',strap_points,strap_faces,coral)
    for lp in strap.data.loops:
        x,y,z=strap_points[lp.vertex_index];strap.data.uv_layers.active.data[lp.index].uv=(x/textile_swatch,y/textile_swatch)
    solid(strap,.008)
    bevel=strap.modifiers.new('Canto cosido redondeado','BEVEL');bevel.width=.003;bevel.segments=3;bevel.limit_method='ANGLE'
    bpy.context.view_layer.objects.active=strap;bpy.ops.object.modifier_apply(modifier=bevel.name);parts.append(strap)
    for dy in (-.013,.013):
        parts.append(tube('Ribete de cinta posterior',[strap_point(cx-.105+.210*i/48,by+dy,.004) for i in range(49)],.0016,coral))
        for i in range(26):
            x=cx-.10+.20*i/26
            parts.append(tube('Pespunte de cinta posterior',[strap_point(x,by+dy*.73,.005),strap_point(x+.004,by+dy*.73,.005)],.0009,thread))
    # Rounded metal buckle and central pin rest on the fabric, including at the sides.
    buckle=[];bx=cx+.052
    for corner_x,corner_y,start in ((bx+.013,by+.013,0),(bx-.013,by+.013,math.pi/2),(bx-.013,by-.013,math.pi),(bx+.013,by-.013,3*math.pi/2)):
        for i in range(7):
            a=start+i*math.pi/12
            buckle.append(strap_point(corner_x+.004*math.cos(a),corner_y+.004*math.sin(a),.008))
    parts.append(tube('Hebilla dorada redondeada',buckle,.0028,gold,True))
    parts.append(tube('Pasador dorado de hebilla',[strap_point(bx,by-.017,.008),strap_point(bx,by+.017,.008)],.0022,gold))
    # Finishing around ear intersections, generated from the actual intersection.
    # Do not add a trim until a real connected hole contour can be extracted.
    for obj in parts:
        obj['article']='cap_coral_r2';obj['species']=sp
    return parts

def pet_meshes(data):
    before=set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(ROOT/data['source']))
    original=[o for o in bpy.data.objects if o not in before]
    source=next(mat for o in original if o.type=='MESH' for mat in o.data.materials if mat is not None).copy()
    if source.use_nodes:
        bsdf=source.node_tree.nodes.get('Principled BSDF')
        if bsdf:bsdf.inputs['Roughness'].default_value=.78;bsdf.inputs['Metallic'].default_value=0
    for obj in original:bpy.data.objects.remove(obj,do_unlink=True)
    result=[]
    for i,m in enumerate(data['meshes']):
        mat=source if m.get('source_material') else material('Color original '+str(i),'#FFFFFF',m['material']['roughness'])
        if not m.get('source_material'):
            # Three.js snapshots already contain linear RGB, not sRGB bytes.
            mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(*m['material']['color'],1)
        obj=mesh(m['name'],np.asarray(m['positions']).reshape(-1,3).tolist(),np.asarray(m['indices']).reshape(-1,3).tolist(),mat,False)
        if m.get('normals'):
            obj.data.normals_split_custom_set_from_vertices([C@Vector(n) for n in np.asarray(m['normals']).reshape(-1,3)])
        if m.get('uv'):
            layer=obj.data.uv_layers.new(name='UVMap')
            for loop in obj.data.loops:
                u,v=m['uv'][loop.vertex_index*2:loop.vertex_index*2+2]
                # glTF uses top-origin texture UVs; Blender's imported images use bottom-origin.
                layer.data[loop.index].uv=(u,1-v)
        result.append(obj)
    # Keep the actual face/ears/tuft, but replace the deformed torso snapshot.
    # The rejected human rig left small folded triangles on the penguin's back.
    sp=data['species'];neck=fits[sp]['skull_center'][1]-fits[sp]['skull_radius'][1]+.006
    original_body=result[0]
    bm=bmesh.new();bm.from_mesh(original_body.data)
    bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.000001,plane_co=C@Vector((0,neck,0)),plane_no=C@Vector((0,1,0)),clear_inner=True)
    bm.to_mesh(original_body.data);bm.free();original_body.name='Cabeza original · facciones y UV conservadas';original_body['rig_bone']='Head'
    kept=[original_body]
    palette={'penguin':('#30313F','#FFF4E8'), 'bear':('#B9834F','#ECD6AD'), 'pig':('#F3AAB8',None), 'chick':('#F7DB7A',None)}
    coat,bib=palette[sp]
    skin=material('Cuerpo '+sp,coat,.82)
    dimensions={'penguin':(.205,.235,.225),'bear':(.245,.235,.255),'pig':(.25,.22,.235),'chick':(.22,.225,.225)}
    rx,ry,rz=dimensions[sp];cy=neck-ry+.035;cz=-.025
    torso=sphere('Torso nuevo · silueta redondeada',(0,cy,cz),(rx,ry,rz),skin)
    torso['rig_bone']='Body';kept.append(torso)
    data['restart_body']={'center':[0,cy,cz],'radius':[rx,ry,rz],'neck':neck}
    if bib:
        bp=[];bf=[];n=64;nr=14
        for j in range(nr+1):
            r=.003+(1-.003)*j/nr
            for i in range(n):
                a=math.tau*i/n;x=rx*.79*r*math.sin(a);y=cy+ry*.79*r*math.cos(a)
                z=cz+rz*math.sqrt(max(.001,1-(x/rx)**2-((y-cy)/ry)**2))+.0018
                bp.append((x,y,z))
        for j in range(nr):
            for i in range(n):bf.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
        bf.append(tuple(reversed(range(n))))
        belly=mesh('Pecho suave integrado',bp,bf,material('Pecho '+sp,bib,.85));belly['rig_bone']='Body';kept.append(belly)
    # Compact mascot limbs with stable, single-bone weights; no human shoulders.
    for side,sign in [('Left',1),('Right',-1)]:
        arm_y=cy+.005
        arm_scale={'penguin':(.060,.135,.079),'bear':(.074,.14,.088),'pig':(.066,.105,.075),'chick':(.058,.113,.079)}[sp]
        wing=sphere('Aleta o brazo '+side,(sign*(rx+.026),arm_y,cz+.007),arm_scale,skin)
        wing['rig_bone']=side+'Wing';kept.append(wing)
        # Original feet stay distinct; their UVs and the approved rounded penguin toes survive.
        if sp=='penguin':
            foot=next(o for o in result if o.name==side+'RoundedFoot');foot['rig_bone']=side+'Foot';kept.append(foot)
        else:
            foot=original_body.copy();foot.data=original_body.data.copy()
            # Recover the original uncut mesh rather than the face-only copy.
            foot.data=bpy.data.meshes.new('Patas originales '+side)
            raw=data['meshes'][0];foot.data.from_pydata([C@Vector(p) for p in np.asarray(raw['positions']).reshape(-1,3)],[],np.asarray(raw['indices']).reshape(-1,3).tolist());foot.data.update();foot.data.materials.append(source)
            uv=foot.data.uv_layers.new(name='UVMap')
            for lp in foot.data.loops:
                u,v=raw['uv'][lp.vertex_index*2:lp.vertex_index*2+2];uv.data[lp.index].uv=(u,1-v)
            bpy.context.collection.objects.link(foot)
            bm=bmesh.new();bm.from_mesh(foot.data)
            geom=lambda:list(bm.verts)+list(bm.edges)+list(bm.faces)
            bmesh.ops.bisect_plane(bm,geom=geom(),dist=.000001,plane_co=C@Vector((0,.145,0)),plane_no=C@Vector((0,1,0)),clear_outer=True)
            bmesh.ops.bisect_plane(bm,geom=geom(),dist=.000001,plane_co=(0,0,0),plane_no=(1,0,0),clear_inner=sign>0,clear_outer=sign<0)
            bm.to_mesh(foot.data);bm.free()
            for face in foot.data.polygons:face.use_smooth=True
            foot.name='Pata original '+side;foot['rig_bone']=side+'Foot';kept.append(foot)
    for obj in result:
        if obj not in kept:bpy.data.objects.remove(obj,do_unlink=True)
    return kept

def rig_pet(data, objects):
    # Dedicated mascot anatomy: no human fingers, long shoulders or thigh-driven belly.
    arm=bpy.data.armatures.new('Rig cartoon · siete controles')
    rig=bpy.data.objects.new('NidoMascotRigR2',arm);bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
    layout={'Root':((0,0,0),(0,.08,0),None),'Body':((0,.27,0),(0,.56,0),'Root'),
            'Head':((0,.60,0),(0,.86,0),'Body'),
            'LeftWing':((.22,.46,0),(.27,.27,0),'Body'),
            'RightWing':((-.22,.46,0),(-.27,.27,0),'Body'),
            'LeftFoot':((.12,.075,0),(.12,.075,.09),'Root'),
            'RightFoot':((-.12,.075,0),(-.12,.075,.09),'Root')}
    for name,(head,tail,parent) in layout.items():
        bone=arm.edit_bones.new(name);bone.head=C@Vector(head);bone.tail=C@Vector(tail)
        if parent:bone.parent=arm.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
    for obj in objects:
        groups={name:obj.vertex_groups.new(name=name) for name in layout}
        groups[obj['rig_bone']].add(list(range(len(obj.data.vertices))),1,'REPLACE')
        modifier=obj.modifiers.new('Rig cartoon R2','ARMATURE');modifier.object=rig;obj.parent=rig
    rig.animation_data_create()
    def move(bone,p):
        bone.location=bone.bone.matrix_local.to_3x3().inverted()@(C@Vector(p))
    def turn(bone,axis,angle):
        local=bone.bone.matrix_local.to_3x3().inverted()@(C@Vector(axis))
        bone.rotation_quaternion=Quaternion(local.normalized(),angle)
    fps=30;bpy.context.scene.render.fps=fps
    for clip,length in [('Rest_R2',90),('Run_R2',24),('Jump_R2',30)]:
        action=bpy.data.actions.new(clip);rig.animation_data.action=action
        for frame in range(length+1):
            phase=frame/length;angle=phase*math.tau
            for bone in rig.pose.bones:bone.location=(0,0,0);bone.rotation_mode='QUATERNION';bone.rotation_quaternion=(1,0,0,0);bone.scale=(1,1,1)
            body=rig.pose.bones['Body'];head=rig.pose.bones['Head']
            if clip=='Rest_R2':
                body.scale=(1+.004*math.sin(angle),1+.005*math.sin(angle),1+.004*math.sin(angle))
                turn(head,(0,0,1),.008*math.sin(angle))
            elif clip=='Run_R2':
                move(body,(0,.007*(1-math.cos(angle*2)),0));turn(body,(0,0,1),.035*math.sin(angle))
                turn(head,(0,0,1),-.017*math.sin(angle))
                for side,sign in [('Left',1),('Right',-1)]:
                    wing=rig.pose.bones[side+'Wing'];turn(wing,(1,0,0),.08*math.sin(angle)*sign)
                    foot=rig.pose.bones[side+'Foot'];s=math.sin(angle)*sign
                    move(foot,(0,.018*max(0,s),.023*s));turn(foot,(1,0,0),.09*s)
            else:
                # In-place clip: game physics supplies vertical travel once.
                crouch=max(0,1-abs(phase-.12)/.12)*.02+max(0,1-abs(phase-.88)/.12)*.012
                move(body,(0,-crouch,0))
                for side,sign in [('Left',1),('Right',-1)]:
                    turn(rig.pose.bones[side+'Wing'],(0,0,1),sign*.20*math.sin(math.pi*phase)**2)
                    turn(rig.pose.bones[side+'Foot'],(1,0,0),.08*math.sin(math.pi*phase)**2)
            for bone in rig.pose.bones:
                bone.keyframe_insert('location',frame=frame);bone.keyframe_insert('rotation_quaternion',frame=frame);bone.keyframe_insert('scale',frame=frame)
        track=rig.animation_data.nla_tracks.new();track.name=clip
        track.strips.new(clip,0,action)
        rig.animation_data.action=None
    return rig

def export_selected(path, objects, animations=False):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:obj.hide_set(False);obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=animations,export_animation_mode='NLA_TRACKS',export_yup=True)

def build():
    reports=[]
    for sp in species_names:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        data=json.loads((ROOT/'design/blender/fitting'/(sp+'.json')).read_text())
        coral=material('Algodón coral','#EC6276',.90,True)
        for node in coral.node_tree.nodes:
            if node.type=='NORMAL_MAP':node.inputs['Strength'].default_value=.75
        ivory=material('Bordado crema','#FFF2DF',.88,True)
        thread=material('Hilo marfil','#FFF2DF',.85)
        gold=material('Hebilla latón','#D9AC55',.3,metal=True)
        cap=build_cap(sp,data,coral,thread,ivory,gold)
        # Combine sewn details into material primitives, avoiding hundreds of draw calls.
        bpy.ops.object.select_all(action='DESELECT')
        for obj in cap:obj.select_set(True)
        bpy.context.view_layer.objects.active=cap[0];bpy.ops.object.join()
        cap=[bpy.context.object];cap[0].name='Gorra coral R2 · pieza completa'
        cap_path=OUT/('cap_coral_r2_'+sp+'.glb');export_selected(cap_path,cap)
        pet_path=OUT/('pet_rig_r2_'+sp+'.glb')
        if '--cap-only' in sys.argv:
            bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(MASTER/('GORRA-R2-'+sp+'.blend')),compress=True)
            reports.append({'species':sp,'label':species_names[sp],'pet':pet_path.relative_to(ROOT).as_posix(),'cap':cap_path.relative_to(ROOT).as_posix(),'pet_sha256':hashlib.sha256(pet_path.read_bytes()).hexdigest(),'cap_sha256':hashlib.sha256(cap_path.read_bytes()).hexdigest()})
            continue
        pets=pet_meshes(data);rig=rig_pet(data,pets)
        export_selected(pet_path,[rig,*pets],True)
        # Master keeps clothing and pet separate, with a reversible head attachment.
        for obj in cap:
            world=obj.matrix_world.copy()
            obj.parent=rig;obj.parent_type='BONE';obj.parent_bone='Head'
            bpy.context.view_layer.update();obj.matrix_world=world
        for track in rig.animation_data.nla_tracks:track.mute=track.name!='Rest_R2'
        bpy.context.scene['status']='Experimental R2; visual review required; not production'
        bpy.context.scene.frame_set(0)
        bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(MASTER/('NIDO-R2-'+sp+'.blend')),compress=True)
        reports.append({'species':sp,'label':species_names[sp],'pet':pet_path.relative_to(ROOT).as_posix(),'cap':cap_path.relative_to(ROOT).as_posix(),
                        'pet_sha256':hashlib.sha256(pet_path.read_bytes()).hexdigest(),'cap_sha256':hashlib.sha256(cap_path.read_bytes()).hexdigest()})
        print('RESTART_EXPORTED',sp,flush=True)
    if '--species' in sys.argv and (OUT/'catalog.json').exists():
        previous=json.loads((OUT/'catalog.json').read_text())['variants']
        reports=[*reports,*[row for row in previous if row['species'] not in species_names]]
    for row in reports:
        fit=fits[row['species']]
        row['headwear_occlusion']={'center':fit['skull_center'],'radius':[r+d for r,d in zip(fit['skull_radius'],(.014,.013,.014))],'hem_margin':.012}
    metadata=json.loads((OUT/'catalog.json').read_text()) if (OUT/'catalog.json').exists() else {}
    metadata.update({'status':'experimental','visible':False,'reference':'design/wardrobe-restart/penguin-dulce-reference-v1.png','variants':reports})
    (OUT/'catalog.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2))
    print('RESTART_READY',flush=True)

if __name__=='__main__':build()
