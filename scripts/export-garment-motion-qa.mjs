// Capture posed geometry from the actual app equipment functions, not a new rig.
import fs from 'node:fs';import path from 'node:path';
import * as THREE from '../assets/runner/vendor/three.module.js';
import {loadPet,runtimeUrl} from '../test/three-runtime.mjs';
const {registerAccessoryAsset}=await import(runtimeUrl('../assets/runner/accessory-pieces.js'));
const {equipRunnerCosmetics}=await import(runtimeUrl('../assets/runner/cosmetics.js'));
const {createNaturalRest}=await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));
const {createWardrobeRun,createWardrobeJump}=await import(runtimeUrl('../assets/runner/pet-wardrobe-jump.js'));
const args=Object.fromEntries(process.argv.slice(2).map(a=>a.split('=')));
const outfit=args.outfit??'dulce',motion=args.motion??'Running',phase=+(args.phase??'.25');
const catalog=JSON.parse(fs.readFileSync('assets/runner/accessory-catalog.json','utf8'));
const outfits=JSON.parse(fs.readFileSync('design/approved-outfits.json','utf8'));
const result={outfit,motion,phase,actors:[]};
async function load(source){
 const raw=fs.readFileSync(source),doc=JSON.parse(raw.subarray(20,20+raw.readUInt32LE(12)));
 const asset=await loadPet(source.replace('assets/runner/play-models/','').replace('assets/runner/accessories/','../accessories/'));
 const materials=new Map();
 asset.scene.traverse(mesh=>{if(!mesh.isMesh)return;const association=asset.parser.associations.get(mesh),primitive=doc.meshes[association.meshes].primitives[association.primitives??0],id=primitive.material??0;
  if(!materials.has(id))materials.set(id,new THREE.MeshBasicMaterial());mesh.material=materials.get(id);mesh.userData.qaSource=source;mesh.userData.qaMaterial=id;
 });return asset;
}
for(const [species,file] of Object.entries({penguin:'Meshy_AI_Pip_the_Penguin_All_Animations.glb',bear:'bear.glb',pig:'pig.glb',chick:'chick.glb'})){
 const pet=await load('assets/runner/play-models/'+file);let bounds=new THREE.Box3().setFromObject(pet.scene);pet.scene.scale.multiplyScalar(1.15/bounds.getSize(new THREE.Vector3()).y);bounds=new THREE.Box3().setFromObject(pet.scene);const center=bounds.getCenter(new THREE.Vector3());pet.scene.position.sub(new THREE.Vector3(center.x,bounds.min.y,center.z));
 const model=new THREE.Group();model.add(pet.scene);model.userData.species=species;const mixer=new THREE.AnimationMixer(model);const rest=createNaturalRest(model);mixer.clipAction(rest).play();mixer.update(0);model.updateMatrixWorld(true);
 const loadout={};
 for(const key of outfits.outfits.find(o=>o.key===outfit).items){const item=catalog.find(i=>i.item_key===key&&i.visible!==false);if(!item)continue;const a=structuredClone(item.appearance),source=a.species_models[species];const asset=await load(source);registerAccessoryAsset(source,asset.scene);
  if(a.coverage_assets?.[species])a.covered_skin_triangles=JSON.parse(fs.readFileSync(a.coverage_assets[species]));
  if(a.headwear_occlusions?.[species])a.headwear_occlusion=a.headwear_occlusions[species];loadout[item.equip_slot]=a;
 }
 const equipment=equipRunnerCosmetics(model,loadout);
 const run=createWardrobeRun(model,pet.animations.find(a=>a.name==='Running')),jump=createWardrobeJump(model,pet.animations.find(a=>a.name==='Regular_Jump'));
 mixer.stopAllAction();const clip=motion==='Rest'?rest:motion==='Wardrobe_Run'?run:motion==='Natural_Jump'?jump:pet.animations.find(a=>a.name===motion);mixer.clipAction(clip).reset().play();mixer.setTime(clip.duration*phase);model.updateMatrixWorld(true);equipment.userData.updateSleeves?.();model.updateMatrixWorld(true);
 const meshes=[];
 model.traverse(m=>{if(!m.isMesh||!m.visible||!m.userData.qaSource)return;
  if(m.isSkinnedMesh)m.skeleton.update();const a=m.geometry.attributes,positions=[],uv=a.uv?Array.from(a.uv.array):null;
  for(let i=0;i<a.position.count;i++){const p=new THREE.Vector3().fromBufferAttribute(a.position,i);if(m.isSkinnedMesh)m.applyBoneTransform(i,p);m.localToWorld(p);model.worldToLocal(p);positions.push(...p.toArray().map(v=>+v.toFixed(7)));}
  meshes.push({name:m.name,source:m.userData.qaSource,material:m.userData.qaMaterial,positions,uv,indices:m.geometry.index?Array.from(m.geometry.index.array):Array.from({length:a.position.count},(_,i)=>i)});
 });result.actors.push({species,meshes});
}
fs.mkdirSync('outputs/motion-qa',{recursive:true});const destination=`outputs/motion-qa/${outfit}-${motion}-${phase}.json`;fs.writeFileSync(destination,JSON.stringify(result));console.log(destination);
