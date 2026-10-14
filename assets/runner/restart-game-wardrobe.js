// Experimental wardrobe uses the actual game, without activating unrevised shop items.
import * as THREE from 'three';
import {prepareHeadwearOcclusion} from './pet-headwear-occlusion.js';
export async function loadRestartWardrobe(loader,species){
  const catalog=await fetch('./restart/catalog.json',{cache:'no-store'}).then(r=>r.json());
  const row=catalog.variants.find(r=>r.species===species);
  const shirt=catalog.wardrobe?.find(r=>r.item_key==='shirt_love')?.variants.find(r=>r.species===species);
  if(!row||!shirt)throw Error('Esta mascota aún no tiene el conjunto nuevo revisado');
  const [pet,cap,clothing]=await Promise.all([loader.loadAsync('../../'+row.pet+'?v='+row.pet_sha256),loader.loadAsync('../../'+row.cap+'?v='+row.cap_sha256),loader.loadAsync('../../'+shirt.asset+'?v='+shirt.sha256)]);
  const bones=new Map();pet.scene.updateMatrixWorld(true);pet.scene.traverse(o=>{if(o.isBone)bones.set(o.name,o);});
  prepareHeadwearOcclusion(pet.scene,pet.scene,row.headwear_occlusion).setEquipped(true);
  pet.scene.add(cap.scene);pet.scene.updateMatrixWorld(true);bones.get('Head').attach(cap.scene);
  pet.scene.add(clothing.scene);pet.scene.updateMatrixWorld(true);
  clothing.scene.traverse(o=>{if(o.isSkinnedMesh){const mapped=o.skeleton.bones.map(b=>bones.get(b.name));if(mapped.some(b=>!b))throw Error('Falta un hueso del conjunto nuevo');o.bind(new THREE.Skeleton(mapped,o.skeleton.boneInverses.map(m=>m.clone())),o.bindMatrix.clone());o.frustumCulled=false;}});
  const aliases={Rest_R2:'Natural_Rest',Run_R2:'Running',Jump_R2:'Regular_Jump'};
  pet.animations=pet.animations.map(c=>{const copy=c.clone();copy.name=aliases[c.name]||c.name;return copy;});
  pet.scene.userData.wardrobeRevision='r2';return pet;
}
