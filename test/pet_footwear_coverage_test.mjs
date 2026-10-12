import test from 'node:test';
import assert from 'node:assert/strict';
import * as THREE from '../assets/runner/vendor/three.module.js';
import {loadPet,runtimeUrl} from './three-runtime.mjs';
const {createNaturalRest}=await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));
const {refinePip}=await import(runtimeUrl('../assets/runner/pip-delicate.js'));
const {measureAccessoryFit,tuckCrownTuft}=await import(runtimeUrl('../assets/runner/cosmetics.js'));
const {stabilizePetTorso}=await import(runtimeUrl('../assets/runner/pet-garment-rig.js'));
const {restoreFootwearCoverage,coverClosedFootwear}=await import(runtimeUrl('../assets/runner/pet-footwear-coverage.js'));
const pets={penguin:'Meshy_AI_Pip_the_Penguin_All_Animations.glb',bear:'bear.glb',pig:'pig.glb',chick:'chick.glb'};

test('closed footwear hides only its covered skin and restores original triangles with sandals, also after a hat change',async()=>{
 for(const [species,file] of Object.entries(pets)){
  const {scene}=await loadPet(file);scene.scale.multiplyScalar(1.15/new THREE.Box3().setFromObject(scene).getSize(new THREE.Vector3()).y);
  const bounds=new THREE.Box3().setFromObject(scene),center=bounds.getCenter(new THREE.Vector3());scene.position.sub(new THREE.Vector3(center.x,bounds.min.y,center.z));
  const model=new THREE.Group();model.add(scene);model.userData.species=species;
  const mixer=new THREE.AnimationMixer(model);mixer.clipAction(createNaturalRest(model)).play();mixer.update(0);if(species==='penguin')refinePip(model);
  const fit=measureAccessoryFit(model);stabilizePetTorso(model,fit);
  const originals=new Map();model.traverse(m=>{if(m.isMesh&&m.geometry.index)originals.set(m,{indices:Array.from(m.geometry.index.array),positions:Array.from(m.geometry.attributes.position.array)});});
  tuckCrownTuft(model,true);coverClosedFootwear(model,fit,{fitted_model_space:true,style:'sneakers'});
  let hidden=0;
  for(const [mesh,source] of originals){
   hidden+=source.indices.length-mesh.geometry.index.count;
   assert.deepEqual(Array.from(mesh.geometry.attributes.position.array),source.positions);
   for(const vertex of mesh.geometry.index.array)assert.ok(!mesh.userData.closedFootwearVertices?.has(vertex),species+': covered toe remains visible');
  }
  assert.ok(hidden>0,species);
  restoreFootwearCoverage(model);tuckCrownTuft(model,false);coverClosedFootwear(model,fit,{fitted_model_space:true,style:'sandals'});
  for(const [mesh,source] of originals)assert.deepEqual(Array.from(mesh.geometry.index.array),source.indices,species+': remove shoes restores anatomy');
 }
});
