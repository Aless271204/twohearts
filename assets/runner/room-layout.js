import * as THREE from 'three';

export const ROOM_LIMITS={left:-1.94,right:1.94,back:-2.32,front:1.04};
export function roomLayer(slot){return ['room_decor','room_mirror','room_shelf'].includes(slot)?'wall':slot==='room_rug'?'rug':'floor';}
export function placementTransform(value,slot){
 const layer=roomLayer(slot),finite=(v,f)=>typeof v==='number'&&Number.isFinite(v)?v:f;
 const x=finite(value?.x,0),z=finite(value?.z,-.8),y=layer==='wall'?finite(value?.y,1.5):0;
 const rotation=Math.round(finite(value?.rotation,0)/90)*90;
 return {x,y,z:layer==='wall'?-2.32:z,rotation:((rotation%360)+360)%360};
}
export function validatePlacement(piece,transform,others=[]){
 const original={position:piece.position.clone(),rotation:piece.rotation.clone()};piece.position.set(transform.x,transform.y,transform.z);piece.rotation.y=THREE.MathUtils.degToRad(transform.rotation);piece.updateMatrixWorld(true);
 const inverseParent=piece.parent?.matrixWorld.clone().invert()??new THREE.Matrix4();
 const box=new THREE.Box3().setFromObject(piece).applyMatrix4(inverseParent),layer=roomLayer(piece.userData.roomSlot);
 piece.position.copy(original.position);piece.rotation.copy(original.rotation);piece.updateMatrixWorld(true);
 if([...box.min.toArray(),...box.max.toArray()].some(v=>!Number.isFinite(v)))return {ok:false,error:'La posición no es válida.'};
 if(box.min.x<ROOM_LIMITS.left||box.max.x>ROOM_LIMITS.right||box.min.z<ROOM_LIMITS.back-.12||box.max.z>ROOM_LIMITS.front||box.max.y>2.63)return {ok:false,error:'Deja el objeto dentro de la habitación.'};
 if(layer==='floor')for(const other of others){
  if(other===piece||roomLayer(other.userData.roomSlot)!=='floor')continue;
  const b=new THREE.Box3().setFromObject(other).applyMatrix4(inverseParent);const overlapX=Math.min(box.max.x,b.max.x)-Math.max(box.min.x,b.min.x),overlapZ=Math.min(box.max.z,b.max.z)-Math.max(box.min.z,b.min.z);
  if(overlapX>.015&&overlapZ>.015)return {ok:false,error:'Ese espacio ya está ocupado por otro mueble.'};
 }
 return {ok:true,box};
}

// Local seat coordinates are authored against the actual seat cushions. These
// are interaction anchors, never a generic centre of the furniture bounding box.
export const ROOM_SEATS={
 nursery_space_special_two:[{position:[0,.35,0],rotation:0}],
 nursery_cars_special_one:[{position:[0,.30,0],rotation:0}],
 nursery_dolls_special_two:[{position:[0,.42,0],rotation:0}],
 nursery_castle_special_two:[{position:[0,.36,0],rotation:0}],
 nursery_worldcup_special_one:[{position:[-.22,.37,.015],rotation:0},{position:[.22,.37,.015],rotation:0}],
 gamer_chair:[{position:[0,.42,.055],rotation:0}],
 space_chair:[{position:[0,.42,.055],rotation:0}],
 cars_bed:[{position:[0,.42,.08],rotation:0}],
 dolls_sofa:[{position:[-.23,.42,.055],rotation:0},{position:[.23,.42,.055],rotation:0}],
 castle_throne:[{position:[0,.42,.055],rotation:0}],
 worldcup_chair:[{position:[0,.42,.055],rotation:0}],
 knights_chair:[{position:[0,.42,.055],rotation:0}],
 sage_heart_chair:[{position:[0,.39,.045],rotation:0}],
 cuddle_chair:[{position:[0,.36,.045],rotation:0}],
 coral_beanbag:[{position:[0,.39,.06],rotation:0}],
 cloud_bed:[{position:[0,.35,.06],rotation:0}],
 artist_desk:[{position:[0,.32,.34],rotation:180}],
};
export function seatsFor(piece){
 const nursery=/^nursery_(gamer|space|cars|dolls|castle|worldcup|knights|cities)_(chair|bed)$/.exec(piece.userData.roomStyle??'');
 const anchors=ROOM_SEATS[piece.userData.roomStyle]??(nursery?[{position:[0,nursery[2]==='chair'?.42:.50,.06],rotation:0}]:[]);
 return anchors.map((seat,index)=>({id:(piece.userData.placementId??piece.name)+':'+index,position:piece.localToWorld(new THREE.Vector3(...seat.position)),rotation:piece.rotation.y+THREE.MathUtils.degToRad(seat.rotation)}));
}

// A small grid path keeps walking pets out of solid furniture. A seat is reached
// through its front approach point, rather than walking through its backrest.
export function roomPath(start,end,obstacles=[],step=.16){
 const bounds=ROOM_LIMITS,w=Math.floor((bounds.right-bounds.left)/step),h=Math.floor((bounds.front-bounds.back)/step);
 const cell=p=>[Math.max(0,Math.min(w-1,Math.floor((p.x-bounds.left)/step))),Math.max(0,Math.min(h-1,Math.floor((p.z-bounds.back)/step)))];
 const index=(x,y)=>y*w+x,point=(x,y)=>new THREE.Vector3(bounds.left+(x+.5)*step,0,bounds.back+(y+.5)*step);
 const blocked=(x,y)=>{const p=point(x,y);return obstacles.some(b=>p.x>b.min.x-.12&&p.x<b.max.x+.12&&p.z>b.min.z-.12&&p.z<b.max.z+.12);};
 const [sx,sy]=cell(start),[ex,ey]=cell(end),origin=index(sx,sy),target=index(ex,ey),queue=[[sx,sy]],parents=new Map([[origin,null]]);
 for(let n=0;n<queue.length;n++){const [x,y]=queue[n],id=index(x,y);if(id===target)break;for(const [xx,yy] of [[x+1,y],[x-1,y],[x,y+1],[x,y-1]]){const ni=index(xx,yy);if(xx<0||yy<0||xx>=w||yy>=h||parents.has(ni)||blocked(xx,yy))continue;parents.set(ni,id);queue.push([xx,yy]);}}
 if(!parents.has(target))return null;const path=[];for(let id=target;id!==null;id=parents.get(id))path.push(point(id%w,Math.floor(id/w)));path.reverse();path.push(new THREE.Vector3(end.x,0,end.z));return path;
}
