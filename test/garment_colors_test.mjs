import test from 'node:test';import assert from 'node:assert/strict';import {readFileSync} from 'node:fs';
import {runtimeUrl} from './three-runtime.mjs';import * as THREE from '../assets/runner/vendor/three.module.js';
const {applyGarmentColor}=await import(runtimeUrl('../assets/runner/pet-garment-colors.js'));
test('Changing textile color preserves relief maps, embroidery, soles and original materials',()=>{
 const cloth=new THREE.MeshStandardMaterial({color:'#fff0d9'});cloth.name='Cotton';cloth.normalMap=new THREE.Texture();cloth.roughnessMap=new THREE.Texture();
 const seam=new THREE.MeshStandardMaterial({color:'white'});seam.name='Stitches';const group=new THREE.Group();const mesh=new THREE.Mesh(new THREE.BoxGeometry(),[cloth,seam]);group.add(mesh);
 applyGarmentColor(group,{garment_color:'#B8DCCB',color_base:'#fff0d9',color_materials:['Cotton']});
 assert.notEqual(mesh.material[0],cloth);assert.equal(mesh.material[1],seam);assert.equal(mesh.material[0].normalMap,cloth.normalMap);assert.equal(mesh.material[0].roughnessMap,cloth.roughnessMap);assert.equal(cloth.userData.nidoDye,undefined);
 const shader={uniforms:{},fragmentShader:'#include <map_fragment>'};mesh.material[0].onBeforeCompile(shader);assert.ok(shader.uniforms.nidoDye);assert.ok(shader.fragmentShader.includes('clothShade'));
});
const catalog=JSON.parse(readFileSync(new URL('../assets/runner/accessory-catalog.json',import.meta.url)));
for(const item of catalog.filter(i=>i.appearance.color_materials))for(const sp of ['penguin','bear','pig','chick'])test(item.item_key+' dye materials exist on '+sp,()=>{
 const raw=readFileSync(new URL('../'+item.appearance.species_models[sp],import.meta.url));const d=JSON.parse(raw.subarray(20,20+raw.readUInt32LE(12)));const names=d.materials.map(m=>m.name);for(const name of item.appearance.color_materials)assert.ok(names.includes(name),name);
});
