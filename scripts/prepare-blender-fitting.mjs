import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {runtimeUrl,loadPet} from '../test/three-runtime.mjs';
import * as THREE from '../assets/runner/vendor/three.module.js';
const {createNaturalRest}=await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));
const {refinePip}=await import(runtimeUrl('../assets/runner/pip-delicate.js'));
const {measureAccessoryFit}=await import(runtimeUrl('../assets/runner/cosmetics.js'));
const {stabilizePetTorso}=await import(runtimeUrl('../assets/runner/pet-garment-rig.js'));
const directory=new URL('../design/blender/fitting/',import.meta.url);mkdirSync(directory,{recursive:true});
const pets={penguin:'Meshy_AI_Pip_the_Penguin_All_Animations.glb',bear:'bear.glb',pig:'pig.glb',chick:'chick.glb'};
const report={};
for(const [species,file] of Object.entries(pets)){
 const {scene,animations}=await loadPet(file);scene.scale.multiplyScalar(1.15/new THREE.Box3().setFromObject(scene).getSize(new THREE.Vector3()).y);
 const bounds=new THREE.Box3().setFromObject(scene),center=bounds.getCenter(new THREE.Vector3());scene.position.sub(new THREE.Vector3(center.x,bounds.min.y,center.z));
 const model=new THREE.Group();model.add(scene);model.userData.species=species;
 const mixer=new THREE.AnimationMixer(model);mixer.clipAction(createNaturalRest(model)).play();mixer.update(0);if(species==='penguin')refinePip(model);model.updateMatrixWorld(true);
 stabilizePetTorso(model,measureAccessoryFit(model));
 const fit=model.userData.accessoryFit,headBone=[];model.traverse(o=>{if(o.isBone&&/Head$/.test(o.name))headBone.push(o);});
 const boneNames=[];model.traverse(o=>{if(o.isSkinnedMesh&&!boneNames.length)boneNames.push(...o.skeleton.bones.map(b=>b.name));});
 const meshes=[];
 model.traverse(o=>{if(!o.isMesh)return;const g=o.geometry,p=g.attributes.position;const positions=[],normals=[];
  if(o.isSkinnedMesh)o.skeleton.update();
  for(let i=0;i<p.count;i++){const v=new THREE.Vector3().fromBufferAttribute(p,i),n=g.attributes.normal?new THREE.Vector3().fromBufferAttribute(g.attributes.normal,i):new THREE.Vector3(0,1,0),end=v.clone().addScaledVector(n,.0001);if(o.isSkinnedMesh){o.applyBoneTransform(i,v);o.applyBoneTransform(i,end);}o.localToWorld(v);o.localToWorld(end);model.worldToLocal(v);model.worldToLocal(end);positions.push(...v.toArray());normals.push(...end.sub(v).normalize().toArray());}
  const skinIndex=o.isSkinnedMesh?Array.from(g.attributes.skinIndex.array):null,skinWeight=o.isSkinnedMesh?Array.from(g.attributes.skinWeight.array):null;
  const material=o.material;meshes.push({skinIndex,skinWeight,name:o.name,positions,normals,indices:g.index?Array.from(g.index.array):Array.from({length:p.count},(_,i)=>i),uv:g.attributes.uv?Array.from(g.attributes.uv.array):null,source_material:o.isSkinnedMesh,material:o.isSkinnedMesh?null:{color:material.color.toArray(),roughness:material.roughness}});
 });
 const data={species,source:'assets/runner/play-models/'+file,head:{min:fit.head.min.toArray(),max:fit.head.max.toArray()},head_matrix:headBone[0].matrixWorld.toArray(),body:{min:fit.body.min.toArray(),max:fit.body.max.toArray()},feet:Object.fromEntries(Object.entries(fit.feet).map(([side,box])=>[side,{min:box.min.toArray(),max:box.max.toArray()}])),boneNames,meshes,animations:animations.map(a=>a.name)};
 writeFileSync(new URL(species+'.json',directory),JSON.stringify(data));report[species]={head:data.head,meshes:meshes.length};
}
console.log(JSON.stringify(report));
