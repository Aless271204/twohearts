"""Tailor the supplied Meshy meshes in Blender using the actual app resting pets.
The source GLBs are never overwritten. Exported heads use app model coordinates.
"""
import bpy, bmesh, json, math, sys, hashlib
from pathlib import Path
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree

REPO=Path(__file__).resolve().parents[1]
DIR=REPO/'design'/'blender'/'fitting';DIR.mkdir(parents=True,exist_ok=True)
OUT=REPO/'assets'/'runner'/'accessories'
settings=json.loads((REPO/'design'/'blender'/'head-tailoring.json').read_text(encoding='utf-8'))
only_cap='--cap-only' in sys.argv
only_penguin='--penguin-only' in sys.argv
report_path=DIR/'tailoring-report.json'
previous_report=json.loads(report_path.read_text(encoding='utf-8')) if only_penguin and report_path.exists() else []
items={k:v for k,v in settings['items'].items() if v.get('visible',True) and (not only_cap or k=='cap_pink')}
C=Matrix.Rotation(math.pi/2,4,'X');CI=C.inverted()
bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene;scene.name='NIDO · Encaje Blender';scene.unit_settings.system='METRIC'
sources=bpy.data.collections.new('00 · Originales conservados');scene.collection.children.link(sources)
work=bpy.data.collections.new('01 · Veinte combinaciones');scene.collection.children.link(work)
reports=[];material_cache={}

def import_original(path):
    before=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=str(path),import_pack_images=True)
    objects=list(set(bpy.data.objects)-before)
    for o in objects:
        for col in list(o.users_collection):col.objects.unlink(o)
        sources.objects.link(o);o.hide_render=True;o.hide_set(True)
    meshes=[o for o in objects if o.type=='MESH' and not any(o==b.custom_shape for arm in objects if arm.type=='ARMATURE' for b in arm.pose.bones)]
    for o in objects:
        if o.animation_data:
            if o.animation_data.action:o.animation_data.action.use_fake_user=True
            for track in o.animation_data.nla_tracks:track.mute=True
    return meshes

def soft_material(mat):
    if mat.name in material_cache:return material_cache[mat.name]
    copy=mat.copy();copy.name=mat.name+' · tejido'
    for node in copy.node_tree.nodes:
        if node.type=='BSDF_PRINCIPLED':
            for link in list(copy.node_tree.links):
                if link.to_socket in (node.inputs['Metallic'],node.inputs['Roughness']):copy.node_tree.links.remove(link)
            node.inputs['Metallic'].default_value=0;node.inputs['Roughness'].default_value=.8
        if node.type=='NORMAL_MAP':node.inputs['Strength'].default_value=.25
    material_cache[mat.name]=copy;return copy

def flat_material(name,color,roughness=.7):
    mat=bpy.data.materials.new(name);mat.use_nodes=True
    node=mat.node_tree.nodes.get('Principled BSDF');node.inputs['Base Color'].default_value=(*color,1);node.inputs['Roughness'].default_value=roughness
    return mat

def make_pet(species,data,parent):
    original=import_original(REPO/data['source'])[0];mat=soft_material(original.data.materials[0])
    if species=='penguin':
        for node in mat.node_tree.nodes:
            if node.type=='NORMAL_MAP':node.inputs['Strength'].default_value=0
    objects=[]
    for i,part in enumerate(data['meshes']):
        mesh=bpy.data.meshes.new(species+'_app_'+str(i))
        pts=[C@Vector(part['positions'][k:k+3]) for k in range(0,len(part['positions']),3)]
        faces=[part['indices'][k:k+3] for k in range(0,len(part['indices']),3)]
        if part.get('source_material') and species in ('penguin','chick'):
            # Hats tuck the crown tuft inside; preserve the original GLB.
            faces=[f for f in faces if not any(pts[index].z>1.065 and abs(pts[index].x)<.18 for index in f)]
        mesh.from_pydata(pts,[],faces);mesh.update()
        if part['uv']:
            uv=mesh.uv_layers.new(name='UVMap')
            for loop in mesh.loops:
                u,v=part['uv'][loop.vertex_index*2:loop.vertex_index*2+2];uv.data[loop.index].uv=(u,1-v)
        mesh.normals_split_custom_set_from_vertices([C.to_3x3()@Vector(part['normals'][k:k+3]) for k in range(0,len(part['normals']),3)])
        for p in mesh.polygons:p.use_smooth=True
        mesh.materials.append(mat if part.get('source_material') else flat_material(part['name'],part['material']['color'],part['material']['roughness']))
        obj=bpy.data.objects.new(part['name'],mesh);parent.objects.link(obj);objects.append(obj)
    return objects

def head_collider(pet,profile,parent):
    body=pet[0];mesh=body.data.copy();obj=bpy.data.objects.new('Cráneo y orejas · contacto',mesh);parent.objects.link(obj)
    bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000015)
    bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,plane_co=(0,0,.56),plane_no=(0,0,1),clear_inner=True,clear_outer=False)
    edges=[e for e in bm.edges if e.is_boundary];bmesh.ops.holes_fill(bm,edges=edges,sides=0)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free();mesh.update()
    obj.hide_render=True;obj.hide_set(True)
    vertices=[v.co.copy() for v in mesh.vertices];polygons=[list(p.vertices) for p in mesh.polygons]
    return obj,BVHTree.FromPolygons(vertices,polygons)

def fit_mesh(original,item,profile,tree,collider,parent):
    obj=bpy.data.objects.new('Prenda · '+item['source'],original.data.copy());parent.objects.link(obj)
    obj.data.materials.clear()
    for mat in original.data.materials:obj.data.materials.append(soft_material(mat))
    coords=[CI@(original.matrix_world@v.co) for v in original.data.vertices]
    low=Vector(tuple(min(v[k] for v in coords) for k in range(3)));high=Vector(tuple(max(v[k] for v in coords) for k in range(3)));size=high-low
    cx=(low.x+high.x)/2;shape=item['shape'];width=profile['width'];depth=profile['depth'];base=profile['base'];crown=profile['crown']
    if shape=='cap':base+=.045 if width>=.70 else .025
    center=Vector(profile['skull_center']);center_b=C@center
    displacement=0
    for v,p in zip(obj.data.vertices,coords):
        x=p.x-cx;y=p.y;z=p.z
        if shape=='cap':
            x*=width/size.x
            z=(z-item['source_crown_center_z'])*depth/item['source_crown_depth']
            is_visor=p.z>.235 and p.y<.015
            if is_visor:
                blend=max(0,min(1,(p.z-.235)/(.474-.235)))
                z=depth*.47+blend*item['visor_extension']
                y=base+.012+(p.y-low.y)*.11-.025*blend+.022*(abs(x)/(width*.5))**2
            else:y=base+(p.y-low.y)/size.y*crown
        elif shape=='garden':
            x*=width*item['width_ratio']/size.x;z=(z+.015)*depth*1.34/size.z
            y=base+.015+(p.y-low.y)/size.y*item['height']
        elif shape=='beanie':
            x*=width*item['width_ratio']/size.x
            z=(z+.50*max(0,p.y+.20))*depth*1.02/size.z
            y=base-.025+(p.y-low.y)/size.y*item['height'];is_visor=False
        elif shape=='beret':
            x*=width*item['width_ratio']/size.x;z=(z-.045)*depth*1.07/size.z
            y=base+.015+(p.y-low.y)/size.y*item['height']-.06*x;is_visor=False
        else:
            x=-x*width*item['width_ratio']/size.x;z=-z*depth*1.10/size.z
            y=base-.115+(p.y-low.y)/size.y*item['height']
            # Bangs stop above the eyes; the rear locks remain long.
            front=max(0,min(1,(z-.10)/.16));middle=max(0,1-(abs(x)/(width*.42))**4)
            minimum=base+.045
            if y<minimum:y+=(minimum-y)*front*middle
            is_visor=False
        point=C@Vector((x,y,z))
        # Tailor inward cloth to the actual resting skull, including ear bases.
        protect=(shape=='cap' and is_visor) or (shape=='garden' and p.y<-.10)
        direction=point-center_b;distance=direction.length
        if distance>.001 and not protect:
            direction.normalize();hit,normal,_,length=tree.ray_cast(center_b,direction,2)
            if hit is not None and profile['width']>=.70:
                # Ear tips must protrude through openings, not inflate the crown.
                app_direction=CI.to_3x3()@direction
                skull_length=1/math.sqrt(sum((app_direction[k]/profile['skull_radius'][k])**2 for k in range(3)))
                length=min(length,skull_length+.012)
            if hit is not None and distance<length+settings['clearance']:
                fitted=center_b+direction*(length+settings['clearance'])
                displacement=max(displacement,(fitted-point).length);point=fitted
        v.co=point
    obj.data.update()
    # Smooth the low-resolution locks and pom-pom in the editable Blender mesh.
    if shape in ('beanie','wig'):
        bm=bmesh.new();bm.from_mesh(obj.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000005);bm.to_mesh(obj.data);bm.free()
        bpy.context.view_layer.objects.active=obj;obj.hide_set(False);obj.select_set(True)
        subdivision=obj.modifiers.new('Tejido y mechones suaves','SUBSURF');subdivision.levels=1;subdivision.render_levels=1
        bpy.ops.object.modifier_apply(modifier=subdivision.name)
        for v in obj.data.vertices:
            direction=v.co-center_b;distance=direction.length
            if distance>.001:
                direction.normalize();hit,_,_,length=tree.ray_cast(center_b,direction,2)
                if hit is not None and profile['width']>=.70:
                    app_direction=CI.to_3x3()@direction;length=min(length,1/math.sqrt(sum((app_direction[k]/profile['skull_radius'][k])**2 for k in range(3)))+.012)
                if hit is not None and distance<length+settings['clearance']:v.co=center_b+direction*(length+settings['clearance'])
    # Actual cavity: subtract the skull rather than laying a solid hat on top.
    # The collider is shrunken very slightly so the outer cloth remains intact.
    cutter=collider.copy();cutter.data=collider.data.copy();parent.objects.link(cutter)
    for v in cutter.data.vertices:v.co=center_b+(v.co-center_b)*.998
    cutter.hide_render=True;cutter.hide_set(False)
    bpy.context.view_layer.objects.active=obj;obj.hide_set(False);obj.select_set(True)
    # Meshy hair uses open locks. Volume subtraction tears those sheets apart.
    # Its clearance is authored above, and a real scalp closes the interior.
    if shape!='wig':
        if shape=='garden':
            # Close the thin straw surface before subtraction. An open brim
            # cannot define a reliable Boolean volume around the ear holes.
            solid=obj.modifiers.new('Espesor real del tejido','SOLIDIFY');solid.thickness=.004;solid.offset=0
            bpy.ops.object.modifier_apply(modifier=solid.name)
        modifier=obj.modifiers.new('Interior adaptado al cráneo','BOOLEAN');modifier.operation='DIFFERENCE';modifier.solver='EXACT';modifier.object=cutter
        try:bpy.ops.object.modifier_apply(modifier=modifier.name)
        except RuntimeError:obj.modifiers.remove(modifier)
    bpy.data.objects.remove(cutter,do_unlink=True)
    # Smooth authored shading with welded normals, while leaving UVs untouched.
    for poly in obj.data.polygons:poly.use_smooth=True
    bm=bmesh.new();bm.from_mesh(obj.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000002);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(obj.data);bm.free();obj.data.validate(clean_customdata=True);obj.data.update()
    obj['source_glb']=item['source'];obj['tailored_in']='Blender';obj['clearance_m']=settings['clearance']
    if shape in ('beanie','wig','garden'):
        bpy.context.view_layer.objects.active=obj
        decimate=obj.modifiers.new('Presupuesto móvil','DECIMATE');decimate.ratio=.65 if shape=='garden' else .55;decimate.use_collapse_triangulate=True
        bpy.ops.object.modifier_apply(modifier=decimate.name);obj.data.validate(clean_customdata=True)
    if shape=='wig':add_hair_lining(obj,profile,parent)
    if shape=='garden':
        # Remove Boolean cavity faces below the hat band, inside the opening.
        # They otherwise duplicate the skull surface and flicker over the face.
        bm=bmesh.new();bm.from_mesh(obj.data);remove=[]
        for face in bm.faces:
            c=face.calc_center_median()
            radius=(c.x/(width*.53))**2+((-c.y-profile['skull_center'][2])/(depth*.53))**2
            if c.z<base+.075 and radius<1.04:remove.append(face)
        bmesh.ops.delete(bm,geom=remove,context='FACES');bm.to_mesh(obj.data);bm.free();obj.data.validate(clean_customdata=True);obj.data.update()
    return obj,displacement

def add_hair_lining(hair,profile,parent):
    positions=[];faces=[];uvs=[];segments=48;rings=16
    center=Vector(profile['skull_center']);r=Vector(profile['skull_radius'])
    r.y=profile['base']+.305-center.y
    uv=hair.data.uv_layers.active.data
    points=[]
    for loop in hair.data.loops:points.append((hair.data.vertices[loop.vertex_index].co.copy(),uv[loop.index].uv.copy()))
    kd=KDTree(len(points))
    for i,(point,_) in enumerate(points):kd.insert(point,i)
    kd.balance()
    for ring in range(rings+1):
        for section in range(segments+1):
            a=section/segments*2*math.pi
            front=max(0,math.cos(a));theta=ring/rings*(1.48-.45*front)
            p=center+Vector((math.sin(theta)*math.sin(a)*(r.x+.006),math.cos(theta)*(r.y+.006),math.sin(theta)*math.cos(a)*(r.z+.006)))
            point=C@p;positions.append(point);_,nearest,_=kd.find(point);uvs.append(points[nearest][1])
    for row in range(rings):
        for col in range(segments):
            a=row*(segments+1)+col;faces.append((a,a+1,a+segments+2,a+segments+1))
    mesh=bpy.data.meshes.new('Base interior de la peluca');mesh.from_pydata(positions,[],faces);mesh.update()
    layer=mesh.uv_layers.new(name='UVMap')
    for loop in mesh.loops:layer.data[loop.index].uv=uvs[loop.vertex_index]
    for poly in mesh.polygons:poly.use_smooth=True
    mesh.materials.append(hair.data.materials[0]);obj=bpy.data.objects.new('Interior de cabello · misma textura',mesh);parent.objects.link(obj)

for species,profile in settings['pets'].items():
    if only_penguin and species!='penguin':continue
    data=json.loads((DIR/(species+'.json')).read_text(encoding='utf-8'))
    pet_collection=bpy.data.collections.new(species+' · mascota de la app');work.children.link(pet_collection)
    pets=make_pet(species,data,pet_collection);collider,tree=head_collider(pets,profile,pet_collection)
    for key,item in items.items():
        col=bpy.data.collections.new(key+' · '+species);work.children.link(col)
        original=import_original(OUT/item['source'])[0]
        fit_overrides=item.get('species_fit',{}).get(species,{})
        fit_profile={**profile,**{k:v for k,v in fit_overrides.items() if k in profile}}
        fit_item={**item,**{k:v for k,v in fit_overrides.items() if k not in profile}}
        obj,movement=fit_mesh(original,fit_item,fit_profile,tree,collider,col)
        bpy.ops.object.select_all(action='DESELECT')
        for mesh in col.objects:mesh.select_set(True)
        bpy.context.view_layer.objects.active=obj
        path=OUT/(key+'_'+species+'_blender.glb')
        bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
        reports.append({'item_key':key,'species':species,'path':'assets/runner/accessories/'+path.name,'source':item['source'],'triangles':sum(len(p.vertices)-2 for mesh in col.objects for p in mesh.data.polygons),'max_contact_adjustment':movement,'fit_status':'visual_review','sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
        for mesh in col.objects:mesh.hide_render=True
        print('TAILORED',species,key,len(obj.data.polygons),flush=True)
    collider.hide_set(True)
    for pet in pets:pet.hide_render=True

world=bpy.data.worlds.new('Fondo cálido');world.use_nodes=True;world.node_tree.nodes.get('Background').inputs[0].default_value=(1,.93,.95,1);world.node_tree.nodes.get('Background').inputs[1].default_value=.7;scene.world=world
for name,position,power in [('Key',(-3,-4,5),550),('Fill',(3,-2,3),350)]:
    light=bpy.data.lights.new(name,'AREA');light.energy=power;light.size=4;obj=bpy.data.objects.new(name,light);scene.collection.objects.link(obj);obj.location=position;obj.rotation_euler=(Vector((0,0,.7))-obj.location).to_track_quat('-Z','Y').to_euler()
camera_data=bpy.data.cameras.new('Camera');camera=bpy.data.objects.new('Camera',camera_data);scene.collection.objects.link(camera);scene.camera=camera;camera_data.type='ORTHO';camera_data.ortho_scale=1.55
scene.render.engine='BLENDER_EEVEE_NEXT';scene.eevee.taa_render_samples=24
scene.render.resolution_x=600;scene.render.resolution_y=740;scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='AgX'
scene.render.film_transparent=True
for action in bpy.data.actions:action.use_fake_user=True
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(DIR/('NIDO-gorra-pinguino.blend' if only_penguin else ('NIDO-gorra-encaje.blend' if only_cap else 'NIDO-cabeza-encaje.blend'))),compress=True)
(DIR/'tailoring-report.json').write_text(json.dumps([e for e in previous_report if not any(e['item_key']==n['item_key'] and e['species']==n['species'] for n in reports)]+reports,ensure_ascii=False,indent=2),encoding='utf-8')
for entry in reports:
    if '--skip-render' in sys.argv:continue
    if '--render-garden' in sys.argv and entry['item_key']!='hat_garden':continue
    species=entry['species'];key=entry['item_key'];col=bpy.data.collections.get(key+' · '+species);pets=bpy.data.collections.get(species+' · mascota de la app')
    for obj in pets.objects:
        if obj.type=='MESH' and not obj.name.startswith('Cráneo'):obj.hide_render=False
    for obj in col.objects:obj.hide_render=False
    for angle,name in [(0,'front'),(math.pi/2,'profile'),(math.pi,'back')]:
        camera.location=(math.sin(angle)*3,-math.cos(angle)*3,1.37);camera.rotation_euler=(Vector((0,0,.72))-camera.location).to_track_quat('-Z','Y').to_euler()
        scene.render.filepath=str(DIR/(species+'-'+key+'-'+name+'.png'));bpy.ops.render.render(write_still=True)
    for obj in pets.objects:obj.hide_render=True
    for obj in col.objects:obj.hide_render=True
# Open the workshop on one clean fitting instead of overlapping twenty hats.
sources.hide_viewport=True
for col in work.children:
    col.hide_viewport=col.name not in ('penguin · mascota de la app','cap_pink · penguin')
    for obj in col.objects:obj.hide_render=col.hide_viewport or obj.name.startswith('Cráneo')
scene.camera.location=(0,-3,1.37);scene.camera.rotation_euler=(Vector((0,0,.72))-scene.camera.location).to_track_quat('-Z','Y').to_euler()
selected=bpy.data.collections['cap_pink · penguin'].objects[0]
bpy.ops.object.select_all(action='DESELECT');selected.hide_set(False);selected.select_set(True);bpy.context.view_layer.objects.active=selected
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.shading.type='MATERIAL'
            region=area.spaces.active.region_3d;region.view_location=(0,0,.72);region.view_distance=2.4;region.view_rotation=scene.camera.rotation_euler.to_quaternion();region.view_perspective='ORTHO'
scene['fit_catalog']='assets/runner/blender-head-models.json'
scene['fit_note']='Species variants in app model coordinates; originals preserved in collection 00.'
bpy.ops.wm.save_as_mainfile(filepath=str(DIR/('NIDO-gorra-pinguino.blend' if only_penguin else ('NIDO-gorra-encaje.blend' if only_cap else 'NIDO-cabeza-encaje.blend'))),compress=True)
print('TAILORING_READY',len(reports),flush=True)
