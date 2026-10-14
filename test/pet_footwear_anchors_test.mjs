import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import * as THREE from '../assets/runner/vendor/three.module.js';
import {loadPet,runtimeUrl} from './three-runtime.mjs';
const {createFootwearAnchors}=await import(runtimeUrl('../assets/runner/pet-footwear-anchors.js'));
const {createNaturalRest}=await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));
for(const [species,file] of Object.entries({penguin:'Meshy_AI_Pip_the_Penguin_All_Animations.glb',bear:'bear.glb',pig:'pig.glb',chick:'chick.glb'}))test(species+': shoe joints stay in contact at rest and ease extreme rotation without changing the source rig',async()=>{
 const {scene,animations}=await loadPet(file);const model=new THREE.Group();model.add(scene);
 const mixer=new THREE.AnimationMixer(model);mixer.clipAction(createNaturalRest(model)).play();mixer.update(0);
 const parent=new THREE.Group();model.add(parent);model.updateMatrixWorld(true);
 const original=[];scene.traverse(o=>{if(o.isBone)original.push([o,o.position.clone(),o.quaternion.clone(),o.scale.clone()]);});
 const anchors=createFootwearAnchors(model,parent);
 for(const bone of Object.values(anchors.bones)){const p=new THREE.Vector3(),q=new THREE.Quaternion(),s=new THREE.Vector3();bone.matrix.decompose(p,q,s);assert.ok(p.length()<1e-5);assert.ok(q.angleTo(new THREE.Quaternion())<1e-5);}
 for(const [bone,p,q,s]of original){assert.ok(bone.position.equals(p));assert.ok(bone.quaternion.equals(q));assert.ok(bone.scale.equals(s));}
 mixer.stopAllAction();mixer.clipAction(animations.find(c=>c.name==='Regular_Jump')).play();mixer.setTime(.5);
 const current=original.map(([bone])=>[bone,bone.position.clone(),bone.quaternion.clone()]);anchors.update();
 for(const bone of Object.values(anchors.bones)){const p=new THREE.Vector3(),q=new THREE.Quaternion(),s=new THREE.Vector3();bone.matrix.decompose(p,q,s);assert.ok(q.angleTo(new THREE.Quaternion())<=.80001);assert.ok(p.toArray().every(Number.isFinite));}
 for(const [bone,p,q] of current){assert.ok(bone.position.equals(p));assert.ok(bone.quaternion.equals(q));}
});

for(const [species,file] of Object.entries({penguin:'Meshy_AI_Pip_the_Penguin_All_Animations.glb',bear:'bear.glb',pig:'pig.glb',chick:'chick.glb'}))test(species+': actual paw attachment preserves shoe shape through the full run and jump cycle',async()=>{
 const {scene,animations}=await loadPet(file),model=new THREE.Group();model.add(scene);
 const initial=new THREE.Box3().setFromObject(scene);scene.scale.multiplyScalar(1.15/initial.getSize(new THREE.Vector3()).y);
 const bounds=new THREE.Box3().setFromObject(scene),center=bounds.getCenter(new THREE.Vector3());scene.position.sub(new THREE.Vector3(center.x,bounds.min.y,center.z));
 const mixer=new THREE.AnimationMixer(model);mixer.clipAction(createNaturalRest(model)).play();mixer.update(0);model.updateMatrixWorld(true);
 const data=JSON.parse(readFileSync(new URL('../design/wardrobe-restart/fitting/'+species+'-original.json',import.meta.url)));
 const fit={feet:Object.fromEntries(Object.entries(data.feet).map(([side,b])=>[side,new THREE.Box3(new THREE.Vector3().fromArray(b.min),new THREE.Vector3().fromArray(b.max))]))};
 const parent=new THREE.Group();model.add(parent);const anchors=createFootwearAnchors(model,parent,.8,fit);
 for(const name of ['Running','Regular_Jump']){
  mixer.stopAllAction();const clip=animations.find(c=>c.name===name);mixer.clipAction(clip).play();
  for(const phase of [0,.25,.5,.75]){
   mixer.setTime(clip.duration*phase);anchors.update();
   for(const bone of Object.values(anchors.bones)){
    const a=new THREE.Vector3(.02,.04,.07),b=new THREE.Vector3(.15,.10,-.04),before=a.distanceTo(b);
    assert.ok(Math.abs(a.applyMatrix4(bone.matrix).distanceTo(b.applyMatrix4(bone.matrix))-before)<1e-6,'sole and upper must not stretch or flatten');
    assert.ok(Math.abs(bone.matrix.determinant()-1)<1e-6,'one rigid paw transform');
   }
  }
 }
});
