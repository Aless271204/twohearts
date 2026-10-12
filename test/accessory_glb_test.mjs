import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {runtimeUrl} from './three-runtime.mjs';
import {registerWardrobeGeometry} from './wardrobe-runtime-fixtures.mjs';
const THREE=await import(runtimeUrl('../assets/runner/vendor/three.module.js'));
const {createAccessory,disposeAccessory}=await import(runtimeUrl('../assets/runner/accessory-pieces.js'));

test('inventory uses all 96 tailored models; batching preserves their triangles, UVs and bounds',async()=>{
 const catalog=JSON.parse(readFileSync(new URL('../assets/runner/accessory-catalog.json',import.meta.url),'utf8'));
 assert.equal(catalog.length,25);
 const generated=[...JSON.parse(readFileSync(new URL('../assets/runner/blender-wardrobe-models.json',import.meta.url))),...JSON.parse(readFileSync(new URL('../assets/runner/blender-complement-models.json',import.meta.url)))];
 const visible=catalog.filter(i=>i.visible!==false);assert.equal(visible.length,24);assert.equal(catalog.find(i=>i.item_key==='wig_pastel')?.visible,false);
 for(const item of visible){
  const definition=generated.find(i=>i.item_key===item.item_key);assert.ok(definition);assert.deepEqual(item.appearance.species_models,definition.appearance.species_models);
  for(const species of ['penguin','bear','pig','chick']){
   const scene=await registerWardrobeGeometry(item.appearance.species_models[species]),original=new THREE.Box3().setFromObject(scene,true);
   let before=0,meshes=0;scene.traverse(m=>{if(m.isMesh){before+=(m.geometry.index?.count??m.geometry.attributes.position.count)/3;meshes++;}});
   const fitted=createAccessory(item.appearance,item.equip_slot,species),bounds=new THREE.Box3().setFromObject(fitted,true);let after=0,batched=0;
   fitted.traverse(m=>{if(m.isMesh){after+=(m.geometry.index?.count??m.geometry.attributes.position.count)/3;batched++;assert.ok(m.geometry.attributes.uv);}});
   assert.equal(after,before,item.item_key+': no discarded detail');assert.ok(batched<=meshes);
   assert.ok(bounds.min.distanceTo(original.min)<1e-5&&bounds.max.distanceTo(original.max)<1e-5,item.item_key+': no changed shape');disposeAccessory(fitted);
  }
 }
});
