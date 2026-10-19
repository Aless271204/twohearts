import {FLOOR,ARENA,WORLD_END} from './config.js';
export function bossFacing(state){
 const alive=state.players.filter(p=>p.hp>0);
 const target=alive.reduce((a,p)=>!a||Math.abs(p.x-state.boss.x)<Math.abs(a.x-state.boss.x)?p:a,null);
 return target&&target.x<state.boss.x?-1:1;
}

// Versioned deterministic attacks. Telegraphs precede damage, including high
// platforms and both arena edges; no distance-based loss of boss aggro.
export function updateAerialThreats(s,emit){
 const alive=s.players.filter(p=>p.hp>0);if(!alive.length)return;
 const hard=s.difficulty==='hard',easy=s.difficulty==='easy';
 if(s.stage==='boss'){
  const b=s.boss;b.facing=bossFacing(s);
  const cadence=hard?66:easy?126:96;
  if(!['expose','ward','sleep'].includes(b.action)&&s.frame%cadence===0){
   for(const p of alive){
    const x=b.x+b.facing*65,y=FLOOR-145,tx=p.x,ty=p.y-22,angle=Math.atan2(ty-y,tx-x),speed=hard?4.8:easy?3.4:4;
    for(const spread of hard?[-.12,0,.12]:[0])s.hazards.push({type:s.chapter==='river'?'bubble':'leaf',x,y,vx:Math.cos(angle+spread)*speed,vy:Math.sin(angle+spread)*speed,life:Math.ceil(Math.hypot(tx-x,ty-y)/speed)+100,delay:hard?30:easy?54:42,targetX:tx,targetY:ty,source:'boss'});
    emit(s,'aerial_warning',tx,ty);
   }
  }
 }else if(s.chapter==='river'){
  const cadence=hard?108:easy?186:144;
  if(s.frame%cadence!==0)return;
  const p=alive[Math.floor(s.frame/cadence)%alive.length],pattern=Math.floor(s.frame/cadence)%3;
  const vx=pattern===0?3.2:pattern===1?-3.2:0;
  const x=Math.max(80,Math.min(ARENA-100,p.x-(vx===0?0:Math.sign(vx)*180)));
  s.hazards.push({type:'fish',x,y:FLOOR+80,vx,vy:hard?-11.6:-10.5,ay:.18,life:145,delay:hard?30:48,source:'water',targetX:x,targetY:FLOOR});
  emit(s,'water_warning',x,FLOOR);
 }
}
