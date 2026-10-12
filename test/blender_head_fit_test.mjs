import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync,existsSync} from 'node:fs';
import {createHash} from 'node:crypto';
import * as THREE from '../assets/runner/vendor/three.module.js';
import {loadPet,runtimeUrl} from './three-runtime.mjs';
const {GLTFLoader}=await import(runtimeUrl('../assets/runner/vendor/loaders/GLTFLoader.js'));
const {registerAccessoryAsset}=await import(runtimeUrl('../assets/runner/accessory-pieces.js'));
const {equipRunnerCosmetics}=await import(runtimeUrl('../assets/runner/cosmetics.js'));
const {createNaturalRest}=await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));
const {refinePip}=await import(runtimeUrl('../assets/runner/pip-delicate.js'));
const catalog=JSON.parse(readFileSync(new URL('../assets/runner/blender-head-models.json',import.meta.url),'utf8'));
const speciesFiles={penguin:'Meshy_AI_Pip_the_Penguin_All_Animations.glb',bear:'bear.glb',pig:'pig.glb',chick:'chick.glb'};

async function geometryOnly(path){
 const bytes=readFileSync(new URL('../'+path,import.meta.url)),length=bytes.readUInt32LE(12),json=JSON.parse(bytes.subarray(20,20+length));
 const doc=structuredClone(json);delete doc.images;delete doc.textures;delete doc.materials;
 for(const mesh of doc.meshes)for(const primitive of mesh.primitives)delete primitive.material;
 const chunk=Buffer.from(JSON.stringify(doc)),padded=Buffer.alloc(Math.ceil(chunk.length/4)*4,32);chunk.copy(padded);
 const bin=bytes.subarray(20+length),output=Buffer.alloc(20+padded.length+bin.length);
 output.writeUInt32LE(0x46546c67,0);output.writeUInt32LE(2,4);output.writeUInt32LE(output.length,8);output.writeUInt32LE(padded.length,12);output.writeUInt32LE(0x4e4f534a,16);padded.copy(output,20);bin.copy(output,20+padded.length);
 return {gltf:await new GLTFLoader().parseAsync(output.buffer.slice(output.byteOffset,output.byteOffset+output.length),''),bytes,json};
}

test('sixteen active Blender garments retain provenance, UVs and texture files',async()=>{
 assert.deepEqual(catalog.filter(item=>item.visible!==false).map(item=>item.item_key).sort(),['beanie_cloud','beret_chic','cap_pink','hat_garden']);
 for(const item of catalog){
  assert.deepEqual(Object.keys(item.appearance.species_models).sort(),Object.keys(speciesFiles).sort());
  assert.equal(item.appearance.fitted_model_space,true);
  for(const variant of item.blender_variants){
   const {bytes,json,gltf}=await geometryOnly(variant.path);
   assert.equal(createHash('sha256').update(bytes).digest('hex'),variant.sha256);
   assert.ok(variant.triangles>2500&&variant.triangles<22000);
   assert.ok(json.images.length>=2);
   for(const material of json.materials){assert.ok(material.pbrMetallicRoughness.baseColorTexture);assert.ok(material.normalTexture);assert.equal(material.pbrMetallicRoughness.metallicFactor,0);}
   for(const image of json.images){assert.ok(image.uri&&!image.uri.includes('..'));assert.ok(existsSync(new URL('../assets/runner/accessories/'+image.uri,import.meta.url)));}
   gltf.scene.traverse(o=>{if(!o.isMesh)return;for(const name of ['position','normal','uv'])assert.ok(o.geometry.attributes[name]);for(const attribute of Object.values(o.geometry.attributes))assert.ok([...attribute.array].every(Number.isFinite));});
  }
 }
});

test('species-specific meshes keep authored dimensions and follow the head during running and jumps',async()=>{
 for(const [species,file] of Object.entries(speciesFiles)){
  const {scene,animations}=await loadPet(file);scene.scale.multiplyScalar(1.15/new THREE.Box3().setFromObject(scene).getSize(new THREE.Vector3()).y);
  const bounds=new THREE.Box3().setFromObject(scene),center=bounds.getCenter(new THREE.Vector3());scene.position.sub(new THREE.Vector3(center.x,bounds.min.y,center.z));
  const model=new THREE.Group();model.add(scene);model.userData.species=species;const mixer=new THREE.AnimationMixer(model),rest=mixer.clipAction(createNaturalRest(model));rest.play();mixer.update(0);if(species==='penguin')refinePip(model);
  const sourceIndices=new Map();model.traverse(o=>{if(o.isSkinnedMesh)sourceIndices.set(o,Array.from(o.geometry.index.array));});
  for(const item of catalog){
   mixer.stopAllAction();rest.reset().play();mixer.update(0);
   const path=item.appearance.species_models[species],{gltf}=await geometryOnly(path);registerAccessoryAsset(path,gltf.scene);
   const authored=new THREE.Box3().setFromObject(gltf.scene,true),equipment=equipRunnerCosmetics(model,{pet_head:item.appearance}),part=equipment.userData.slots[0];model.updateMatrixWorld(true);
   assert.ok(part.parent.isBone&&/Head$/.test(part.parent.name));assert.equal(part.userData.blenderTailored,true);
   const worn=new THREE.Box3().setFromObject(part,true);
   assert.ok(worn.min.distanceTo(authored.min)<1e-5&&worn.max.distanceTo(authored.max)<1e-5,'Blender shaping must not be resized or conformed twice');
   const attached=part.matrix.clone();
   for(const name of ['Running','Regular_Jump']){
    const clip=animations.find(a=>a.name===name);assert.ok(clip);mixer.stopAllAction();mixer.clipAction(clip).reset().play();
    for(let frame=0;frame<90;frame++){mixer.update(1/30);model.updateMatrixWorld(true);assert.deepEqual(part.matrix.elements,attached.elements);const b=new THREE.Box3().setFromObject(part,true);assert.ok([...b.min.toArray(),...b.max.toArray()].every(Number.isFinite));}
   }
   for(const growth of [.74,.88,1]){model.scale.setScalar(growth);model.updateMatrixWorld(true);assert.deepEqual(part.matrix.elements,attached.elements);}model.scale.setScalar(1);
  }
  equipRunnerCosmetics(model,{});
  for(const [mesh,indices] of sourceIndices)assert.deepEqual(Array.from(mesh.geometry.index.array),indices,'Removing a hat restores crown feathers');
 }
});
