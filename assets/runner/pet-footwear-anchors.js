import * as THREE from 'three';

// Clothing-only joints: preserve the moving ankle and ease extreme source
// rotations that turn a closed shoe's ankle opening towards the camera.
export function createFootwearAnchors(model,parent,maxAngle=.80,fit=null){
 const originals={};model.traverse(o=>{if(o.isBone)for(const side of ['Left','Right'])if(o.name.endsWith(side+'Foot'))originals[side]=o;});
 const states=[],bones={},inverse=new THREE.Quaternion(),position=new THREE.Vector3();
 model.updateMatrixWorld(true);model.getWorldQuaternion(inverse).invert();
 for(const side of ['Left','Right']){
  const source=originals[side];if(!source)throw Error('Falta el anclaje original del calzado');
  const point=model.worldToLocal(source.getWorldPosition(new THREE.Vector3()));
  const rotation=inverse.clone().multiply(source.getWorldQuaternion(new THREE.Quaternion()));
  const bone=new THREE.Bone();bone.name='Nido'+side+'Footwear';bone.matrixAutoUpdate=false;parent.add(bone);
  let influences=null,contact=point;
  const box=fit?.feet?.[side];
  if(box&&!box.isEmpty()){
   const weights=new Map();
   model.traverse(mesh=>{
    if(!mesh.isSkinnedMesh||mesh.userData.cosmetic)return;
    mesh.skeleton.update();const p=mesh.geometry.attributes.position,j=mesh.geometry.attributes.skinIndex,w=mesh.geometry.attributes.skinWeight;
    for(let i=0;i<p.count;i++){
     const q=new THREE.Vector3().fromBufferAttribute(p,i);mesh.applyBoneTransform(i,q);mesh.localToWorld(q);model.worldToLocal(q);
     if(q.y<box.min.y+.003||q.y>box.min.y+.075||q.x<box.min.x||q.x>box.max.x||q.z<box.min.z||q.z>box.max.z)continue;
     let own=0;for(let k=0;k<4;k++)if(mesh.skeleton.bones[j.getComponent(i,k)].name.includes(side))own+=w.getComponent(i,k);
     if(own<.5)continue;
     for(let k=0;k<4;k++){const b=mesh.skeleton.bones[j.getComponent(i,k)],value=w.getComponent(i,k);if(value>0)weights.set(b,(weights.get(b)??0)+value);}
    }
   });
   const total=[...weights.values()].reduce((a,b)=>a+b,0);
   if(total>0){
    influences=[...weights].map(([source,value])=>({source,weight:value/total,restInverse:source.matrixWorld.clone().invert()}));
    contact=box.getCenter(new THREE.Vector3());contact.y=box.max.y+.020;contact.z-=box.getSize(new THREE.Vector3()).z*.20;
   }
  }
  bones[side+'Foot']=bone;states.push({source,bone,point:contact,rotation:rotation.invert(),influences,modelRest:model.matrixWorld.clone()});
 }
 function update(){
  model.updateMatrixWorld(true);model.getWorldQuaternion(inverse).invert();
  for(const state of states){
   let delta;
   if(state.influences){
    // The original paw may follow Leg and Toe, not only Foot. Use its real
    // average attachment, then extract one rigid transform: no vertex-by-
    // vertex sole bending or shear from linear skin-weight interpolation.
    const field=new THREE.Matrix4();field.elements.fill(0);const modelInverse=model.matrixWorld.clone().invert();
    for(const influence of state.influences){
     const m=modelInverse.clone().multiply(influence.source.matrixWorld).multiply(influence.restInverse).multiply(state.modelRest);
     for(let i=0;i<16;i++)field.elements[i]+=m.elements[i]*influence.weight;
    }
    position.copy(state.point).applyMatrix4(field);
    delta=new THREE.Quaternion();field.decompose(new THREE.Vector3(),delta,new THREE.Vector3());delta.normalize();
   }else{
    model.worldToLocal(state.source.getWorldPosition(position));
    delta=inverse.clone().multiply(state.source.getWorldQuaternion(new THREE.Quaternion())).multiply(state.rotation).normalize();
   }
   if(delta.w<0)delta.set(-delta.x,-delta.y,-delta.z,-delta.w);
   const angle=2*Math.acos(THREE.MathUtils.clamp(delta.w,-1,1));
   const eased=angle>1e-7?new THREE.Quaternion().slerp(delta,maxAngle*Math.tanh(angle/maxAngle)/angle):delta;
   state.bone.matrix.makeTranslation(position.x,position.y,position.z)
    .multiply(new THREE.Matrix4().makeRotationFromQuaternion(eased))
    .multiply(new THREE.Matrix4().makeTranslation(-state.point.x,-state.point.y,-state.point.z));
   state.bone.matrixWorldNeedsUpdate=true;
  }
  parent.updateMatrixWorld(true);
 }
 update();return {bones,update};
}
