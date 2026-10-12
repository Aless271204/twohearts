import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {runtimeUrl} from './three-runtime.mjs';
const THREE=await import(runtimeUrl('../assets/runner/vendor/three.module.js'));
const {createRoomPiece,createPetRoom,ROOM_ANCHORS}=await import(runtimeUrl('../assets/runner/room-pieces.js'));
const catalog=JSON.parse(readFileSync(new URL('../assets/runner/room-catalog.json',import.meta.url)));
const legacy=JSON.parse(readFileSync(new URL('../docs/inventory-catalog.json',import.meta.url))).filter(i=>i.scope==='room');
test('published room collections also have an actual 3D piece',()=>{
  assert.equal(legacy.length,24);
  for(const item of legacy){const root=createRoomPiece({style:item.style,color:item.color},item.slot);assert.ok(!new THREE.Box3().setFromObject(root).isEmpty(),item.key);}
});
test('all 20 room products build finite geometry and batch repeated details',()=>{
  assert.equal(catalog.length,20);
  for(const item of catalog){const root=createRoomPiece(item.appearance,item.equip_slot);const bounds=new THREE.Box3().setFromObject(root);assert.ok(!bounds.isEmpty(),item.item_key);assert.ok([...bounds.min.toArray(),...bounds.max.toArray()].every(Number.isFinite));assert.ok(root.children.length<=6,`${item.item_key}: excessive draw calls`);const triangles=root.children.reduce((n,m)=>n+(m.geometry.index?.count??m.geometry.attributes.position.count)/3,0);assert.ok(triangles<20000,`${item.item_key}: too much geometry for a small room product`);}
});
test('walls and floors fill the room; floor furniture sits on the floor outside pet space',()=>{
  for(const item of catalog){const root=createRoomPiece(item.appearance,item.equip_slot);root.position.fromArray(ROOM_ANCHORS[item.equip_slot]);const b=new THREE.Box3().setFromObject(root);if(item.equip_slot==='room_floor'){assert.equal(b.min.x,-2);assert.equal(b.max.x,2);assert.ok(b.min.z<-2.3&&b.max.z>1);}
    if(item.equip_slot==='room_wall'){assert.ok(b.min.y<=0&&b.max.y>=2.69);assert.ok(b.min.x<=-2&&b.max.x>=2);}
    if(['room_bed','room_chair','room_table','room_dresser','room_plant'].includes(item.equip_slot)){assert.ok(Math.abs(b.min.y)<.021,item.item_key);const centre=b.getCenter(new THREE.Vector3());assert.ok(Math.abs(centre.x)>.7,'Furniture must leave the centre clear');}
  }
});
test('replacing a surface replaces rather than layers two walls or floors',()=>{
  const room=createPetRoom({room_floor:{style:'rose_tile',color:'#dba397'},room_wall:{style:'floral',color:'#f6e8dd'}});
  assert.equal(room.children.filter(i=>i.name.startsWith('room:room_wall:')).length,1);assert.equal(room.children.filter(i=>i.name.startsWith('room:room_floor:')).length,1);
});
