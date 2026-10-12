import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {runtimeUrl,loadPet} from './three-runtime.mjs';
import {Box3,Vector3,Group,AnimationMixer} from '../assets/runner/vendor/three.module.js';
const {GLTFLoader}=await import(runtimeUrl('../assets/runner/vendor/loaders/GLTFLoader.js'));
const {normalizeHeadAsset,registerAccessoryAsset}=await import(runtimeUrl('../assets/runner/accessory-pieces.js'));
const {cutHeadEarOpenings,equipRunnerCosmetics}=await import(runtimeUrl('../assets/runner/cosmetics.js'));
const {createNaturalRest}=await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));
const {refinePip}=await import(runtimeUrl('../assets/runner/pip-delicate.js'));
const {softenAccessoryGeometry}=await import(runtimeUrl('../assets/runner/accessory-subdivision.js'));
const catalog=JSON.parse(readFileSync(new URL('../assets/runner/head-models.json',import.meta.url),'utf8'));
test('five original Meshy models retain hashes, stable identifiers and embedded textures',()=>{
 assert.equal(catalog.length,5);assert.equal(new Set(catalog.map(i=>i.item_key)).size,5);
 for(const item of catalog){const bytes=readFileSync(new URL('../'+item.appearance.model_asset,import.meta.url));assert.equal(createHash('sha256').update(bytes).digest('hex'),item.sha256);const json=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)));assert.equal(json.images.length,3);assert.ok(item.triangles<5000);assert.equal(item.fit_status,'pending_visual_review');assert.equal(item.preview_only,true);}
});

test('fitted cap lowers the crown, shortens the visor and retains its original provenance',()=>{
 const item=catalog.find(i=>i.item_key==='cap_pink');
 const source=readFileSync(new URL('../assets/runner/accessories/cap_pink_meshy.glb',import.meta.url));
 const fitted=readFileSync(new URL('../assets/runner/accessories/cap_pink_fitted.glb',import.meta.url));
 assert.equal(createHash('sha256').update(source).digest('hex'),item.sha256);
 const parse=bytes=>JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)));
 const a=parse(source),b=parse(fitted),pa=a.accessors[a.meshes[0].primitives[0].attributes.POSITION],pb=b.accessors[b.meshes[0].primitives[0].attributes.POSITION];
 assert.ok((pb.max[1]-pb.min[1])/(pa.max[1]-pa.min[1])<.75);
 assert.ok((pb.max[2]-pb.min[2])/(pa.max[2]-pa.min[2])<.8);
 assert.deepEqual(a.images,b.images);assert.deepEqual(a.materials,b.materials);
 for(const species of ['penguin','bear','pig','chick']){
  const fit=item.appearance.head_fit[species];assert.ok(fit.offset.every(Number.isFinite));assert.ok(fit.rotation.every(Number.isFinite));assert.ok(fit.scale>.8&&fit.scale<1.2);
 }
});

test('ear openings interpolate surface and UVs without editing the pet or source geometry',async()=>{
 const {Group,Mesh,PlaneGeometry,MeshStandardMaterial}=await import('../assets/runner/vendor/three.module.js');
 const pet=new Group(),part=new Group(),geometry=new PlaneGeometry(1,1,12,12),saved=geometry.clone();
 const material=new MeshStandardMaterial(),mesh=new Mesh(geometry,material);part.add(mesh);pet.add(part);pet.updateMatrixWorld(true);
 assert.ok(cutHeadEarOpenings(part,pet,[{center:[0,0,0],radius:[.2,.2,.2]}])>0);
 assert.equal(mesh.material,material);assert.equal(mesh.geometry.attributes.uv.count,mesh.geometry.attributes.position.count);
 assert.ok([...mesh.geometry.attributes.position.array,...mesh.geometry.attributes.normal.array,...mesh.geometry.attributes.uv.array].every(Number.isFinite));
 assert.deepEqual(geometry.attributes.position.array,saved.attributes.position.array);
 assert.equal(pet.position.length(),0);
});
test('cloth subdivision welds geometry across texture seams without changing the source',async()=>{
 const {BoxGeometry}=await import('../assets/runner/vendor/three.module.js');
 const source=new BoxGeometry(),saved=source.attributes.position.array.slice(),result=softenAccessoryGeometry(source);
 assert.deepEqual(source.attributes.position.array,saved);
 assert.equal(result.index.count,source.index.count*4);
 assert.equal(result.attributes.position.count,result.attributes.uv.count);
 assert.ok([...result.attributes.position.array,...result.attributes.normal.array,...result.attributes.uv.array].every(Number.isFinite));
 const normals=result.attributes.normal;for(let i=0;i<normals.count;i++)assert.ok(Math.abs(new Vector3().fromBufferAttribute(normals,i).length()-1)<1e-5);
});
test('imported head geometry loads and uniform normalization preserves proportions',async()=>{
 for(const item of catalog){
  const original=readFileSync(new URL('../'+item.appearance.model_asset,import.meta.url)),length=original.readUInt32LE(12),document=JSON.parse(original.subarray(20,20+length));
  // Node geometry validation does not decode textures; real browser review does.
  delete document.images;delete document.textures;delete document.materials;
  for(const mesh of document.meshes)for(const primitive of mesh.primitives)delete primitive.material;
  const json=Buffer.from(JSON.stringify(document)),padded=Buffer.alloc(Math.ceil(json.length/4)*4,32);json.copy(padded);const binary=original.subarray(20+length),output=Buffer.alloc(20+padded.length+binary.length);
  output.writeUInt32LE(0x46546c67,0);output.writeUInt32LE(2,4);output.writeUInt32LE(output.length,8);output.writeUInt32LE(padded.length,12);output.writeUInt32LE(0x4e4f534a,16);padded.copy(output,20);binary.copy(output,20+padded.length);
  const {scene}=await new GLTFLoader().parseAsync(output.buffer.slice(output.byteOffset,output.byteOffset+output.length),'');
  registerAccessoryAsset(item.appearance.model_asset,scene.clone(true));
  const before=new Box3().setFromObject(scene,true).getSize(new Vector3()),root=normalizeHeadAsset(scene,item.appearance.style),after=new Box3().setFromObject(root,true).getSize(new Vector3());
  assert.ok(after.toArray().every(Number.isFinite));assert.ok(Math.abs(before.y/before.x-after.y/after.x)<1e-5);assert.ok(Math.abs(before.z/before.x-after.z/after.x)<1e-5);assert.ok(after.x>.5&&after.x<.8);
 }
});

test('all five original head meshes follow all four pets through running, jumping and growth',async()=>{
 for(const [species,file] of Object.entries({penguin:'Meshy_AI_Pip_the_Penguin_All_Animations.glb',bear:'bear.glb',pig:'pig.glb',chick:'chick.glb'})){
  const {scene,animations}=await loadPet(file);scene.scale.multiplyScalar(1.15/new Box3().setFromObject(scene).getSize(new Vector3()).y);
  const bounds=new Box3().setFromObject(scene),center=bounds.getCenter(new Vector3());scene.position.sub(new Vector3(center.x,bounds.min.y,center.z));
  const model=new Group();model.add(scene);model.userData.species=species;const mixer=new AnimationMixer(model),rest=mixer.clipAction(createNaturalRest(model));rest.play();mixer.update(0);if(species==='penguin')refinePip(model);
  for(const item of catalog){
   mixer.stopAllAction();rest.reset().play();mixer.update(0);
   const equipment=equipRunnerCosmetics(model,{pet_head:item.appearance}),part=equipment.userData.slots[0];
   assert.ok(part.parent.isBone&&/Head$/.test(part.parent.name));
   assert.equal(part.name,'normalized-head:'+item.appearance.style,'Equipment must use the imported mesh, not a procedural substitute');
   assert.ok(part.userData.headConformance,'Actual head contact must be fitted');
   assert.ok(part.userData.headConformance.maxMovement<=.04501,'Contact must remain bounded');
   if(item.item_key==='wig_pastel')assert.ok(part.getObjectByName('fitted-hair-inner-lining'));
   const attached=part.matrix.clone();
   for(const clipName of ['Running','Regular_Jump']){
    const clip=animations.find(a=>a.name===clipName);assert.ok(clip,`${species}: missing ${clipName}`);mixer.stopAllAction();mixer.clipAction(clip).reset().play();
    for(let frame=0;frame<60;frame++){mixer.update(1/30);model.updateMatrixWorld(true);const b=new Box3().setFromObject(part,true);assert.ok([...b.min.toArray(),...b.max.toArray()].every(Number.isFinite));assert.deepEqual(part.matrix.elements,attached.elements);}
   }
   for(const growth of [.74,.88,1]){model.scale.setScalar(growth);model.updateMatrixWorld(true);assert.deepEqual(part.matrix.elements,attached.elements);}
   model.scale.setScalar(1);
  }
 }
});
