import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {runtimeUrl} from './three-runtime.mjs';
const THREE=await import(runtimeUrl('../assets/runner/vendor/three.module.js'));
const {GLTFLoader}=await import(runtimeUrl('../assets/runner/vendor/loaders/GLTFLoader.js'));
const {createAccessory}=await import(runtimeUrl('../assets/runner/accessory-pieces.js'));

test('all exported accessories load as GLB with the same bounds as their fitted meshes',async()=>{
 const catalog=JSON.parse(readFileSync(new URL('../assets/runner/accessory-catalog.json',import.meta.url),'utf8'));
 assert.equal(catalog.length,25);
 for(const item of catalog){
  const bytes=readFileSync(new URL('../'+item.appearance.model_asset,import.meta.url));
  const gltf=await new GLTFLoader().parseAsync(bytes.buffer.slice(bytes.byteOffset,bytes.byteOffset+bytes.byteLength),'');
  const exported=new THREE.Box3().setFromObject(gltf.scene,true);
  const source=createAccessory(item.appearance,item.equip_slot);
  const hidden=[];source.traverse(node=>{if(!node.visible)hidden.push(node);});
  for(const node of hidden)node.removeFromParent();
  const fitted=new THREE.Box3().setFromObject(source,true);
  for(const bound of ['min','max'])for(const axis of ['x','y','z']){
   assert.ok(Number.isFinite(exported[bound][axis]),item.item_key);
   assert.ok(Math.abs(exported[bound][axis]-fitted[bound][axis])<0.0001,`${item.item_key}: ${bound}.${axis}`);
  }
 }
});
