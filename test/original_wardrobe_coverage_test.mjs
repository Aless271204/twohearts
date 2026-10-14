import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {loadPet,runtimeUrl} from './three-runtime.mjs';
const {coverSleeveSkin,restoreSleeveCoverage}=await import(runtimeUrl('../assets/runner/pet-sleeve-coverage.js'));

test('removing the new shirt restores the supplied mesh exactly, including its original texture coordinates and rig weights',async()=>{
 const {scene}=await loadPet('Meshy_AI_Pip_the_Penguin_All_Animations.glb');
 const coverage=JSON.parse(readFileSync(new URL('../assets/runner/restart/shirt-original-coverage-penguin.json',import.meta.url)));
 const snapshots=new Map();
 scene.traverse(mesh=>{if(mesh.isSkinnedMesh)snapshots.set(mesh,{index:Array.from(mesh.geometry.index.array),attributes:Object.fromEntries(Object.entries(mesh.geometry.attributes).map(([name,a])=>[name,Array.from(a.array)])),bones:mesh.skeleton.bones.map(b=>b.name)});});
 coverSleeveSkin(scene,{covered_skin_triangles:coverage});
 let hidden=0;
 for(const [mesh,snapshot] of snapshots){
  hidden+=snapshot.index.length-mesh.geometry.index.count;
  for(const [name,array] of Object.entries(snapshot.attributes))assert.deepEqual(Array.from(mesh.geometry.attributes[name].array).slice(0,array.length),array,name+' original vertices must remain intact');
  assert.deepEqual(mesh.skeleton.bones.map(b=>b.name),snapshot.bones);
  const vertices=mesh.geometry.attributes.position.count;
  for(const vertex of mesh.geometry.index.array)assert.ok(vertex<vertices,'clipped seams must reference valid vertices');
  const weights=mesh.geometry.attributes.skinWeight;
  for(let i=snapshot.attributes.position.length/3;i<vertices;i++){
   const sum=[0,1,2,3].reduce((s,k)=>s+weights.getComponent(i,k),0);
   assert.ok(Math.abs(sum-1)<1e-5,'new cuff-edge weights must stay normalized');
  }
 }
 assert.ok(hidden>0,'the actual shirt coverage must be exercised');
 restoreSleeveCoverage(scene);
 for(const [mesh,snapshot] of snapshots){
  assert.deepEqual(Array.from(mesh.geometry.index.array),snapshot.index,'unequipping must restore every supplied triangle');
  for(const [name,array] of Object.entries(snapshot.attributes))assert.deepEqual(Array.from(mesh.geometry.attributes[name].array),array,'unequipping restores '+name+' exactly');
 }
});

for(const [species,file] of [['bear','bear.glb'],['pig','pig.glb'],['chick','chick.glb']])test(`${species}: every sewn outfit preserves head triangles and restores the supplied body after unequipping`,async()=>{
 const {scene}=await loadPet(file),snapshots=new Map();
 const fitting=JSON.parse(readFileSync(new URL(`../design/wardrobe-restart/fitting/${species}-original.json`,import.meta.url)));
 scene.traverse(mesh=>{if(mesh.isSkinnedMesh)snapshots.set(mesh,{geometry:mesh.geometry,index:Array.from(mesh.geometry.index.array)});});
 for(const item of ['shirt_love','jacket_denim','coat_cloud','dress_petal','hoodie_nido']){
  const name=item==='shirt_love'?`shirt-original-coverage-${species}.json`:`sewn-coverage-${species}-${item}.json`;
  const coverage=JSON.parse(readFileSync(new URL('../assets/runner/restart/'+name,import.meta.url)));coverSleeveSkin(scene,{covered_skin_triangles:coverage});
  for(const [mesh,snapshot]of snapshots){
   const p=snapshot.geometry.attributes,kept=new Set();for(let i=0;i<mesh.geometry.index.count;i+=3)kept.add([0,1,2].map(k=>mesh.geometry.index.getX(i+k)).join(','));
   const source=fitting.meshes.find(m=>m.name===mesh.name);assert.ok(source);
   for(let i=0;i<snapshot.index.length;i+=3){const tri=snapshot.index.slice(i,i+3);const head=tri.some(v=>{let amount=0;for(let k=0;k<4;k++)if(mesh.skeleton.bones[p.skinIndex.getComponent(v,k)].name.endsWith('Head'))amount+=p.skinWeight.getComponent(v,k);return amount>=.90;});
    // A collar can cover the underside of the neck. Every facial triangle
    // above that small contact region must remain exactly the original one.
    if(head)assert.ok(kept.has(tri.join(',')),item+' must preserve the supplied head and lower neck');
   }
  }
  restoreSleeveCoverage(scene);for(const [mesh,snapshot]of snapshots)assert.deepEqual(Array.from(mesh.geometry.index.array),snapshot.index,item+' is reversible');
 }
});
