import * as THREE from 'three';

// The supplied rigs give some belly vertices thigh/toe influences and some
// chest vertices head influences. Correct only those torso influences in
// the live copy, preserving the exact fitted rest surface and original GLBs.
export function stabilizePetTorso(model,fit){
 if(model.userData.torsoRigStabilized)return;
 const hem=Math.max(.135,fit.body.min.y+.08),low=hem-.055,high=hem-.005;
 const chest=fit.body.max.y,neckTop=chest+.055;
 model.userData.accessoryFit=fit;
 model.updateMatrixWorld(true);
 model.traverse(mesh=>{
  if(!mesh.isSkinnedMesh||mesh.userData.cosmetic)return;
  mesh.skeleton.update();
  const geometry=mesh.geometry.clone(),p=geometry.attributes.position,j=geometry.attributes.skinIndex,w=geometry.attributes.skinWeight;
  const names=mesh.skeleton.bones.map(b=>b.name),hips=names.findIndex(name=>/Hips$/.test(name)),spine=names.findIndex(name=>/Spine2$/.test(name));if(hips<0||spine<0)return;
  const leg=new Set(names.flatMap((name,i)=>/(UpLeg|Leg|Foot|ToeBase|Toe_End)$/.test(name)?[i]:[]));
  const neck=new Set(mesh.skeleton.bones.flatMap((bone,i)=>{
   for(let ancestor=bone;ancestor?.isBone;ancestor=ancestor.parent)if(/(Head|Neck)$/.test(ancestor.name))return [i];
   return [];
  }));
  const blend=new THREE.Matrix4(),boneMatrix=new THREE.Matrix4(),rest=new THREE.Vector3(),posed=new THREE.Vector3();let corrected=0;
  for(let i=0;i<p.count;i++){
   rest.fromBufferAttribute(p,i);mesh.applyBoneTransform(i,rest);posed.copy(rest);mesh.localToWorld(posed);model.worldToLocal(posed);
   const legAmount=THREE.MathUtils.smoothstep(posed.y,low,high);
   const chestAmount=1-THREE.MathUtils.smoothstep(posed.y,chest,neckTop);
   const weights=new Map();let transfer=0;
   for(let k=0;k<4;k++){
    const bone=j.getComponent(i,k),weight=w.getComponent(i,k);
    const target=leg.has(bone)?hips:neck.has(bone)?spine:bone;
    const move=leg.has(bone)?weight*legAmount:neck.has(bone)?weight*chestAmount:0;
    transfer+=move;weights.set(bone,(weights.get(bone)??0)+weight-move);
    if(move)weights.set(target,(weights.get(target)??0)+move);
   }
   if(transfer<1e-6)continue;
   const chosen=[...weights].filter(([,weight])=>weight>1e-8).sort((a,b)=>b[1]-a[1]).slice(0,4),total=chosen.reduce((sum,[,weight])=>sum+weight,0);
   blend.elements.fill(0);
   for(let k=0;k<4;k++){
    const [bone,raw]=chosen[k]??[0,0],weight=raw/total;j.setComponent(i,k,bone);w.setComponent(i,k,weight);
    if(!weight)continue;boneMatrix.fromArray(mesh.skeleton.boneMatrices,bone*16);for(let t=0;t<16;t++)blend.elements[t]+=weight*boneMatrix.elements[t];
   }
   // New weights must reproduce the old rest position, including any posed arm
   // influence that shares this vertex; compensate in the mesh's bind frame.
   blend.premultiply(mesh.bindMatrixInverse).multiply(mesh.bindMatrix).invert();rest.applyMatrix4(blend);p.setXYZ(i,rest.x,rest.y,rest.z);corrected++;
  }
  if(corrected){p.needsUpdate=true;j.needsUpdate=true;w.needsUpdate=true;geometry.computeBoundingBox();geometry.computeBoundingSphere();mesh.geometry=geometry;mesh.userData.torsoRigCorrectedVertices=corrected;}
  else geometry.dispose();
 });
 model.userData.torsoRigStabilized=true;
}
