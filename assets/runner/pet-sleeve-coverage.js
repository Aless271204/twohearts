import * as THREE from 'three';

// Garments render their own volume over the upper arm. Cull only the skin
// that is physically inside a sleeve; preserve the exposed forearm/hand and
// every original attribute. Restore before applying any other coverage mask.
export function restoreSleeveCoverage(model){
 model.traverse(mesh=>{
  const index=mesh.userData.sleeveSourceIndices;
  if(index){mesh.geometry.setIndex(index.clone());delete mesh.userData.sleeveSourceIndices;}
 });
}
export function coverSleeveSkin(model,item){
 const coverage=item?.sleeve_coverage?.[model.userData.species];
 const body=model.userData.accessoryFit?.body;
 const bodyTop=body?.max.y??0,shoulderX=body?Math.max(Math.abs(body.min.x),Math.abs(body.max.x))*.70:Infinity;
 model.updateMatrixWorld(true);
 model.traverse(mesh=>{
  if(!mesh.isSkinnedMesh||mesh.userData.cosmetic||!mesh.geometry.index)return;
  let samples=mesh.userData.sleeveRestSamples;
  if(!samples){
   mesh.skeleton.update();samples=[];
   const p=mesh.geometry.attributes.position,j=mesh.geometry.attributes.skinIndex,w=mesh.geometry.attributes.skinWeight;
   for(let i=0;i<p.count;i++){
    let arm=0;for(let k=0;k<4;k++)if(/(Arm|ForeArm)$/.test(mesh.skeleton.bones[j.getComponent(i,k)].name))arm+=w.getComponent(i,k);
    const point=new THREE.Vector3().fromBufferAttribute(p,i);mesh.applyBoneTransform(i,point);mesh.localToWorld(point);model.worldToLocal(point);
    // Source shoulder skin sometimes carries spine/neck weights rather than
    // arm weights. The tailored sleeve still covers that entire shoulder.
    if(Math.abs(point.x)>.10&&(arm>.30||point.y<=bodyTop&&Math.abs(point.x)>=shoulderX))samples.push({i,y:point.y,arm});
   }
   mesh.userData.sleeveRestSamples=samples;
  }
  if(!coverage)return;
  const hidden=new Set(samples.filter(p=>p.y>=coverage.min_y&&p.y<=coverage.max_y).map(p=>p.i));
  if(!hidden.size)return;
  const source=mesh.geometry.index,kept=[];
  // Keep triangles crossing the cuff boundary. Removing a face merely because
  // one vertex lies under the sleeve opens a visible tear in the exposed arm.
  for(let i=0;i<source.count;i+=3){const a=source.getX(i),b=source.getX(i+1),c=source.getX(i+2);if(!(hidden.has(a)&&hidden.has(b)&&hidden.has(c)))kept.push(a,b,c);}
  mesh.userData.sleeveSourceIndices=source.clone();mesh.geometry.setIndex(kept);
 });
}
