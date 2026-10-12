import * as THREE from 'three';

// Retain the supplied stride and timing. Limit the upper-body swing around
// the fitted natural pose so shoulders cannot fold through tailored sleeves.
// The original embedded animation and imported mascot remain unchanged.
export function createRunnerRun(model,source){
 if(!source)return null;
 const bones=new Map();model.traverse(bone=>{if(bone.isBone){bones.set(bone.name,bone);bones.set(bone.uuid,bone);}});
 const clip=source.clone();clip.name='Natural_Run';
 for(const track of clip.tracks){
  const binding=THREE.PropertyBinding.parseTrackName(track.name);
  const bone=bones.get(binding.nodeName);
  if(!bone||binding.propertyName!=='quaternion'||!/(Shoulder|Arm|ForeArm)$/.test(bone.name))continue;
  const limit=/Shoulder$/.test(bone.name)?.14:/ForeArm$/.test(bone.name)?.20:.26;
  const base=bone.quaternion.clone().normalize();
  for(let i=0;i<track.values.length;i+=4){
   const rotation=new THREE.Quaternion().fromArray(track.values,i).normalize(),angle=base.angleTo(rotation);
   base.clone().slerp(rotation,angle>limit?limit/angle:1).toArray(track.values,i);
  }
 }
 return clip;
}
