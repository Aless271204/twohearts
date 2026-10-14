"""Reversible original shoulder coverage under the restored shirt."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def update(data,sewn=False,species='penguin',dimensions=None,item='shirt_love'):
    dimensions=dimensions or {'hem':.235,'cuff_x':.267,'cuff_y':.402,'cuff_slope':.012/.055,'top':.540}
    coverage={};clips={}
    for mesh in data['meshes']:
        hidden=[];mesh_clips=[]
        for i in range(0,len(mesh['indices']),3):
            tri=mesh['indices'][i:i+3];arm_weight=0.0;head_weight=0.0;head_vertex_max=0.0
            for vertex in tri:
                vertex_head=0.0
                for bone,w in zip(mesh['skinIndex'][vertex*4:vertex*4+4],mesh['skinWeight'][vertex*4:vertex*4+4]):
                    name=data['boneNames'][bone]
                    if name.endswith(('Shoulder','Arm','ForeArm','Hand')):arm_weight+=w/3
                    if name.endswith('Head'):head_weight+=w/3;vertex_head+=w
                head_vertex_max=max(head_vertex_max,vertex_head)
            y=[mesh['positions'][v*3+1] for v in tri]
            x=sum(mesh['positions'][v*3] for v in tri)/3;side=1 if x>0 else -1
            if sewn:
                # Clip only the neck that is INSIDE the folded collar, retaining
                # the upper head and interpolated UV/skin attributes. Keeping
                # a whole mixed triangle exposed left brown/pink jagged tabs.
                # The bear's lower head starts well below the collar. A planar
                # cut there removed its chin/neck silhouette, particularly in
                # running poses. Preserve the entire original head; garment
                # fit must not be achieved by cutting anatomy away.
                if head_vertex_max>=.90:continue
                # Non-penguin shoulder vertices share partial head weights. Keep
                # the face, but cover the mixed neck triangles enclosed by cloth.
                head_limit=.5 if species=='penguin' else .90
                # Protect every fully head-weighted face; mixed shoulder skin is
                # hidden only where the removable sewn garment encloses it.
                if species!='penguin' and head_vertex_max>=.90:continue
                arm_threshold=.60 if species=='penguin' else .10
                arm_region=arm_weight>arm_threshold and head_weight<head_limit and max(y)<dimensions['top']+.060
                body_region=arm_weight<=arm_threshold and head_weight<head_limit and max(y)<dimensions['top']-.030
                if species!='penguin':
                    # Mixed spine/arm weights on the exposed fin are not torso.
                    # The former Y-only torso mask cut triangular holes below
                    # the cuff on chick and pig. Limit it to the actual chest.
                    chest=abs(x)<dimensions.get('shoulder_start',.17)
                    arm_region &= not chest
                    body_region=chest and head_weight<head_limit and max(y)<dimensions['top']-.030
                    if head_weight>.10 and max(y)>dimensions['top']-.030:continue
                if not (arm_region or body_region):continue
                def distance(v):
                    px,py=mesh['positions'][v*3:v*3+2]
                    edge=dimensions['cuff_y']+dimensions['cuff_slope']*(abs(px)-dimensions['cuff_x']) if arm_region else dimensions['hem']
                    return py-edge
                distances=[distance(v) for v in tri]
                if min(distances)>=0:hidden.extend(tri);continue
                if max(distances)<=0:continue
                polygon=[]
                for edge in range(3):
                    a,b=tri[edge],tri[(edge+1)%3];da,db=distances[edge],distances[(edge+1)%3]
                    if da<=0:polygon.append(a)
                    if (da<=0)!=(db<=0):polygon.append([a,b,da/(da-db)])
                if len(polygon)>=3:mesh_clips.append({'triangle':tri,'polygon':polygon})
                else:hidden.extend(tri)
                continue
            cuff=(.402+.012*(abs(x)-.267)/.055) if sewn else (.430-.025*side*(x-side*.250)/.062)
            covered_arm=arm_weight>.10 and sum(y)/3>cuff-.008 and min(y)>.30 and max(y)<.60
            # Hide only skin enclosed by the removable torso, as in a standard
            # wearable body mask. The supplied vertex data and rig stay intact.
            covered_torso=arm_weight<.60 and abs(x)<.30 and sum(y)/3>.245 and max(y)<.550
            if (covered_arm and head_weight<.90) or (covered_torso and head_weight<.5):hidden.extend(tri)
        coverage[mesh['name']]=hidden
        if mesh_clips:clips[mesh['name']]=mesh_clips
    if clips:coverage['__clips']=clips
    filename=f'shirt-original-coverage-{species}.json' if item=='shirt_love' else f'sewn-coverage-{species}-{item}.json'
    (ROOT/'assets/runner/restart'/filename).write_text(json.dumps(coverage),encoding='utf-8')
    return coverage
if __name__=='__main__':
    data=json.loads((ROOT/'design/wardrobe-restart/fitting/penguin-original.json').read_text(encoding='utf-8'))
    print({name:len(indices)//3 for name,indices in update(data,sewn=True).items()})
