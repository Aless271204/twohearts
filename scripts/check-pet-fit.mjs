import {loadPet,runtimeUrl} from '../test/three-runtime.mjs';
import {Group,Box3,Vector3} from '../assets/runner/vendor/three.module.js';
const {createNaturalRest}=await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));
const {measureAccessoryFit}=await import(runtimeUrl('../assets/runner/cosmetics.js'));
for(const file of ['Meshy_AI_Pip_the_Penguin_All_Animations.glb','bear.glb','pig.glb','chick.glb']){
 const gltf=await loadPet(file), source=gltf.scene;
 const box=new Box3().setFromObject(source);source.scale.multiplyScalar(1.15/box.getSize(new Vector3()).y);
 const fitted=new Box3().setFromObject(source),center=fitted.getCenter(new Vector3());source.position.sub(new Vector3(center.x,fitted.min.y,center.z));
 const model=new Group();model.add(source);model.userData.species=file.includes('Penguin')?'penguin':file.replace('.glb','');createNaturalRest(model);
 const fit=measureAccessoryFit(model);console.log(file, Object.fromEntries(Object.entries(fit).map(([k,b])=>[k,k==='feet'?Object.fromEntries(Object.entries(b).map(([s,v])=>[s,v.getSize(new Vector3()).toArray()])):{min:b.min.toArray(),max:b.max.toArray()}])));
}

