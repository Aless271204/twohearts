import test from 'node:test';
import assert from 'node:assert/strict';
import * as THREE from '../assets/runner/vendor/three.module.js';
import {loadPet,runtimeUrl} from './three-runtime.mjs';
const {createNaturalRest}=await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));
const {refinePip}=await import(runtimeUrl('../assets/runner/pip-delicate.js'));
const {measureAccessoryFit}=await import(runtimeUrl('../assets/runner/cosmetics.js'));
const {stabilizePetTorso}=await import(runtimeUrl('../assets/runner/pet-garment-rig.js'));
const pets={penguin:'Meshy_AI_Pip_the_Penguin_All_Animations.glb',bear:'bear.glb',pig:'pig.glb',chick:'chick.glb'};
function point(mesh,index,model){mesh.skeleton.update();const p=new THREE.Vector3().fromBufferAttribute(mesh.geometry.attributes.position,index);mesh.applyBoneTransform(index,p);mesh.localToWorld(p);return model.worldToLocal(p);}
test('torso correction preserves each textured resting surface and separates belly motion from legs',async()=>{
 for(const [species,file] of Object.entries(pets)){
  const {scene}=await loadPet(file);scene.scale.multiplyScalar(1.15/new THREE.Box3().setFromObject(scene).getSize(new THREE.Vector3()).y);
  const box=new THREE.Box3().setFromObject(scene),center=box.getCenter(new THREE.Vector3());scene.position.sub(new THREE.Vector3(center.x,box.min.y,center.z));
  const model=new THREE.Group();model.add(scene);model.userData.species=species;const mixer=new THREE.AnimationMixer(model);mixer.clipAction(createNaturalRest(model)).play();mixer.update(0);if(species==='penguin')refinePip(model);
  const fit=measureAccessoryFit(model),hem=Math.max(.135,fit.body.min.y+.08),original=new Map();model.updateMatrixWorld(true);
  model.traverse(mesh=>{if(mesh.isSkinnedMesh)original.set(mesh,Array.from({length:mesh.geometry.attributes.position.count},(_,i)=>point(mesh,i,model)));});
  stabilizePetTorso(model,fit);model.updateMatrixWorld(true);let corrected=0;
  for(const [mesh,positions] of original){corrected+=mesh.userData.torsoRigCorrectedVertices??0;for(let i=0;i<positions.length;i++)assert.ok(point(mesh,i,model).distanceTo(positions[i])<2e-6,`${species}: rest ${i}`);}
  assert.ok(corrected>0,species);
  let leg,head;model.traverse(bone=>{if(bone.isBone&&/LeftUpLeg$/.test(bone.name))leg=bone;if(bone.isBone&&/Head$/.test(bone.name))head=bone;});const legRest=leg.quaternion.clone();leg.rotation.x+=.7;model.updateMatrixWorld(true);let moved=0;
  for(const [mesh,positions] of original)for(let i=0;i<positions.length;i+=7){const distance=point(mesh,i,model).distanceTo(positions[i]);if(positions[i].y>=hem)assert.ok(distance<2e-6,`${species}: leg pulled torso`);else moved=Math.max(moved,distance);}
  assert.ok(moved>.01,`${species}: legs still move independently`);
  leg.quaternion.copy(legRest);head.rotation.x+=.35;model.updateMatrixWorld(true);let faceMoved=0;
  for(const [mesh,positions] of original)for(let i=0;i<positions.length;i+=7){
   const distance=point(mesh,i,model).distanceTo(positions[i]);
   if(positions[i].y<=fit.body.max.y)assert.ok(distance<2e-6,`${species}: head pulled the clothed chest`);
   if(positions[i].y>fit.body.max.y+.10)faceMoved=Math.max(faceMoved,distance);
  }
  assert.ok(faceMoved>.01,`${species}: face still responds independently`);
 }
});
