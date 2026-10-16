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
const catalog=JSON.parse(readFileSync(new URL('../assets/runner/blender-wardrobe-models.json',import.meta.url),'utf8'));
const speciesFiles={penguin:'Meshy_AI_Pip_the_Penguin_All_Animations.glb',bear:'bear.glb',pig:'pig.glb',chick:'chick.glb'};
async function garment(path){
 const bytes=readFileSync(new URL('../'+path,import.meta.url)),length=bytes.readUInt32LE(12),json=JSON.parse(bytes.subarray(20,20+length)),doc=structuredClone(json);
 // Node has no browser image decoder. Validate the embedded texture references
 // below, and exercise the exact geometry/weights without material decoding.
 delete doc.images;delete doc.textures;delete doc.materials;
 for(const mesh of doc.meshes)for(const primitive of mesh.primitives)delete primitive.material;
 const chunk=Buffer.from(JSON.stringify(doc)),padded=Buffer.alloc(Math.ceil(chunk.length/4)*4,32);chunk.copy(padded);
 const bin=bytes.subarray(20+length),output=Buffer.alloc(20+padded.length+bin.length);
 output.writeUInt32LE(0x46546c67,0);output.writeUInt32LE(2,4);output.writeUInt32LE(output.length,8);output.writeUInt32LE(padded.length,12);output.writeUInt32LE(0x4e4f534a,16);padded.copy(output,20);bin.copy(output,20+padded.length);
 return {bytes,json,gltf:await new GLTFLoader().parseAsync(output.buffer.slice(output.byteOffset,output.byteOffset+output.length),'')};
}
test('nine editable patterns have four valid Blender variants, finite attributes and normalized weights',async()=>{
 assert.equal(catalog.length,9);
 for(const item of catalog){assert.equal(item.preview_only,true);assert.equal(item.variants.length,4);
  for(const v of item.variants){const {bytes,json,gltf}=await garment(v.path);assert.equal(createHash('sha256').update(bytes).digest('hex'),v.sha256);let triangles=0;
   assert.ok(item.fabric);assert.ok(json.images.length>=2);
   for(const image of json.images){assert.equal(image.mimeType,'image/png');if(image.uri){assert.match(image.uri,/^fabric_tex_[a-f0-9]{24}\.png$/);const png=readFileSync(new URL(image.uri,new URL('../'+v.path,import.meta.url)));assert.equal(png.subarray(0,8).toString('hex'),'89504e470d0a1a0a');assert.equal(createHash('sha256').update(png).digest('hex').slice(0,24),image.uri.slice(11,35));}else assert.ok(json.bufferViews[image.bufferView].byteLength>100);}
   for(const m of json.materials){assert.ok(m.pbrMetallicRoughness.baseColorTexture);assert.ok(m.normalTexture);assert.equal(m.pbrMetallicRoughness.metallicFactor,0);assert.ok(m.pbrMetallicRoughness.roughnessFactor>=.7-1e-6);}
   gltf.scene.traverse(m=>{if(!m.isMesh)return;triangles+=(m.geometry.index?.count??m.geometry.attributes.position.count)/3;
    for(const a of Object.values(m.geometry.attributes))assert.ok([...a.array].every(Number.isFinite));
    if(item.equip_slot==='pet_body'){
     assert.ok(m.userData.nidoBoneNames.length>10);const w=m.geometry.attributes.skinWeight,indices=m.geometry.attributes.skinIndex;assert.ok(w);
     assert.equal(m.userData.nidoSkinTransfer?.method,m.userData.nidoShoulderLining?'original_surface_lining':'closest_triangle_barycentric');
     if(!m.userData.nidoShoulderLining)assert.equal(m.userData.nidoSkinTransfer?.version,3);
     if(!m.userData.nidoShoulderLining)assert.equal(m.userData.nidoSkinTransfer?.source,/^(Patrón[ _]envolvente|Manga[ _]adaptada)/.test(m.name)?'pet_surface':'garment_surface');
     if(!m.userData.nidoShoulderLining)assert.equal(m.userData.nidoSkinTransfer?.stage,/^(Patrón[ _]envolvente|Manga[ _]adaptada)/.test(m.name)?'primary':/^(Panel[ _]·|Volante[ _]pétalo)/.test(m.name)?'secondary':'decoration');
     for(let i=0;i<w.count;i++){
      assert.ok(Math.abs(w.getX(i)+w.getY(i)+w.getZ(i)+w.getW(i)-1)<.002);
      for(let j=0;j<4;j++){
       assert.ok(w.getComponent(i,j)>=0);
       assert.ok(indices.getComponent(i,j)<m.userData.nidoBoneNames.length);
       if(w.getComponent(i,j)>1e-7)assert.ok(!/(UpLeg|Leg|Foot|ToeBase|Toe_End)$/.test(m.userData.nidoBoneNames[indices.getComponent(i,j)]),'Leg cannot pull fabric above the hem');
       if(w.getComponent(i,j)>1e-7)assert.ok(!/(Head|Neck)$/.test(m.userData.nidoBoneNames[indices.getComponent(i,j)]),'Head cannot pull a shirt into the face');
      }
     }
    }
   });assert.ok(triangles>500&&triangles<30000,`${v.path}: ${triangles}`);
  }
 }
});
test('body patterns bind to the real pet rig, retain resting geometry and deform during animations',async()=>{
 for(const [species,file] of Object.entries(speciesFiles)){
  const {scene,animations}=await loadPet(file);scene.scale.multiplyScalar(1.15/new THREE.Box3().setFromObject(scene).getSize(new THREE.Vector3()).y);
  const b=new THREE.Box3().setFromObject(scene),c=b.getCenter(new THREE.Vector3());scene.position.sub(new THREE.Vector3(c.x,b.min.y,c.z));
  const model=new THREE.Group();model.add(scene);model.userData.species=species;const mixer=new THREE.AnimationMixer(model),rest=mixer.clipAction(createNaturalRest(model));rest.play();mixer.update(0);if(species==='penguin')refinePip(model);
  stabilizePetTorso(model,measureAccessoryFit(model));
  const jump=createRunnerJump(model);
  for(const item of catalog.filter(i=>i.equip_slot==='pet_body')){
   mixer.stopAllAction();rest.reset().play();mixer.update(0);model.updateMatrixWorld(true);
   const {gltf}=await garment(item.appearance.species_models[species]);registerAccessoryAsset(item.appearance.species_models[species],gltf.scene);
   const expected=new THREE.Box3().setFromObject(gltf.scene,true);const equipment=equipRunnerCosmetics(model,{pet_body:item.appearance});model.updateMatrixWorld(true);
   const part=equipment.userData.slots[0],actual=new THREE.Box3().setFromObject(part,true);assert.ok(expected.min.distanceTo(actual.min)<1e-4&&expected.max.distanceTo(actual.max)<1e-4,'Rest pose must preserve Blender pattern');
   let skinned=0;part.traverse(m=>{if(m.isSkinnedMesh){skinned++;assert.ok(m.skeleton.bones.every(b=>b.isBone));}});assert.ok(skinned>0);
   for(const name of ['Running','Regular_Jump']){mixer.stopAllAction();mixer.clipAction(name==='Regular_Jump'?jump:animations.find(a=>a.name===name)).reset().play();for(let frame=0;frame<40;frame++){mixer.update(1/30);model.updateMatrixWorld(true);part.traverse(m=>{if(!m.isSkinnedMesh)return;m.skeleton.update();for(let i=0;i<m.geometry.attributes.position.count;i+=113){const p=new THREE.Vector3().fromBufferAttribute(m.geometry.attributes.position,i);m.applyBoneTransform(i,p);assert.ok(p.toArray().every(Number.isFinite));}});}}
  }
 }
});
