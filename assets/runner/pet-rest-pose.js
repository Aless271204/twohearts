import * as THREE from 'three';

// Pose the existing rig; keep the same mesh and accessory anchors.
export function seatPet(model) {
  const bones={};model.traverse(node=>{if(node.isBone)bones[node.name.replace(/^mixamorig:?/,'')]=node;});
  const point=bone=>bone.getWorldPosition(new THREE.Vector3());
  function aim(name,childName,direction){
    const bone=bones[name],child=bones[childName];if(!bone||!child)return;
    model.updateMatrixWorld(true);
    const from=point(child).sub(point(bone)).normalize();
    const delta=new THREE.Quaternion().setFromUnitVectors(from,new THREE.Vector3(...direction).normalize());
    const world=delta.multiply(bone.getWorldQuaternion(new THREE.Quaternion()));
    bone.quaternion.copy(bone.parent.getWorldQuaternion(new THREE.Quaternion()).invert().multiply(world));
    model.updateMatrixWorld(true);
  }
  for(const [side,sign] of [['Left',1],['Right',-1]]){
    // Pip has very short legs: a deep human knee bend distorts his belly.
    // Tuck the legs beneath the body while preserving their original rotations.
    if(bones[side+'UpLeg'])bones[side+'UpLeg'].scale.y=.7;
    if(bones[side+'Leg'])bones[side+'Leg'].scale.y=.7;
    aim(side+'Foot',side+'ToeBase',[sign*.3,-.65,.7]);
    aim(side+'ToeBase',side+'Toe_End',[sign*.3,-.3,.95]);
  }
  // Measure the actual skinned soles rather than guessing from a joint pivot.
  let sole=Infinity;
  model.traverse(mesh=>{
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
