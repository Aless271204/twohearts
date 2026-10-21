import * as THREE from 'three';
import {mergeGeometries,mergeVertices} from './vendor/utils/BufferGeometryUtils.js';
import {buildThemedRoomPiece} from './room-themed-pieces.js';
import {buildChildrenRoomPiece} from './room-children-pieces.js';

// Metres, Y up. Furniture origins sit on the floor; wall pieces face +Z.
// This factory is shared by the room and product renders.
export function createRoomPiece(item, slot) {
  const root=new THREE.Group();root.name=`room:${slot}:${item.style}`;
  root.userData.roomSlot=slot;root.userData.roomStyle=item.style;
  const color=/^#[0-9a-f]{6}$/i.test(item.color)?item.color:'#b8dccb';
  const cream='#fff2df',wood='#c99d70',gold='#d2ab66';
  const materials=new Map();
  function material(c){if(!materials.has(c))materials.set(c,new THREE.MeshStandardMaterial({color:c,roughness:.72,metalness:0}));return materials.get(c);}
  function mesh(g,c,x=0,y=0,z=0){const o=new THREE.Mesh(g,material(c));o.position.set(x,y,z);o.castShadow=true;o.receiveShadow=true;root.add(o);return o;}
  function box(w,h,d,c,x=0,y=0,z=0){return mesh(new THREE.BoxGeometry(w,h,d),c,x,y,z);}
  function soft(rx,ry,rz,c,x=0,y=0,z=0){const o=mesh(new THREE.SphereGeometry(1,28,18),c,x,y,z);o.scale.set(rx,ry,rz);return o;}
  function cylinder(r,h,c,x=0,y=0,z=0){return mesh(new THREE.CylinderGeometry(r,r,h,32),c,x,y,z);}
  function rounded(w,h,d,c,x=0,y=0,z=0,r=.025){
    r=Math.min(r,w/2-.001,h/2-.001,d/2-.001);const s=new THREE.Shape(),l=-w/2+r,b=-h/2+r,rr=w/2-r,t=h/2-r;
    s.moveTo(l-r,b);s.lineTo(l-r,t);s.quadraticCurveTo(l-r,t+r,l,t+r);s.lineTo(rr,t+r);s.quadraticCurveTo(rr+r,t+r,rr+r,t);s.lineTo(rr+r,b);s.quadraticCurveTo(rr+r,b-r,rr,b-r);s.lineTo(l,b-r);s.quadraticCurveTo(l-r,b-r,l-r,b);
    const g=new THREE.ExtrudeGeometry(s,{depth:d-2*r,bevelEnabled:true,bevelSize:r,bevelThickness:r,bevelSegments:3,curveSegments:6});g.translate(0,0,-d/2+r);g.deleteAttribute('normal');g.deleteAttribute('uv');const smooth=mergeVertices(g,1e-6);smooth.computeVertexNormals();g.dispose();return mesh(smooth,c,x,y,z);
  }
  function heart(c,x,y,z,s=.12){const shape=new THREE.Shape();shape.moveTo(0,-.5);shape.bezierCurveTo(-1,.1,-.7,.9,0,.45);shape.bezierCurveTo(.7,.9,1,.1,0,-.5);const o=mesh(new THREE.ExtrudeGeometry(shape,{depth:.08,bevelEnabled:true,bevelSize:.035,bevelThickness:.025,bevelSegments:3,curveSegments:16}),c,x,y,z);o.scale.setScalar(s);return o;}
  const style=item.style;
  if(buildChildrenRoomPiece(style,{mesh,box,soft,cylinder,rounded,heart,color,cream,wood,gold})||buildThemedRoomPiece(style,{mesh,box,soft,cylinder,rounded,heart,color,cream,wood,gold})){
    root.userData.themed=true;
  }else if(style==='sage_heart_chair'){
    for(const x of [-.25,.25])for(const z of [-.18,.18])cylinder(.032,.12,wood,x,.06,z);
    rounded(.69,.20,.57,color,0,.22,0,.065);rounded(.65,.48,.14,color,0,.50,-.24,.06);
    for(const x of [-.30,.30])rounded(.14,.34,.52,color,x,.37,0,.055);
    soft(.26,.065,.22,cream,0,.36,.025);heart('#efa0ab',0,.57,-.13,.13);
    for(const x of [-.19,0,.19])soft(.009,.009,.004,cream,x,.61,-.161);
  }else if(style==='oak_bookshelf'){
    rounded(.70,1.22,.04,wood,0,.68,-.14);rounded(.61,1.10,.012,cream,0,.68,-.112,.004);
    for(const x of [-.33,.33])rounded(.045,1.22,.32,wood,x,.68,0,.012);
    for(const y of [.18,.52,.88,1.23])rounded(.69,.04,.35,wood,0,y,.02);
    for(const x of [-.26,.26])cylinder(.025,.12,wood,x,.06,0);
    for(let i=0;i<7;i++)rounded(.045,.21+(i%3)*.025,.16,[color,'#efa0ab',cream][i%3],-.22+i*.064,.65,.07,.01);
    for(let i=0;i<4;i++)rounded(.18,.035,.17,i%2?color:cream,-.14,.23+i*.038,.08,.009);
    cylinder(.085,.13,cream,.17,1.315,.02);for(let i=0;i<5;i++){const a=i*2.4;const leaf=soft(.035,.10,.018,color,.17+Math.sin(a)*.06,1.45+Math.cos(a)*.025,.02+Math.cos(a)*.05);leaf.rotation.z=Math.sin(a)*.6;}
  }else if(style==='artist_desk'){
    for(const x of [-.32,.32])for(const z of [-.16,.16])cylinder(.022,.48,wood,x,.24,z);
    rounded(.78,.045,.46,wood,0,.50,0);rounded(.22,.006,.19,cream,-.09,.526,.01,.002);
    cylinder(.047,.10,color,.22,.573,-.08);for(let i=0;i<3;i++){const p=cylinder(.004,.14,['#efa0ab',color,wood][i],.20+i*.018,.66,-.08);p.rotation.z=(i-1)*.13;}
    soft(.17,.035,.15,color,0,.28,.34);for(const x of [-.10,.10])for(const z of [.25,.42])cylinder(.014,.245,wood,x,.1225,z);
  }else if(style==='moon_lamp'){
    cylinder(.14,.035,wood,0,.0175,0);cylinder(.014,.58,wood,0,.325,0);
    const moon=new THREE.Shape();moon.moveTo(.12,.19);moon.bezierCurveTo(-.21,.29,-.28,-.24,.11,-.20);moon.bezierCurveTo(-.07,-.12,-.09,.10,.12,.19);
    const g=new THREE.ExtrudeGeometry(moon,{depth:.05,bevelEnabled:true,bevelSize:.012,bevelThickness:.01,bevelSegments:2,curveSegments:20});mesh(g,'#ffe4ac',0,.83,0);
    heart('#efa0ab',.12,.62,0,.045);
  }else if(style==='coral_beanbag'){
    soft(.40,.25,.35,color,0,.25,0);soft(.33,.22,.13,color,0,.43,-.21);soft(.28,.055,.24,cream,0,.37,.035);
    heart('#efa0ab',0,.53,-.055,.075);
  }else if(style==='knit_rug'){
    soft(.68,.018,.46,color,0,.018,0);
    for(let i=0;i<15;i++){const r=.08+i*.04;const torus=mesh(new THREE.TorusGeometry(r,.004,4,80),i%2?cream:color,0,.038,0);torus.rotation.x=-Math.PI/2;torus.scale.y=.67;}
  }else if(style==='oak_side_table'){
    for(let i=0;i<3;i++){const a=i*Math.PI*2/3;const leg=cylinder(.023,.39,wood,Math.sin(a)*.15,.195,Math.cos(a)*.15);leg.rotation.z=Math.sin(a)*-.12;}
    cylinder(.28,.045,wood,0,.415,0);cylinder(.065,.06,cream,.08,.468,0);cylinder(.055,.004,'#705a43',.08,.50,0);
    rounded(.16,.025,.12,color,-.10,.455,-.05,.007);
  }else if(style==='landscape_frame'){
    rounded(.57,.43,.045,wood,0,0,0,.015);rounded(.50,.36,.012,'#d4edf0',0,0,.028,.004);
    const hill=(cx,cy,rx,ry,c,z)=>{const s=new THREE.Shape();const points=[];for(let i=0;i<=32;i++){const a=i*Math.PI/32;points.push([Math.max(-.245,Math.min(.245,cx+rx*Math.cos(a))),cy+ry*Math.sin(a)]);}s.moveTo(points[0][0],-.174);for(const p of points)s.lineTo(...p);s.lineTo(points.at(-1)[0],-.174);s.closePath();mesh(new THREE.ExtrudeGeometry(s,{depth:.004,bevelEnabled:false}),c,0,0,z);};
    hill(-.08,-.10,.19,.10,color,.04);hill(.12,-.11,.17,.13,'#78a77d',.047);soft(.038,.038,.004,'#ffe4ac',.15,.095,.04);
  }else if(style==='heart_planter'){
    mesh(new THREE.CylinderGeometry(.135,.10,.23,24),cream,0,.115,0);cylinder(.12,.01,'#705a43',0,.233,0);heart('#efa0ab',0,.12,.124,.045);
    for(let i=0;i<7;i++){const a=i*2.4,y=.36+(i%3)*.08;const leaf=soft(.045,.12,.025,i%2?color:'#537d60',Math.sin(a)*.10,y,Math.cos(a)*.10);leaf.rotation.set(.4*Math.cos(a),a,-.5*Math.sin(a));}
  }else if(slot==='room_floor'){
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
  const layout=loadout.room_options?.layout?.items;
  const items={room_wall:{style:'sage_panel',color:'#f3e3db'},room_floor:{style:'honey',color:'#d9b17e'},...(!Array.isArray(layout)||!layout.some(i=>i.slot==='room_rug')?{room_rug:{style:'cloud_rug',color:'#fff2df'}}:{}),...Object.fromEntries(Object.entries(loadout).filter(([slot])=>slot.startsWith('room_')&&slot!=='room_options'&&(!Array.isArray(layout)||['room_wall','room_floor','room_ceiling'].includes(slot))))};
  for(const [slot,item] of Object.entries(items)){const piece=createRoomPiece(item,slot);piece.position.fromArray(ROOM_ANCHORS[slot]??[0,0,0]);room.add(piece);if(slot==='room_rug')room.userData.petFloor=new THREE.Box3().setFromObject(piece).max.y;}
  if(Array.isArray(layout))for(const entry of layout.slice(0,40)){
    if(!entry||typeof entry.id!=='string'||!entry.slot?.startsWith('room_')||['room_wall','room_floor','room_ceiling','room_options'].includes(entry.slot)||!entry.appearance)continue;
    if(![entry.x,entry.y,entry.z,entry.rotation].every(Number.isFinite))continue;
    const piece=createRoomPiece(entry.appearance,entry.slot);piece.userData.placementId=entry.id;piece.userData.itemKey=entry.item_key;piece.position.set(entry.x,entry.y,entry.z);piece.rotation.y=THREE.MathUtils.degToRad(entry.rotation);room.add(piece);
  }
  const rugs=room.children.filter(p=>p.userData.roomSlot==='room_rug'),supportRay=new THREE.Raycaster(),supportPoint=new THREE.Vector3();
  room.userData.floorAt=(x,z)=>{room.updateMatrixWorld(true);supportRay.set(room.localToWorld(supportPoint.set(x,3,z)),new THREE.Vector3(0,-1,0));const hit=supportRay.intersectObjects(rugs,true)[0];return hit?room.worldToLocal(hit.point.clone()).y:0;};
  room.userData.petFloor=room.userData.floorAt(0,0);
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
