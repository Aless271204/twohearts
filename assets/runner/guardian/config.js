export const VERSION=1, FPS=60, FLOOR=440, WORLD_END=7060, ARENA=5900;
export const INPUT={left:1,right:2,jump:4,dodge:8,pulse:16,upgrade:32};
export const DIFFICULTIES={
  easy:{label:'Fácil',hearts:4,enemyHP:5,bossHP:100,warning:78,recovery:180,enemyRate:180,rollSpeed:0,rewardUnits:10},
  medium:{label:'Medio',hearts:3,enemyHP:7,bossHP:145,warning:60,recovery:132,enemyRate:140,rollSpeed:0,rewardUnits:15},
  hard:{label:'Difícil',hearts:3,enemyHP:9,bossHP:195,warning:45,recovery:102,enemyRate:108,rollSpeed:6.3,rewardUnits:25},
};
export const SPECIES=['penguin','bear','pig','chick'];
export const RUNE_X=[ARENA+300,WORLD_END-300];
export const POWERUPS=['heal','heart','shield','power','speed','jump','magnet','slow','link'];
export const ITEM_FRAMES={heal:0,heart:1,shield:2,power:3,speed:4,jump:5,magnet:6,slow:7,coin:8,chest:10,link:11};
export function rng(seed){let x=seed>>>0;return()=>{x=(Math.imul(x,1664525)+1013904223)>>>0;return x/4294967296;};}

// Reachable optional ledges guard the better rewards. The final arena always
// retains two safe ledges; random variation never changes jump distances.
export function createLevel(seed,difficulty){
  const r=rng(seed),platforms=[],coins=[],pickups=[],enemies=[];
  const pits=[[1040,1160],[2570,2710],[4090,4240]];
  let start=0;for(const [a,b] of pits){platforms.push({x:start,y:FLOOR,w:a-start});start=b;}
  platforms.push({x:start,y:FLOOR,w:WORLD_END-start});
  for(const x of [540,1430,2130,3030,3660,4480,5080]){
    platforms.push({x,y:344,w:150});platforms.push({x:x+105,y:266,w:135});
    pickups.push({id:pickups.length,x:x+170,y:242,type:POWERUPS[Math.floor(r()*POWERUPS.length)],used:false});
    for(let j=0;j<5;j++)coins.push({id:coins.length,x:x+120+j*24,y:238,used:false});
  }
  platforms.push({x:5960,y:320,w:180},{x:6710,y:320,w:180});
  for(let x=190;x<5760;x+=65){if(pits.some(([a,b])=>x>a-20&&x<b+20))continue;coins.push({id:coins.length,x,y:400-(r()>.65?24:0),used:false});}
  for(let x=680;x<5680;x+=difficulty==='hard'?245:340){
    if(pits.some(([a,b])=>x>a-60&&x<b+70))continue;
    enemies.push({id:enemies.length,type:Math.floor(r()*6),x,y:FLOOR,hp:DIFFICULTIES[difficulty].enemyHP,origin:x,phase:r()*6,stolen:0,cooldown:60+Math.floor(r()*100)});
  }
  const camps=[1770,3450,5410];
  for(const x of camps)pickups.push({id:pickups.length,x:x+60,y:405,type:'heal',used:false});
  return {platforms,pits,coins,pickups,enemies,camps};
}

// All amounts are even before solo's exact 50% multiplier. Shop payout is only
// granted by the authenticated server after replaying the completed expedition.
export function rewardFor(state){
  if(state.status!=='victory')return 0;
  const units=DIFFICULTIES[state.difficulty].rewardUnits+Math.min(5,Math.floor(state.gold/40));
  return state.mode==='partner'?units*2:units;
}
