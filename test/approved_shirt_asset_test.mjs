import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
test('restored shirt keeps the archived approved source intact and contains no oversized cutting solids',()=>{
 const source=readFileSync(new URL('../assets/runner/restart/shirt_love_r2_penguin.glb',import.meta.url));
 assert.equal(createHash('sha256').update(source).digest('hex'),'c98638501ebd2a4be8378b93d7a0af88c0d579919e7cb10031cf301c8fcdfc7f');
 const catalog=JSON.parse(readFileSync(new URL('../assets/runner/restart/catalog.json',import.meta.url)));
 const garment=catalog.wardrobe.find(item=>item.item_key==='shirt_love').variants.find(v=>v.species==='penguin');
 const bytes=readFileSync(new URL('../'+garment.original_asset,import.meta.url));
 const doc=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)));
 assert.ok(doc.meshes.some(m=>m.name.includes('Camiseta cosida continua')),'torso and flipper sleeves share the sewn pattern');
 for(const mesh of doc.meshes)for(const primitive of mesh.primitives){
  const box=doc.accessors[primitive.attributes.POSITION];
  assert.ok([...box.min,...box.max].every(Number.isFinite));
  assert.ok(Math.max(Math.abs(box.min[0]),Math.abs(box.max[0]))<.38,mesh.name+' must fit the original pet');
  assert.ok(box.min[1]>.18&&box.max[1]<.65,mesh.name+' must not include cutting boxes');
  assert.ok(Math.max(Math.abs(box.min[2]),Math.abs(box.max[2]))<.38);
  assert.ok(primitive.attributes.TEXCOORD_0!==undefined,'retain real cloth UVs');
  assert.ok(primitive.attributes.JOINTS_0!==undefined&&primitive.attributes.WEIGHTS_0!==undefined,'clothes must follow the original rig');
 }
});
