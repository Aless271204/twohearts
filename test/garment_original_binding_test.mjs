import test from 'node:test';import assert from 'node:assert/strict';
import * as THREE from '../assets/runner/vendor/three.module.js';
import {loadPet,runtimeUrl} from './three-runtime.mjs';
const {bindGarmentToOriginalSkin}=await import(runtimeUrl('../assets/runner/pet-garment-binding.js'));
const {createNaturalRest}=await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));
for(const [sp,file] of Object.entries({penguin:'Meshy_AI_Pip_the_Penguin_All_Animations.glb',bear:'bear.glb',pig:'pig.glb',chick:'chick.glb'}))test(sp+': garment points follow the actual source skin, including mixed shoulder weights',async()=>{
 const {scene,animations}=await loadPet(file);const initial=new THREE.Box3().setFromObject(scene);scene.scale.multiplyScalar(1.15/initial.getSize(new THREE.Vector3()).y);const box=new THREE.Box3().setFromObject(scene),center=box.getCenter(new THREE.Vector3());scene.position.sub(new THREE.Vector3(center.x,box.min.y,center.z));
 const model=new THREE.Group();model.add(scene);const mixer=new THREE.AnimationMixer(model);mixer.clipAction(createNaturalRest(model)).play();mixer.update(0);model.updateMatrixWorld(true);
 let source;scene.traverse(m=>{if(m.isSkinnedMesh)source=m;});source.skeleton.update();
 const ids=[];for(let i=0;i<source.geometry.attributes.position.count;i+=11)ids.push(i);
 const positions=[],indices=[],weights=[],p=new THREE.Vector3();
 for(const i of ids){p.fromBufferAttribute(source.geometry.attributes.position,i);source.applyBoneTransform(i,p);source.localToWorld(p);model.worldToLocal(p);positions.push(...p.toArray());for(let k=0;k<4;k++){indices.push(source.geometry.attributes.skinIndex.getComponent(i,k));weights.push(source.geometry.attributes.skinWeight.getComponent(i,k));}}
 const g=new THREE.BufferGeometry();g.setAttribute('position',new THREE.Float32BufferAttribute(positions,3));g.setAttribute('skinIndex',new THREE.Uint16BufferAttribute(indices,4));g.setAttribute('skinWeight',new THREE.Float32BufferAttribute(weights,4));
 const mesh=new THREE.Mesh(g,new THREE.MeshBasicMaterial());mesh.userData.nidoBoneNames=source.skeleton.bones.map(b=>b.name);model.add(mesh);
 const garment=bindGarmentToOriginalSkin(mesh,source);
 for(const motion of ['Natural_Rest','Running','Regular_Jump'])for(const phase of [0,.2,.5,.8]){
  mixer.stopAllAction();const clip=motion==='Natural_Rest'?createNaturalRest(model):animations.find(c=>c.name===motion);mixer.clipAction(clip).reset().play();mixer.setTime(clip.duration*phase);model.updateMatrixWorld(true);source.skeleton.update();garment.skeleton.update();
  let max=0;
  for(let j=0;j<ids.length;j++){
   const a=new THREE.Vector3().fromBufferAttribute(source.geometry.attributes.position,ids[j]);source.applyBoneTransform(ids[j],a);source.localToWorld(a);
   const b=new THREE.Vector3().fromBufferAttribute(garment.geometry.attributes.position,j);garment.applyBoneTransform(j,b);garment.localToWorld(b);max=Math.max(max,a.distanceTo(b));
  }
  assert.ok(max<1e-5,`${motion} ${phase}: detached by ${max}`);
 }
});
