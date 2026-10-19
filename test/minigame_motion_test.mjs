import test from 'node:test';
import assert from 'node:assert/strict';
import {loadPet,runtimeUrl} from './three-runtime.mjs';
const {shotPresentation,keeperPresentation,CONTACT_TIME}=await import(runtimeUrl('../assets/runner/penalties/motion.js'));
const {createMazePartnerMotion}=await import(runtimeUrl('../assets/runner/maze/partner-motion.js'));
test('ball waits for the actual kick, keeper reacts after contact and recovers',()=>{
 const result={kind:'goal'};
 assert.equal(shotPresentation(.2,result).flight,0);
 assert.equal(shotPresentation(CONTACT_TIME,result).flight,0);
 assert.ok(Math.abs(shotPresentation(1.24,result).flight-1)<1e-12);
 assert.equal(shotPresentation(.4,result).dive,0);
 assert.ok(shotPresentation(.8,result).dive>0);
 assert.equal(shotPresentation(2.8,result).dive,0);
 assert.ok(shotPresentation(2,result).celebrate>0);
 assert.equal(shotPresentation(2,{kind:'save'}).celebrate,0);
 const low=keeperPresentation(.9,{kind:'save',shot:{x:.8,y:.1}}),high=keeperPresentation(.9,{kind:'save',shot:{x:.8,y:.9}});
 assert.ok(high.y>low.y);assert.ok(high.x>0);
});
test('all four original maze partners articulate their legs and blend back to rest',async()=>{
 for(const file of ['Meshy_AI_Pip_the_Penguin_All_Animations.glb','bear.glb','pig.glb','chick.glb']){
  const pet=await loadPet(file),model=pet.scene,motion=createMazePartnerMotion(model,pet.animations);
  const legs=[];model.traverse(o=>{if(o.isBone&&/(UpLeg|Leg|Foot)$/.test(o.name))legs.push(o);});
  const size=legs.map(b=>b.scale.clone());
  for(let i=0;i<15;i++)motion.update(1/60,3);
  const first=legs.map(b=>b.quaternion.clone());
  for(let i=0;i<15;i++)motion.update(1/60,3);
  assert.ok(legs.some((b,i)=>b.quaternion.angleTo(first[i])>.1),file+' must step instead of sliding');
  for(let i=0;i<90;i++)motion.update(1/60,0);
  assert.ok(motion.walkingWeight<.001);
  legs.forEach((b,i)=>assert.ok(b.scale.distanceTo(size[i])<1e-10));
  motion.update(.1,3,true);assert.ok(model.rotation.z<0,'Fallen partner remains visible for rescue');
  motion.dispose();
 }
});
