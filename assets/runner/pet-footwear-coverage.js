import * as THREE from 'three';

// A closed shoe covers the toes, just as a hat covers the crown feathers.
// Keep every original vertex/UV/weight, and restore the same triangles when
// the shoes are removed or replaced with open sandals. Never alter source GLBs.
export function restoreFootwearCoverage(model){
  model.traverse(mesh=>{
    if(!mesh.isMesh||mesh.userData.cosmetic)return;
    const source=mesh.userData.closedFootwearIndices;
    if(source){mesh.geometry.setIndex(source.clone());delete mesh.userData.closedFootwearIndices;}
  });
}

export function coverClosedFootwear(model,fit,item){
  const closed=!!item?.fitted_model_space&&!/sandals/.test(item.style??'');
  model.updateMatrixWorld(true);
  model.traverse(mesh=>{
    if(!mesh.isMesh||mesh.userData.cosmetic||!mesh.geometry.index)return;
    let hidden=mesh.userData.closedFootwearVertices;
    if(!hidden){
      hidden=new Set();
      const p=mesh.geometry.attributes.position;
      if(mesh.isSkinnedMesh)mesh.skeleton.update();
      for(let i=0;i<p.count;i++){
        const point=new THREE.Vector3().fromBufferAttribute(p,i);
        if(mesh.isSkinnedMesh)mesh.applyBoneTransform(i,point);
        mesh.localToWorld(point);model.worldToLocal(point);
        for(const box of Object.values(fit.feet)){
          if(box.isEmpty())continue;
          if(point.y<box.max.y+.018&&point.x>=box.min.x-.015&&point.x<=box.max.x+.015&&point.z>=box.min.z-.020&&point.z<=box.max.z+.020){hidden.add(i);break;}
        }
      }
      mesh.userData.closedFootwearVertices=hidden;
    }
    if(!closed||!hidden.size)return;
    const source=mesh.geometry.index,kept=[];
    for(let i=0;i<source.count;i+=3){
      const a=source.getX(i),b=source.getX(i+1),c=source.getX(i+2);
      if(!hidden.has(a)&&!hidden.has(b)&&!hidden.has(c))kept.push(a,b,c);
    }
    mesh.userData.closedFootwearIndices=source.clone();
    mesh.geometry.setIndex(kept);
  });
  model.userData.closedFootwearCovered=closed;
}
