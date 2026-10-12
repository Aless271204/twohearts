import {Group,Box3,Vector3,AnimationMixer} from '../assets/runner/vendor/three.module.js';
import {runtimeUrl,loadPet} from '../test/three-runtime.mjs';
const {createNaturalRest}=await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));
for(const species of ['bear','pig']){
 const {scene}=await loadPet(species+'.glb');scene.scale.multiplyScalar(1.15/new Box3().setFromObject(scene).getSize(new Vector3()).y);
 const bounds=new Box3().setFromObject(scene),center=bounds.getCenter(new Vector3());scene.position.sub(new Vector3(center.x,bounds.min.y,center.z));
 const model=new Group();model.add(scene);model.userData.species=species;const mixer=new AnimationMixer(model);mixer.clipAction(createNaturalRest(model)).play();mixer.update(0);model.updateMatrixWorld(true);
 const ears={left:[],right:[]};model.traverse(mesh=>{if(!mesh.isSkinnedMesh)return;mesh.skeleton.update();const positions=mesh.geometry.attributes.position;for(let i=0;i<positions.count;i++){const p=new Vector3().fromBufferAttribute(positions,i);mesh.applyBoneTransform(i,p);mesh.localToWorld(p);model.worldToLocal(p);if(Math.abs(p.x)>.27&&p.y>.93)ears[p.x>0?'left':'right'].push(p);}});
 console.log(species,Object.fromEntries(Object.entries(ears).map(([k,v])=>{const box=new Box3().setFromPoints(v);return[k,{center:box.getCenter(new Vector3()).toArray(),size:box.getSize(new Vector3()).toArray()}];})));
}
