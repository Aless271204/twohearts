import {readFileSync,writeFileSync} from 'node:fs';
import {loadPet,runtimeUrl} from '../test/three-runtime.mjs';
import * as THREE from '../assets/runner/vendor/three.module.js';
const {createNaturalRest}=await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));
const {createSleeveAnchors}=await import(runtimeUrl('../assets/runner/pet-sleeve-anchors.js'));
const pet=await loadPet('Meshy_AI_Pip_the_Penguin_All_Animations.glb');
const initial=new THREE.Box3().setFromObject(pet.scene);pet.scene.scale.multiplyScalar(1.15/initial.getSize(new THREE.Vector3()).y);
const bounds=new THREE.Box3().setFromObject(pet.scene),center=bounds.getCenter(new THREE.Vector3());pet.scene.position.sub(new THREE.Vector3(center.x,bounds.min.y,center.z));
const model=new THREE.Group();model.add(pet.scene);model.userData.species='penguin';
const mixer=new THREE.AnimationMixer(model);mixer.clipAction(createNaturalRest(model)).play();mixer.update(0);model.updateMatrixWorld(true);
const fitting=JSON.parse(readFileSync(new URL('../design/wardrobe-restart/fitting/penguin-original.json',import.meta.url)));
model.userData.accessoryFit={head:new THREE.Box3(new THREE.Vector3().fromArray(fitting.head.min),new THREE.Vector3().fromArray(fitting.head.max))};
const source=[];const bones={};model.traverse(o=>{if(o.isSkinnedMesh)source.push(o);if(o.isBone)bones[o.name.replace(/^mixamorig:?/,'')]=o;});
const cloth=await loadPet('../accessories/sewn_shirt_love_penguin.glb');model.add(cloth.scene);model.updateMatrixWorld(true);
const meshes=[];cloth.scene.traverse(o=>{if(o.isMesh)meshes.push(o);});
const anchors=createSleeveAnchors(model,meshes.find(m=>m.userData.nidoSleeveFit).userData.nidoSleeveFit,cloth.scene);Object.assign(bones,anchors.bones);
const clothes=[];const skeletons=new Map();
for(const mesh of meshes){
 const names=mesh.userData.nidoBoneNames,joints=names.map(n=>bones[n.replace(/^mixamorig:?/,'')]),key=names.join('|');
 let skeleton=skeletons.get(key);if(!skeleton){skeleton=new THREE.Skeleton(joints,joints.map(j=>j.matrixWorld.clone().invert()));skeletons.set(key,skeleton);}
 const garment=new THREE.SkinnedMesh(mesh.geometry,mesh.material);mesh.updateWorldMatrix(true,false);garment.bind(skeleton,mesh.matrixWorld.clone());
 garment.position.copy(mesh.position);garment.quaternion.copy(mesh.quaternion);garment.scale.copy(mesh.scale);mesh.parent.add(garment);mesh.parent.remove(mesh);clothes.push(garment);
}
const coveragePath=new URL('../assets/runner/restart/shirt-original-coverage-penguin.json',import.meta.url);
const coverage=JSON.parse(readFileSync(coveragePath));const additions={};const results=[];
for(const motion of ['Running','Regular_Jump']){
 const clip=pet.animations.find(c=>c.name===motion);if(!clip)continue;
 for(const phase of [0,.25,.5,.75]){
  mixer.stopAllAction();const action=mixer.clipAction(clip);action.play();action.time=clip.duration*phase;mixer.update(0);anchors.update();model.updateMatrixWorld(true);
  const posed=[];
  for(const mesh of clothes){
   mesh.skeleton.update();const values=[];
   for(let i=0;i<mesh.geometry.attributes.position.count;i++){const p=new THREE.Vector3().fromBufferAttribute(mesh.geometry.attributes.position,i);mesh.applyBoneTransform(i,p);mesh.localToWorld(p);values.push(p.x,p.y,p.z);}
   const g=new THREE.BufferGeometry();g.setAttribute('position',new THREE.Float32BufferAttribute(values,3));g.setIndex(mesh.geometry.index.clone());g.computeBoundingSphere();
   posed.push(new THREE.Mesh(g,new THREE.MeshBasicMaterial({side:THREE.DoubleSide})));
  }
  let intersections=0;
  for(const mesh of source){
   mesh.skeleton.update();const reference=fitting.meshes.find(m=>m.name===mesh.name),indices=reference.indices;
   const hidden=new Set();for(let i=0;i<(coverage[mesh.name]??[]).length;i+=3)hidden.add(coverage[mesh.name].slice(i,i+3).join(','));
   for(let i=0;i<indices.length;i+=3){
    const tri=indices.slice(i,i+3);if(hidden.has(tri.join(',')))continue;
    const rest=tri.map(v=>new THREE.Vector3().fromArray(reference.positions,v*3)),cy=rest.reduce((s,p)=>s+p.y,0)/3;
    let head=0;for(const v of tri)for(let j=0;j<4;j++)if(fitting.boneNames[reference.skinIndex[v*4+j]].endsWith('Head'))head+=reference.skinWeight[v*4+j]/3;
    if(cy<.315||cy>.555||head>.90)continue;
    const vertices=tri.map(v=>{const p=new THREE.Vector3().fromBufferAttribute(mesh.geometry.attributes.position,v);mesh.applyBoneTransform(v,p);return mesh.localToWorld(p);});
    let hit=false;
    for(let edge=0;edge<3&&!hit;edge++){const a=vertices[edge],b=vertices[(edge+1)%3],d=b.clone().sub(a),length=d.length();if(length<1e-8)continue;
     const ray=new THREE.Raycaster(a,d.multiplyScalar(1/length),.0001,length-.0001);hit=ray.intersectObjects(posed,false).length>0;}
    if(hit){intersections++;(additions[mesh.name]??=new Map()).set(tri.join(','),tri);}
   }
  }
  results.push({motion,phase,intersections});for(const m of posed){m.geometry.dispose();m.material.dispose();}
 }
}
writeFileSync(new URL('../outputs/sewn-shirt-motion-intersections.json',import.meta.url),JSON.stringify({results,triangles:Object.fromEntries(Object.entries(additions).map(([k,v])=>[k,[...v.values()].flat()]))},null,2));
console.log(JSON.stringify(results));
