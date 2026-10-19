import test from 'node:test';import assert from 'node:assert/strict';
import * as T from '../assets/runner/vendor/three.module.js';
import {loadPet,runtimeUrl} from './three-runtime.mjs';
const {createNaturalRest}=await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));
const {createPetMotion}=await import(runtimeUrl('../assets/runner/pet-motion.js'));
for(const file of ['Meshy_AI_Pip_the_Penguin_All_Animations.glb','bear.glb','pig.glb','chick.glb'])test(file+': breathing, wave and kisses do not stretch body or displace feet',async()=>{
 const {scene}=await loadPet(file),mixer=new T.AnimationMixer(scene);mixer.clipAction(createNaturalRest(scene)).play();mixer.update(0);
 const fixed=[];scene.traverse(b=>{if(b.isBone&&/(Hips|Leg|Foot|ToeBase|Spine|Head|Arm|Hand)$/.test(b.name))fixed.push({bone:b,position:b.position.clone(),scale:b.scale.clone(),q:b.quaternion.clone()});});
 const motion=createPetMotion(scene),seen=new Set();
 for(let i=0;i<28*30;i++){
  mixer.update(1/30);motion.update(1/30);seen.add(scene.userData.roomGesture);
  for(const f of fixed){assert.ok(f.bone.scale.equals(f.scale));assert.ok(f.bone.position.equals(f.position));if(/(Hips|Leg|Foot|ToeBase)$/.test(f.bone.name))assert.ok(f.bone.quaternion.equals(f.q),f.bone.name+' stays in its original stance');}
 }
 assert.deepEqual(seen,new Set(['breathing','wave','kiss']));
 motion.dispose();assert.equal(scene.getObjectByName('room-kiss-hearts'),undefined);
});
