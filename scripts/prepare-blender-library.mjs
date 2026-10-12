// Uses the same geometry factory as the app, not replacement furniture.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
import {runtimeUrl} from '../test/three-runtime.mjs';
const {createRoomPiece,createPetRoom}=await import(runtimeUrl('../assets/runner/room-pieces.js'));
const repo=fileURLToPath(new URL('../',import.meta.url));
const output=new URL('../design/blender/',import.meta.url);mkdirSync(output,{recursive:true});
const read=name=>JSON.parse(readFileSync(new URL('../'+name,import.meta.url),'utf8'));
const items=[];
function asset(id,name,category,path){const bytes=readFileSync(new URL('../'+path,import.meta.url));items.push({id,name,category,path,sha256:createHash('sha256').update(bytes).digest('hex'),status:'source_for_editing'});}
for(const [id,name,file] of [['penguin','Pingüino','Meshy_AI_Pip_the_Penguin_All_Animations.glb'],['bear','Oso','bear.glb'],['pig','Cerdito','pig.glb'],['chick','Pollito','chick.glb']])asset(id,name,'pets','assets/runner/play-models/'+file);
for(const item of read('assets/runner/head-models.json'))asset('meshy_'+item.item_key,item.name+' · Meshy original','meshy_heads',item.appearance.model_asset);
for(const item of read('assets/runner/accessory-catalog.json'))if(item.appearance.model_asset)asset(item.item_key,item.name+' · catálogo previo','accessories',item.appearance.model_asset);
// Landscape library: use authored GLBs, no duplicated optimized copies.
const {readdirSync}=await import('node:fs');
for(const file of readdirSync(new URL('../assets/runner/models/',import.meta.url)))if(file.endsWith('.glb')&&!file.includes('Pip_the'))asset('landscape_'+file.replace(/\.glb$/,'').replace(/[^a-zA-Z0-9]+/g,'_'),file.replace(/\.glb$/,''),'landscape','assets/runner/models/'+file);
function geometry(root){root.updateMatrixWorld(true);const meshes=[];root.traverse(o=>{if(!o.isMesh)return;const g=o.geometry,p=g.attributes.position,n=g.attributes.normal,uv=g.attributes.uv;const m=Array.isArray(o.material)?o.material[0]:o.material;meshes.push({name:o.name||'Mesh',matrix:o.matrixWorld.toArray(),positions:Array.from(p.array),normals:n?Array.from(n.array):null,uv:uv?Array.from(uv.array):null,indices:g.index?Array.from(g.index.array):Array.from({length:p.count},(_,i)=>i),material:{color:m.color?.toArray()??[1,1,1],roughness:m.roughness??1,metalness:m.metalness??0}});});return meshes;}
for(const item of read('assets/runner/room-catalog.json'))items.push({id:item.item_key,name:item.name,category:'room',slot:item.equip_slot,meshes:geometry(createRoomPiece(item.appearance,item.equip_slot)),status:'same_geometry_as_app'});
items.push({id:'room_base',name:'Habitación · arquitectura actual',category:'room_scene',meshes:geometry(createPetRoom()),status:'same_geometry_as_app'});
writeFileSync(new URL('library.json',output),JSON.stringify({schema:1,repo,items,notes:['No fitted asset is approved by this import.','Original GLBs remain unchanged.','Room geometry is generated from the app factory.']},null,2));
console.log(JSON.stringify({items:items.length,counts:items.reduce((a,i)=>(a[i.category]=(a[i.category]??0)+1,a),{})}));
