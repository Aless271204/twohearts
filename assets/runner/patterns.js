import {kilometreEvent} from './kilometre-events.js';
// Shared with the reward validator: a free lane always remains available.
export function seedFromSession(id) {
  let h=2166136261;for(const c of String(id))h=Math.imul(h^c.charCodeAt(0),16777619);
  return h>>>0;
}
export function roll(seed,row,salt){let x=(seed^Math.imul(row+1,0x9e3779b9)^salt)>>>0;x^=x>>>16;x=Math.imul(x,0x85ebca6b);x^=x>>>13;return (x>>>0);}
export function runnerRow(row, distance, version=3, seed=0) {
  if(version>=11){
    const base=runnerRow(row,distance,10,seed),event=kilometreEvent(distance),rollValue=roll(seed,row,173)%100;
    if(!event.km)return base;
    const safeLane=base.safeLane,extra=rollValue<Math.min(85,18+event.km*6);
    const obstacleLanes=extra?[0,1,2].filter(lane=>lane!==safeLane):base.obstacleLanes;
    const kinds={rocks:'rock',fences:'fence',leaves:'rock',ice:'rock',collapse:'collapse',trees:rollValue<45?'tree':'collapse'};
    return {...base,obstacleLanes,kind:rollValue<70?(kinds[event.id]??base.kind):base.kind};
  }
  if(version>=10){
    const base=runnerRow(row,distance,9,seed),hazard=roll(seed,row,131)%100;
    const kind=distance>=10000&&hazard<28?'tree':distance>=8000&&hazard<58?'collapse':['crate','rock','fence'][roll(seed,row,29)%3];
    return {...base,kind};
  }
  if(version>=9){
    const base=runnerRow(row,distance,8,seed),tier=Math.max(0,Math.floor((distance-2000)/1000));
    const safeLane=(base.obstacleLane+1+roll(seed,row,101)%2)%3;
    const double=tier>0&&roll(seed,row,103)%100<Math.min(78,22+tier*9);
    const obstacleLanes=double?[0,1,2].filter(lane=>lane!==safeLane):[base.obstacleLane];
    return {...base,safeLane,obstacleLanes,kind:distance>=2000&&roll(seed,row,107)%100<Math.min(65,30+tier*5)?'collapse':base.kind};
  }
  if(version>=7){
    const obstacleLane=roll(seed,row,7)%3;
    const coinLane=distance<160?(obstacleLane+1+roll(seed,row,17)%2)%3:roll(seed,row,19)%3;
    const count=3+roll(seed,row,43)%5,shape=roll(seed,row,47)%3;
    const coins=Array.from({length:count},(_,i)=>({lane:coinLane,z:-60-i*3.4,y:shape===0?.7:shape===1?(Math.abs(i-(count-1)/2)<1.1?1.8:.7):i%2?1.6:.7}));
    return {obstacleLane,kind:version>=8&&distance>=1500&&roll(seed,row,71)%4===0?'collapse':['crate','rock','fence'][roll(seed,row,29)%3],coinLane,alternateLane:(coinLane+1)%3,coins};
  }
  if(version<3)return {obstacleLane:row%3,kind:['crate','fence','rock'][row%3],coinLane:row%3,alternateLane:(row+1)%3};
  const sequence=[0,2,1,2,0,1,0,2,2,1,0,1];
  const obstacleLane=sequence[row%sequence.length];
  const coinLane=distance<180?(obstacleLane+1)%3:row%4===0?obstacleLane:(obstacleLane+2)%3;
  return {obstacleLane,kind:['crate','rock','fence','rock'][row%4],coinLane,alternateLane:(coinLane+1)%3};
}
