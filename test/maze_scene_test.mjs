import test from 'node:test';import assert from 'node:assert/strict';
import * as T from '../assets/runner/vendor/three.module.js';
import {runtimeUrl} from './three-runtime.mjs';
import {createMaze,publicMaze} from '../assets/runner/maze/engine.js';
const {MazeScene}=await import(runtimeUrl('../assets/runner/maze/scene.js'));
// Inspect the actual scene builder without pretending this is a GPU screenshot.
globalThis.document={createElement(){return {width:384,height:128,getContext(){return {fillText(){}};}};}};
test('actual garden geometry builds all lanterns and bridges within a mobile geometry budget',()=>{
 const scene=Object.create(MazeScene.prototype);Object.assign(scene,{world:new T.Group(),scene:new T.Scene(),camera:new T.PerspectiveCamera(),chests:new Map(),traps:new Map(),stations:new Map(),bridges:new Map()});
 const s=publicMaze(createMaze(17,'hard'));scene.build(s,0);assert.equal(scene.stations.size,3);assert.equal(scene.bridges.size,1);
 let triangles=0,instances=0,geometryCount=0;scene.world.traverse(o=>{if(!o.isMesh)return;geometryCount++;const n=o.geometry.index?.count??o.geometry.attributes.position.count;triangles+=n/3*(o.isInstancedMesh?o.count:1);if(o.isInstancedMesh)instances++;assert.ok(Number.isFinite(o.position.x+o.position.y+o.position.z));for(const v of o.geometry.attributes.position.array)assert.ok(Number.isFinite(v));});
 assert.ok(instances>=7);assert.ok(geometryCount<220,geometryCount+' drawables');assert.ok(triangles<700000,triangles+' triangles');
 scene.clearWorld();assert.equal(scene.world.children.length,0);assert.equal(scene.stations.size,0);
});
test('old clients create a compatible classic room while new clients get lantern puzzles',()=>{
 const old=createMaze(4,'easy','solo','halloween',1),current=createMaze(4);assert.equal(old.version,1);assert.equal(old.bridges.length,0);assert.ok(old.chests.every(c=>!c.lantern));assert.equal(current.version,2);
});
