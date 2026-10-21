"""Small closed beret fitted to the actual normalized resting pet surface.
Separate candidate: original pet and active catalog are never overwritten.
"""
import bpy, bmesh, json, math, sys, hashlib
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
R = Path(__file__).resolve().parents[1]
sp = next((a.split('=', 1)[1] for a in sys.argv if a.startswith('species=')), 'penguin')
profile = json.loads((R/'design/blender/head-tailoring.json').read_text())['pets'][sp]
cx, cy, cz = profile['skull_center']; rx, ry, rz = profile['skull_radius']
snapshot = R/'assets/runner/play-models'/({'penguin':'Meshy_AI_Pip_the_Penguin_All_Animations.glb','bear':'bear.glb','pig':'pig.glb','chick':'chick.glb'}[sp])
bpy.ops.wm.read_factory_settings(use_empty=True)
source = R/f'design/wardrobe-restart/experiments/beret-fit-v9/sources/{sp}.glb'
if not source.exists(): source=R/f'assets/runner/accessories/restart_headfinish_beret_chic_{sp}.glb'
bpy.ops.import_scene.gltf(filepath=str(source))
old = [o for o in bpy.context.scene.objects if o.type == 'MESH']
material = next(o for o in old if 'Copa' in o.name).data.materials[0]
heart = next((o for o in old if 'Coraz' in o.name), None)
for o in old:
    if o != heart:
        bpy.data.objects.remove(o, do_unlink=True)
cx, cy, cz = profile['skull_center']; rx, ry, rz = profile['skull_radius']
origin = Vector((cx, -cz, cy))
N, M, tmax = 80, 24, .76
points = []
def point(t, a, extra=0):
    # Analytical skull envelope avoids the tuft spikes and abrupt ring transitions
    # documented in v7. The accessory occupies only the upper skull footprint.
    u=t/tmax
    fold=max(0,math.sin(math.pi*u))**1.6
    # Gathered narrow band, inflated slouching crown, soft irregular felt folds.
    # All offsets fade at the hem, keeping the footprint inside the skull width.
    radial=.024*fold + .007*math.sin(5*a+.7)*fold
    skew=-.032*(1-u*u)
    lift=.012*(1-u*u)+.031*math.sin(math.pi*u)
    wave=.009*math.sin(3*a+.4)*fold + .005*math.sin(6*a)*fold
    envelope=origin+Vector(((rx*math.sin(t)+radial)*math.sin(a)+skew,
      -(rz*math.sin(t)+radial*.85)*math.cos(a),
      ry*math.cos(t)+lift+wave-.012*math.sin(a)*fold))
    normal=Vector((math.sin(t)*math.sin(a)/rx,-math.sin(t)*math.cos(a)/rz,math.cos(t)/ry)).normalized()
    loft=.010+.020*math.cos(t/tmax*math.pi/2)**2
    return envelope+normal*(loft+extra)

verts = [point(0, 0)]
for j in range(1, M+1):
    for i in range(N): verts.append(point(tmax*j/M, math.tau*i/N))
faces = [(0, 1+i, 1+(i+1)%N) for i in range(N)]
for j in range(M-1):
    for i in range(N):
        a = 1+j*N+i; b = 1+j*N+(i+1)%N
        faces.append((a, a+N, b+N, b))
mesh = bpy.data.meshes.new('Copa pequeña · superficie original')
mesh.from_pydata(verts, [], faces); mesh.update()
cap = bpy.data.objects.new('Boina pequeña · fieltro con forro', mesh)
bpy.context.collection.objects.link(cap); mesh.materials.append(material)
uv = mesh.uv_layers.new(name='UVMap')
for polygon in mesh.polygons:
    polygon.use_smooth = True
    for loop in polygon.loop_indices:
        v = mesh.vertices[mesh.loops[loop].vertex_index].co
        uv.data[loop].uv = ((v.x-cx)/(2*rx)+.5, (v.y+cz)/(2*rz)+.5)
bpy.context.view_layer.objects.active = cap; cap.select_set(True)
solid = cap.modifiers.new('Forro continuo 6 mm', 'SOLIDIFY')
solid.thickness = .006; solid.offset = 0; solid.use_even_offset = True
bpy.ops.object.modifier_apply(modifier=solid.name)
bm = bmesh.new(); bm.from_mesh(mesh); bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(mesh); bm.free()
def curve(name, vertices, radius, mat, cyclic=False):
    data = bpy.data.curves.new(name, 'CURVE'); data.dimensions = '3D'
    data.bevel_depth = radius; data.bevel_resolution = 2
    data.use_fill_caps = True
    spline = data.splines.new('POLY'); spline.points.add(len(vertices)-1)
    for p, v in zip(spline.points, vertices): p.co = (*v, 1)
    spline.use_cyclic_u = cyclic
    obj = bpy.data.objects.new(name, data); bpy.context.collection.objects.link(obj); data.materials.append(mat)
    return obj
curve('Banda fina asentada · sin disco saliente', [point(tmax, math.tau*i/N, -.0005) for i in range(N)], .0045, material, True)
thread = bpy.data.materials.new('Hilo lavanda · costura sutil'); thread.diffuse_color=(.61,.52,.68,1)
thread.use_nodes=True; thread.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.61,.52,.68,1)
thread.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.96
for i in range(64):
    a = math.tau*(i+.16)/64; b = math.tau*(i+.66)/64
    curve('Pespunte de banda', [point(tmax-.023,a+(b-a)*j/2,.004) for j in range(3)], .0006, thread)
for seam in range(6):
    angle=seam*math.tau/6
    curve('Unión de panel · discreta', [point(tmax*j/24,angle,.0009) for j in range(2,25)], .00065, thread)
if heart:
    center = sum((heart.matrix_world@v.co for v in heart.data.vertices), Vector())/len(heart.data.vertices)
    heart.scale *= .55
    bpy.context.view_layer.update()
    moved = sum((heart.matrix_world@v.co for v in heart.data.vertices), Vector())/len(heart.data.vertices)
    heart.location += point(.56,-.48,.006)-moved
top = point(0,0,.004)
curve('Rabito corto', [top,top+Vector((.004,0,.013))], .0038, material)
for node in material.node_tree.nodes:
    if node.type == 'BSDF_PRINCIPLED':
        node.inputs['Roughness'].default_value=.94
        if 'Sheen Weight' in node.inputs: node.inputs['Sheen Weight'].default_value=.16
out = R/'design/wardrobe-restart/experiments/beret-fit-v9'; out.mkdir(parents=True,exist_ok=True)
destination = R/f'assets/runner/accessories/experimental_beret_chic_{sp}_v9.glb'
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.convert(target='MESH')
bpy.context.view_layer.objects.active=cap
bpy.ops.object.join()  # Batch stitches by material instead of 70 draw calls.
bpy.ops.export_scene.gltf(filepath=str(destination), export_format='GLB', use_selection=True, export_animations=False, export_yup=True)
bpy.ops.file.pack_all(); bpy.ops.wm.save_as_mainfile(filepath=str(out/f'{sp}.blend'),compress=True)
report={'species':sp,'candidate':str(destination.relative_to(R)),'source_pet_snapshot':str(snapshot.relative_to(R)),
 'surface_fit':'small asymmetric felt crown with gathered folds; app QA pending','angle_limit':tmax,'lining':.006,'catalog_updated':False,'sha256':hashlib.sha256(destination.read_bytes()).hexdigest()}
(out/f'{sp}.json').write_text(json.dumps(report,indent=2))
print('BERET_SMALL_FIT',destination,flush=True)
