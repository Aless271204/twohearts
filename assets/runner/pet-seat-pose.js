import * as THREE from 'three';
// Joint rotations on the supplied rig; no scale tracks or pet mesh edits.
export function createPetSeatPose(model){
 model.updateMatrixWorld(true);const bones={};model.traverse(o=>{if(o.isBone)bones[o.name.replace(/^mixamorig:?/,'')]=o;});
 const saved=new Map(Object.values(bones).map(b=>[b,b.quaternion.clone()]));
 function aim(joint,child,direction){if(!joint||!child)return;model.updateMatrixWorld(true);const from=child.getWorldPosition(new THREE.Vector3()).sub(joint.getWorldPosition(new THREE.Vector3())).normalize();const world=new THREE.Quaternion().setFromUnitVectors(from,direction.clone().normalize()).multiply(joint.getWorldQuaternion(new THREE.Quaternion()));joint.quaternion.copy(joint.parent.getWorldQuaternion(new THREE.Quaternion()).invert().multiply(world));}
 for(const [side,sign] of [['Left',1],['Right',-1]]){
  aim(bones[side+'UpLeg'],bones[side+'Leg'],new THREE.Vector3(sign*.06,-.22,.97));
  aim(bones[side+'Leg'],bones[side+'Foot'],new THREE.Vector3(sign*.02,-.98,.16));
 }
 const tracks=[];for(const bone of Object.values(bones)){const q=bone.quaternion.clone(),breath=q.clone();if(/(Spine2|Head)$/.test(bone.name))breath.multiply(new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(1,0,0),.01));tracks.push(new THREE.QuaternionKeyframeTrack(bone.name+'.quaternion',[0,1.8,3.6],[...q.toArray(),...breath.toArray(),...q.toArray()]));}
 model.updateMatrixWorld(true);const pelvis=bones.Hips?.getWorldPosition(new THREE.Vector3());if(pelvis)model.worldToLocal(pelvis);
 for(const [bone,q] of saved)bone.quaternion.copy(q);model.updateMatrixWorld(true);
 return {clip:new THREE.AnimationClip('Room_Sit',3.6,tracks),pelvisHeight:pelvis?.y??.25};
}
