import * as THREE from 'three';
import {keepJumpFacingForward} from './pet-jump-heading.js';

// Experimental animation retarget only. The supplied GLB, mesh, textures,
// skeleton and original animation remain immutable and available for comparison.
function tailorMotion(model,source,name,limits){
 if(!source)return null;
 const clip=keepJumpFacingForward(model,source);clip.name=name;
 const bones=new Map();model.traverse(bone=>{if(bone.isBone)bones.set(bone.name,bone);});
 for(const track of clip.tracks){
  if(!track.name.endsWith('.quaternion'))continue;
  const name=track.name.slice(0,-11),semantic=name.replace(/^mixamorig:?/,''),limit=limits[semantic]??(/^(Left|Right)Hand/.test(semantic)?.04:undefined),bone=bones.get(name);
  if(limit===undefined||!bone)continue;
  const reference=bone.quaternion.clone().normalize();
  for(let i=0;i<track.values.length;i+=4){
   const target=new THREE.Quaternion().fromArray(track.values,i).normalize(),angle=reference.angleTo(target);
   // Smooth compression retains changes in velocity through the cycle; a hard
   // angular clamp flattened those changes and made the former jump look stiff.
   if(angle>1e-6)reference.clone().slerp(target,limit*Math.tanh(angle/limit)/angle).toArray(track.values,i);
  }
 }
 return clip;
}

export function createWardrobeJump(model,source){
 return tailorMotion(model,source,'Natural_Jump',{Hips:.32,Spine:.06,Spine1:.06,Spine2:.06,Neck:.06,Head:.07,LeftShoulder:.08,RightShoulder:.08,LeftArm:.16,RightArm:.16,LeftForeArm:.10,RightForeArm:.10,LeftUpLeg:.55,RightUpLeg:.55,LeftLeg:.45,RightLeg:.45,LeftFoot:.36,RightFoot:.36,LeftToeBase:.12,RightToeBase:.12});
}
export function createWardrobeRun(model,source){
 return tailorMotion(model,source,'Wardrobe_Run',{Hips:.24,Spine:.05,Spine1:.04,Spine2:.04,Neck:.05,Head:.05,LeftShoulder:.06,RightShoulder:.06,LeftArm:.12,RightArm:.12,LeftForeArm:.08,RightForeArm:.08,LeftUpLeg:.45,RightUpLeg:.45,LeftLeg:.40,RightLeg:.40,LeftFoot:.32,RightFoot:.32,LeftToeBase:.10,RightToeBase:.10});
}
