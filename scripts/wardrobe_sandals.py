"""Broad sewn sandal straps seated on each source pet's actual foot surface."""
import math
from mathutils import Vector
from mathutils.bvhtree import BVHTree

def build(B,ns,item,sp,col,data):
    color=item['appearance']['color'].upper()
    tree=ns.get('skin_tree')
    points=[];triangles=[]
    for m in data['meshes']:
        offset=len(points);points.extend(Vector(m['positions'][i:i+3]) for i in range(0,len(m['positions']),3))
        triangles.extend(tuple(offset+k for k in m['indices'][i:i+3]) for i in range(0,len(m['indices']),3))
    surface=BVHTree.FromPolygons(points,triangles,all_triangles=True)
    for side in ('Left','Right'):
        before=set(col.objects);f=data['feet'][side];lo=f['min'];hi=f['max'];cx=(lo[0]+hi[0])/2;cz=(lo[2]+hi[2])/2
        rx=(hi[0]-lo[0])/2+.006;rz=(hi[2]-lo[2])/2+.010
        ns['fabric']='rubber';pts=[];faces=[];N=80
        for yy,r in ((.002,.95),(.006,1),(.028,1),(.033,.97)):
            for i in range(N):
                a=i*math.tau/N;s=math.sin(a);c=math.cos(a)
                # Broad rounded toe platform supports all three original toes.
                pts.append((cx+rx*r*math.copysign(abs(s)**.62,s),yy,cz+rz*r*math.copysign(abs(c)**.62,c)))
        for j in range(3):
            for i in range(N):k=j*N+i;faces.append((k,j*N+(i+1)%N,(j+1)*N+(i+1)%N,k+N))
        faces.extend((tuple(reversed(range(N))),tuple(3*N+i for i in range(N))))
        B.mesh('Suela sandalia biselada',pts,faces,col,'#EBA687')
        def top(x,z):
            hit,_,_,_=surface.ray_cast(Vector((x,hi[1]+.080,z)),Vector((0,-1,0)),.20)
            arch=.048+(hi[1]+.035-.048)*max(0,math.cos(min(1,abs(x-cx)/rx)*math.pi/2))**.55
            return max(arch,min(hi[1]+.065,hit.y+.015) if hit is not None else .047)
        def front(x,y):
            hit,_,_,_=surface.ray_cast(Vector((x,y,1)),Vector((0,0,-1)),2)
            return hit.z+.018 if hit is not None else cz+rz*.80
        ns['fabric']='cotton'
        front_fitted=sp in ('bear','pig')
        for band,z in enumerate((cz+rz*.68,cz+rz*.18)):
            pts=[];faces=[];steps=48
            for i in range(steps+1):
                x=cx+rx*.96*(-1+2*i/steps)
                for j in range(5):
                    if front_fitted:
                        # These paws merge continuously into the leg. A vertical
                        # ray starts inside that leg and finds its bottom face;
                        # seat their straps on the true front of the paw instead.
                        arch=.054+(.052+band*.039)*max(0,math.cos(abs(x-cx)/rx*math.pi/2))**.6
                        yy=arch+(-1+j/2)*.015;pts.append((x,yy,front(x,yy)))
                    else:
                        zz=z+(-1+j/2)*.014;pts.append((x,top(x,zz),zz))
            for i in range(steps):
                for j in range(4):k=i*5+j;faces.append((k,k+1,k+6,k+5))
            o=B.mesh('Correa ancha adaptada '+str(band),pts,faces,col,color);B.solid(o,.009)
            for j in (0,4):B.curve('Pespunte sandalia',[tuple(Vector(pts[i*5+j])+Vector((0,0,.006) if front_fitted else (0,.006,0))) for i in range(steps+1)],.0008,col,ns['cream'])
        ns['fabric']='cotton'
        heel=[(cx+rx*.94*math.sin(a),max(.054,hi[1]+.008),cz+rz*.89*math.cos(a)) for a in [math.pi/2+i*math.pi/48 for i in range(49)]]
        B.curve('Talón redondeado',heel,.009,col,color)
        # Flower lies on the upper strap, instead of intersecting the toe.
        z=cz+rz*.68;y=top(cx,z)+.008
        if front_fitted:y=.109;z=front(cx,y)+.008
        for i in range(5):
            a=i*math.tau/5
            if front_fitted:B.sphere('Pétalo flor',(cx+.018*math.sin(a),y+.018*math.cos(a),z+.004),(.014,.014,.008),col,'#FFD2BE')
            else:B.sphere('Pétalo flor',(cx+.018*math.sin(a),y+.004,z+.018*math.cos(a)),(.014,.008,.014),col,'#FFD2BE')
        B.sphere('Centro flor',(cx,y if front_fitted else y+.011,z+.011 if front_fitted else z),(.009,.009,.008),col,ns['cream'])
        for o in set(col.objects)-before:o.name='Calzado · '+side+' · '+o.name
