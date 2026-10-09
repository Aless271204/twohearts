import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';

const root=new URL('../assets/runner/',import.meta.url);
test('Android permits the two local viewer hosts while public HTTP stays blocked',async()=>{
  const config=await readFile(new URL('../android/app/src/main/res/xml/network_security_config.xml',import.meta.url),'utf8');
  assert.match(config,/<base-config\s+cleartextTrafficPermitted="false"\s*\/>/);
  const local=config.match(/<domain-config\s+cleartextTrafficPermitted="true">([\s\S]*?)<\/domain-config>/)?.[1];
  assert.ok(local,'Local-only cleartext configuration missing');
  assert.match(local,/<domain includeSubdomains="false">localhost<\/domain>/);
  assert.match(local,/<domain includeSubdomains="false">127\.0\.0\.1<\/domain>/);
  assert.equal((local.match(/<domain(?:\s|>)/g)??[]).length,2);
});
test('all supplied models are complete, self-contained GLBs with valid buffers',async()=>{
  const manifest=JSON.parse(await readFile(new URL('models.json',root),'utf8'));
  assert.equal(Object.keys(manifest).length,15);
  for(const [name,file] of Object.entries(manifest)){
    const bytes=await readFile(new URL(`${['bear','pig','chick'].includes(name)?'play-models':'models'}/${file}`,root));
    assert.equal(bytes.toString('ascii',0,4),'glTF',name);
    assert.equal(bytes.readUInt32LE(4),2,name);
    assert.equal(bytes.readUInt32LE(8),bytes.length,name);
    const jsonLength=bytes.readUInt32LE(12);
    assert.equal(bytes.readUInt32LE(16),0x4e4f534a,name);
    const gltf=JSON.parse(bytes.toString('utf8',20,20+jsonLength));
    const binStart=20+jsonLength;
    assert.equal(bytes.readUInt32LE(binStart+4),0x004e4942,name);
    const binLength=bytes.readUInt32LE(binStart);
    assert.equal(binStart+8+binLength,bytes.length,name);
    assert.ok(gltf.meshes.length>0,name);
    assert.ok(gltf.buffers.every(b=>!b.uri),`${name}: external buffer`);
    assert.ok((gltf.images??[]).every(image=>!image.uri),`${name}: external image`);
    for(const view of gltf.bufferViews??[]) assert.ok((view.byteOffset??0)+view.byteLength<=binLength,`${name}: buffer bounds`);
    if(name==='pip'){
      const names=gltf.animations.map(animation=>animation.name);
      for(const animation of ['Running','Walking','Idle_9','Regular_Jump'])assert.ok(names.includes(animation),animation);
      assert.deepEqual(bytes,await readFile(new URL('../assets/models/Meshy_AI_Pip_the_Penguin_All_Animations.glb',import.meta.url)));
    }
  }
});
