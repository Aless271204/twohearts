import test from 'node:test';
import assert from 'node:assert/strict';
import * as THREE from '../assets/runner/vendor/three.module.js';
import {loadPet,runtimeUrl} from './three-runtime.mjs';
const {createNaturalRest}=await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));
const {createRunnerRun}=await import(runtimeUrl('../assets/runner/pet-runner-run.js'));
const files=['Meshy_AI_Pip_the_Penguin_All_Animations.glb','bear.glb','pig.glb','chick.glb'];
test('running keeps the supplied stride and original data while containing sleeve motion on all four pets',async()=>{
 for(const file of files){
  const {scene,animations}=await loadPet(file),model=new THREE.Group();model.add(scene);
  const mixer=new THREE.AnimationMixer(model);mixer.clipAction(createNaturalRest(model)).play();mixer.update(0);
  const source=animations.find(c=>c.name==='Running'),before=source.tracks.map(t=>Array.from(t.values));
  const bones=new Map();model.traverse(b=>{if(b.isBone){bones.set(b.name,b);bones.set(b.uuid,b);}});
  const clip=createRunnerRun(model,source);assert.equal(clip.duration,source.duration);let limited=0;
  for(let i=0;i<clip.tracks.length;i++){
   const track=clip.tracks[i],binding=THREE.PropertyBinding.parseTrackName(track.name),bone=bones.get(binding.nodeName);
   assert.deepEqual(Array.from(source.tracks[i].values),before[i],'Original animation stays intact');
   assert.deepEqual(track.times,source.tracks[i].times,'Stride timing stays intact');
   if(bone&&binding.propertyName==='quaternion'&&/(Shoulder|Arm|ForeArm)$/.test(bone.name)){
    limited++;const limit=/Shoulder$/.test(bone.name)?.14:/ForeArm$/.test(bone.name)?.20:.26;
    for(let k=0;k<track.values.length;k+=4)assert.ok(bone.quaternion.angleTo(new THREE.Quaternion().fromArray(track.values,k).normalize())<=limit+1e-5);
   }else assert.deepEqual(track.values,source.tracks[i].values,'Other motion stays intact');
  }
  assert.ok(limited>=4,file+': shoulder/arm tracks found');
 }
});
