import * as THREE from 'three';
import {clipSkinGeometry} from './skin-boundary-clip.js';

// A closed shoe covers the toes, just as a hat covers the crown feathers.
// Keep every original vertex/UV/weight, and restore the same triangles when
// the shoes are removed or replaced with open sandals. Never alter source GLBs.
export function restoreFootwearCoverage(model){
  model.traverse(mesh=>{
    if(!mesh.isMesh||mesh.userData.cosmetic)return;
    if(mesh.userData.footwearSourceGeometry){
      mesh.geometry.dispose();mesh.geometry=mesh.userData.footwearSourceGeometry;
      delete mesh.userData.footwearSourceGeometry;delete mesh.userData.closedFootwearVertices;return;
    }
    const source=mesh.userData.closedFootwearIndices;
    if(source){mesh.geometry.setIndex(source.clone());delete mesh.userData.closedFootwearIndices;}
  });
}

export function coverClosedFootwear(model,fit,item){
  const closed=!!item?.fitted_model_space&&!/sandals/.test(item.style??'');
  model.updateMatrixWorld(true);
  model.traverse(mesh=>{
    if(!mesh.isMesh||mesh.userData.cosmetic||!mesh.geometry.index)return;
    if(!closed)return;
      const hidden=new Map(),samples=[];
      const p=mesh.geometry.attributes.position;
      if(mesh.isSkinnedMesh)mesh.skeleton.update();
      for(let i=0;i<p.count;i++){
        const point=new THREE.Vector3().fromBufferAttribute(p,i);
        if(mesh.isSkinnedMesh)mesh.applyBoneTransform(i,point);
        mesh.localToWorld(point);model.worldToLocal(point);
        samples.push(point);
        for(const box of Object.values(fit.feet)){
          if(box.isEmpty())continue;
          if(point.y<box.max.y+.005&&point.x>=box.min.x-.015&&point.x<=box.max.x+.015&&point.z>=box.min.z-.020&&point.z<=box.max.z+.020){hidden.set(i,box.max.y+.005);break;}
        }
      }
    if(!hidden.size)return;
    const source=mesh.geometry.index,covered=new Set(),clips=new Map();
    for(let i=0;i<source.count;i+=3){
      const a=source.getX(i),b=source.getX(i+1),c=source.getX(i+2);
      const tri=[a,b,c],key=tri.join(',');if(!tri.some(v=>hidden.has(v)))continue;
      const threshold=Math.max(...tri.filter(v=>hidden.has(v)).map(v=>hidden.get(v))),polygon=[];
      for(let k=0;k<3;k++){
        const u=tri[k],v=tri[(k+1)%3],yu=samples[u].y,yv=samples[v].y,inside=yu>=threshold,next=yv>=threshold;
        if(inside)polygon.push(u);
        if(inside!==next)polygon.push([u,v,(threshold-yu)/(yv-yu)]);
      }
      if(polygon.length<3)covered.add(key);else clips.set(key,polygon);
    }
    mesh.userData.footwearSourceGeometry=mesh.geometry;
    mesh.geometry=clipSkinGeometry(mesh.geometry,covered,clips);
  });
  model.userData.closedFootwearCovered=closed;
}
