import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
const root=new URL('../',import.meta.url),catalog=JSON.parse(readFileSync(new URL('assets/runner/restart/catalog.json',root)));
function values(doc,bytes,index){
 const a=doc.accessors[index],v=doc.bufferViews[a.bufferView],sizes={SCALAR:1,VEC2:2,VEC3:3,VEC4:4},size={5126:4,5123:2,5121:1}[a.componentType],components=sizes[a.type];
 const offset=28+bytes.readUInt32LE(12)+(v.byteOffset??0)+(a.byteOffset??0),stride=v.byteStride??size*components,result=[];
 for(let i=0;i<a.count;i++){const row=[];for(let j=0;j<components;j++){const k=offset+i*stride+j*size;row.push(a.componentType===5126?bytes.readFloatLE(k):a.componentType===5123?bytes.readUInt16LE(k):bytes.readUInt8(k));}result.push(row);}return result;
}
for(const species of ['penguin','bear','pig','chick'])for(const item of ['shirt_love','jacket_denim','coat_cloud','dress_petal','hoodie_nido'])test(`${species}/${item}: all exported panels attach to the original rig with normalized finite weights`,()=>{
 const v=catalog.wardrobe.find(v=>v.item_key===item)?.variants.find(v=>v.species===species);assert.ok(v?.original_asset.includes('/sewn_'));
 const bytes=readFileSync(new URL(v.original_asset,root));assert.equal(createHash('sha256').update(bytes).digest('hex'),v.original_sha256);assert.equal(bytes.readUInt32LE(8),bytes.length);
 const doc=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12))),known=new Set(JSON.parse(readFileSync(new URL(`design/wardrobe-restart/fitting/${species}-original.json`,root))).boneNames.concat(['NidoLeftSleeve','NidoRightSleeve']));
 assert.ok(doc.images?.length>=2,'cloth includes exported colour and normal maps');assert.ok(doc.meshes.some(m=>m.name.startsWith('Manga adaptada')));
 for(const mesh of doc.meshes){const names=mesh.extras.nidoBoneNames;assert.ok(names.every(n=>known.has(n)),mesh.name);
  for(const p of mesh.primitives){const attrs=p.attributes;assert.ok(attrs.TEXCOORD_0!==undefined&&attrs.NORMAL!==undefined);const joints=values(doc,bytes,attrs.JOINTS_0),weights=values(doc,bytes,attrs.WEIGHTS_0),positions=values(doc,bytes,attrs.POSITION);
   for(let i=0;i<weights.length;i++){assert.ok(positions[i].every(Number.isFinite));assert.ok(weights[i].every(w=>Number.isFinite(w)&&w>=0&&w<=1));assert.ok(Math.abs(weights[i].reduce((a,b)=>a+b,0)-1)<.00001);assert.ok(joints[i].every(j=>j>=0&&j<names.length));}
  }
 }
});
