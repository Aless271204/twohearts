import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import * as THREE from '../assets/runner/vendor/three.module.js';
import {loadPet} from './three-runtime.mjs';

// A reversed top face disappeared behind the real toes of open sandals.
// Exercise front-face ray visibility on each exported sole, not just bounds.
for(const species of ['penguin','bear','pig','chick'])for(const item of ['boots_rain','slippers_cloud','shoes_chic','sandals_summer']){
 test(`${species} ${item}: both sole tops face outwards and remain visible`,async()=>{
  const fitting=JSON.parse(readFileSync(new URL(`../design/wardrobe-restart/fitting/${species}-original.json`,import.meta.url)));
  const {scene}=await loadPet(`../accessories/restart_${item}_${species}.glb`);scene.updateMatrixWorld(true);
  for(const side of ['Left','Right']){
   const mesh=[];scene.traverse(o=>{if(o.isMesh&&o.name.includes(side))mesh.push(o);});
   const f=fitting.feet[side],x=(f.min[0]+f.max[0])/2,z=(f.min[2]+f.max[2])/2;
   const top=item==='sandals_summer'?.033:.031;
   const ray=new THREE.Raycaster(new THREE.Vector3(x,.5,z),new THREE.Vector3(0,-1,0));
   const hits=ray.intersectObjects(mesh,false);
   assert.ok(hits.some(h=>Math.abs(h.point.y-top)<1e-5&&h.face.normal.y>.1),`${side} sole top must be visible from above`);
  }
 });
}
