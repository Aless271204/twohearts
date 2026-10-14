// Geometry-only offline snapshot of the same original GLB and resting pose.
// No reconstructed limbs, topology edits, vertex displacement or weight repairs.
import fs from 'node:fs';import path from 'node:path';
import * as THREE from '../assets/runner/vendor/three.module.js';
import {loadPet,runtimeUrl} from '../test/three-runtime.mjs';
const {createNaturalRest}=await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));
const {measureAccessoryFit}=await import(runtimeUrl('../assets/runner/cosmetics.js'));
const catalog=JSON.parse(fs.readFileSync('assets/runner/models.json','utf8'));
const selected=process.argv.includes('--species')?[process.argv[process.argv.indexOf('--species')+1]]:['penguin','bear','pig','chick'];
fs.mkdirSync('design/wardrobe-restart/fitting',{recursive:true});
for(const species of selected){
 const file=catalog[species==='penguin'?'pip':species],{scene,animations}=await loadPet(file);
 const initial=new THREE.Box3().setFromObject(scene),size=initial.getSize(new THREE.Vector3());scene.scale.multiplyScalar(1.15/size.y);
 const bounds=new THREE.Box3().setFromObject(scene),center=bounds.getCenter(new THREE.Vector3());scene.position.sub(new THREE.Vector3(center.x,bounds.min.y,center.z));
 const model=new THREE.Group();model.add(scene);model.userData.species=species;
 const mixer=new THREE.AnimationMixer(model);mixer.clipAction(createNaturalRest(model)).play();mixer.update(0);model.updateMatrixWorld(true);
 const fit=measureAccessoryFit(model),boneNames=[],meshes=[],limbs={};
 model.traverse(o=>{if(o.isSkinnedMesh&&!boneNames.length)boneNames.push(...o.skeleton.bones.map(b=>b.name));});
 model.traverse(o=>{
  if(!o.isMesh)return;const g=o.geometry,p=g.attributes.position,positions=[],normals=[],uv=[];
  const jointMap=o.isSkinnedMesh?o.skeleton.bones.map(b=>boneNames.indexOf(b.name)):null,skinIndex=[],skinWeight=[];
  if(o.isSkinnedMesh)o.skeleton.update();
  for(let i=0;i<p.count;i++){
   const q=new THREE.Vector3().fromBufferAttribute(p,i);if(o.isSkinnedMesh)o.applyBoneTransform(i,q);o.localToWorld(q);model.worldToLocal(q);positions.push(...q.toArray());
   if(g.attributes.normal){const n=new THREE.Vector3().fromBufferAttribute(g.attributes.normal,i).transformDirection(o.matrixWorld);normals.push(...n.toArray());}
   if(g.attributes.uv)uv.push(g.attributes.uv.getX(i),g.attributes.uv.getY(i));
   if(o.isSkinnedMesh){for(let k=0;k<4;k++){const ji=g.attributes.skinIndex.getComponent(i,k),w=g.attributes.skinWeight.getComponent(i,k);skinIndex.push(jointMap[ji]);skinWeight.push(w);const name=o.skeleton.bones[ji].name;if(w>.5&&/(Arm|ForeArm|Hand)$/.test(name)){const side=name.includes('Left')?'Left':'Right';(limbs[side]??=new THREE.Box3()).expandByPoint(q);}}}
  }
  meshes.push({name:o.name,positions,normals,indices:g.index?Array.from(g.index.array):Array.from({length:p.count},(_,i)=>i),uv,skinIndex,skinWeight});
 });
 const box=b=>({min:b.min.toArray(),max:b.max.toArray()});const data={species,source:'assets/runner/play-models/'+file,provenance:'original GLB, original bones/weights, Natural_Rest pose only',head:box(fit.head),body:box(fit.body),feet:Object.fromEntries(Object.entries(fit.feet).map(([k,b])=>[k,box(b)])),limbs:Object.fromEntries(Object.entries(limbs).map(([k,b])=>[k,box(b)])),boneNames,meshes,animations:animations.map(c=>c.name)};
 fs.writeFileSync(path.join('design/wardrobe-restart/fitting',species+'-original.json'),JSON.stringify(data));console.log(species,JSON.stringify({body:data.body,limbs:data.limbs,head:data.head}));
}
