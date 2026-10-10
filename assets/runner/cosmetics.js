import * as THREE from 'three';
import {createAccessory, disposeAccessory} from './accessory-pieces.js';

export {createAccessory} from './accessory-pieces.js';

export function measureAccessoryFit(model) {
  model.updateMatrixWorld(true);
  const head=new THREE.Box3(),body=new THREE.Box3(),feet={Left:new THREE.Box3(),Right:new THREE.Box3()};
  const points=[],weightedFeet={Left:new THREE.Box3(),Right:new THREE.Box3()};
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
  const bones={};model.traverse(o=>{if(o.isBone)bones[o.name.replace(/^mixamorig:?/,'')]=o;});
  const fit=model.userData.accessoryFit??=measureAccessoryFit(model);
  const group=new THREE.Group();group.name='equipped-cosmetics';group.userData.slots=[];model.add(group);
  const h=fit.head.getSize(new THREE.Vector3()),hc=fit.head.getCenter(new THREE.Vector3());
  const b=fit.body.getSize(new THREE.Vector3()),bc=fit.body.getCenter(new THREE.Vector3());
  function attach(item,slot,bone,position,scale){
    const part=createAccessory(item,slot);part.position.copy(position);part.scale.copy(scale);group.add(part);
    model.updateMatrixWorld(true);if(bone)bone.attach(part);group.userData.slots.push(part);return part;
  }
  for(const [slot,item] of Object.entries(loadout??{})){
    if(!item||typeof item!=='object'||!slot.startsWith('pet_'))continue;
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
