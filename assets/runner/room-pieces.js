import * as THREE from 'three';
import {mergeGeometries} from './vendor/utils/BufferGeometryUtils.js';

// Metres, Y up. Furniture origins sit on the floor; wall pieces face +Z.
// This factory is shared by the room and product renders.
export function createRoomPiece(item, slot) {
  const root=new THREE.Group();root.name=`room:${slot}:${item.style}`;
  const color=/^#[0-9a-f]{6}$/i.test(item.color)?item.color:'#b8dccb';
  const cream='#fff2df',wood='#c99d70',gold='#d2ab66';
  const materials=new Map();
  function material(c){if(!materials.has(c))materials.set(c,new THREE.MeshStandardMaterial({color:c,roughness:.72,metalness:0}));return materials.get(c);}
  function mesh(g,c,x=0,y=0,z=0){const o=new THREE.Mesh(g,material(c));o.position.set(x,y,z);o.castShadow=true;o.receiveShadow=true;root.add(o);return o;}
  function box(w,h,d,c,x=0,y=0,z=0){return mesh(new THREE.BoxGeometry(w,h,d),c,x,y,z);}
  function soft(rx,ry,rz,c,x=0,y=0,z=0){const o=mesh(new THREE.SphereGeometry(1,28,18),c,x,y,z);o.scale.set(rx,ry,rz);return o;}
  function cylinder(r,h,c,x=0,y=0,z=0){return mesh(new THREE.CylinderGeometry(r,r,h,32),c,x,y,z);}
  function heart(c,x,y,z,s=.12){const shape=new THREE.Shape();shape.moveTo(0,-.5);shape.bezierCurveTo(-1,.1,-.7,.9,0,.45);shape.bezierCurveTo(.7,.9,1,.1,0,-.5);const o=mesh(new THREE.ExtrudeGeometry(shape,{depth:.08,bevelEnabled:true,bevelSize:.035,bevelThickness:.025,bevelSegments:3,curveSegments:16}),c,x,y,z);o.scale.setScalar(s);return o;}
  const style=item.style;
  if(slot==='room_floor'){
    box(4,.06,3.5,color,0,-.03,-.65);
    if(style==='rose_tile'){for(let x=-1.995;x<1.995;x+=.4)box(.009,.002,3.5,'#fff2df',x,.002,-.65);for(let z=-2.395;z<1.095;z+=.4)box(4,.002,.009,'#fff2df',0,.002,z);}
    else{for(let z=-2.397;z<1.097;z+=.18){box(4,.002,.006,'#b8936d',0,.002,z);const length=Math.min(.18,1.097-z);for(let x=-1.65+(Math.abs(Math.round(z/.18))%2)*.4;x<1.997;x+=.8)box(.005,.002,length,'#b8936d',x,.002,z+length/2);}}
  }else if(slot==='room_wall'){
    box(4,2.7,.08,color,0,1.35,-2.4);box(.08,2.7,3.5,color,-2,1.35,-.65);box(.08,2.7,3.5,color,2,1.35,-.65);
    for(const x of [-1.98,1.98])box(.025,.12,3.5,cream,x,.06,-.65);box(4,.12,.025,cream,0,.06,-2.34);
    if(style==='sage_panel'){for(let x=-1.9;x<2;x+=.35)box(.018,1.25,.025,cream,x,.69,-2.34);box(4,.05,.025,cream,0,1.32,-2.34);}
    if(style==='floral'){for(let y=.45;y<2.6;y+=.36)for(let x=-1.8;x<1.9;x+=.38){for(let i=0;i<5;i++){const a=i*Math.PI*2/5;mesh(new THREE.CircleGeometry(.034,16),'#e8b5c4',x+Math.sin(a)*.038,y+Math.cos(a)*.038,-2.345);}mesh(new THREE.CircleGeometry(.013,16),cream,x,y,-2.335);}}
  }else if(slot==='room_rug'){
    soft(.69,.025,.46,color,0,.026,0);
    if(style==='cloud_rug')for(const x of [-.46,-.23,0,.23,.46])soft(.25,.025,.38,color,x,.026,0);
    else for(let i=0;i<8;i++){const a=i*Math.PI/4;soft(.14,.012,.14,cream,Math.sin(a)*.51,.049,Math.cos(a)*.32);}
  }else if(slot==='room_bed'||slot==='room_chair'){
    const chair=slot==='room_chair';soft(.43,.09,.34,wood,0,.10,0);soft(.44,.13,.35,color,0,.22,0);soft(.36,.08,.28,cream,0,.29,.015);
    soft(.43,chair?.34:.15,.095,color,0,chair?.47:.33,-.25);
    for(const x of [-.35,.35])soft(.085,chair?.21:.13,.28,color,x,chair?.36:.29,0);
    heart('#efa0ab',0,chair?.48:.32,-.13,.09);
  }else if(slot==='room_table'){
    for(const x of [-.24,.24])for(const z of [-.17,.17])cylinder(.035,.38,wood,x,.19,z);
    soft(.38,.045,.28,color,0,.42,0);heart('#f05280',0,.47,0,.075).rotation.x=-Math.PI/2;
  }else if(slot==='room_dresser'){
    for(const x of [-.29,.29])for(const z of [-.17,.17])cylinder(.025,.12,wood,x,.06,z);
    box(.72,.57,.42,color,0,.4,0);box(.76,.04,.46,wood,0,.705,0);
    for(const y of [.22,.4,.58]){box(.64,.15,.025,cream,0,y,.22);soft(.025,.018,.018,gold,0,y,.244);}
  }else if(slot==='room_plant'){
    mesh(new THREE.CylinderGeometry(.13,.10,.25,32),style==='plant'?color:cream,0,.125,0);cylinder(.12,.02,'#705a43',0,.253,0);heart('#f05280',0,.13,.117,.05);
    for(let i=0;i<9;i++){const a=i*2.4,y=.36+(i%4)*.11;const leaf=soft(.065,.17,.025,i%2?'#78a77d':'#537d60',Math.sin(a)*.15,y,Math.cos(a)*.15);leaf.rotation.set(.4*Math.cos(a),a,-.45*Math.sin(a));cylinder(.009,y, '#537d60',0,y/2+.2,0);}
  }else if(slot==='room_decor'){
    box(.43,.43,.045,wood);box(.37,.37,.012,cream,0,0,.027);heart(color,0,0,.035,.18);
  }else if(slot==='room_mirror'){
    soft(.24,.38,.035,wood);soft(.208,.345,.008,'#c8dfdf',0,0,.035);
  }else if(slot==='room_shelf'){
    box(.75,.045,.24,wood);for(const x of [-.27,.27])box(.025,.12,.16,gold,x,-.08,-.01);
    for(let i=0;i<4;i++)box(.055,.16+i*.018,.1,['#efa0ab','#b8dccb','#baa2db',cream][i],-.22+i*.065,.11,-.025);
    box(.17,.2,.035,cream,.20,.125,-.05);heart('#efa0ab',.20,.13,-.025,.05);
  }else if(slot==='room_lamp'){
    cylinder(.17,.04,wood,0,.02,0);cylinder(.016,.82,wood,0,.45,0);mesh(new THREE.CylinderGeometry(.16,.23,.25,32),color,0,.96,0);
  }else if(slot==='room_ceiling'){
    if(style==='beams'){for(const x of [-1.3,0,1.3])box(.10,.12,3.4,wood,x,0,-.65);}
    else if(style==='lights'){for(let i=0;i<15;i++){const x=-1.8+i*.257,y=-.12-.25*(1-(x/1.8)**2);cylinder(.008,.12,wood,x,y,0);soft(.035,.045,.035,'#ffe4ac',x,y-.08,0);}}
    else if(style==='mobile'){box(.65,.025,.025,wood);for(let i=0;i<5;i++){const x=-.28+i*.14,y=-.2-(i%3)*.12;cylinder(.003,-y,gold,x,y/2,0);heart(i%2?color:gold,x,y,0,.055);}}
    else{cylinder(.008,.24,wood,0,-.12,0);if(style==='petal')for(let i=0;i<7;i++){const a=i*Math.PI*2/7;soft(.14,.085,.14,color,Math.sin(a)*.18,-.28,Math.cos(a)*.18);}else for(const x of [-.2,0,.2])soft(.18,.115,.14,cream,x,-.29,0);soft(.11,.045,.11,'#ffe4ac',0,-.35,0);}
  }else throw new Error(`Artículo de habitación sin modelo: ${slot}/${style}`);
  // Merge only within an item: editing/removing another item stays independent.
  root.updateMatrixWorld(true);const batches=new Map();
  for(const part of [...root.children]){let geometry=part.geometry.clone().applyMatrix4(part.matrixWorld);if(geometry.index){const indexed=geometry;geometry=indexed.toNonIndexed();indexed.dispose();}geometry.deleteAttribute('uv');if(!batches.has(part.material))batches.set(part.material,[]);batches.get(part.material).push(geometry);part.geometry.dispose();root.remove(part);}
  for(const [mat,geometries] of batches){const joined=mergeGeometries(geometries,false);if(!joined)throw new Error('No pudimos construir el artículo de habitación');const part=new THREE.Mesh(joined,mat);part.castShadow=true;part.receiveShadow=true;root.add(part);for(const geometry of geometries)geometry.dispose();}
  return root;
}

export const ROOM_ANCHORS={room_wall:[0,0,0],room_floor:[0,0,0],room_rug:[0,0,.05],room_bed:[-.98,0,-.78],room_chair:[.98,0,-1.05],room_table:[1.23,0,.25],room_dresser:[.88,0,-2.06],room_plant:[-1.35,0,-1.75],room_lamp:[1.58,0,-1.5],room_decor:[.90,1.63,-2.33],room_mirror:[-1.10,1.64,-2.33],room_shelf:[.90,1.17,-2.23],room_ceiling:[0,2.60,-1.0]};

export function createPetRoom(loadout={}){
  const room=new THREE.Group();room.name='pet-room';
  const items={room_wall:{style:'sage_panel',color:'#f3e3db'},room_floor:{style:'honey',color:'#d9b17e'},room_rug:{style:'cloud_rug',color:'#fff2df'},...Object.fromEntries(Object.entries(loadout).filter(([slot])=>slot.startsWith('room_')))};
  for(const [slot,item] of Object.entries(items)){const piece=createRoomPiece(item,slot);piece.position.fromArray(ROOM_ANCHORS[slot]??[0,0,0]);room.add(piece);if(slot==='room_rug')room.userData.petFloor=new THREE.Box3().setFromObject(piece).max.y;}
  // Architectural trim and daylight window are part of the room, not overlays.
  const trim=new THREE.MeshStandardMaterial({color:'#fff2df',roughness:.7});
  const addBox=(w,h,d,x,y,z,mat=trim)=>{const o=new THREE.Mesh(new THREE.BoxGeometry(w,h,d),mat);o.position.set(x,y,z);o.castShadow=true;o.receiveShadow=true;room.add(o);};
  const sky=new THREE.MeshBasicMaterial({color:'#d4edf0'});addBox(.63,.77,.022,-.92,1.83,-2.335,sky);
  for(const x of [-1.26,-.92,-.58])addBox(.035,.85,.075,x,1.83,-2.30);
  for(const y of [1.40,1.83,2.26])addBox(.72,.035,.075,-.92,y,-2.30);
  addBox(.80,.06,.18,-.92,1.39,-2.24);
  addBox(4,.08,.10,0,2.63,-2.31);
  addBox(4,.06,3.5,0,2.73,-.65);room.children.at(-1).castShadow=false;
  return room;
}
