import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {limitTextureMemory} from '../assets/runner/texture_budget.js';
import {REVISION,Vector3} from '../assets/runner/vendor/three.module.js';

test('the forest engine is bundled locally at the original pinned revision',()=>{
  assert.equal(REVISION,'180');assert.equal(new Vector3(1,2,3).lengthSq(),14);
  const html=readFileSync(new URL('../assets/runner/index.html',import.meta.url),'utf8');
  const map=JSON.parse(html.match(/<script type="importmap">(.*?)<\/script>/s)[1]);
  assert.deepEqual(map.imports,{three:'./vendor/three.module.js','three/addons/':'./vendor/'});
  assert.ok(!html.includes('https://'));
  for(const file of ['three.core.js','loaders/GLTFLoader.js','utils/SkeletonUtils.js','utils/BufferGeometryUtils.js','LICENSE'])
    assert.ok(readFileSync(new URL(`../assets/runner/vendor/${file}`,import.meta.url),'utf8').length>1000);
});

test('runtime texture budget reduces memory without modifying geometry or animations',()=>{
  const canvases=[];let closed=0,drawn=0;
  const oldDocument=globalThis.document;
  globalThis.document={createElement:()=>{const canvas={getContext:()=>({drawImage(){drawn++;}})};canvases.push(canvas);return canvas;}};
  try{
    const texture={isTexture:true,image:{width:2048,height:2048,close(){closed++;}}};
    const small={isTexture:true,image:{width:256,height:128}};
    const mesh={geometry:{},material:{map:texture,normalMap:texture,roughnessMap:small}};
    const geometry=mesh.geometry,root={animations:['Running','Regular_Jump'],traverse:fn=>fn(mesh)};
    limitTextureMemory(root);
    assert.equal(texture.image.width,512);assert.equal(texture.image.height,512);
    assert.equal(texture.needsUpdate,true);assert.equal(small.image.width,256);
    assert.equal(closed,1);assert.equal(drawn,1);assert.equal(mesh.geometry,geometry);
    assert.deepEqual(root.animations,['Running','Regular_Jump']);
    limitTextureMemory(root);assert.equal(canvases.length,1);
  }finally{globalThis.document=oldDocument;}
});
