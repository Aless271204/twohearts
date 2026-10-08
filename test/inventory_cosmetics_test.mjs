import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {Group,Box3,Vector3,Bone} from '../assets/runner/vendor/three.module.js';

const source=readFileSync(new URL('../assets/runner/cosmetics.js',import.meta.url),'utf8').replace("'three'",JSON.stringify(new URL('../assets/runner/vendor/three.module.js',import.meta.url).href));
const {equipRunnerCosmetics}=await import('data:text/javascript;base64,'+Buffer.from(source).toString('base64'));
const catalog=JSON.parse(readFileSync(new URL('../docs/inventory-catalog.json',import.meta.url),'utf8'));
test('All catalogue accessories produce finite 3D geometry without changing Pip',()=>{
  for(const item of catalog.filter(i=>i.scope==='pet')){
    const pip=new Group();pip.position.set(2,.18,0);pip.rotation.y=Math.PI;
    const before=pip.position.clone();const group=equipRunnerCosmetics(pip,{[item.slot]:{style:item.style,color:item.color}});
    assert.equal(group.parent,pip);assert.ok(group.children.length>0,item.key);
    assert.deepEqual(pip.position,before);assert.equal(pip.rotation.y,Math.PI);
    const size=new Box3().setFromObject(group).getSize(new Vector3());assert.ok([size.x,size.y,size.z].every(Number.isFinite));
  }
});
test('Empty inventory leaves the original model intact and malformed colors fall back',()=>{
  const pip=new Group();assert.equal(equipRunnerCosmetics(pip,{}).children.length,0);
  const group=equipRunnerCosmetics(pip,{pet_back:{color:'javascript:bad',style:'backpack'}});
  assert.equal(group.children[0].children[0].material.color.getHexString(),'91bda7');
});


test('real Pip head and spine anchors follow animation and replacing equipment removes the old set',()=>{
  const bytes=readFileSync(new URL('../assets/runner/play-models/Meshy_AI_Pip_the_Penguin_All_Animations.glb',import.meta.url));
  const json=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString());
  const joints=new Set(json.skins.flatMap(s=>s.joints));
  const nodes=json.nodes.map((node,index)=>{const object=joints.has(index)?new Bone():new Group();object.name=node.name??'';if(node.translation)object.position.fromArray(node.translation);if(node.rotation)object.quaternion.fromArray(node.rotation);if(node.scale)object.scale.fromArray(node.scale);return object;});
  json.nodes.forEach((node,index)=>(node.children??[]).forEach(child=>nodes[index].add(nodes[child])));
  const pip=new Group();json.scenes[json.scene??0].nodes.forEach(index=>pip.add(nodes[index]));
  const head=nodes.find(n=>n.name.endsWith('Head')),spine=nodes.find(n=>n.name.endsWith('Spine2'));
  const first=equipRunnerCosmetics(pip,{pet_head:{style:'crown',color:'#f6ce68'},pet_back:{style:'backpack',color:'#538ee5'}});
  assert.equal(first.userData.slots.length,2);assert.equal(first.userData.slots[0].parent,head);assert.equal(first.userData.slots[1].parent,spine);
  const before=first.userData.slots[0].getWorldPosition(new Vector3());head.position.x+=.2;pip.updateMatrixWorld(true);
  assert.ok(first.userData.slots[0].getWorldPosition(new Vector3()).distanceTo(before)>.19);
  equipRunnerCosmetics(pip,{pet_head:{style:'bow',color:'#68abe8'}});
  assert.equal(first.parent,null);assert.ok(first.userData.slots.every(slot=>slot.parent===null));
});
