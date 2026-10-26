import * as THREE from 'three';

// The garment retains its own mesh/UV/material and ease. Source triangles only
// provide its moving cage; the supplied mascot geometry and skeleton are read.
export function createClothWrap(model,garments){
 const sources=new Map();model.traverse(m=>{if(m.isSkinnedMesh&&!m.userData.cosmetic)sources.set(m.name,m);});
 const states=garments.map(mesh=>{
  const a=mesh.geometry.attributes,profile=mesh.userData.nidoSurfaceWrap;
  if(!profile||!a._nido_wrap_indices||!a._nido_wrap_weights||!a._nido_wrap_offset)throw Error('Falta el molde animado de la prenda');
  const lookup=[];
  for(const source of profile.sources){const m=sources.get(source.name);if(!m)throw Error('El molde no corresponde a esta mascota');for(let i=0;i<source.count;i++)lookup[source.offset+i]={mesh:m,index:i};}
  return {mesh,lookup,ids:a._nido_wrap_indices,weights:a._nido_wrap_weights,offset:a._nido_wrap_offset,blend:a._nido_wrap_blend,rest:a.position.array.slice(),skin:mesh.userData.nidoWrapSkin};
 });
 const p=new THREE.Vector3(),tangent=new THREE.Vector3(),across=new THREE.Vector3(),normal=new THREE.Vector3(),delta=new THREE.Vector3(),out=new THREE.Vector3();
 const modelInverse=new THREE.Matrix4(),meshInverse=new THREE.Matrix4(),sourceMatrix=new THREE.Matrix4();
 function update(){
  model.updateMatrixWorld(true);modelInverse.copy(model.matrixWorld).invert();const cache=new Map(),updatedSkeletons=new Set();
  const updateSkeleton=skeleton=>{if(!updatedSkeletons.has(skeleton)){skeleton.update();updatedSkeletons.add(skeleton);}};
  for(const {mesh,lookup,ids,weights,offset,blend,rest,skin} of states){
   mesh.updateWorldMatrix(true,false);meshInverse.copy(mesh.matrixWorld).invert().multiply(model.matrixWorld);
   if(skin){skin.matrixWorld.copy(mesh.matrixWorld);skin.bindMatrixInverse.copy(mesh.matrixWorld).invert();updateSkeleton(skin.skeleton);}
   const get=i=>{const source=lookup[i];if(!cache.has(source.mesh))cache.set(source.mesh,new Map());const values=cache.get(source.mesh);if(!values.has(source.index)){updateSkeleton(source.mesh.skeleton);p.fromBufferAttribute(source.mesh.geometry.attributes.position,source.index);source.mesh.applyBoneTransform(source.index,p);sourceMatrix.multiplyMatrices(modelInverse,source.mesh.matrixWorld);values.set(source.index,p.clone().applyMatrix4(sourceMatrix));}return values.get(source.index);};
   for(let i=0;i<ids.count;i++){
    const a=get(ids.getX(i)),b=get(ids.getY(i)),c=get(ids.getZ(i));
    tangent.subVectors(b,a).normalize();delta.subVectors(c,a);normal.crossVectors(tangent,delta).normalize();across.crossVectors(normal,tangent).normalize();
    out.copy(a).multiplyScalar(weights.getX(i)).addScaledVector(b,weights.getY(i)).addScaledVector(c,weights.getZ(i));
    if(mesh.userData.nidoSurfaceWrap.offset_frame==='model')out.add(delta.set(offset.getX(i),offset.getY(i),offset.getZ(i)));
    else out.addScaledVector(tangent,offset.getX(i)).addScaledVector(across,offset.getY(i)).addScaledVector(normal,offset.getZ(i));
    out.applyMatrix4(meshInverse);
    if(skin&&blend){p.fromArray(rest,i*3);skin.applyBoneTransform(i,p);out.lerp(p,1-blend.getX(i));}
    mesh.geometry.attributes.position.setXYZ(i,out.x,out.y,out.z);
   }
   mesh.geometry.attributes.position.needsUpdate=true;mesh.geometry.computeVertexNormals();
  }
 }
 update();return {update};
}
