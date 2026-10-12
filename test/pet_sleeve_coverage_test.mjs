import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import * as THREE from '../assets/runner/vendor/three.module.js';
import {loadPet,runtimeUrl} from './three-runtime.mjs';
const {createNaturalRest}=await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));
const {refinePip}=await import(runtimeUrl('../assets/runner/pip-delicate.js'));
const {measureAccessoryFit,tuckCrownTuft}=await import(runtimeUrl('../assets/runner/cosmetics.js'));
const {stabilizePetTorso}=await import(runtimeUrl('../assets/runner/pet-garment-rig.js'));
const {restoreFootwearCoverage,coverClosedFootwear}=await import(runtimeUrl('../assets/runner/pet-footwear-coverage.js'));
const {restoreSleeveCoverage,coverSleeveSkin}=await import(runtimeUrl('../assets/runner/pet-sleeve-coverage.js'));
const items=JSON.parse(readFileSync(new URL('../assets/runner/accessory-catalog.json',import.meta.url))).filter(i=>i.equip_slot==='pet_body');
const pets={penguin:'Meshy_AI_Pip_the_Penguin_All_Animations.glb',bear:'bear.glb',pig:'pig.glb',chick:'chick.glb'};
test('sleeves cover upper-arm skin, retain exposed hands and restore every source triangle when removed',async()=>{
 for(const [species,file] of Object.entries(pets)){
  const {scene}=await loadPet(file);scene.scale.multiplyScalar(1.15/new THREE.Box3().setFromObject(scene).getSize(new THREE.Vector3()).y);
  const bounds=new THREE.Box3().setFromObject(scene),center=bounds.getCenter(new THREE.Vector3());scene.position.sub(new THREE.Vector3(center.x,bounds.min.y,center.z));
  const model=new THREE.Group();model.add(scene);model.userData.species=species;
  const mixer=new THREE.AnimationMixer(model);mixer.clipAction(createNaturalRest(model)).play();mixer.update(0);if(species==='penguin')refinePip(model);
  const fit=measureAccessoryFit(model);stabilizePetTorso(model,fit);const original=new Map();model.traverse(mesh=>{if(mesh.isMesh&&mesh.geometry.index)original.set(mesh,Array.from(mesh.geometry.index.array));});
  for(const item of items){
   tuckCrownTuft(model,true);coverClosedFootwear(model,fit,{fitted_model_space:true,style:'sneakers'});coverSleeveSkin(model,item.appearance);
   let exposed=0;const coverage=item.appearance.sleeve_coverage[species];
   model.traverse(mesh=>{
    if(!mesh.userData.sleeveRestSamples)return;
    const shown=new Set(mesh.geometry.index.array);
    const covered=new Set(mesh.userData.sleeveRestSamples.filter(p=>p.y>=coverage.min_y&&p.y<=coverage.max_y).map(p=>p.i));
    const source=mesh.userData.sleeveSourceIndices;
    if(source){
     const remaining=new Set();for(let i=0;i<mesh.geometry.index.count;i+=3)remaining.add([0,1,2].map(k=>mesh.geometry.index.getX(i+k)).join(','));
     for(let i=0;i<source.count;i+=3){const face=[0,1,2].map(k=>source.getX(i+k)),allCovered=face.every(k=>covered.has(k));
      assert.equal(remaining.has(face.join(',')),!allCovered,species+': only wholly covered faces removed; cuff boundary remains sealed');}
    }
    for(const p of mesh.userData.sleeveRestSamples)if(p.y<coverage.min_y&&p.arm>.3&&shown.has(p.i))exposed++;
   });
   if(species!=='penguin')assert.ok(exposed>0,species+': hands remain visible');
   restoreSleeveCoverage(model);restoreFootwearCoverage(model);tuckCrownTuft(model,false);
   for(const [mesh,index] of original)assert.deepEqual(Array.from(mesh.geometry.index.array),index,species+': source restored');
  }
 }
});
