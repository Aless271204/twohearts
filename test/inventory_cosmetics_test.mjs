import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {Group,Box3,Vector3} from '../assets/runner/vendor/three.module.js';

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
  assert.equal(group.children[0].material.color.getHexString(),'91bda7');
});
