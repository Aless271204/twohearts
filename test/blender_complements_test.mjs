import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import * as THREE from '../assets/runner/vendor/three.module.js';
import {loadPet,runtimeUrl} from './three-runtime.mjs';
const {GLTFLoader}=await import(runtimeUrl('../assets/runner/vendor/loaders/GLTFLoader.js'));
const {registerAccessoryAsset}=await import(runtimeUrl('../assets/runner/accessory-pieces.js'));
const {equipRunnerCosmetics}=await import(runtimeUrl('../assets/runner/cosmetics.js'));
const {createNaturalRest}=await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));
const {refinePip}=await import(runtimeUrl('../assets/runner/pip-delicate.js'));
const {stabilizePetTorso}=await import(runtimeUrl('../assets/runner/pet-garment-rig.js'));
const {measureAccessoryFit}=await import(runtimeUrl('../assets/runner/cosmetics.js'));
const {createRunnerJump}=await import(runtimeUrl('../assets/runner/pet-runner-jump.js'));
const catalog=JSON.parse(readFileSync(new URL('../assets/runner/blender-complement-models.json',import.meta.url)));
async function load(path){
 const bytes=readFileSync(new URL('../'+path,import.meta.url)),length=bytes.readUInt32LE(12),doc=JSON.parse(bytes.subarray(20,20+length));
 const original=structuredClone(doc);delete doc.images;delete doc.textures;delete doc.materials;
 for(const m of doc.meshes)for(const p of m.primitives)delete p.material;
 const json=Buffer.from(JSON.stringify(doc)),padded=Buffer.alloc(Math.ceil(json.length/4)*4,32);json.copy(padded);
 const bin=bytes.subarray(20+length),output=Buffer.alloc(20+padded.length+bin.length);
 output.writeUInt32LE(0x46546c67,0);output.writeUInt32LE(2,4);output.writeUInt32LE(output.length,8);output.writeUInt32LE(padded.length,12);output.writeUInt32LE(0x4e4f534a,16);padded.copy(output,20);bin.copy(output,20+padded.length);
 return {bytes,doc:original,gltf:await new GLTFLoader().parseAsync(output.buffer.slice(output.byteOffset,output.byteOffset+output.length),'')};
}
const pets={penguin:'Meshy_AI_Pip_the_Penguin_All_Animations.glb',bear:'bear.glb',pig:'pig.glb',chick:'chick.glb'};
test('all fifteen complements have four real variants with intact materials and foot attachments',async()=>{
 assert.equal(catalog.length,15);
 for(const item of catalog){assert.deepEqual(Object.keys(item.appearance.species_models).sort(),Object.keys(pets).sort());
  for(const variant of item.variants){const {bytes,doc,gltf}=await load(variant.path);assert.equal(createHash('sha256').update(bytes).digest('hex'),variant.sha256);let triangles=0,feet=new Set();
   assert.ok(doc.materials.length);
   for(const image of doc.images??[]){
    assert.equal(image.mimeType,'image/png');
    if(image.uri){
     assert.match(image.uri,/^fabric_tex_[a-f0-9]{24}\.png$/);
     const png=readFileSync(new URL(image.uri,new URL('../'+variant.path,import.meta.url)));
     assert.equal(png.subarray(0,8).toString('hex'),'89504e470d0a1a0a');
     assert.equal(createHash('sha256').update(png).digest('hex').slice(0,24),image.uri.slice(11,35));
    }else assert.ok(doc.bufferViews[image.bufferView].byteLength>100);
   }
   gltf.scene.traverse(mesh=>{if(!mesh.isMesh)return;triangles+=(mesh.geometry.index?.count??mesh.geometry.attributes.position.count)/3;
    for(const a of Object.values(mesh.geometry.attributes))assert.ok([...a.array].every(Number.isFinite));
    if(item.equip_slot!=='pet_eyes'){
     const w=mesh.geometry.attributes.skinWeight,j=mesh.geometry.attributes.skinIndex;assert.ok(w&&j);
     for(let i=0;i<w.count;i++){let sum=0;for(let k=0;k<4;k++){const weight=w.getComponent(i,k);sum+=weight;assert.ok(weight>=0);assert.ok(j.getComponent(i,k)<mesh.userData.nidoBoneNames.length);}assert.ok(Math.abs(sum-1)<.002);}
     if(item.equip_slot==='pet_feet'){
      assert.equal(mesh.userData.nidoSkinTransfer.method,'rigid_named_foot');
      feet.add(mesh.userData.nidoSkinTransfer.bone.replace(/^mixamorig:?/,''));
      for(let i=0;i<w.count;i++)assert.equal(w.getX(i),1);
     }
    }
   });assert.ok(triangles>100&&triangles<30000,`${variant.path}: ${triangles}`);
   if(item.equip_slot==='pet_feet')assert.deepEqual([...feet].sort(),['LeftFoot','RightFoot']);
  }
 }
});
test('each complement retains its fitted rest shape and follows the actual pets during running and jumping',async()=>{
 for(const [species,file] of Object.entries(pets)){
  const {scene,animations}=await loadPet(file);scene.scale.multiplyScalar(1.15/new THREE.Box3().setFromObject(scene).getSize(new THREE.Vector3()).y);
  const bounds=new THREE.Box3().setFromObject(scene),center=bounds.getCenter(new THREE.Vector3());scene.position.sub(new THREE.Vector3(center.x,bounds.min.y,center.z));
  const model=new THREE.Group();model.add(scene);model.userData.species=species;const mixer=new THREE.AnimationMixer(model),rest=mixer.clipAction(createNaturalRest(model));rest.play();mixer.update(0);if(species==='penguin')refinePip(model);
  stabilizePetTorso(model,measureAccessoryFit(model));
  const jump=createRunnerJump(model);
  for(const item of catalog){mixer.stopAllAction();rest.reset().play();mixer.update(0);model.updateMatrixWorld(true);
   const path=item.appearance.species_models[species],{gltf}=await load(path);registerAccessoryAsset(path,gltf.scene);
   const expected=new THREE.Box3().setFromObject(gltf.scene,true),equipment=equipRunnerCosmetics(model,{[item.equip_slot]:item.appearance});model.updateMatrixWorld(true);
   const part=equipment.userData.slots[0],actual=new THREE.Box3().setFromObject(part,true);
   assert.ok(expected.min.distanceTo(actual.min)<1e-4&&expected.max.distanceTo(actual.max)<1e-4,path);
   const skeletons=new Set();part.traverse(m=>{if(m.isSkinnedMesh)skeletons.add(m.skeleton)});assert.ok(skeletons.size<=1,'One shared skeleton per item');
   for(const name of ['Running','Regular_Jump']){mixer.stopAllAction();mixer.clipAction(name==='Regular_Jump'?jump:animations.find(a=>a.name===name)).reset().play();for(let frame=0;frame<16;frame++){mixer.update(1/24);model.updateMatrixWorld(true);part.traverse(m=>{if(!m.isMesh)return;if(m.isSkinnedMesh)m.skeleton.update();for(let i=0;i<m.geometry.attributes.position.count;i+=71){const p=new THREE.Vector3().fromBufferAttribute(m.geometry.attributes.position,i);if(m.isSkinnedMesh)m.applyBoneTransform(i,p);m.localToWorld(p);assert.ok(p.toArray().every(Number.isFinite));}});}}
  }
 }
});
