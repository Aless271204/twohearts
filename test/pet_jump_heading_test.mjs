import test from 'node:test';
import assert from 'node:assert/strict';
import * as THREE from '../assets/runner/vendor/three.module.js';
import {loadPet,runtimeUrl} from './three-runtime.mjs';
const {keepJumpFacingForward}=await import(runtimeUrl('../assets/runner/pet-jump-heading.js'));
const pets={penguin:'Meshy_AI_Pip_the_Penguin_All_Animations.glb',bear:'bear.glb',pig:'pig.glb',chick:'chick.glb'};

for(const [species,file] of Object.entries(pets))test(`${species}: original jump articulation with forward root heading`,async()=>{
 const {scene,animations}=await loadPet(file),source=animations.find(c=>c.name==='Regular_Jump');
 assert.ok(source,'Actual pet asset must include its original jump');
 const original=source.tracks.map(t=>Array.from(t.values));
 const bones=new Map();scene.traverse(b=>{if(b.isBone){bones.set(b.name,b);bones.set(b.uuid,b);}});
 const result=keepJumpFacingForward(scene,source);assert.equal(result.duration,source.duration);
 let rootTracks=0;
 for(let i=0;i<source.tracks.length;i++){
  const before=source.tracks[i],after=result.tracks[i],binding=THREE.PropertyBinding.parseTrackName(before.name),bone=bones.get(binding.nodeName);
  assert.deepEqual(Array.from(before.values),original[i],'Source data remains untouched');
  assert.deepEqual(after.times,before.times,'Original timing remains untouched');
  if(!bone||!/(Hips|Root)$/.test(bone.name)){assert.deepEqual(after.values,before.values,'Limbs, head and spine retain original animation');continue;}
  if(binding.propertyName==='position'){
   rootTracks++;
   for(let k=0;k<after.values.length;k+=3){assert.ok(Math.abs(after.values[k]-bone.position.x)<1e-5);assert.equal(after.values[k+1],before.values[k+1]);assert.ok(Math.abs(after.values[k+2]-bone.position.z)<1e-5);}
  }else if(binding.propertyName==='quaternion'){
   rootTracks++;
   const heading=new THREE.Quaternion(0,bone.quaternion.y,0,bone.quaternion.w).normalize();
   for(let k=0;k<after.values.length;k+=4){const rotation=new THREE.Quaternion().fromArray(after.values,k);assert.ok(Math.abs(rotation.length()-1)<1e-5);rotation.multiply(heading.clone().invert());assert.ok(Math.abs(rotation.y)<1e-5,'No sideways twist relative to standing heading');}
  }
 }
 assert.ok(rootTracks>=2,'The source root rotation and position were checked');
});
