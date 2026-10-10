import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {runtimeUrl} from '../test/three-runtime.mjs';
const THREE=await import(runtimeUrl('../assets/runner/vendor/three.module.js'));
const {createAccessory}=await import(runtimeUrl('../assets/runner/accessory-pieces.js'));
const catalog=JSON.parse(readFileSync('assets/runner/accessory-catalog.json','utf8'));
mkdirSync('assets/runner/accessories',{recursive:true});
const report=[];
for(const item of catalog){
 const root=createAccessory(item.appearance,item.equip_slot);root.updateMatrixWorld(true);
 const chunks=[],views=[],accessors=[],primitives=[],materials=[];let offset=0,triangles=0;
 const add=(array,type,components,target)=>{
  const b=Buffer.from(array.buffer,array.byteOffset,array.byteLength),view=views.length;
  views.push({buffer:0,byteOffset:offset,byteLength:b.length,target});chunks.push(b);offset+=b.length;
  const pad=(4-offset%4)%4;if(pad){chunks.push(Buffer.alloc(pad));offset+=pad;}
  const accessor={bufferView:view,componentType:type,count:array.length/components,type:components===3?'VEC3':'SCALAR'};
  if(components===3){accessor.min=[Infinity,Infinity,Infinity];accessor.max=[-Infinity,-Infinity,-Infinity];for(let i=0;i<array.length;i++){const c=i%3;accessor.min[c]=Math.min(accessor.min[c],array[i]);accessor.max[c]=Math.max(accessor.max[c],array[i]);}}
  accessors.push(accessor);return accessors.length-1;
 };
 root.traverse(mesh=>{
  if(!mesh.isMesh||!mesh.visible)return;
  const g=mesh.geometry.clone().applyMatrix4(mesh.matrixWorld);if(!g.attributes.normal)g.computeVertexNormals();
  const indices=g.index?Uint32Array.from(g.index.array):Uint32Array.from({length:g.attributes.position.count},(_,i)=>i);
  triangles+=indices.length/3;const m=mesh.material;
  materials.push({name:m.name||item.name,pbrMetallicRoughness:{baseColorFactor:[...m.color.toArray(),m.opacity],roughnessFactor:m.roughness??.6,metallicFactor:m.metalness??0},doubleSided:m.side===THREE.DoubleSide,...(m.transparent?{alphaMode:'BLEND'}:{})});
  primitives.push({attributes:{POSITION:add(Float32Array.from(g.attributes.position.array),5126,3,34962),NORMAL:add(Float32Array.from(g.attributes.normal.array),5126,3,34962)},indices:add(indices,5125,1,34963),material:materials.length-1});
 });
 const binary=Buffer.concat(chunks),doc={asset:{version:'2.0',generator:'NIDO editable accessories'},scene:0,scenes:[{nodes:[0]}],nodes:[{name:item.name,mesh:0}],meshes:[{primitives}],materials,buffers:[{byteLength:binary.length}],bufferViews:views,accessors};
 const json=Buffer.from(JSON.stringify(doc)),jsonPad=Buffer.alloc(Math.ceil(json.length/4)*4,32);json.copy(jsonPad);
 const out=Buffer.alloc(28+jsonPad.length+binary.length);out.writeUInt32LE(0x46546c67,0);out.writeUInt32LE(2,4);out.writeUInt32LE(out.length,8);out.writeUInt32LE(jsonPad.length,12);out.writeUInt32LE(0x4e4f534a,16);jsonPad.copy(out,20);const binOffset=20+jsonPad.length;out.writeUInt32LE(binary.length,binOffset);out.writeUInt32LE(0x004e4942,binOffset+4);binary.copy(out,binOffset+8);
 writeFileSync(item.appearance.model_asset,out);report.push({key:item.item_key,triangles,bytes:out.length});
}
writeFileSync('docs/accessory-model-budget.json',JSON.stringify(report,null,2));
console.log(JSON.stringify({models:report.length,bytes:report.reduce((n,m)=>n+m.bytes,0),maxTriangles:Math.max(...report.map(m=>m.triangles))}));
