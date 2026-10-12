import test from 'node:test';
import assert from 'node:assert/strict';
import * as THREE from '../assets/runner/vendor/three.module.js';
import {loadPet,runtimeUrl} from './three-runtime.mjs';
const {createNaturalRest}=await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));
const {createRunnerJump}=await import(runtimeUrl('../assets/runner/pet-runner-jump.js'));
const pets={penguin:'Meshy_AI_Pip_the_Penguin_All_Animations.glb',bear:'bear.glb',pig:'pig.glb',chick:'chick.glb'};
test('the runner jump preserves proportions, has no root motion and lands in the fitted natural pose for all pets',async()=>{
 for(const [species,file] of Object.entries(pets)){
  const {scene}=await loadPet(file),model=new THREE.Group();model.add(scene);model.userData.species=species;
  const mixer=new THREE.AnimationMixer(model),rest=mixer.clipAction(createNaturalRest(model));rest.play();mixer.update(0);
  const bones=[];model.traverse(b=>{if(b.isBone)bones.push({bone:b,position:b.position.clone(),rotation:b.quaternion.clone(),scale:b.scale.clone()});});
  const clip=createRunnerJump(model);mixer.stopAllAction();const action=mixer.clipAction(clip);action.setLoop(THREE.LoopOnce,1);action.clampWhenFinished=true;action.play();
  for(const phase of [0,.15,.3,.5,.7,1]){
   mixer.setTime(clip.duration*phase);assert.deepEqual(model.position.toArray(),[0,0,0]);
   for(const {bone,position,rotation,scale} of bones){
    assert.ok(bone.position.distanceTo(position)<1e-5);assert.ok(bone.quaternion.angleTo(rotation)<.145);assert.ok(bone.scale.distanceTo(scale)<1e-7);
    if(phase===1)assert.ok(bone.quaternion.angleTo(rotation)<.001,species+': natural landing');
   }
  }
 }
});
