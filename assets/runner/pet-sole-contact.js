import * as THREE from 'three';

// Select soles once in the fitted resting pose, not all body vertices on every
// frame. Grounding follows the animated supporting foot instead of the old
// resting bounding box, which made a running preview sink and float.
export function createSoleContactSampler(model,maximum=192){
 model.updateMatrixWorld(true);const p=new THREE.Vector3(),sources=[],shoes=[];
 model.traverse(mesh=>{if(!mesh.isMesh||!mesh.geometry.attributes.position)return;
  const mats=Array.isArray(mesh.material)?mesh.material:[mesh.material];
  const sole=mesh.userData.cosmetic&&mats.some(m=>/rubber|suela|sole/i.test(m?.name??''));
  if(sole)shoes.push(mesh);else if(!mesh.userData.cosmetic&&mesh.isSkinnedMesh)sources.push(mesh);
 });
 const meshes=shoes.length?shoes:sources,points=[];let lowest=Infinity;
 for(const mesh of meshes){if(mesh.isSkinnedMesh)mesh.skeleton.update();const position=mesh.geometry.attributes.position;for(let i=0;i<position.count;i++){
  p.fromBufferAttribute(position,i);if(mesh.isSkinnedMesh)mesh.applyBoneTransform(i,p);mesh.localToWorld(p);
  lowest=Math.min(lowest,p.y);points.push({mesh,index:i,y:p.y});
 }}
 const region=points.filter(q=>q.y<lowest+(shoes.length?.012:.035));
 const selected=region.length<=maximum?region:Array.from({length:maximum},(_,i)=>region[Math.floor(i*region.length/maximum)]);
 const groups=new Map();for(const q of selected){if(!groups.has(q.mesh))groups.set(q.mesh,[]);groups.get(q.mesh).push(q.index);}
 return {count:selected.length,measure(){
  model.updateMatrixWorld(true);let y=Infinity;for(const [mesh,indices] of groups){if(mesh.isSkinnedMesh)mesh.skeleton.update();for(const index of indices){p.fromBufferAttribute(mesh.geometry.attributes.position,index);if(mesh.isSkinnedMesh)mesh.applyBoneTransform(index,p);mesh.localToWorld(p);y=Math.min(y,p.y);}}
  return Number.isFinite(y)?y-model.getWorldPosition(p).y:0;
 }};
}
