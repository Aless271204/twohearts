import test from 'node:test';
import assert from 'node:assert/strict';
import * as THREE from '../assets/runner/vendor/three.module.js';
import {loadPet,runtimeUrl} from './three-runtime.mjs';
const {createNaturalRest}=await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));
const {equipRunnerCosmetics}=await import(runtimeUrl('../assets/runner/cosmetics.js'));
const {registerAccessoryAsset}=await import(runtimeUrl('../assets/runner/accessory-pieces.js?revision=wardrobe-shared-1'));

for(const reversed of [false,true])test(`shoe and sleeve motion both update when shoes are equipped ${reversed?'before':'after'} the shirt`,async()=>{
 const {scene}=await loadPet('Meshy_AI_Pip_the_Penguin_All_Animations.glb');
 const bounds=new THREE.Box3().setFromObject(scene);scene.scale.multiplyScalar(1.15/bounds.getSize(new THREE.Vector3()).y);
 const scaled=new THREE.Box3().setFromObject(scene),center=scaled.getCenter(new THREE.Vector3());scene.position.sub(new THREE.Vector3(center.x,scaled.min.y,center.z));
 const model=new THREE.Group();model.add(scene);model.userData.species='penguin';
 const mixer=new THREE.AnimationMixer(model);mixer.clipAction(createNaturalRest(model)).play();mixer.update(0);model.updateMatrixWorld(true);
 const paths={pet_body:'sewn_shirt_love_penguin',pet_feet:'restart_shoes_heart_penguin'};
 const entries=[];
 for(const [slot,name] of Object.entries(paths)){
  const {scene:asset}=await loadPet('../accessories/'+name+'.glb');const path='assets/runner/accessories/'+name+'.glb';registerAccessoryAsset(path,asset);
  entries.push([slot,{style:slot==='pet_body'?'shirt_love':'shoes_heart',model_asset:path,fitted_model_space:true,skinned_model_space:true}]);
 }
 const group=equipRunnerCosmetics(model,Object.fromEntries(reversed?entries.reverse():entries));
 let foot,anchor;model.traverse(o=>{if(o.isBone&&o.name.endsWith('LeftFoot'))foot=o;if(o.name==='NidoLeftFootwear')anchor=o;});
 assert.ok(foot&&anchor);const before=anchor.matrix.clone();foot.position.x+=.030;model.updateMatrixWorld(true);group.userData.updateSleeves();
 assert.ok(!anchor.matrix.equals(before),'footwear updater must survive sleeve attachment');
});
