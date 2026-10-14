import * as THREE from 'three';

// Clothing-only joints follow the visible wing surface, not the displaced
// humanoid joint pivots in the supplied animation. No pet vertex or bone changes.
export function createSleeveAnchors(model,profiles,parent){
 const sourceMeshes=new Map();
 model.traverse(mesh=>{if(mesh.isSkinnedMesh&&!mesh.userData.cosmetic)sourceMeshes.set(mesh.name,mesh);});
 const bones={},states=[];
 let head;model.traverse(bone=>{if(bone.isBone&&/Head$/.test(bone.name))head=bone;});
 model.updateMatrixWorld(true);
 const headBounds=model.userData.accessoryFit?.head;
 const headCenter=headBounds?.getCenter(new THREE.Vector3());
 const headRadii=headBounds?.getSize(new THREE.Vector3()).multiplyScalar(.5).addScalar(.055);
 const restHeadInverse=head?new THREE.Matrix4().copy(model.matrixWorld).invert().multiply(head.matrixWorld).invert():null;
 for(const [side,profile] of Object.entries(profiles)){
  const source=sourceMeshes.get(profile.mesh);
  if(!source)throw Error('No se encontró la superficie original de la manga');
  const bone=new THREE.Bone();bone.name='Nido'+side+'Sleeve';parent.add(bone);bones[bone.name]=bone;
  const indices=[...new Set(Object.values(profile.groups).flat())];
  if(indices.some(i=>!Number.isInteger(i)||i<0||i>=source.geometry.attributes.position.count))throw Error('El ajuste de manga no corresponde a esta mascota');
  states.push({source,bone,profile,indices,points:new Map(),restInverse:null});
 }
 const point=new THREE.Vector3(),meshToModel=new THREE.Matrix4();
 function frame(state){
  meshToModel.copy(model.matrixWorld).invert().multiply(state.source.matrixWorld);
  state.source.skeleton.update();
  for(const index of state.indices){
   point.fromBufferAttribute(state.source.geometry.attributes.position,index);
   state.source.applyBoneTransform(index,point);point.applyMatrix4(meshToModel);
   state.points.set(index,point.clone());
  }
  const average=ids=>{if(!ids.length)throw Error('Grupo de ajuste de manga vacío');const result=new THREE.Vector3();for(const i of ids)result.add(state.points.get(i));return result.multiplyScalar(1/ids.length);};
  const g=state.profile.groups,center=average(g.center);
  const y=average(g.top).sub(average(g.bottom)).normalize();
  const z=average(g.front).sub(average(g.back));z.addScaledVector(y,-z.dot(y)).normalize();
  const x=new THREE.Vector3().crossVectors(y,z).normalize();z.crossVectors(x,y).normalize();
  if(x.lengthSq()<.5||y.lengthSq()<.5||z.lengthSq()<.5){
   if(state.lastFrame)return state.lastFrame.clone().setPosition(center);
   throw Error('La superficie de manga no define un ajuste estable');
  }
  const result=new THREE.Matrix4().makeBasis(x,y,z).setPosition(center);state.lastFrame=result.clone();return result;
 }
 model.updateMatrixWorld(true);
 for(const state of states){
  state.restInverse=frame(state).invert();
  // The tailored shoulder intentionally sits partly beneath the large head.
  // Preserve that authored contact at rest instead of pushing its seam away.
  state.restHeadContact=headCenter&&state.profile.garment_center
   ? Math.min(1,new THREE.Vector3().fromArray(state.profile.garment_center).sub(headCenter).divide(headRadii).lengthSq())
   : 1;
 }
 function update(){
  model.updateMatrixWorld(true);
  for(const state of states){
   const currentFrame=frame(state),outward=new THREE.Vector3().setFromMatrixColumn(currentFrame,1).negate().normalize();
   const delta=currentFrame.clone().multiply(state.restInverse);
   if(head&&headCenter&&state.profile.garment_center&&!state.profile.preserve_authored_contact){
    const inverseHeadDelta=new THREE.Matrix4().copy(model.matrixWorld).invert().multiply(head.matrixWorld).multiply(restHeadInverse).invert();
    const garmentCenter=new THREE.Vector3().fromArray(state.profile.garment_center);
    const shift=new THREE.Vector3();
    // The supplied jump brings the wing root inside the large cartoon head.
    // Move only the clothing along the visible wing until it clears the head.
    for(let step=0;step<32;step++){
     const contact=garmentCenter.clone().applyMatrix4(delta).add(shift).applyMatrix4(inverseHeadDelta).sub(headCenter).divide(headRadii);
     if(contact.lengthSq()>=state.restHeadContact-1e-6)break;
     shift.addScaledVector(outward,.005);
    }
    delta.elements[12]+=shift.x;delta.elements[13]+=shift.y;delta.elements[14]+=shift.z;
   }
   delta.decompose(state.bone.position,state.bone.quaternion,state.bone.scale);
   state.bone.scale.set(1,1,1);state.bone.updateMatrixWorld(true);
  }
 }
 update();return {bones,update};
}
