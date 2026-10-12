import * as THREE from 'three';

// Capture the same natural pose used by the wardrobe mannequin. The runner
// moves the whole character through its jump arc; this clip only tucks the
// paws and opens the arms gently. It never translates/scales the root or folds
// the imported mascot through its clothes like the source acrobatic jump.
export function createRunnerJump(model){
 const times=[0,.12,.30,.52,.72],amounts=[0,.65,1,.35,0],tracks=[];
 model.traverse(bone=>{
  if(!bone.isBone)return;
  const name=bone.name.replace(/^mixamorig:?/,''),base=bone.quaternion.clone();
  let axis=new THREE.Vector3(1,0,0),angle=0;
  if(/UpLeg$/.test(name))angle=.14;
  else if(/Leg$/.test(name))angle=-.10;
  else if(/Foot$/.test(name))angle=.04;
  else if(name==='Head')angle=-.035;
  else if(name==='Spine2')angle=.025;
  else if(/^(Left|Right)Arm$/.test(name)){axis.set(0,0,1);angle=name.startsWith('Left')?.10:-.10;}
  const rotations=amounts.flatMap(amount=>base.clone().multiply(new THREE.Quaternion().setFromAxisAngle(axis,angle*amount)).toArray());
  tracks.push(new THREE.QuaternionKeyframeTrack(bone.name+'.quaternion',times,rotations));
  tracks.push(new THREE.VectorKeyframeTrack(bone.name+'.position',[0,.72],[...bone.position.toArray(),...bone.position.toArray()]));
 });
 return new THREE.AnimationClip('Regular_Jump',.72,tracks);
}
