import {bindGarmentToOriginalSkin} from './pet-garment-binding.js?revision=original-skin-1';
import * as THREE from 'three';
import {createAccessory, disposeAccessory} from './accessory-pieces.js?revision=wardrobe-colors-2';
import {conformHeadAccessory} from './head-conform.js';
import {restoreFootwearCoverage,coverClosedFootwear} from './pet-footwear-coverage.js?revision=ankle-boundary-2';
import {restoreSleeveCoverage,coverSleeveSkin} from './pet-sleeve-coverage.js?revision=sleeves-sewn-1';
import {createSleeveAnchors} from './pet-sleeve-anchors.js?revision=surface-fit-4';
import {prepareHeadwearOcclusion} from './pet-headwear-occlusion.js?revision=ear-seam-2';
import {createClothWrap} from './pet-cloth-wrap.js?revision=3';
import {createFootwearAnchors} from './pet-footwear-anchors.js?revision=paw-contact-3';

// Export the same stateful registry used by equipRunnerCosmetics. Importing a
// second revision creates another ESM instance with an empty accessory cache.
export {createAccessory,prepareAccessoryAssets,registerAccessoryAsset,releaseAccessoryAssets,disposeAccessory} from './accessory-pieces.js?revision=wardrobe-colors-2';

export function measureAccessoryFit(model) {
  model.updateMatrixWorld(true);
  const head=new THREE.Box3(),body=new THREE.Box3(),feet={Left:new THREE.Box3(),Right:new THREE.Box3()};
  const points=[],torsoPoints=[],weightedFeet={Left:new THREE.Box3(),Right:new THREE.Box3()};
  // Include the replacement feet and torso when fitting the room variant.
  // Otherwise the removed original toes raise the measured floor and neck.
  model.traverse(mesh=>{
    if(!mesh.isMesh||!/(RoundedFoot|RoundedTorsoLining)$/.test(mesh.name))return;
    const positions=mesh.geometry.attributes.position;
    for(let i=0;i<positions.count;i++){
      const point=new THREE.Vector3().fromBufferAttribute(positions,i);
      mesh.localToWorld(point);model.worldToLocal(point);points.push(point);
    }
  });
  model.traverse(mesh=>{
    if(!mesh.isSkinnedMesh)return;
    mesh.skeleton.update();
    const positions=mesh.geometry.attributes.position;
    const vertices=mesh.geometry.index?new Set(mesh.geometry.index.array):Array.from({length:positions.count},(_,i)=>i);
    for(const i of vertices){
      const point=new THREE.Vector3().fromBufferAttribute(positions,i);mesh.applyBoneTransform(i,point);mesh.localToWorld(point);model.worldToLocal(point);points.push(point);
      let torsoWeight=0;
      for(let k=0;k<4;k++)if(/(Hips|Spine|Spine1|Spine2)$/.test(mesh.skeleton.bones[mesh.geometry.attributes.skinIndex.getComponent(i,k)]?.name??''))torsoWeight+=mesh.geometry.attributes.skinWeight.getComponent(i,k);
      if(torsoWeight>.65)torsoPoints.push(point.clone());
      for(const side of ['Left','Right']){let weight=0;for(let k=0;k<4;k++)if(new RegExp(side+'(Foot|ToeBase|Toe_End)$').test(mesh.skeleton.bones[mesh.geometry.attributes.skinIndex.getComponent(i,k)]?.name??''))weight+=mesh.geometry.attributes.skinWeight.getComponent(i,k);if(weight>.45)weightedFeet[side].expandByPoint(point);}
    }
  });
  const all=new THREE.Box3().setFromPoints(points);
  if(!all.isEmpty()){
    const size=all.getSize(new THREE.Vector3()),center=all.getCenter(new THREE.Vector3());
    const split=all.min.y+size.y*({penguin:.46,bear:.40,pig:.42,chick:.42}[model.userData.species]??.46);
    for(const point of points){
      if(point.y>=split)head.expandByPoint(point);
      else if(point.y>all.min.y+size.y*.07&&Math.abs(point.x-center.x)<size.x*.30)body.expandByPoint(point);
      if(point.y<all.min.y+size.y*.07){
        const side=point.x>center.x?'Left':'Right';feet[side].expandByPoint(point);
      }
    }
  }
  // Leg and arm vertices must not stretch a shirt down to the toes or across
  // the wings. Fit the garment to skin weighted to the torso joints only.
  if(torsoPoints.length>20){const torso=new THREE.Box3().setFromPoints(torsoPoints);torso.max.y=Math.min(torso.max.y,head.min.y+.025);const size=torso.getSize(new THREE.Vector3());if(size.x>.1&&size.y>.1&&size.z>.1)body.copy(torso);}
  for(const side of ['Left','Right']){const w=weightedFeet[side].getSize(new THREE.Vector3());if(w.x>.05&&w.z>.06)feet[side].union(weightedFeet[side]);}
  // Refined penguin feet are rigid meshes following the original foot joints.
  model.traverse(mesh=>{for(const side of ['Left','Right'])if(mesh.name===side+'RoundedFoot'){
    const bounds=new THREE.Box3().setFromObject(mesh,true);feet[side].makeEmpty();
    for(const x of [bounds.min.x,bounds.max.x])for(const y of [bounds.min.y,bounds.max.y])for(const z of [bounds.min.z,bounds.max.z])feet[side].expandByPoint(model.worldToLocal(new THREE.Vector3(x,y,z)));
  }});
  if(head.isEmpty())head.set(new THREE.Vector3(-.28,.55,-.26),new THREE.Vector3(.28,1.08,.30));
  if(body.isEmpty())body.set(new THREE.Vector3(-.24,.13,-.19),new THREE.Vector3(.24,.57,.23));
  return {head,body,feet};
}

// Equipment is positioned in the resting model's coordinates, then attached
// preserving its world transform. It follows the rig without moving the pet.
export function equipRunnerCosmetics(model, loadout={}) {
  const previous=model.userData.cosmetics;
  if(previous){for(const part of previous.userData.slots??[])disposeAccessory(part);disposeAccessory(previous);}
  model.userData.headwearOcclusion?.dispose();delete model.userData.headwearOcclusion;
  restoreSleeveCoverage(model);
  restoreFootwearCoverage(model);
  tuckCrownTuft(model,!!loadout?.pet_head?.tuck_crown_tuft);
  const bones={};model.traverse(o=>{if(o.isBone)bones[o.name.replace(/^mixamorig:?/,'')]=o;});
  const fit=model.userData.accessoryFit??=measureAccessoryFit(model);
  coverClosedFootwear(model,fit,loadout?.pet_feet);
  coverSleeveSkin(model,loadout?.pet_body);
  if(loadout?.pet_head?.headwear_occlusion){
    const occlusion=prepareHeadwearOcclusion(model,model,loadout.pet_head.headwear_occlusion);occlusion.setEquipped(true);model.userData.headwearOcclusion=occlusion;
  }
  const group=new THREE.Group();group.name='equipped-cosmetics';group.userData.slots=[];model.add(group);
  const h=fit.head.getSize(new THREE.Vector3()),hc=fit.head.getCenter(new THREE.Vector3());
  const b=fit.body.getSize(new THREE.Vector3()),bc=fit.body.getCenter(new THREE.Vector3());
  function attach(item,slot,bone,position,scale){
    const part=createAccessory(item,slot,model.userData.species);part.position.copy(position);part.scale.copy(scale);
    if(item.preserve_proportions)part.scale.setScalar(scale.x);
    const profile=slot==='pet_head'?item.head_fit?.[model.userData.species]:null;
    if(profile){part.position.add(new THREE.Vector3(...profile.offset));part.rotation.set(...profile.rotation);part.scale.multiplyScalar(profile.scale);}
    group.add(part);
    model.updateMatrixWorld(true);
    if(slot==='pet_head'&&item.conform_head)conformHeadAccessory(part,model,fit.head,{...item.conform_head,visor:item.style==='cap'});
    if(profile?.ear_clearance)cutHeadEarOpenings(part,model,profile.ear_clearance);
    if(bone)bone.attach(part);group.userData.slots.push(part);return part;
  }
  for(const [slot,item] of Object.entries(loadout??{})){
    if(!item||typeof item!=='object'||!slot.startsWith('pet_'))continue;
    if(item.preview_static_fit&&item.fitted_model_space&&new URLSearchParams(globalThis.location?.search??'').get('pet')==='1'){
      const part=createAccessory(item,slot,model.userData.species);
      if(item.preview_hide_finishes)part.traverse(mesh=>{if(/^(Dobladillo|Hilo)/.test(mesh.name))mesh.visible=false;});
      if(item.preview_component)part.traverse(mesh=>{if(mesh.isMesh)mesh.visible=item.preview_component==='cloth'?mesh.name.replaceAll('_',' ').startsWith('Manga adaptada'):mesh.name.includes('Cuello');});
      group.add(part);group.userData.slots.push(part);continue;
    }
    if(item.skinned_model_space){
      const part=createAccessory(item,slot,model.userData.species);group.add(part);model.updateMatrixWorld(true);
      let clothingBones=bones;
      if(slot==='pet_feet'){
        const anchors=createFootwearAnchors(model,group,Infinity,fit);clothingBones={...bones,...anchors.bones};
        const previous=group.userData.updateSleeves;group.userData.updateSleeves=()=>{previous?.();anchors.update();};
      }
      const replacements=[];
      const wrapped=[];
      const skeletons=new Map();
      part.traverse(mesh=>{if(mesh.isMesh)replacements.push(mesh);});
      const sleeveProfile=replacements.find(mesh=>!mesh.userData.nidoMotionTransfer&&mesh.userData.nidoSleeveFit)?.userData.nidoSleeveFit;
      if(sleeveProfile){
        const anchors=createSleeveAnchors(model,sleeveProfile,group);Object.assign(bones,anchors.bones);
        const previous=group.userData.updateSleeves;group.userData.updateSleeves=()=>{previous?.();anchors.update();};
      }
      for(const mesh of replacements){
        if(mesh.userData.nidoMotionTransfer){
          let source;model.traverse(candidate=>{if(candidate.isSkinnedMesh&&!candidate.userData.cosmetic&&candidate.name===(mesh.userData.nidoMotionTransfer.source_mesh??'Mesh_0'))source=candidate;});
          if(!source)throw Error('No se encontró el cuerpo original para enlazar la ropa');
          bindGarmentToOriginalSkin(mesh,source,skeletons);continue;
        }
        const names=mesh.userData.nidoBoneNames;
        if(!Array.isArray(names)||!mesh.geometry.attributes.skinIndex||!mesh.geometry.attributes.skinWeight)throw Error('La prenda no tiene pesos de animación');
        const joints=names.map(name=>clothingBones[name.replace(/^mixamorig:?/,'')]);
        if(joints.some(joint=>!joint))throw Error('El esqueleto de la prenda no corresponde a la mascota');
        const key=names.join('|');
        let skeleton=skeletons.get(key);
        if(!skeleton){skeleton=new THREE.Skeleton(joints,joints.map(joint=>joint.matrixWorld.clone().invert()));skeletons.set(key,skeleton);}
        const garment=new THREE.SkinnedMesh(mesh.geometry,mesh.material);garment.name=mesh.name;garment.userData={...mesh.userData,cosmetic:true};
        // Pattern vertices are authored in the normalized resting model frame.
        mesh.updateWorldMatrix(true,false);garment.bind(skeleton,mesh.matrixWorld.clone());
        if(mesh.userData.nidoSurfaceWrap){
          const wrappedMesh=new THREE.Mesh(mesh.geometry.clone(),mesh.material);wrappedMesh.name=mesh.name;wrappedMesh.userData={...mesh.userData,cosmetic:true,nidoWrapSkin:garment};
          wrappedMesh.position.copy(mesh.position);wrappedMesh.quaternion.copy(mesh.quaternion);wrappedMesh.scale.copy(mesh.scale);wrappedMesh.frustumCulled=false;
          mesh.parent.add(wrappedMesh);mesh.parent.remove(mesh);wrapped.push(wrappedMesh);continue;
        }
        garment.position.copy(mesh.position);garment.quaternion.copy(mesh.quaternion);garment.scale.copy(mesh.scale);
        garment.frustumCulled=false;mesh.parent.add(garment);mesh.parent.remove(mesh);
      }
      if(wrapped.length){const wrap=createClothWrap(model,wrapped);const previous=group.userData.updateSleeves;group.userData.updateSleeves=()=>{previous?.();wrap.update();};if(globalThis.document)document.body.dataset.petClothDeformation='surface_cage';}
      part.userData.blenderTailored=true;part.userData.skinnedWardrobe=true;group.userData.slots.push(part);continue;
    }
    if(['pet_head','pet_eyes'].includes(slot)&&item.fitted_model_space){
      // Blender exported this species' garment in the app's resting model frame.
      // Re-scaling or conforming it again would undo the authored tailoring.
      const part=createAccessory(item,slot,model.userData.species);group.add(part);model.updateMatrixWorld(true);
      if(!bones.Head)throw Error('La mascota no tiene el hueso Head');
      bones.Head.attach(part);part.userData.blenderTailored=true;group.userData.slots.push(part);continue;
    }
    if(slot==='pet_head'){const ratio={bear:.78,pig:.76,penguin:.94,chick:.94}[model.userData.species]??1;const inset={bear:.24,pig:.23,penguin:.23,chick:.24}[model.userData.species]??.18;attach(item,slot,bones.Head,new THREE.Vector3(hc.x,fit.head.max.y-h.y*inset,hc.z),new THREE.Vector3(h.x/.56*ratio,h.x/.56*ratio,h.z/.56*ratio));}
    else if(slot==='pet_eyes'){const ratio={penguin:.86,bear:.82,pig:.88,chick:.85}[model.userData.species]??.85;const height={penguin:.36,bear:.43,pig:.32,chick:.38}[model.userData.species]??.38;attach(item,slot,bones.Head,new THREE.Vector3(hc.x,fit.head.min.y+h.y*height,hc.z+h.z*.43),new THREE.Vector3(h.x/.56*ratio,h.x/.56*ratio,1));}
    else if(slot==='pet_neck'){const penguin=model.userData.species==='penguin';attach(item,slot,bones.Neck??bones.Spine2,new THREE.Vector3(bc.x,fit.head.min.y+(penguin?-.055:.035),bc.z),new THREE.Vector3(b.x*(penguin?.94:1.03)/.50,penguin?.82:1,Math.max(b.z,h.z*.75)/.40));}
    else if(slot==='pet_body')attach(item,slot,bones.Spine2,new THREE.Vector3(bc.x,bc.y,bc.z),new THREE.Vector3(Math.max(.38,b.x)*1.06/.57,Math.max(.34,b.y)*1.12/.48,Math.max(.3,b.z)*1.08/.456));
    else if(slot==='pet_back')attach(item,slot,bones.Spine2,new THREE.Vector3(bc.x,bc.y,fit.body.min.z-.025),new THREE.Vector3(1,1,1));
    else if(slot==='pet_feet')for(const side of ['Left','Right']){
      const box=fit.feet[side];if(box.isEmpty())continue;const center=box.getCenter(new THREE.Vector3()),size=box.getSize(new THREE.Vector3());
      attach(item,slot,bones[side+'Foot'],new THREE.Vector3(center.x,box.min.y-.01,center.z+.01),new THREE.Vector3(size.x*1.14/.16,Math.max(.10,size.y)/.09,size.z*1.28/.19));
    }
  }
  model.userData.cosmetics=group;model.userData.cosmeticStyles=Object.fromEntries(Object.entries(loadout??{}).filter(([k,v])=>k.startsWith('pet_')&&v).map(([k,v])=>[k,v.style]));
  return group;
}

// Tuck the small crown feathers only while a fitted hat is worn. Restore the
// same source indices when removed; no permanent edit to the character GLB.
export function tuckCrownTuft(model,tucked){
  if(!['penguin','chick'].includes(model.userData.species))return;
  model.updateMatrixWorld(true);
  model.traverse(mesh=>{
    if(!mesh.isSkinnedMesh||mesh.userData.cosmetic)return;
    if(mesh.userData.crownTuftSource){mesh.geometry.setIndex(mesh.userData.crownTuftSource.clone());delete mesh.userData.crownTuftSource;}
    if(!tucked)return;
    const geometry=mesh.geometry;if(!geometry.index)return;
    mesh.skeleton.update();const positions=geometry.attributes.position,hidden=new Set();
    for(let i=0;i<positions.count;i++){
      const point=new THREE.Vector3().fromBufferAttribute(positions,i);mesh.applyBoneTransform(i,point);mesh.localToWorld(point);model.worldToLocal(point);
      if(point.y>1.065&&Math.abs(point.x)<.18)hidden.add(i);
    }
    const indices=geometry.index.array,kept=[];
    for(let i=0;i<indices.length;i+=3)if(!hidden.has(indices[i])&&!hidden.has(indices[i+1])&&!hidden.has(indices[i+2]))kept.push(indices[i],indices[i+1],indices[i+2]);
    mesh.userData.crownTuftSource=geometry.index.clone();geometry.setIndex(kept);
  });
  model.userData.crownTuftTucked=tucked;
}

// Open the cloth around the ears in the resting pet's coordinates. This edits
// only this equipment instance; the pet mesh, source GLB and UVs stay intact.
export function cutHeadEarOpenings(part,model,openings){
  let removed=0;
  part.traverse(mesh=>{
    if(!mesh.isMesh)return;
    const geometry=mesh.geometry,positions=geometry.attributes.position;
    const indices=geometry.index?.array??Array.from({length:positions.count},(_,i)=>i);
    const attributes=Object.entries(geometry.attributes),output=Object.fromEntries(attributes.map(([name])=>[name,[]]));
    const vertices=Array.from({length:positions.count},(_,i)=>({point:model.worldToLocal(mesh.localToWorld(new THREE.Vector3().fromBufferAttribute(positions,i))),data:Object.fromEntries(attributes.map(([name,a])=>[name,Array.from({length:a.itemSize},(_,k)=>a.getComponent(i,k))]))}));
    const interpolate=(a,b,t)=>({point:a.point.clone().lerp(b.point,t),data:Object.fromEntries(attributes.map(([name])=>[name,a.data[name].map((v,k)=>v+(b.data[name][k]-v)*t)]))});
    function clip(polygon,{center,radius}){
      const distance=v=>v.point.toArray().reduce((sum,x,k)=>sum+((x-center[k])/radius[k])**2,0)-1;
      const result=[];
      for(let i=0;i<polygon.length;i++){
        const a=polygon[i],b=polygon[(i+1)%polygon.length],outsideA=distance(a)>=0,outsideB=distance(b)>=0;
        if(outsideA)result.push(a);
        if(outsideA!==outsideB){let low=0,high=1;for(let step=0;step<18;step++){const t=(low+high)/2;if((distance(interpolate(a,b,t))>=0)===outsideA)low=t;else high=t;}result.push(interpolate(a,b,(low+high)/2));}
      }
      return result;
    }
    for(let i=0;i<indices.length;i+=3){
      let polygon=[vertices[indices[i]],vertices[indices[i+1]],vertices[indices[i+2]]];
      for(const opening of openings)polygon=clip(polygon,opening);
      if(polygon.length!==3||polygon.some(v=>!vertices.includes(v)))removed++;
      for(let k=1;k+1<polygon.length;k++)for(const vertex of [polygon[0],polygon[k],polygon[k+1]])for(const [name] of attributes)output[name].push(...vertex.data[name]);
    }
    const fitted=new THREE.BufferGeometry();for(const [name,a] of attributes)fitted.setAttribute(name,new THREE.Float32BufferAttribute(output[name],a.itemSize));
    fitted.normalizeNormals();fitted.computeBoundingBox();fitted.computeBoundingSphere();mesh.geometry=fitted;geometry.dispose();
  });
  part.userData.earClearanceTriangles=removed;
  return removed;
}
