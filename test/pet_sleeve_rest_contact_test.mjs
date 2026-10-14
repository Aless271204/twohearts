import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {loadPet,runtimeUrl} from './three-runtime.mjs';
import * as THREE from '../assets/runner/vendor/three.module.js';
const {createNaturalRest}=await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));
const {createSleeveAnchors}=await import(runtimeUrl('../assets/runner/pet-sleeve-anchors.js'));
for(const [species,file] of Object.entries({penguin:'Meshy_AI_Pip_the_Penguin_All_Animations.glb',bear:'bear.glb',pig:'pig.glb',chick:'chick.glb'})){
 test(species+': tailored sleeves preserve their authored contact in the actual original resting pose',async()=>{
  const {scene}=await loadPet(file);
  const initial=new THREE.Box3().setFromObject(scene);scene.scale.multiplyScalar(1.15/initial.getSize(new THREE.Vector3()).y);
  const bounds=new THREE.Box3().setFromObject(scene),center=bounds.getCenter(new THREE.Vector3());scene.position.sub(new THREE.Vector3(center.x,bounds.min.y,center.z));
  const model=new THREE.Group();model.add(scene);model.userData.species=species;
  const mixer=new THREE.AnimationMixer(model);mixer.clipAction(createNaturalRest(model)).play();mixer.update(0);model.updateMatrixWorld(true);
  const fitting=JSON.parse(readFileSync(new URL('../design/wardrobe-restart/fitting/'+species+'-original.json',import.meta.url)));
  model.userData.accessoryFit={head:new THREE.Box3(new THREE.Vector3().fromArray(fitting.head.min),new THREE.Vector3().fromArray(fitting.head.max))};
  const catalog=JSON.parse(readFileSync(new URL('../assets/runner/restart/catalog.json',import.meta.url)));
  const garment=catalog.wardrobe.find(item=>item.item_key==='shirt_love').variants.find(v=>v.species===species);
  const bytes=readFileSync(new URL('../'+garment.original_asset,import.meta.url));
  const doc=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)));
  const profiles=doc.meshes.find(m=>m.extras?.nidoSleeveFit)?.extras.nidoSleeveFit;
  assert.ok(profiles,'exercise the metadata exported by Blender');
  const originalBones=[];scene.traverse(o=>{if(o.isBone)originalBones.push([o,o.position.clone(),o.quaternion.clone(),o.scale.clone()]);});
  const clothing=new THREE.Group();model.add(clothing);
  const anchors=createSleeveAnchors(model,profiles,clothing);anchors.update();
  for(const bone of Object.values(anchors.bones)){
   assert.ok(bone.position.length()<1e-5,'do not push a fitted sleeve away at rest');
   assert.ok(bone.quaternion.angleTo(new THREE.Quaternion())<1e-5,'do not rotate the authored sleeve at rest');
   assert.ok(bone.scale.distanceTo(new THREE.Vector3(1,1,1))<1e-8);
  }
  for(const [bone,p,q,s] of originalBones){assert.ok(bone.position.equals(p));assert.ok(bone.quaternion.equals(q));assert.ok(bone.scale.equals(s));}
 });
}
