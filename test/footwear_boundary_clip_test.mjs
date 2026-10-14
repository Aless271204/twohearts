import test from 'node:test';
import assert from 'node:assert/strict';
import * as THREE from '../assets/runner/vendor/three.module.js';
import {runtimeUrl} from './three-runtime.mjs';
const {coverClosedFootwear,restoreFootwearCoverage}=await import(runtimeUrl('../assets/runner/pet-footwear-coverage.js'));

test('a face crossing the ankle boundary keeps the exposed leg and restores every original attribute',()=>{
 const geometry=new THREE.BufferGeometry();
 geometry.setAttribute('position',new THREE.Float32BufferAttribute([-.02,.04,0,.02,.20,0,.08,.20,0],3));
 geometry.setAttribute('normal',new THREE.Float32BufferAttribute([0,0,1,0,0,1,0,0,1],3));
 geometry.setAttribute('uv',new THREE.Float32BufferAttribute([0,0,.5,1,1,1],2));geometry.setIndex([0,1,2]);
 const mesh=new THREE.Mesh(geometry),model=new THREE.Group();model.add(mesh);
 const box=new THREE.Box3(new THREE.Vector3(-.1,0,-.1),new THREE.Vector3(.1,.08,.1));
 coverClosedFootwear(model,{feet:{Left:box}}, {style:'shoes_heart',fitted_model_space:true});
 assert.equal(mesh.geometry.index.count,6,'keep a clipped quad instead of deleting the whole leg face');
 const p=mesh.geometry.attributes.position,ids=new Set(mesh.geometry.index.array);
 for(const i of ids)assert.ok(p.getY(i)>=.085-1e-6);
 assert.ok(ids.has(1)&&ids.has(2),'both exposed original vertices remain');
 for(let i=3;i<p.count;i++)assert.ok(mesh.geometry.attributes.uv.getY(i)>0&&mesh.geometry.attributes.uv.getY(i)<1,'interpolate original texture coordinates');
 restoreFootwearCoverage(model);assert.equal(mesh.geometry,geometry);assert.deepEqual(Array.from(geometry.index.array),[0,1,2]);
});
