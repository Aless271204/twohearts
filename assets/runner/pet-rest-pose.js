import * as THREE from 'three';

// Measure the supplied pose without changing any bone or body proportions.
export function measurePetSoles(model) {
  model.updateMatrixWorld(true);
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
