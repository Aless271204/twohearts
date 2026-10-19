export const VERSION=2, FPS=60, FLOOR=440, ARENA=7700, WORLD_END=ARENA+1160;
export const BOSS_HOME=ARENA+640;
export const INPUT={left:1,right:2,jump:4,dodge:8,pulse:16,upgrade:32};
export const DIFFICULTIES={
  easy:{label:'Fácil',hearts:5,enemyHP:5,bossHP:100,warning:78,recovery:180,enemyRate:180,rollSpeed:0,rewardUnits:10},
  medium:{label:'Medio',hearts:3,enemyHP:7,bossHP:145,warning:60,recovery:132,enemyRate:140,rollSpeed:0,rewardUnits:15},
  hard:{label:'Difícil',hearts:1,enemyHP:9,bossHP:195,warning:36,recovery:82,enemyRate:86,rollSpeed:7.6,rewardUnits:25},
};
export const SPECIES=['penguin','bear','pig','chick'];
export const RUNE_X=[ARENA+300,WORLD_END-300];
export const POWERUPS=['heal','heart','shield','power','speed','jump','magnet','slow','link'];
export const ITEM_FRAMES={heal:0,heart:1,shield:2,power:3,speed:4,jump:5,magnet:6,slow:7,coin:8,chest:10,link:11};
export function rng(seed){let x=seed>>>0;return()=>{x=(Math.imul(x,1664525)+1013904223)>>>0;return x/4294967296;};}

// Reachable optional ledges guard the better rewards. The final arena always
// retains two safe ledges; random variation never changes jump distances.
export function createLevel(seed,difficulty,chapter='forest'){
  const r=rng(seed),platforms=[],coins=[],pickups=[],enemies=[];
  const availablePowerups=difficulty==='hard'?POWERUPS.filter(type=>!['heal','heart'].includes(type)):POWERUPS;
  const pits=chapter==='river'?[[930,1060],[2350,2490],[3850,4000],[6030,6180],[6900,7020]]:[[1040,1160],[2570,2710],[4090,4240],[6220,6350]];
  let start=0;for(const [a,b] of pits){platforms.push({x:start,y:FLOOR,w:a-start});start=b;}
  platforms.push({x:start,y:FLOOR,w:WORLD_END-start});
  for(const x of [540,1430,2130,3030,3660,4480,5080,5820,6530,7140]){
    platforms.push({x,y:344,w:150});platforms.push({x:x+105,y:266,w:135});
    pickups.push({id:pickups.length,x:x+170,y:242,type:availablePowerups[Math.floor(r()*availablePowerups.length)],used:false});
    for(let j=0;j<5;j++)coins.push({id:coins.length,x:x+120+j*24,y:238,used:false});
  }
  platforms.push({x:ARENA+60,y:320,w:180},{x:ARENA+810,y:320,w:180});
  for(let x=190;x<ARENA-140;x+=65){if(pits.some(([a,b])=>x>a-20&&x<b+20))continue;coins.push({id:coins.length,x,y:400-(r()>.65?24:0),used:false});}
  for(let x=680;x<ARENA-220;x+=difficulty==='hard'?245:340){
    if(pits.some(([a,b])=>x>a-60&&x<b+70))continue;
    enemies.push({id:enemies.length,type:Math.floor(r()*6),x,y:FLOOR,hp:DIFFICULTIES[difficulty].enemyHP,origin:x,phase:r()*6,stolen:0,cooldown:60+Math.floor(r()*100)});
  }
  const camps=chapter==='river'?[1770,3450,5410,7200]:[1770,3450,5410,6900];
  for(const x of difficulty==='hard'?[]:camps)pickups.push({id:pickups.length,x:x+60,y:405,type:'heal',used:false});
  return {platforms,pits,coins,pickups,enemies,camps,currents:chapter==='river'?[[1200,1800],[2850,3400],[4700,5300]]:[]};
}

// Expedition total: 20 remaining loot points per coin; solo earns half.
// Only the server credits a verified victory. Partner settlement splits this
// total between accounts, so the shared wallet never receives it twice.
export function rewardFor(state){
  if(state.status!=='victory')return 0;
  return Math.floor(Math.max(0,Number(state.gold)||0)/(state.mode==='partner'?20:40));
}
