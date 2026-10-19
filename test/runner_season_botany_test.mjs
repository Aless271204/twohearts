import test from 'node:test';
import assert from 'node:assert/strict';
import * as THREE from '../assets/runner/vendor/three.module.js';
import {runtimeUrl} from './three-runtime.mjs';
const {createLivingForest} = await import(runtimeUrl('../assets/runner/living-forest.js'));

test('spring includes actual petalled canopy flowers, bank flowers and fruit within the runner camera', () => {
  const scene = new THREE.Scene(), world = createLivingForest(scene);
  world.update(1/60, .6, 0, 1000);
  const blooms = scene.getObjectByName('spring-canopy-blossoms');
  const meadow = scene.getObjectByName('spring-meadow-flowers');
  const fruit = scene.getObjectByName('orchard-fruit');
  assert.equal(blooms.count, 720);
  assert.equal(meadow.count, 192);
  assert.equal(fruit.count, 144);
  for (const mesh of [blooms,meadow,fruit]) {
    assert.ok(mesh.visible);
    assert.ok(mesh.geometry.attributes.color, 'real petal, centre and stem colours');
    assert.ok(Array.from(mesh.instanceMatrix.array).every(Number.isFinite));
  }
  const camera = new THREE.PerspectiveCamera(56, .6, .08, 300);
  camera.position.set(0,2.35,5.8); camera.lookAt(0,.95,-10); camera.updateMatrixWorld(true);
  const frustum = new THREE.Frustum().setFromProjectionMatrix(new THREE.Matrix4().multiplyMatrices(camera.projectionMatrix,camera.matrixWorldInverse));
  const matrix = new THREE.Matrix4(), centre = new THREE.Vector3();
  let visible = 0;
  for (let i=0;i<blooms.count;i++) {
    blooms.getMatrixAt(i,matrix); centre.setFromMatrixPosition(matrix);
    if(frustum.containsPoint(centre))visible++;
    assert.ok(Math.abs(centre.x)>2.6 || centre.y>2.2,'overhanging blooms remain above the pet, keeping lanes legible');
  }
  assert.ok(visible>20,`blossoms must be visible from the actual portrait camera (${visible})`);
  world.dispose();
});

test('four seasons change their actual decorations and review can hold a chosen season while moving', () => {
  const scene = new THREE.Scene(), world = createLivingForest(scene);
  const blooms = scene.getObjectByName('spring-canopy-blossoms'), suns = scene.getObjectByName('summer-sunflowers');
  const fallen = scene.getObjectByName('autumn-leaf-carpet'), snow = scene.getObjectByName('winter-crown-snow');
  world.update(.016,.6,0,1000);
  assert.ok(blooms.visible); assert.ok(!suns.visible && !fallen.visible && !snow.visible);
  world.update(.016,.6,0,3000);
  assert.ok(suns.visible); assert.ok(!fallen.visible && !snow.visible);
  world.update(.016,.6,0,5000);
  assert.ok(fallen.visible); assert.ok(!blooms.visible && !snow.visible);
  world.update(.016,.6,0,7000);
  assert.ok(snow.visible); assert.ok(!blooms.visible && !fallen.visible && !suns.visible);
  world.update(.016,.6,0,9000,1000);
  assert.equal(scene.getObjectByName('seasonal-botany').userData.season,'spring');
  assert.ok(blooms.visible && !snow.visible);
  // The decorative additions share geometry and materials; they add no bitmap
  // downloads and cannot turn into hundreds of individual draw calls.
  const botany = scene.getObjectByName('seasonal-botany');
  assert.equal(botany.children.length,6);
  assert.ok(botany.children.every(m=>m.isInstancedMesh && !m.material.map));
  world.dispose();
});

test('canopy decorations stay attached through wind and the forest looping boundary',()=>{
  const scene=new THREE.Scene(),world=createLivingForest(scene);
  const blooms=scene.getObjectByName('spring-canopy-blossoms');
  let canopy;
  scene.traverse(mesh=>{if(mesh.isInstancedMesh&&mesh.count===144&&mesh.geometry.attributes.color&&mesh.geometry.type==='SphereGeometry'&&mesh.parent.name!=='seasonal-botany')canopy=mesh;});
  assert.ok(canopy);
  const leafMatrix=new THREE.Matrix4(),bloomMatrix=new THREE.Matrix4(),relative=new THREE.Vector3();
  function localAnchor(distance,dt){
    world.update(dt,.6,0,distance,1000);
    canopy.getMatrixAt(0,leafMatrix);blooms.getMatrixAt(0,bloomMatrix);
    return relative.setFromMatrixPosition(bloomMatrix).applyMatrix4(leafMatrix.invert()).clone();
  }
  const originalZ=10+Math.sin(-1)*.9,boundary=144*8+4-originalZ;
  const before=localAnchor(boundary-.02,0),after=localAnchor(boundary+.02,1.3);
  assert.ok(before.distanceTo(after)<1e-4, 'flower must wrap with its own tree, not detach 144m away');
  assert.ok(after.length()>.85 && after.length()<1.1,'flower base stays on the actual canopy surface');
  world.dispose();
});
