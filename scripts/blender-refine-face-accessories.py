"""Stable star frames and connected necklaces fitted to the original pets.

No pet mesh/rig edits. Collar contours come from the actual sewn shirt export,
not the bounding box that includes a pet's arms or head.
"""
import ast, hashlib, importlib.util, json, math, struct, sys
from pathlib import Path
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts'))
from wardrobe_gltf import add_skin_attributes, _attribute
spec=importlib.util.spec_from_file_location('pattern_tools',ROOT/'scripts/blender-build-wardrobe.py')
B=importlib.util.module_from_spec(spec);spec.loader.exec_module(B)
source=(ROOT/'scripts/blender-build-complements.py').read_text(encoding='utf-8')
ns={'B':B,'bpy':bpy,'math':math,'Vector':Vector,'BVHTree':BVHTree,'materials':{},'fabric':'cotton',
    'cream':'#FFF2DF','pink':'#F05280','gold':'#E2B957','textile':B.material}
names=('material','ring','badge','skin_tree','frontal')
exec('\n\n'.join(ast.get_source_segment(source,n) for n in ast.parse(source).body if isinstance(n,ast.FunctionDef) and n.name in names),ns)
B.material=ns['material']
fits=json.loads((ROOT/'design/wardrobe-restart/sewn-species-fit.json').read_text())['species']

def smooth_corner_path(points, radius=.15):
    result=[]
    for i,p in enumerate(points):
        prev=Vector(points[i-1]);p=Vector(p);nxt=Vector(points[(i+1)%len(points)])
        start=p.lerp(prev,radius);end=p.lerp(nxt,radius)
        for j in range(9):
            t=j/8;result.append(tuple((1-t)**2*start+2*(1-t)*t*p+t*t*end))
    return result

def star_glasses(sp,col,data,tree,color):
    ns['fabric']='plastic';p=B.heads[sp];rx=p['skull_radius'][0]
    low=data['head']['min'][1];height=data['head']['max'][1]-low
    y=low+height*dict(penguin=.36,bear=.43,pig=.32,chick=.38)[sp]
    x=rx*dict(penguin=.42,bear=.38,pig=.43,chick=.40)[sp];r=rx*.28
    project=ns['frontal'](tree,.020)
    for sign in (-1,1):
        corners=[(sign*x+r*(1 if i%2==0 else .49)*math.cos(math.pi/2+i*math.pi/5),
                  y+r*(1 if i%2==0 else .49)*math.sin(math.pi/2+i*math.pi/5),0) for i in range(10)]
        # One gently tilted optical plane. Per-vertex skin projection warped the
        # lens and created a broken-looking star on every animal.
        z=max(project((q[0],q[1],.3))[2] for q in corners)
        contour=smooth_corner_path([(a,b,z) for a,b,_ in corners])
        frame=B.curve('Montura estrella redondeada',contour,.011,col,color,True);frame.data.bevel_resolution=4
        ns['fabric']='lens';center=(sign*x,y,z-.004)
        lens=[(q[0],q[1],q[2]-.004) for q in contour]+[center];n=len(contour)
        glass=B.mesh('Lente estrella continua',lens,[(n,i,(i+1)%n) for i in range(n)],col,'#59415B');B.solid(glass,.003)
        shader=glass.data.materials[0].node_tree.nodes.get('Principled BSDF')
        shader.inputs['Base Color'].default_value=(.075,.045,.12,1);shader.inputs['Alpha'].default_value=.78
        ns['fabric']='plastic'
        outer=max(contour,key=lambda q:sign*q[0]);c=p['skull_center']
        # Surface-following temples curve backwards, without side spikes.
        arm=[outer]
        for i in range(25):
            a=.82+1.12*i/24;direction=Vector((sign*math.sin(a),0,math.cos(a)))
            hit,_,_,_=tree.ray_cast(Vector((c[0],y,c[2]))+direction*1.2,-direction,2.4)
            q=hit+direction*.003 if hit is not None else Vector((sign*rx*math.sin(a),y,c[2]+p['skull_radius'][2]*math.cos(a)))
            arm.append(tuple(q))
        # Ease the short hinge into the measured head surface.
        first=Vector(arm[1]);arm[1:1]=[tuple(Vector(outer).lerp(first,i/6)) for i in range(1,6)]
        temple=B.curve('Patilla envolvente',arm,.0045,col,color);temple.data.bevel_resolution=3
    bridge=[(-x+r*.84,y+.022,z),(0,y+.030,z+.003),(x-r*.84,y+.022,z)]
    B.curve('Puente nasal redondeado',bridge,.006,col,color).data.bevel_resolution=4

def collar_dimensions(sp):
    raw=(ROOT/f'assets/runner/accessories/sewn_shirt_love_{sp}.glb').read_bytes()
    jl=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+jl]);binary=raw[28+jl:]
    points=[p for m in doc['meshes'] if 'Cuello' in m['name'] for prim in m['primitives'] for p in _attribute(doc,binary,prim['attributes']['POSITION'])]
    if not points:raise ValueError('Missing authored collar '+sp)
    lo=[min(p[k] for p in points) for k in range(3)];hi=[max(p[k] for p in points) for k in range(3)]
    return (lo[0]+hi[0])/2,(lo[2]+hi[2])/2,(hi[0]-lo[0])/2,(hi[2]-lo[2])/2

def necklace(sp,col,data,tree,color):
    cx,cz,rx,rz=collar_dimensions(sp);y=fits[sp]['collar_top']-.027
    count=36;beads=[]
    for i in range(count):
        a=i*math.tau/count;beads.append((cx+(rx+.003)*math.sin(a),y-.024*math.cos(a),cz+(rz+.003)*math.cos(a)))
    ns['fabric']='gold';B.curve('Hilo continuo del collar',beads,.002,col,ns['gold'],True)
    ns['fabric']='pearl'
    for i,p in enumerate(beads):B.sphere('Perla engarzada',p,(.014,.014,.014),col,ns['cream'] if i%2 else '#F5BAC5')
    # A short hanger seats the heart against the breast, instead of losing it
    # inside the body after a ring that was measured across the shoulders.
    project=ns['frontal'](tree,.006);target=project((cx,beads[0][1]-.045,.3))
    ns['fabric']='gold'
    ns['ring']('Anilla del dije',(cx,beads[0][1]-.016,beads[0][2]+.006),.008,.010,0,.0025,col,ns['gold'],False)
    B.curve('Enganche del corazón',[(cx,beads[0][1]-.022,beads[0][2]+.006),(cx,target[1]+.015,target[2]+.005)],.0025,col,ns['gold'])
    ns['fabric']='plastic';B.heart(target,.055,col,color,project)

items=json.loads((ROOT/'assets/runner/accessory-catalog.json').read_text(encoding='utf-8'));reports=[]
for sp in ('penguin','bear','pig','chick'):
    data=json.loads((ROOT/f'design/wardrobe-restart/fitting/{sp}-original.json').read_text());tree=ns['skin_tree'](data)
    for key in ('glasses_star','necklace_heart'):
        item=next(i for i in items if i['item_key']==key);col=bpy.data.collections.new(key+' · '+sp);B.scene.collection.children.link(col)
        color=item['appearance']['color'].upper()
        (star_glasses if key=='glasses_star' else necklace)(sp,col,data,tree,color)
        bpy.ops.object.select_all(action='DESELECT')
        for o in col.objects:o.select_set(True)
        bpy.context.view_layer.objects.active=list(col.objects)[0];bpy.ops.object.convert(target='MESH');bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
        for o in col.objects:o.data.name=o.name
        path=ROOT/f'assets/runner/accessories/restart_{key}_{sp}.glb';stage=path.with_suffix('.building.glb')
        bpy.ops.export_scene.gltf(filepath=str(stage),export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
        if key=='necklace_heart':data['rigid_garment_bone']='Neck';add_skin_attributes(stage,data)
        stage.replace(path);reports.append({'item_key':key,'species':sp,'asset':path.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'skinned_model_space':key=='necklace_heart'})
        col.hide_viewport=True
        for o in col.objects:o.hide_render=True
        print('FACE_REFINED',sp,key,flush=True)
B.save_editable_master(ROOT/'design/wardrobe-restart/models/COLLAR-GAFAS-ACABADOS.blend')
path=ROOT/'assets/runner/restart/details-catalog.json';old=json.loads(path.read_text(encoding='utf-8'));keys={(r['item_key'],r['species']) for r in reports}
path.write_text(json.dumps(reports+[r for r in old if (r['item_key'],r['species']) not in keys],ensure_ascii=False,indent=2),encoding='utf-8')
