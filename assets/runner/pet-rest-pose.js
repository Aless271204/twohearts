import * as THREE from 'three';

export function createNaturalRest(model) {
  const skeletons=new Set();
  model.traverse(mesh=>{if(mesh.isSkinnedMesh)skeletons.add(mesh.skeleton);});
  for(const skeleton of skeletons)skeleton.pose();
  model.updateMatrixWorld(true);
  const bones={};model.traverse(bone=>{if(bone.isBone)bones[bone.name.replace(/^mixamorig:?/,'')]=bone;});
  for(const [side,sign] of [['Left',1],['Right',-1]]){
    const arm=bones[side+'Arm'],elbow=bones[side+'ForeArm'];if(!arm||!elbow)continue;
    const direction=elbow.getWorldPosition(new THREE.Vector3()).sub(arm.getWorldPosition(new THREE.Vector3())).normalize();
    const turn=new THREE.Quaternion().setFromUnitVectors(direction,new THREE.Vector3(sign*.23,-.97,.03).normalize());
    const world=turn.multiply(arm.getWorldQuaternion(new THREE.Quaternion()));
    arm.quaternion.copy(arm.parent.getWorldQuaternion(new THREE.Quaternion()).invert().multiply(world));
    model.updateMatrixWorld(true);
  }
  const tracks=[];
  model.traverse(bone=>{
    if(!bone.isBone||!/(Spine2|Head)$/.test(bone.name))return;
    const base=bone.quaternion.clone(),tilt=new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(1,0,0),.012);
    const breath=base.clone().multiply(tilt);
    tracks.push(new THREE.QuaternionKeyframeTrack(bone.name+'.quaternion',[0,1.8,3.6],[...base.toArray(),...breath.toArray(),...base.toArray()]));
  });
  return new THREE.AnimationClip('Natural_Rest',3.6,tracks);
}

// Measure the supplied pose without changing any bone or body proportions.
export function measurePetSoles(model) {
  model.updateMatrixWorld(true);
  // Measure the actual skinned soles rather than guessing from a joint pivot.
  let sole=Infinity;
  model.traverse(mesh=>{
    if(mesh.name.endsWith('RoundedFoot')){sole=Math.min(sole,new THREE.Box3().setFromObject(mesh,true).min.y);return;}
    if(model.userData.delicatePip)return;
    if(!mesh.isSkinnedMesh)return;
    mesh.skeleton.update();
    const positions=mesh.geometry.attributes.position,indices=mesh.geometry.attributes.skinIndex,weights=mesh.geometry.attributes.skinWeight;
    for(let i=0;i<positions.count;i++){
      let footWeight=0;
      for(let k=0;k<4;k++)if(/(Foot|ToeBase|Toe_End)$/.test(mesh.skeleton.bones[indices.getComponent(i,k)]?.name??''))footWeight+=weights.getComponent(i,k);
      if(footWeight<.5)continue;
      const vertex=new THREE.Vector3().fromBufferAttribute(positions,i);
      mesh.applyBoneTransform(i,vertex);mesh.localToWorld(vertex);sole=Math.min(sole,vertex.y);
    }
  });
  return Number.isFinite(sole)?sole-model.position.y:0;
}
