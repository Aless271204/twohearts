import * as THREE from 'three';

// Preserve the imported jump's articulation while removing sideways root motion.
// Game physics owns lane position; the mascot keeps its forward heading.
export function keepJumpFacingForward(model,source){
 if(!source)return null;
 const bones=new Map();model.traverse(o=>{if(o.isBone){bones.set(o.name,o);bones.set(o.uuid,o);}});
 const clip=source.clone();
 for(const track of clip.tracks){
  const binding=THREE.PropertyBinding.parseTrackName(track.name),bone=bones.get(binding.nodeName);
  if(!bone||!/(Hips|Root)$/.test(bone.name))continue;
  if(binding.propertyName==='quaternion'){
   const base=bone.quaternion.clone().normalize(),heading=new THREE.Quaternion(0,base.y,0,base.w).normalize();
   for(let i=0;i<track.values.length;i+=4){
    const q=new THREE.Quaternion().fromArray(track.values,i).normalize();
    const twist=new THREE.Quaternion(0,q.y,0,q.w);
    if(twist.lengthSq()<1e-10)continue;
    twist.normalize();q.multiply(twist.invert()).multiply(heading).normalize().toArray(track.values,i);
   }
  }else if(binding.propertyName==='position'){
   for(let i=0;i<track.values.length;i+=3){track.values[i]=bone.position.x;track.values[i+2]=bone.position.z;}
  }
 }
 return clip;
}
