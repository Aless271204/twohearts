import test from 'node:test';
import assert from 'node:assert/strict';
import {loadPet,runtimeUrl} from './three-runtime.mjs';
import * as THREE from '../assets/runner/vendor/three.module.js';
const {createClothWrap}=await import(runtimeUrl('../assets/runner/pet-cloth-wrap.js'));
const {createNaturalRest}=await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));
const {createSleeveAnchors}=await import(runtimeUrl('../assets/runner/pet-sleeve-anchors.js'));

test('cloth cage preserves authored rest positions and original pet through running and jumping',async()=>{
 const pet=await loadPet('Meshy_AI_Pip_the_Penguin_All_Animations.glb');
 const initial=new THREE.Box3().setFromObject(pet.scene);pet.scene.scale.multiplyScalar(1.15/initial.getSize(new THREE.Vector3()).y);
 const bounds=new THREE.Box3().setFromObject(pet.scene),center=bounds.getCenter(new THREE.Vector3());pet.scene.position.sub(new THREE.Vector3(center.x,bounds.min.y,center.z));
 const model=new THREE.Group();model.add(pet.scene);const mixer=new THREE.AnimationMixer(model);mixer.clipAction(createNaturalRest(model)).play();mixer.update(0);model.updateMatrixWorld(true);
 const originals=[];pet.scene.traverse(m=>{if(m.isSkinnedMesh)originals.push([m,m.geometry.attributes.position.array.slice(),m.geometry.attributes.skinWeight.array.slice()]);});
 const cloth=await loadPet('../accessories/sewn_shirt_love_penguin_surface_experiment.glb');model.add(cloth.scene);const garments=[],authored=[];
 cloth.scene.traverse(m=>{if(m.isMesh){m.geometry=m.geometry.clone();m.userData.cosmetic=true;garments.push(m);authored.push(m.geometry.attributes.position.array.slice());}});
 const bones={};model.traverse(o=>{if(o.isBone)bones[o.name.replace(/^mixamorig:?/,'')]=o;});
 const anchors=createSleeveAnchors(model,garments[0].userData.nidoSleeveFit,cloth.scene);Object.assign(bones,anchors.bones);
 for(const m of garments){const joints=m.userData.nidoBoneNames.map(n=>bones[n.replace(/^mixamorig:?/,'')]);const skeleton=new THREE.Skeleton(joints,joints.map(j=>j.matrixWorld.clone().invert()));const proxy=new THREE.SkinnedMesh(m.geometry.clone(),m.material);m.updateWorldMatrix(true,false);proxy.bind(skeleton,m.matrixWorld.clone());m.userData.nidoWrapSkin=proxy;}
 const wrap=createClothWrap(model,garments);let maximum=0;
 garments.forEach((m,k)=>{const a=m.geometry.attributes.position.array;for(let i=0;i<a.length;i++)maximum=Math.max(maximum,Math.abs(a[i]-authored[k][i]));});
 assert.ok(maximum<.0001,'rest drift '+maximum);
 model.position.set(.2,.35,-.1);model.updateMatrixWorld(true);anchors.update();wrap.update();
 garments.forEach((m,k)=>{const a=m.geometry.attributes.position.array;for(let i=0;i<a.length;i++)assert.ok(Math.abs(a[i]-authored[k][i])<.0001,'parent motion must not distort the cloth');});
 model.position.set(0,0,0);model.updateMatrixWorld(true);
 for(const name of ['Running','Regular_Jump'])for(const phase of [0,.25,.5,.75]){
  mixer.stopAllAction();const clip=pet.animations.find(c=>c.name===name),action=mixer.clipAction(clip);action.reset().play();mixer.setTime(clip.duration*phase);anchors.update();wrap.update();
  for(const m of garments)for(const value of m.geometry.attributes.position.array)assert.ok(Number.isFinite(value)&&Math.abs(value)<5);
 }
 for(const [m,positions,weights] of originals){assert.deepEqual(m.geometry.attributes.position.array,positions);assert.deepEqual(m.geometry.attributes.skinWeight.array,weights);}
});
