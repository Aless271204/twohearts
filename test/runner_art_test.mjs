import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync,statSync} from 'node:fs';
import {Box3,Vector3,Scene} from '../assets/runner/vendor/three.module.js';

async function module(name){
  let source=readFileSync(new URL(`../assets/runner/${name}`,import.meta.url),'utf8');
  const three=JSON.stringify(new URL('../assets/runner/vendor/three.module.js',import.meta.url).href);
  source=source.replace("'three'",three);
  const utils=readFileSync(new URL('../assets/runner/vendor/utils/BufferGeometryUtils.js',import.meta.url),'utf8').replace("'three'",three);
  const utilsURL='data:text/javascript;base64,'+Buffer.from(utils).toString('base64');
  source=source.replace("'three/addons/utils/BufferGeometryUtils.js'",JSON.stringify(utilsURL));
  return import('data:text/javascript;base64,'+Buffer.from(source).toString('base64'));
}

test('coin is one shared mesh with bounded geometry and readable relief',async()=>{
  const {createRunnerCoin}=await module('runner-coin.js');const a=createRunnerCoin(),b=createRunnerCoin();
  assert.equal(a.geometry,b.geometry);assert.equal(a.material,b.material);assert.equal(a.children.length,0);
  assert.ok(a.geometry.attributes.position.count/3<=1100);
  assert.equal(a.geometry.attributes.color.count,a.geometry.attributes.position.count);
  const size=new Box3().setFromObject(a).getSize(new Vector3());
  assert.ok(size.x>.49&&size.x<.6&&size.y>.49&&size.y<.6&&size.z>.09&&size.z<.2);
});
test('backdrop uses two triangles and its animation freezes at zero delta',async()=>{
  const {createForestBackdrop}=await module('forest-backdrop.js');const scene=new Scene(),backdrop=createForestBackdrop(scene);
  assert.equal(scene.children.length,1);const mesh=scene.children[0];assert.equal(mesh.geometry.index.count/3,2);
  backdrop.update(.25,.46,.2);const before=mesh.material.uniforms.time.value;
  backdrop.update(0,.56,0);assert.equal(mesh.material.uniforms.time.value,before);
  assert.equal(mesh.material.uniforms.aspect.value,.56);assert.equal(mesh.material.depthWrite,false);backdrop.dispose();
});
test('packaged runner contains compact local art and the four selectable pet models',()=>{
  const manifest=JSON.parse(readFileSync(new URL('../assets/runner/models.json',import.meta.url),'utf8'));
  let bytes=0;for(const key of ['pip','crate','fence','rock']){
    const file=new URL(`../assets/runner/play-models/${manifest[key]}`,import.meta.url);bytes+=statSync(file).size;
    assert.deepEqual(readFileSync(file),readFileSync(new URL(`../assets/runner/models/${manifest[key]}`,import.meta.url)));
  }
  assert.ok(bytes<25_000_000);
  let pets=0;for(const key of ['bear','pig','chick'])pets+=statSync(new URL(`../assets/runner/play-models/${manifest[key]}`,import.meta.url)).size;
  assert.ok(pets<23_000_000,'Additional pets must stay within the mobile package budget');
  const pubspec=readFileSync(new URL('../pubspec.yaml',import.meta.url),'utf8');
  assert.ok(pubspec.includes('- assets/runner/play-models/'));assert.ok(!pubspec.includes('- assets/runner/models/'));
  const art=readFileSync(new URL('../assets/runner/forest-kingdom.jpg',import.meta.url));assert.ok(art.length<400_000);assert.equal(art.readUInt16BE(0),0xffd8);
  const video=readFileSync(new URL('../assets/runner/forest-kingdom-loop.mp4',import.meta.url));
  assert.ok(video.length<2_500_000);assert.equal(video.toString('ascii',4,8),'ftyp');
  assert.ok(video.indexOf(Buffer.from('moov'))<video.indexOf(Buffer.from('mdat')),'Video metadata must precede frames for local streaming');
});
