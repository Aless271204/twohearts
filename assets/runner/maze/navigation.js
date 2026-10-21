export const STEP_MS=280;
// Face the arrival corridor on the actual route, rather than a fixed world axis.
export function doorFacing(s){
 const start=1+s.size,goal=s.exit.z*s.size+s.exit.x,parents=new Map([[start,null]]),queue=[start];
 for(let i=0;i<queue.length&&!parents.has(goal);i++){
  const cell=queue[i],x=cell%s.size,z=Math.floor(cell/s.size);
  for(const [dx,dz]of [[1,0],[-1,0],[0,1],[0,-1]]){
   const nx=x+dx,nz=z+dz,next=nz*s.size+nx;
   if(nx<0||nz<0||nx>=s.size||nz>=s.size||s.grid[next]||parents.has(next))continue;
   parents.set(next,cell);queue.push(next);
  }
 }
 const before=parents.get(goal);
 return before==null?0:Math.atan2(before%s.size-s.exit.x,Math.floor(before/s.size)-s.exit.z);
}
export function movementDirection(vx,vz,yaw){
 if(Math.hypot(vx,vz)<.2)return null;
 const x=vx*Math.cos(yaw)-vz*Math.sin(yaw),z=-vx*Math.sin(yaw)-vz*Math.cos(yaw);
 return Math.abs(x)>Math.abs(z)?{dx:Math.sign(x),dz:0}:{dx:0,dz:Math.sign(z)};
}
export function nearbyInteraction(state,side){
 const p=state?.players[side];if(!p||p.hp<=0)return null;
 const near=q=>Math.abs(q.x-p.x)+Math.abs(q.z-p.z)<=1;
 const fallen=state.players.find(q=>q.id!==side&&q.hp<=0&&near(q));
 if(fallen&&state.revive>0)return {action:'open',label:'Ayudar',hint:'Ayuda a tu pareja a volver a explorar.'};
 const trap=state.traps.find(q=>!q.used&&near(q));
 if(trap)return {action:'disarm',chest:trap.id,label:'Asegurar',hint:'Grietas delante: asegura el piso antes de pasar.'};
 const bridge=state.bridges?.find(b=>!b.secured&&near(b.plate));
 if(bridge)return {action:'activate',chest:bridge.id,label:'Activar puente',hint:state.mode==='solo'?'Activa la hoja y cruza: tienes 20 segundos.':'Mantén la placa o actívala para ayudar a cruzar.'};
 const chest=state.chests.find(q=>!q.opened&&near(q));
 if(chest)return {action:'open',chest:chest.id,label:chest.lantern?(chest.revealed?'Resolver':'Iluminar'):'Abrir cofre',hint:chest.lantern?'Farolito seguro: ilumina la pista y ordena sus símbolos.':chest.hint==='leaf'?'Hoja verde: un cofre seguro con llave u oro.':'Marcas moradas: puede esconder una sorpresa.'};
 return null;
}
export function objectiveText(state){return state.keys<3?`Enciende los farolitos con hoja · ${state.keys}/3`:'¡Tres farolitos! Regresa a la puerta iluminada.';}
// Only explored cells and their immediate walls are revealed; no hidden prizes.
export class MazeTrail{
 constructor(){this.key='';this.seen=new Set();this.visited=new Set();}
 update(s,side){const key=`${s.seed}:${s.size}`;if(key!==this.key){this.key=key;this.seen.clear();this.visited.clear();}const p=s.players[side];this.visited.add(p.z*s.size+p.x);for(const [dx,dz]of [[0,0],[1,0],[-1,0],[0,1],[0,-1]]){const x=p.x+dx,z=p.z+dz;if(x>=0&&z>=0&&x<s.size&&z<s.size)this.seen.add(z*s.size+x);}}
}

// A compass points to the teammate, never through a fabricated route to treasure.
export function companionBearing(s,side,yaw){
 const p=s.players[side],q=s.players.find(v=>v.id!==side);
 if(!q)return null;
 const distance=Math.abs(q.x-p.x)+Math.abs(q.z-p.z);
 const heading=Math.atan2(q.x-p.x,-(q.z-p.z))+yaw;
 return {distance,angle:Math.atan2(Math.sin(heading),Math.cos(heading)),fallen:q.hp<=0};
}
export function districtAt(s,x,z){return Math.min(2,Math.floor((x+z)/(2*(s.size-1))*3));}
export const DISTRICTS=['Jardín de calabazas','Sendero de luciérnagas','Rincón de la luna'];
