import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {Group,Box3,Vector3,AnimationMixer} from '../assets/runner/vendor/three.module.js';
import {runtimeUrl,loadPet} from './three-runtime.mjs';
const {createNaturalRest}=await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));
const {equipRunnerCosmetics}=await import(runtimeUrl('../assets/runner/cosmetics.js'));
const {createPetMotion}=await import(runtimeUrl('../assets/runner/pet-motion.js'));
const {refinePip}=await import(runtimeUrl('../assets/runner/pip-delicate.js'));
const catalog=JSON.parse(readFileSync(new URL('../assets/runner/accessory-catalog.json',import.meta.url)));

test('Refined room penguin fits the scarf below its face and shoes around replacement feet',async()=>{
  const {scene}=await loadPet('Meshy_AI_Pip_the_Penguin_All_Animations.glb');
  scene.scale.multiplyScalar(1.15/new Box3().setFromObject(scene).getSize(new Vector3()).y);
  const bounds=new Box3().setFromObject(scene),center=bounds.getCenter(new Vector3());
  scene.position.sub(new Vector3(center.x,bounds.min.y,center.z));
  const model=new Group();model.add(scene);model.userData.species='penguin';
  const mixer=new AnimationMixer(model);mixer.clipAction(createNaturalRest(model)).play();mixer.update(0);refinePip(model);
  const group=equipRunnerCosmetics(model,{pet_neck:{style:'bandana',color:'#b8dccb'},pet_feet:{style:'sneakers',color:'#efa0ab'}});
  const neck=model.worldToLocal(group.userData.slots[0].getWorldPosition(new Vector3()));
  assert.ok(neck.y<.51&&neck.y>.43,'Collar must sit at the torso, below the lower face');
  for(const part of group.userData.slots.slice(1)){
    const shoe=new Box3().setFromObject(part);
    const foot=new Box3().setFromObject(model.getObjectByName(part.parent.name.includes('Left')?'LeftRoundedFoot':'RightRoundedFoot'));
    assert.ok(shoe.min.x<=foot.min.x&&shoe.max.x>=foot.max.x,'Shoe must cover replacement toes');
    assert.ok(shoe.min.z<=foot.min.z&&shoe.max.z>=foot.max.z,'Shoe depth must cover the actual foot');
  }
});

test('25 accessories attach to all four actual skeletons, follow animation and preserve growth',async()=>{
  assert.equal(catalog.length,25);
  for(const [species,file] of Object.entries({penguin:'Meshy_AI_Pip_the_Penguin_All_Animations.glb',bear:'bear.glb',pig:'pig.glb',chick:'chick.glb'})){
    const {scene,animations}=await loadPet(file);
    const size=new Box3().setFromObject(scene).getSize(new Vector3());scene.scale.multiplyScalar(1.15/size.y);
    const bounds=new Box3().setFromObject(scene),center=bounds.getCenter(new Vector3());scene.position.sub(new Vector3(center.x,bounds.min.y,center.z));
    const model=new Group();model.add(scene);model.userData.species=species;
    const rest=createNaturalRest(model),mixer=new AnimationMixer(model);mixer.clipAction(rest).play();mixer.update(0);
    for(const item of catalog){
      const group=equipRunnerCosmetics(model,{[item.equip_slot]:item.appearance});
      assert.equal(group.userData.slots.length,item.equip_slot==='pet_feet'?2:1,`${species}:${item.item_key}`);
      for(const part of group.userData.slots){
        assert.ok(part.parent.isBone,`${species}:${item.item_key} must follow skeleton`);
        const local=part.matrix.clone();
        for(const scale of [.74,.88,1]){
          model.scale.setScalar(scale);model.updateMatrixWorld(true);
          const b=new Box3().setFromObject(part);assert.ok([b.min.x,b.max.x,b.min.y,b.max.y,b.min.z,b.max.z].every(Number.isFinite));
          assert.ok(b.getSize(new Vector3()).length()<3,`${species}:${item.item_key} oversized`);
        }
        assert.deepEqual(part.matrix.elements,local.elements,'Growth must not alter attachment transform');
      }
      model.scale.setScalar(1);
    }
    equipRunnerCosmetics(model,Object.fromEntries(catalog.filter((_,i)=>i%5===0).map(item=>[item.equip_slot,item.appearance])));
    const run=animations.find(c=>c.name==='Running');
    if(run){mixer.stopAllAction();mixer.clipAction(run).play();for(let i=0;i<90;i++){mixer.update(1/30);model.updateMatrixWorld(true);for(const part of model.userData.cosmetics.userData.slots)assert.ok(part.getWorldPosition(new Vector3()).toArray().every(Number.isFinite));}}
  }
});

test('Breathing and cuddles do not move root or feet and reaction settles',async()=>{
  const {scene}=await loadPet('Meshy_AI_Pip_the_Penguin_All_Animations.glb');
  const model=new Group();model.add(scene);const mixer=new AnimationMixer(model);mixer.clipAction(createNaturalRest(model)).play();mixer.update(0);
  let foot;model.traverse(o=>{if(o.isBone&&/LeftFoot$/.test(o.name))foot=o;});
  const sole=foot.getWorldPosition(new Vector3()),root=model.position.clone(),motion=createPetMotion(model);
  motion.stroke();let maximum=0;
  for(let i=0;i<150;i++){mixer.update(1/30);motion.update(1/30);model.updateMatrixWorld(true);maximum=Math.max(maximum,model.userData.affection);assert.ok(foot.getWorldPosition(new Vector3()).distanceTo(sole)<1e-6);assert.deepEqual(model.position,root);}
  assert.ok(maximum>.9);assert.equal(model.userData.affection,0);assert.ok(Math.abs(model.userData.breathing)<=.007);
});
