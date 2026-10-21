import * as THREE from 'three';
import {placementTransform,validatePlacement,roomLayer,seatsFor,roomPath} from './room-layout.js';
import {requestHost} from './bridge.js';

export function createRoomEditor({renderer,camera,onSaved=()=>{}}){
 let room,options={},selected=null,drag=null,busy=false,seat=null,walk=null,position=new THREE.Vector3();
 const ray=new THREE.Raycaster(),pointer=new THREE.Vector2(),hit=new THREE.Vector3();
 const bar=document.createElement('div');bar.className='room-edit-controls';bar.style.cssText='position:fixed;bottom:12px;left:12px;right:12px;z-index:20;display:flex;justify-content:center;gap:8px;flex-wrap:wrap;pointer-events:none';
 const status=document.createElement('span');status.setAttribute('role','status');status.style.cssText='display:block;flex-basis:100%;text-align:center;color:#493c35;font:13px system-ui;background:#fff8f0e8;border-radius:12px;padding:5px';
 function button(label,fn){const b=document.createElement('button');b.textContent=label;b.style.cssText='pointer-events:auto;background:#fff8f0;color:#493c35;border:1px solid #c9a68d;border-radius:16px;padding:10px 15px;font:600 14px system-ui;box-shadow:0 3px 12px #65473618';b.onclick=fn;bar.append(b);return b;}
 const rotate=button('↻ Girar',async()=>{if(!selected||busy)return;const previous=selected.rotation.y,t=placementTransform({x:selected.position.x,y:selected.position.y,z:selected.position.z,rotation:THREE.MathUtils.radToDeg(previous)+90},selected.userData.roomSlot);const result=validatePlacement(selected,t,pieces());if(!result.ok){status.textContent=result.error;return;}selected.rotation.y=THREE.MathUtils.degToRad(t.rotation);await persist(t,()=>selected.rotation.y=previous);});
 const remove=button('Guardar en cofre',async()=>{if(!selected||busy)return;await send('remove',{id:selected.userData.placementId,revision:options.layout?.revision});});
 const stand=button('Levantarse',()=>{const previous=seat;seat=null;walk=previous?.approach?{path:[previous.approach],index:0,next:null}:null;refreshBar();});bar.append(status);document.body.append(bar);
 function pieces(){return room?.children.filter(p=>p.userData.roomSlot&&!['room_wall','room_floor','room_ceiling'].includes(p.userData.roomSlot))??[];}
 function refreshBar(){const editing=options.editing===true&&options.layout?.editable===true;bar.style.display=editing||seat||walk?'flex':'none';rotate.hidden=remove.hidden=!editing;rotate.disabled=remove.disabled=!selected||busy;stand.hidden=!(seat||walk);if(!selected&&!busy)status.textContent=editing?'Toca un mueble para moverlo. Arrastra para colocarlo.':'';}
 async function send(action,data){busy=true;refreshBar();status.textContent='Guardando…';try{const next=await requestHost('room_layout',{p_action:action,p_data:data});if(next.guest)throw Error('La distribución se guarda al entrar desde NIDO.');options={...options,layout:next};onSaved(next);status.textContent='Guardado en vuestro Nido';return true;}catch(e){status.textContent=e.message||'No se pudo guardar. Reintenta.';return false;}finally{busy=false;refreshBar();}}
 async function persist(t,revert){if(!await send('move',{id:selected.userData.placementId,revision:options.layout?.revision,...t}))revert();}
 function aim(e){const rect=renderer.domElement.getBoundingClientRect();pointer.set((e.clientX-rect.left)/rect.width*2-1,-(e.clientY-rect.top)/rect.height*2+1);ray.setFromCamera(pointer,camera);}
 function target(e){aim(e);const found=ray.intersectObjects(pieces(),true)[0];if(!found)return null;let p=found.object;while(p.parent&&p.parent!==room)p=p.parent;return p;}
 function down(e){if(!room||busy)return;const piece=target(e);if(!piece)return;
  const editing=options.editing===true&&options.layout?.editable===true;
  if(editing&&piece.userData.placementId){selected=piece;const original={x:piece.position.x,y:piece.position.y,z:piece.position.z,rotation:THREE.MathUtils.radToDeg(piece.rotation.y)};const wall=roomLayer(piece.userData.roomSlot)==='wall',plane=wall?new THREE.Plane(new THREE.Vector3(0,0,1),2.32):new THREE.Plane(new THREE.Vector3(0,1,0),-room.position.y);if(ray.ray.intersectPlane(plane,hit))drag={plane,original,offset:piece.position.clone().sub(room.worldToLocal(hit.clone())),pointer:e.pointerId,moved:false};renderer.domElement.setPointerCapture(e.pointerId);refreshBar();e.stopImmediatePropagation();
  }else if(!editing){const available=seatsFor(piece);if(available.length){const next=available[0],approach=next.position.clone().add(new THREE.Vector3(Math.sin(next.rotation)*.46,0,Math.cos(next.rotation)*.46));next.approach=approach;const obstacles=pieces().filter(p=>p!==piece&&roomLayer(p.userData.roomSlot)==='floor').map(p=>new THREE.Box3().setFromObject(p));const path=roomPath(position,approach,obstacles);if(!path){status.textContent='Deja un camino libre hasta el asiento.';bar.hidden=false;return;}walk={path,index:0,next};seat=null;refreshBar();e.stopImmediatePropagation();}}
 }
 function move(e){if(!drag||!selected||e.pointerId!==drag.pointer)return;aim(e);if(!ray.ray.intersectPlane(drag.plane,hit))return;const local=room.worldToLocal(hit.clone()).add(drag.offset),t=placementTransform({x:local.x,y:local.y,z:local.z,rotation:THREE.MathUtils.radToDeg(selected.rotation.y)},selected.userData.roomSlot);const result=validatePlacement(selected,t,pieces());status.textContent=result.ok?'Suelta para guardar':result.error;if(result.ok){selected.position.set(t.x,t.y,t.z);drag.moved=true;}e.stopImmediatePropagation();}
 async function up(e){if(!drag||e.pointerId!==drag.pointer)return;const previous=drag.original,moved=drag.moved;drag=null;e.stopImmediatePropagation();if(moved){const t=placementTransform({x:selected.position.x,y:selected.position.y,z:selected.position.z,rotation:THREE.MathUtils.radToDeg(selected.rotation.y)},selected.userData.roomSlot);await persist(t,()=>selected.position.set(previous.x,previous.y,previous.z));}}
 const canvas=renderer.domElement;canvas.addEventListener('pointerdown',down,true);canvas.addEventListener('pointermove',move,true);canvas.addEventListener('pointerup',up,true);canvas.addEventListener('pointercancel',()=>{drag=null;});
 refreshBar();return {
  setRoom(next,nextOptions={}){const selectedId=selected?.userData.placementId;room=next;options=nextOptions;room.updateMatrixWorld(true);selected=pieces().find(p=>p.userData.placementId===selectedId)??null;if(seat){const latest=pieces().flatMap(seatsFor).find(s=>s.id===seat.id);seat=latest?{...latest,approach:seat.approach}:null;}refreshBar();},
  get seated(){return seat!==null;},get walking(){return walk!==null;},
  apply(model,dt,pelvisHeight){
   if(walk){const waypoint=walk.path[walk.index],delta=waypoint.clone().sub(position);delta.y=0;const distance=delta.length(),amount=Math.min(distance,Math.max(0,dt)*.65);if(distance<.04){walk.index++;if(walk.index>=walk.path.length){seat=walk.next;walk=null;refreshBar();}}else{position.addScaledVector(delta,amount/distance);model.rotation.y=Math.atan2(delta.x,delta.z);}model.position.x=position.x;model.position.z=position.z;}
   else if(seat){model.position.set(seat.position.x,seat.position.y+.08-pelvisHeight,seat.position.z);model.rotation.y=seat.rotation;position.copy(model.position);}
   else {model.position.x=position.x;model.position.z=position.z;}
  },
  dispose(){bar.remove();canvas.removeEventListener('pointerdown',down,true);canvas.removeEventListener('pointermove',move,true);canvas.removeEventListener('pointerup',up,true);},
 };
}
