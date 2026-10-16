import * as THREE from 'three';

// Clothes are authored on the posed, normalized mascot. The source skeleton
// still skins from its original GLB bind pose. Rebase the garment through the
// *blended* source bind transform, rather than inverting each joint separately.
export function bindGarmentToOriginalSkin(mesh, source, skeletons=new Map()) {
  mesh.updateWorldMatrix(true, false);source.updateWorldMatrix(true, false);source.skeleton.update();
  const geometry=mesh.geometry.clone(),position=geometry.attributes.position,joints=geometry.attributes.skinIndex,weights=geometry.attributes.skinWeight;
  const names=mesh.userData.nidoBoneNames;
  const byName=new Map(source.skeleton.bones.map((b,i)=>[b.name.replace(/^mixamorig:?/,''),i]));
  const remap=names.map(n=>byName.get(n.replace(/^mixamorig:?/,'')));
  const transform=new THREE.Matrix4(),boneMatrix=new THREE.Matrix4(),p=new THREE.Vector3();
  for(let i=0;i<position.count;i++){
    transform.elements.fill(0);
    for(let k=0;k<4;k++){
      const weight=weights.getComponent(i,k),bone=remap[joints.getComponent(i,k)];
      if(weight>1e-8&&bone===undefined)throw Error('La prenda usa un hueso ajeno a la mascota original');
      joints.setComponent(i,k,bone??0);
      if(!weight)continue;
      boneMatrix.fromArray(source.skeleton.boneMatrices,(bone??0)*16);
      for(let n=0;n<16;n++)transform.elements[n]+=weight*boneMatrix.elements[n];
    }
    transform.multiply(source.bindMatrix);
    if(Math.abs(transform.determinant())<1e-10)throw Error('El enlace de la prenda no es invertible');
    p.fromBufferAttribute(position,i).applyMatrix4(mesh.matrixWorld).applyMatrix4(transform.invert());
    position.setXYZ(i,p.x,p.y,p.z);
  }
  position.needsUpdate=true;joints.needsUpdate=true;
  geometry.computeVertexNormals();geometry.computeBoundingBox();geometry.computeBoundingSphere();
  const garment=new THREE.SkinnedMesh(geometry,mesh.material);garment.name=mesh.name;
  garment.userData={...mesh.userData,cosmetic:true,nidoOriginalSkinBinding:true};garment.frustumCulled=false;
  const parent=mesh.parent;parent.add(garment);
  const local=parent.matrixWorld.clone().invert().multiply(source.matrixWorld);
  local.decompose(garment.position,garment.quaternion,garment.scale);
  let skeleton=skeletons.get(source);
  if(!skeleton){skeleton=new THREE.Skeleton(source.skeleton.bones,source.skeleton.boneInverses.map(m=>m.clone()));skeletons.set(source,skeleton);}
  garment.bind(skeleton,source.bindMatrix.clone());
  mesh.removeFromParent();mesh.geometry.dispose();
  garment.updateWorldMatrix(true,false);
  return garment;
}
