import test from 'node:test';
import assert from 'node:assert/strict';
import * as THREE from '../assets/runner/vendor/three.module.js';
import {loadPet,runtimeUrl} from './three-runtime.mjs';
const {createNaturalRest}=await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));
const {createWardrobeJump,createWardrobeRun}=await import(runtimeUrl('../assets/runner/pet-wardrobe-jump.js'));
for(const [species,file] of Object.entries({penguin:'Meshy_AI_Pip_the_Penguin_All_Animations.glb',bear:'bear.glb',pig:'pig.glb',chick:'chick.glb'})){
 test(species+': tailored jump keeps the source immutable, preserves timing and dynamic leg drive, and eases ankle twists',async()=>{
  const {scene,animations}=await loadPet(file);createNaturalRest(scene);
  const source=animations.find(clip=>clip.name==='Regular_Jump');
  const original=source.tracks.map(track=>({times:Array.from(track.times),values:Array.from(track.values)}));
  const result=createWardrobeJump(scene,source);
  assert.equal(result.duration,source.duration);assert.equal(result.name,'Natural_Jump');
  for(let i=0;i<source.tracks.length;i++){
   const track=source.tracks[i];assert.deepEqual(Array.from(track.times),original[i].times);assert.deepEqual(Array.from(track.values),original[i].values);
   assert.deepEqual(Array.from(result.tracks[i].times),original[i].times);

  }
  const shoulder=result.tracks.filter(track=>/Shoulder\.quaternion$/.test(track.name));
  for(const track of shoulder){const reference=scene.getObjectByName(track.name.slice(0,-11)).quaternion;
   for(let i=0;i<track.values.length;i+=4)assert.ok(reference.angleTo(new THREE.Quaternion().fromArray(track.values,i))<=.201);
  }
  for(const [semantic,limit]of [['LeftUpLeg',.55],['RightUpLeg',.55],['LeftLeg',.45],['RightLeg',.45],['LeftFoot',.36],['RightFoot',.36]]){
   const track=result.tracks.find(t=>t.name.endsWith(semantic+'.quaternion')),reference=scene.getObjectByName(track.name.slice(0,-11)).quaternion;
   for(let i=0;i<track.values.length;i+=4)assert.ok(reference.angleTo(new THREE.Quaternion().fromArray(track.values,i))<=limit+.001);
  }
 });
 test(species+': new run preserves timing and an alternating leg cycle with controlled paw twists',async()=>{
  const {scene,animations}=await loadPet(file);createNaturalRest(scene);
  const source=animations.find(c=>c.name==='Running'),before=source.tracks.map(t=>Array.from(t.values));
  const result=createWardrobeRun(scene,source);assert.equal(result.duration,source.duration);
  for(let i=0;i<source.tracks.length;i++){
   assert.deepEqual(Array.from(source.tracks[i].values),before[i]);assert.deepEqual(Array.from(result.tracks[i].times),Array.from(source.tracks[i].times));

  }
  for(const semantic of ['LeftArm','RightArm','LeftUpLeg','RightUpLeg']){
   const t=result.tracks.find(t=>t.name.endsWith(semantic+'.quaternion'));
   assert.ok(t&&Array.from(t.values).some((v,i)=>Math.abs(v-t.values[i%4])>1e-5),'flipper cycle must retain movement');
  }
 });
}
