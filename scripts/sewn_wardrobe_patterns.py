"""Editable sewn patterns: shared construction, independent anatomical fitting.

Never transforms a pet. Coordinates below are the approved penguin pattern;
the final fitting pass measures the immutable natural-rest capture of each pet.
"""
import json, math
import bpy, bmesh
from mathutils import Vector
from mathutils.kdtree import KDTree
from mathutils.bvhtree import BVHTree
from wardrobe_materials import make_material

STYLES={
    'shirt_love':('#FFF0D9','cotton'),
    'jacket_denim':('#92B9D5','denim'),
    'coat_cloud':('#B3C4A2','wool'),
    'dress_petal':('#F5A8B6','poplin'),
    'hoodie_nido':('#C1ADE2','cotton'),
}

def finish_and_fit(base,parts,source,field,species,item,root):
    if item not in STYLES:raise ValueError('Unknown editable pattern '+item)
    cfg=json.loads((root/'design/wardrobe-restart/original-shirt-patterns.json').read_text(encoding='utf-8'))['species'][species]
    target=json.loads((root/f'design/wardrobe-restart/fitting/{species}-original.json').read_text(encoding='utf-8'))
    dims={'hem':.235,'top':.540,'cuff_x':.267,'cuff_y':.402,'cuff_slope':.012/.055,
          'shoulder_start':.17,'sleeve_full':.28,'sleeve_min_y':.30,
          'sleeve_volume':{'center':[.245,.460,-.012],'radius':[.095,.110,.170]}}
    white=make_material('#FFF0DC','cotton',root/'design/blender/fabrics')
    thread=base.material('Hilo crema de pespunte','#EEDCC3',.95)
    gold=base.material('Latón de botones','#C99A55',.38,metal=True)
    cloth=parts[0]
    if item!='shirt_love':
        fabric=make_material(*STYLES[item],root/'design/blender/fabrics')
        original_material=cloth.data.materials[0]
        for obj in parts:
            for index,mat in enumerate(obj.data.materials):
                if mat==original_material:obj.data.materials[index]=fabric
        # Embroidery is reserved for the tee and hoodie; lapels and ruffles have
        # their own construction, not a recoloured heart shirt.
        if item in ('jacket_denim','coat_cloud','dress_petal'):
            embroidery=parts.pop(1);bpy.data.objects.remove(embroidery,do_unlink=True)
        def panel(name,points,faces,mat,thickness=.008):
            obj=base.mesh(name,points,faces,mat);base.solid(obj,thickness);parts.append(obj);return obj
        def line(name,points,radius=.0012,mat=thread):
            obj=base.tube(name,points,radius,mat,False);parts.append(obj);return obj
        def frontz(x,y):
            t=(y-.235)/.340;rx=.254-.032*t+.006*math.sin(t*math.pi)+.050*max(0,min(1,(y-.490)/.085))**2
            rz=.265-.059*t+.008*math.sin(t*math.pi)
            return -.025+rz*math.sqrt(max(.01,1-(x/rx)**2))+.021
        def patch(name,corners,mat):
            # Subdivide so a pocket/placket follows the belly instead of floating
            # as a planar rectangular decal.
            points=[];faces=[];steps=12
            for j in range(steps+1):
                for i in range(steps+1):
                    u=i/steps;v=j/steps
                    x=(1-v)*((1-u)*corners[0][0]+u*corners[1][0])+v*((1-u)*corners[3][0]+u*corners[2][0])
                    y=(1-v)*((1-u)*corners[0][1]+u*corners[1][1])+v*((1-u)*corners[3][1]+u*corners[2][1])
                    points.append((x,y,frontz(x,y)))
            for j in range(steps):
                for i in range(steps):
                    k=j*(steps+1)+i;faces.append((k,k+1,k+steps+2,k+steps+1))
            return panel('Panel · '+name,points,faces,mat)
        if item in ('jacket_denim','coat_cloud'):
            trim=white if item=='coat_cloud' else fabric
            patch('tapeta central cosida',[(-.014,.251),(.014,.251),(.014,.502),(-.014,.502)],trim)
            for sign in (-1,1):
                patch('solapa '+str(sign),[(sign*.025,.440),(sign*.092,.485),(sign*.125,.510),(sign*.026,.508)],trim)
                line('Costura tapeta '+str(sign),[(sign*.011,y,frontz(sign*.011,y)+.006) for y in (.26,.31,.36,.41,.46,.49)])
                if item=='jacket_denim':
                    patch('bolsillo pecho '+str(sign),[(sign*.065,.365),(sign*.140,.365),(sign*.145,.428),(sign*.070,.428)],fabric)
                    for yy in (.370,.425):line('Pespunte bolsillo',[(sign*x,yy,frontz(sign*x,yy)+.006) for x in (.071,.085,.10,.12,.136)])
            for y in (.285,.360,.435):
                button=base.sphere('Botón cosido',(0,y,frontz(0,y)+.013),(.015,.015,.008),gold);parts.append(button)
            if item=='coat_cloud':
                # Fleece edging uses a thick rounded woven binding, not spheres
                # on the shoulder. Both edges remain continuous sewn loops.
                for obj in parts:
                    if obj.name.startswith('Dobladillo'):
                        for i in range(len(obj.data.materials)):obj.data.materials[i]=make_material('#FFF4E5','wool',root/'design/blender/fabrics')
        elif item=='dress_petal':
            for tier,(top,bottom,radius) in enumerate([(.345,.255,.286),(.290,.202,.326)]):
                pts=[];faces=[];rings=12;count=128
                for row in range(rings+1):
                    t=row/rings
                    for col in range(count):
                        a=col*math.tau/count;r=.243+(radius-.243)*t+.005*math.sin(a*14)*t
                        pts.append((r*math.sin(a),top+(bottom-top)*t,-.025+r*1.03*math.cos(a)))
                for row in range(rings):
                    for col in range(count):
                        k=row*count+col;faces.append((k,row*count+(col+1)%count,(row+1)*count+(col+1)%count,k+count))
                panel('Volante pétalo · falda '+str(tier),pts,faces,fabric,.012)
                edge=pts[-count:];parts.append(base.tube('Dobladillo falda '+str(tier),edge,.006,fabric,True))
            # Small embroidered blossoms have real petal relief.
            for x,y in [(-.11,.397),(.13,.404),(-.065,.295),(.095,.25)]:
                z=frontz(x,y)+.01
                for k in range(5):
                    a=k*math.tau/5;parts.append(base.sphere('Pétalo bordado',(x+.009*math.cos(a),y+.009*math.sin(a),z),(.009,.006,.003),white))
        elif item=='hoodie_nido':
            patch('bolsillo canguro',[(-.120,.285),(.120,.285),(.090,.360),(-.090,.360)],fabric)
            for sign in (-1,1):
                line('Cordón de capucha '+str(sign),[(sign*.055,.501,frontz(sign*.055,.501)+.008),(sign*.049,.472,frontz(sign*.049,.472)+.014),(sign*.058,.435,frontz(sign*.058,.435)+.014)],.003,white)
            # Hood lowered behind the neck: an open sewn bowl, never a sphere
            # enclosing or deforming the pet's head.
            pts=[];faces=[];count=80;rings=10
            for row in range(rings+1):
                t=row/rings
                for col in range(count+1):
                    a=math.pi/2+math.pi*col/count
                    r=.214+.030*math.sin(t*math.pi)
                    pts.append((r*math.sin(a),.375+.100*t,-.055+r*math.cos(a)-.014*t))
            for row in range(rings):
                for col in range(count):
                    k=row*(count+1)+col;faces.append((k,k+1,k+count+2,k+count+1))
            panel('Panel · capucha bajada cosida',pts,faces,fabric,.016)
            # Close every exposed hood cut with its own soft folded binding.
            # The hood is sewn below the neckline, not stacked on its upper rim.
            edge=pts[-(count+1):]+[pts[row*(count+1)+count] for row in range(rings-1,-1,-1)]+pts[:count+1]+[pts[row*(count+1)] for row in range(1,rings)]
            parts.append(base.tube('Ribete continuo de capucha',edge,.006,fabric,True))
    # Anatomical fitting uses separate sleeve and torso fields. The source pet
    # mesh, rig, UVs and textures are never scaled, masked destructively or saved.
    if species!='penguin':
        fit_config=json.loads((root/'design/wardrobe-restart/sewn-species-fit.json').read_text(encoding='utf-8'))['species'][species]
        hem=cfg['hem'];top=fit_config['collar_top']
        sy=(top-hem)/(.540-.235);sx=cfg['torso_half_width']/.254;sz=cfg['torso_depth_radius']/.265
        centerz=(target['body']['min'][2]+target['body']['max'][2])/2
        cuff=list(cfg['cuff_center']);cuff_scale=cfg['sleeve_radius'][0]/.095
        # Jackets and warm garments have their own sleeve length, rather than
        # inheriting a short tee sleeve under a differently coloured material.
        cuff[1]-={'jacket_denim':.025,'coat_cloud':.050,'hoodie_nido':.045}.get(item,0)
        tree=KDTree(len(field))
        for i,entry in enumerate(field):tree.insert(Vector(entry[:3]),i)
        tree.balance()
        skin_points=[];skin_faces=[];head_faces=[]
        for mesh in target['meshes']:
            offset=len(skin_points);skin_points.extend(Vector(mesh['positions'][i:i+3]) for i in range(0,len(mesh['positions']),3))
            for i in range(0,len(mesh['indices']),3):
                tri=mesh['indices'][i:i+3];arm=head=0
                for vi in tri:
                    for bone,w in zip(mesh['skinIndex'][vi*4:vi*4+4],mesh['skinWeight'][vi*4:vi*4+4]):
                        name=target['boneNames'][bone]
                        if name.endswith(('Shoulder','Arm','ForeArm','Hand')):arm+=w/3
                        if name.endswith('Head'):head+=w/3
                yy=sum(mesh['positions'][vi*3+1] for vi in tri)/3
                if arm<.60 and head<.5 and hem-.02<yy<top-.025:skin_faces.append(tuple(offset+vi for vi in tri))
                if head>.70:head_faces.append(tuple(offset+vi for vi in tri))
        torso_surface=BVHTree.FromPolygons(skin_points,skin_faces,all_triangles=True)
        head_surface=BVHTree.FromPolygons(skin_points,head_faces,all_triangles=True)
        neck_y=.524;nt=(neck_y-.235)/.340
        nw=(neck_y-.490)/.085;nw=nw*nw*(3-2*nw)
        neck_rx=.254-.032*nt+.006*math.sin(nt*math.pi)+.050*nw
        neck_rz=.265-.059*nt+.008*math.sin(nt*math.pi)
        neck_offsets=[]
        for i in range(128):
            a=i*math.tau/128;factor=fit_config.get('neck_taper',1)
            x=neck_rx*math.sin(a)*sx*factor;z=centerz+neck_rz*math.cos(a)*sz*factor
            hit,_,_,_=head_surface.ray_cast(Vector((x,.15,z)),Vector((0,1,0)),1.2)
            baseline=hem+(neck_y-.235)*sy
            neck_offsets.append(max(-.045,min(.075,hit.y-.018-baseline)) if hit is not None else 0)
        # Follow the underside of the supplied head, rather than pushing a flat
        # ring through it. Circular relaxation keeps the binding smooth while
        # the raw cut and folded edge use exactly the same contact contour.
        for _ in range(3):neck_offsets=[.5*v+.25*(neck_offsets[(i-1)%128]+neck_offsets[(i+1)%128]) for i,v in enumerate(neck_offsets)]
        relief=[]
        for entry in field:
            yy=hem+(entry[1]-.235)*sy;amount=0
            if entry[4]<.10 and hem-.01<yy<top-.035:
                radial=Vector((entry[0]*sx,0,(entry[2]+.025)*sz))
                if radial.length>1e-8:
                    hit,_,_,distance=torso_surface.ray_cast(Vector((0,yy,centerz)),radial.normalized(),1)
                    if hit is not None:amount=max(0,distance+.025-radial.length)
            relief.append(amount)
        # Cloth follows the broad body contour with ease. The raw surface also
        # contains tiny arm/skin irregularities: transferring each ray verbatim
        # embossed lumpy anatomy into the jacket instead of a soft woven panel.
        # Relax only the displacement field, keeping the sewn pattern, collar,
        # sleeve openings and all existing decorative relief intact.
        neighbors=[tree.find_n(Vector(entry[:3]),20) if entry[4]<.10 else [] for entry in field]
        for _ in range(3):
            smoothed=[]
            for i,entry in enumerate(field):
                nearby=[(index,math.exp(-distance*distance/(2*.028**2))) for _,index,distance in neighbors[i] if field[index][4]<.10]
                total=sum(w for _,w in nearby)
                average=sum(relief[index]*w for index,w in nearby)/total if total else relief[i]
                smoothed.append(.25*relief[i]+.75*average)
            relief=smoothed
        def fit(q,entry=None,neck_binding=False):
            _,index,_=tree.find(q)
            if entry is None:entry=field[index]
            t=0 if neck_binding else entry[4];sign=1 if q.x>=0 else -1
            body=Vector((q.x*sx,hem+(q.y-.235)*sy,centerz+(q.z+.025)*sz))
            u=max(0,min(1,(q.y-.445)/(.524-.445)))
            taper=1-(1-fit_config.get('neck_taper',1))*u*u*(3-2*u)
            body.x*=taper;body.z=centerz+(body.z-centerz)*taper
            a=(math.atan2(q.x/neck_rx,(q.z+.025)/neck_rz)/math.tau)%1*128
            lo=int(a);delta=neck_offsets[lo%128]*(1-(a-lo))+neck_offsets[(lo+1)%128]*(a-lo)
            if fit_config.get('follow_head_underside',False):body.y+=delta*u*u*(3-2*u)
            if t<.10 and hem-.01<body.y<top-.035:
                origin=Vector((0,body.y,centerz));radial=body-origin
                if radial.length>1e-8:
                    direction=radial.normalized()
                    body+=direction*relief[index]*(1-t/.10)
            arm=Vector((sign*(cuff[0]+(abs(q.x)-.267)*cuff_scale),cuff[1]+(q.y-.402)*sy,cuff[2]+(q.z+.012)*cfg['sleeve_radius'][2]/.132))
            return body.lerp(arm,t)
        for obj in parts:
            matrix=obj.matrix_world.copy();inverse=matrix.inverted()
            neck_binding='Cuello' in obj.name
            for v in obj.data.vertices:
                q=base.CI@(matrix@v.co);v.co=inverse@(base.C@fit(q,neck_binding=neck_binding))
            bm=bmesh.new();bm.from_mesh(obj.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(obj.data);bm.free();obj.data.update()
        transformed=[]
        for entry in field:transformed.append([*fit(Vector(entry[:3]),entry),*entry[3:]])
        field=transformed
        dims.update(hem=hem,top=top,cuff_x=cuff[0],cuff_y=cuff[1],cuff_slope=.012*sy/(.055*cuff_scale),shoulder_start=cfg['shoulder_start'],sleeve_full=cfg['sleeve_full'],sleeve_min_y=cfg['sleeve_min_y'],sleeve_volume={'center':cfg['sleeve_center'],'radius':cfg['sleeve_radius']})
    return parts,target,field,dims
