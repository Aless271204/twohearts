import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import * as THREE from '../assets/runner/vendor/three.module.js';
import {runtimeUrl,loadPet} from './three-runtime.mjs';
const {registerAccessoryAsset,equipRunnerCosmetics}=await import(runtimeUrl('../assets/runner/cosmetics.js',{preserveModuleIdentity:true}));
const {createNaturalRest}=await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));
const profiles=JSON.parse(readFileSync(new URL('../design/blender/head-tailoring.json',import.meta.url))).pets;
const appearance=JSON.parse(readFileSync(new URL('../assets/runner/accessory-catalog.json',import.meta.url))).find(i=>i.item_key==='beret_chic').appearance;

test('small folded berets remain inside skull width and follow the original head through run and jump',async()=>{
  for(const [species,file] of Object.entries({penguin:'Meshy_AI_Pip_the_Penguin_All_Animations.glb',bear:'bear.glb',pig:'pig.glb',chick:'chick.glb'})){
    const source=appearance.species_models[species];
    const hat=await loadPet(source.replace('assets/runner/','../'));
    const b=new THREE.Box3().setFromObject(hat.scene,true),p=profiles[species];
    assert.ok(b.getSize(new THREE.Vector3()).x<2*p.skull_radius[0]*.82,`${species}: crown must remain narrower than skull`);
    assert.ok(b.min.x>p.skull_center[0]-p.skull_radius[0] && b.max.x<p.skull_center[0]+p.skull_radius[0]);
    assert.ok(b.getSize(new THREE.Vector3()).y>.09,`${species}: crown retains textile relief`);
    const pet=await loadPet(file),scene=pet.scene;
    scene.scale.multiplyScalar(1.15/new THREE.Box3().setFromObject(scene).getSize(new THREE.Vector3()).y);
    const bounds=new THREE.Box3().setFromObject(scene),center=bounds.getCenter(new THREE.Vector3());
    scene.position.sub(new THREE.Vector3(center.x,bounds.min.y,center.z));
    const model=new THREE.Group();model.add(scene);model.userData.species=species;
    const mixer=new THREE.AnimationMixer(model);mixer.clipAction(createNaturalRest(model)).play();mixer.update(0);model.updateMatrixWorld(true);
    registerAccessoryAsset(source,hat.scene);
    const equipment=equipRunnerCosmetics(model,{pet_head:{...appearance,model_asset:source,species_models:{[species]:source}}});
    const part=equipment.userData.slots[0];assert.ok(part.parent.isBone&&/Head$/.test(part.parent.name));
    const attached=part.matrix.clone();
    for(const name of ['Running','Regular_Jump']){
      mixer.stopAllAction();mixer.clipAction(pet.animations.find(a=>a.name===name)).reset().play();
      for(let frame=0;frame<45;frame++){
        mixer.update(1/30);model.updateMatrixWorld(true);
        assert.deepEqual(part.matrix.elements,attached.elements);
        const box=new THREE.Box3().setFromObject(part,true);
        assert.ok([...box.min.toArray(),...box.max.toArray()].every(Number.isFinite));
      }
    }
  }
});
