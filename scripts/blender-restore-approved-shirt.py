"""Restore the user-approved shirt geometry, never the experimental R2 pet.
The user explicitly requested the previous approved garment on 2026-10-13.
Preserves authored shape, UVs and materials; binds clothing to original pet.
"""
import bpy,bmesh,json,sys,hashlib,importlib.util,math,struct
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts'))
from wardrobe_gltf import add_skin_attributes
spec=importlib.util.spec_from_file_location('base',ROOT/'scripts/blender-restart-wardrobe.py')
base=importlib.util.module_from_spec(spec);spec.loader.exec_module(base)
source=ROOT/'assets/runner/restart/shirt_love_r2_penguin.glb'
source_hash=hashlib.sha256(source.read_bytes()).hexdigest()
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(source))
meshes=[o for o in bpy.data.objects if o.type=='MESH' and o.name.startswith('Camiseta')]
if len(meshes)!=1:raise ValueError('Expected the archived garment only, without mascot meshes')
garment=meshes[0]
world=garment.matrix_world.copy();garment.parent=None;garment.matrix_world=world
for modifier in list(garment.modifiers):
    if modifier.type=='ARMATURE':garment.modifiers.remove(modifier)
garment.name='Manga adaptada - Camiseta aprobada R20'
garment.data.name=garment.name
data=json.loads((ROOT/'design/wardrobe-restart/fitting/penguin-original.json').read_text(encoding='utf-8'))
skin_points=[];skin_faces=[]
for source_mesh in data['meshes']:
    offset=len(skin_points);skin_points.extend(Vector(source_mesh['positions'][i:i+3]) for i in range(0,len(source_mesh['positions']),3))
    for i in range(0,len(source_mesh['indices']),3):
        triangle=source_mesh['indices'][i:i+3];limb=0.0;arm=0.0
        for vi in triangle:
            limb+=sum(w for bone,w in zip(source_mesh['skinIndex'][vi*4:vi*4+4],source_mesh['skinWeight'][vi*4:vi*4+4])
                if data['boneNames'][bone].endswith(('Shoulder','Arm','ForeArm','Hand','HandMiddle','UpLeg','Leg','Foot','ToeBase')))/3
            arm+=sum(w for bone,w in zip(source_mesh['skinIndex'][vi*4:vi*4+4],source_mesh['skinWeight'][vi*4:vi*4+4])
                if data['boneNames'][bone].endswith(('Shoulder','Arm','ForeArm','Hand','HandMiddle')))/3
        cy=sum(source_mesh['positions'][vi*3+1] for vi in triangle)/3
        cx=sum(source_mesh['positions'][vi*3] for vi in triangle)/3
        # The supplied torso contains vertices weighted mainly to UpLeg. Use
        # actual anatomy too, rather than omitting its lateral belly by weight.
        torso_core=abs(cx)<.245 and .20<cy<.490 and arm<.60
        if (limb<.25 or torso_core) and .20<cy<.565:skin_faces.append(tuple(offset+vi for vi in triangle))
skin_surface=BVHTree.FromPolygons(skin_points,skin_faces,all_triangles=True)
decoration={}
for polygon in garment.data.polygons:
    for vi in polygon.vertices:decoration[vi]=max(decoration.get(vi,0),polygon.material_index)
clearance_vertices=0
# Lift only the upper neckline to meet the supplied pet's lower face. Preserve
# the approved hem, short sleeves, embroidery and their texture coordinates.
for vertex in garment.data.vertices:
    q=base.CI@vertex.co
    blend=max(0,min(1,(q.y-.40)/.122));blend=blend*blend*(3-2*blend)
    q.y+=.030*blend
    vertex.co=base.C@q
garment.data.update()
cream=garment.data.materials[0]
# Remove the old sleeve geometry cleanly while retaining the approved torso.
# The vertical cut walls lie inside the new real flipper sleeves.
bm=bmesh.new();bm.from_mesh(garment.data)
for sign in (-1,1):
    bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.000001,
        plane_co=base.C@Vector((sign*.245,0,0)),plane_no=base.C@Vector((sign,0,0)),clear_outer=True)
bmesh.ops.holes_fill(bm,edges=[e for e in bm.edges if e.is_boundary],sides=0)
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(garment.data);bm.free()
# Fit the surviving torso AFTER trimming the archived sleeves. Otherwise the
# X cut also removes the new lateral ease and exposes the supplied pet's belly.
decoration={}
for polygon in garment.data.polygons:
    for vi in polygon.vertices:decoration[vi]=max(decoration.get(vi,0),polygon.material_index)
for vertex in garment.data.vertices:
    q=base.CI@vertex.co
    if .23<q.y<.490:
        origin=Vector((0,q.y,-.030));radial=q-origin
        if radial.length>.03:
            direction=radial.normalized();hit,_,_,distance=skin_surface.ray_cast(origin,direction,1)
            margin=.018+(.006 if decoration.get(vertex.index)==2 else .002 if decoration.get(vertex.index)==1 else 0)
            if hit is not None and radial.length<distance+margin:
                q=origin+direction*(distance+margin);clearance_vertices+=1
    vertex.co=base.C@q
garment.data.update()
parts=[garment]
thread=next((m for m in garment.data.materials if 'costura' in m.name.lower()),cream)
sleeve_material=cream.copy();sleeve_material.name='Algodón de manga suave'
shader=sleeve_material.node_tree.nodes.get('Principled BSDF')
for link in shader.inputs['Base Color'].links:
    texture=link.from_node
    if texture.type=='TEX_IMAGE' and texture.image:
        image=texture.image.copy();image.name='Tejido crema de manga · copia editable'
        pixels=base.np.asarray(image.pixels[:],dtype=base.np.float32).reshape(-1,4)
        luminance=pixels[:,:3]@base.np.array((.2126,.7152,.0722))
        shade=base.np.clip(.98+.18*(luminance-luminance.mean()),.90,1.02)
        color=base.np.array((1.0,.99,.97))
        pixels[:,:3]=base.np.clip(shade[:,None]*color[None,:],0,1)
        image.pixels.foreach_set(pixels.ravel());image.pack();texture.image=image
for node in sleeve_material.node_tree.nodes:
    if node.type=='NORMAL_MAP':node.inputs['Strength'].default_value=.35
for sign in (-1,1):
    points=[];faces=[];rows=24;n=64
    for row in range(rows+1):
        t=row/rows;cx=sign*(.250-.020*t);cz=-.012
        # A dropped shoulder slopes from the neckline down to the flipper.
        # Do not finish the sleeve with a horizontal padded crown.
        rx=.062+.002*t;rz=.145-.015*t
        for i in range(n):
            a=i*math.tau/n
            top=.545-.055*sign*math.cos(a)
            cuff=.430-.025*sign*math.cos(a)
            y=cuff+(top-cuff)*t
            points.append((cx+rx*math.cos(a),y,cz+rz*math.sin(a)))
    for row in range(rows):
        for i in range(n):faces.append((row*n+i,(row+1)*n+i,(row+1)*n+(i+1)%n,row*n+(i+1)%n))
    # A closed, softly rounded shoulder crown belongs to this same sleeve.
    # The only wearable opening is the cuff around the flipper, not a cup above.
    previous=rows*n
    for ring in range(1,7):
        t=ring/6;new_start=len(points)
        for i in range(n):
            a=i*math.tau/n
            points.append((sign*(.230-.055*t)+.064*(1-t)*math.cos(a),
                .545+.040*t-.055*sign*math.cos(a)*(1-t),-.012+.130*(1-t)*math.sin(a)))
        for i in range(n):faces.append((previous+i,new_start+i,new_start+(i+1)%n,previous+(i+1)%n))
        previous=new_start
    sleeve=base.mesh('Manga adaptada - Tejido alrededor de aleta '+str(sign),points,faces,sleeve_material)
    # Continuous UVs in physical cloth scale, no painted flat overlay.
    for face in sleeve.data.polygons:
        for li in face.loop_indices:
            vi=sleeve.data.loops[li].vertex_index;row,i=divmod(vi,n)
            sleeve.data.uv_layers.active.data[li].uv=(i/n*2.0,points[vi][1]/.32)
    bm=bmesh.new();bm.from_mesh(sleeve.data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
    bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=.000001)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(sleeve.data);bm.free()
    base.solid(sleeve,.010);parts.append(sleeve)
    band_points=[];band_faces=[]
    for row in range(5):
        for i in range(n):
            a=i*math.tau/n;y=.430-.025*sign*math.cos(a)+row/4*.018
            band_points.append((sign*.250+.067*math.cos(a),y,-.012+.150*math.sin(a)))
    for row in range(4):
        for i in range(n):band_faces.append((row*n+i,(row+1)*n+i,(row+1)*n+(i+1)%n,row*n+(i+1)%n))
    band=base.mesh('Puño tejido integrado '+str(sign),band_points,band_faces,sleeve_material);base.solid(band,.004);parts.append(band)
    for y in (.433,.445):
        line=[(sign*.250+.070*math.cos(i*math.tau/n),y-.025*sign*math.cos(i*math.tau/n),-.012+.153*math.sin(i*math.tau/n)) for i in range(n)]
        parts.append(base.tube('Costura del puño '+str(sign),line,.0009,thread,True))
# Armhole cut walls sit inside the sleeves. Keep the real textile shells and
# thread editable; avoid Boolean operations over thousands of stitch islands.
data=json.loads((ROOT/'design/wardrobe-restart/fitting/penguin-original.json').read_text(encoding='utf-8'))
from approved_shirt_coverage import update
update(data)
data['garment_skin_profile']={
 'shoulder_start':.17,'sleeve_full':.28,'sleeve_min_y':.30,'sleeve_fade_y':.06,
 'preserve_torso_surface':True,'stable_torso':True,'surface_sleeve_anchors':True,
 'sleeve_root_fade':[.445,.550],
 'volumetric_sleeves':{'center':[.240,.460,.015],'radius':[.095,.110,.170]},
 'cuff_areas':[{'center':[sign*.250,.430,-.012],'normal':[0,-1,0]} for sign in (-1,1)]}
path=ROOT/'assets/runner/accessories/approved_shirt_love_penguin.glb'
staging=path.with_name(path.stem+'.building.glb')
base.export_selected(staging,parts,False)
binary=staging.read_bytes();document=json.loads(binary[20:20+struct.unpack_from('<I',binary,12)[0]])
for mesh in document['meshes']:
    for primitive in mesh['primitives']:
        box=document['accessors'][primitive['attributes']['POSITION']]
        if any(not math.isfinite(v) for v in box['min']+box['max']):raise ValueError('Invalid garment bounds')
        if max(abs(box['min'][0]),abs(box['max'][0]))>.38 or box['min'][1]<.18 or box['max'][1]>.65 or max(abs(box['min'][2]),abs(box['max'][2]))>.38:
            raise ValueError('Reject oversized geometry before replacing the preview asset')
add_skin_attributes(staging,data);staging.replace(path)
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'design/wardrobe-restart/models/CAMISETA-APROBADA-ORIGINAL-penguin.blend'),compress=True)
registry_path=ROOT/'assets/runner/restart/catalog.json'
registry=json.loads(registry_path.read_text(encoding='utf-8'))
entry=next(i for i in registry['wardrobe'] if i['item_key']=='shirt_love')
variant=next(v for v in entry['variants'] if v['species']=='penguin')
variant.update(original_asset=path.relative_to(ROOT).as_posix(),original_sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
 fit_status='restored_approved_shape_pending_original_pet_fit',approved_reference='design/wardrobe-restart/camiseta-acabados-frente-r20.png',
 approved_source_sha256=source_hash,coverage_asset='assets/runner/restart/shirt-original-coverage-penguin.json')
registry_path.write_text(json.dumps(registry,ensure_ascii=False,indent=2),encoding='utf-8')
(ROOT/'outputs/approved-shirt-restore.json').write_text(json.dumps({'source':str(source),'source_sha256':source_hash,
 'asset':str(path),'sha256':variant['original_sha256'],'mascot_exported':False,'body_clearance_adjusted_vertices':clearance_vertices},indent=2),encoding='utf-8')
print('APPROVED_SHIRT_RESTORED',flush=True)
