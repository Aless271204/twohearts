import {DIFFICULTIES,INPUT,FLOOR,ARENA,WORLD_END,BOSS_HOME,SPECIES,RUNE_X,createLevel,rewardFor} from './config.js';
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const near=(a,b,dx,dy)=>Math.abs(a.x-b.x)<dx&&Math.abs(a.y-b.y)<dy;
export function createGame(seed=1,difficulty='easy',mode='solo',species=['penguin','bear'],chapter='forest'){
  if(!DIFFICULTIES[difficulty]||!['solo','partner'].includes(mode))throw Error('Configuración inválida');
  if(!['forest','river'].includes(chapter))throw Error('Capítulo inválido');
  const d=DIFFICULTIES[difficulty],level=createLevel(seed,difficulty,chapter);
  return {version:2,chapter,seed:seed>>>0,difficulty,mode,frame:0,status:'playing',stage:'path',gold:0,upgrades:0,checkpoint:90,level,shots:[],hazards:[],events:[],sigils:[-9999,-9999],boss:{x:BOSS_HOME,y:FLOOR,hp:d.bossHP*(mode==='partner'?1.6:1)*(chapter==='river'?1.2:1),maxHP:d.bossHP*(mode==='partner'?1.6:1)*(chapter==='river'?1.2:1),action:'sleep',timer:0,cycle:0,phase:1,rolls:0,vx:0},
    players:Array.from({length:mode==='partner'?2:1},(_,i)=>({id:i,species:SPECIES.includes(species[i])?species[i]:SPECIES[i],x:90+i*48,y:FLOOR,vx:0,vy:0,facing:1,hp:d.hearts,maxHP:d.hearts,ground:true,coyote:7,buffer:0,previous:0,invulnerable:0,dash:0,dashCooldown:0,attackCooldown:0,buffs:{},rescue:0,revives:0}))};
}
function event(s,type,x,y){s.eventSeq=(s.eventSeq??0)+1;s.events.push({id:s.eventSeq,type,x,y,frame:s.frame});}
function damage(s,p,source){
  if(p.hp<=0||p.invulnerable>0||p.dash>0)return false;
  if(p.buffs.shield>0){p.buffs.shield=0;p.invulnerable=36;event(s,'shield',p.x,p.y-25);return false;}
  p.hp--;p.invulnerable=78;p.vy=-3;p.rescue=0;
  if(source?.type===0){const n=Math.min(6,s.gold);s.gold-=n;source.stolen+=n;event(s,'theft',p.x,p.y-30);}
  if(source?.type===1)p.buffs.sluggish=180;
  if(source?.type===4){p.buffs.power=0;p.buffs.magnet=0;}
  event(s,'hurt',p.x,p.y-25);return true;
}
function pickup(s,p,item){
  if(item.type==='coin'){s.gold++;return;}
  switch(item.type){
    case 'heal':p.hp=Math.min(p.maxHP,p.hp+1);break;
    case 'heart':p.maxHP=Math.min(6,p.maxHP+1);p.hp=Math.min(p.maxHP,p.hp+1);break;
    case 'shield':p.buffs.shield=1;break;
    case 'link':for(const q of s.players)q.buffs.link=480;break;
    default:p.buffs[item.type]=600;
  }
  event(s,'pickup',item.x,item.y);
}
function pulse(s,p){
  if(s.stage==='boss'&&s.boss.action==='ward'){
    const side=Math.abs(p.x-RUNE_X[0])<Math.abs(p.x-RUNE_X[1])?0:1;
    if(Math.abs(p.x-RUNE_X[side])<100){
      s.sigils[side]=s.frame;
      // Solo keeps a rune lit long enough to cross via the upper ledges.
      const window=s.players.filter(q=>q.hp>0).length===1?420:80;
      if(s.sigils.every(t=>s.frame-t<=window)){s.boss.wardLocked=false;s.boss.action='expose';s.boss.timer=DIFFICULTIES[s.difficulty].recovery+60;event(s,'link',s.boss.x,s.boss.y-100);}
    }
  }
  let target=s.level.enemies.filter(e=>e.hp>0&&Math.abs(e.x-p.x)<420).sort((a,b)=>Math.abs(a.x-p.x)-Math.abs(b.x-p.x))[0];
  if(!target&&s.stage==='boss')target={x:s.boss.x,y:s.boss.y-45};
  const x=p.x+p.facing*16,y=p.y-26;
  const tx=target?target.x-x:p.facing*100,ty=target?target.y-20-y:0,len=Math.max(1,Math.hypot(tx,ty));
  s.shots.push({x,y,vx:tx/len*8,vy:ty/len*8,life:75,owner:p.id,power:4+s.upgrades*1.5+(p.buffs.power>0?3:0)});
  event(s,'pulse',x,y);
}
function updatePlayer(s,p,mask){
  const pressed=mask&~p.previous;p.previous=mask;
  for(const key of ['invulnerable','dashCooldown','attackCooldown'])p[key]=Math.max(0,p[key]-1);
  for(const key of Object.keys(p.buffs))if(!['shield'].includes(key))p.buffs[key]=Math.max(0,p.buffs[key]-1);
  if(p.hp<=0)return;
  if(pressed&INPUT.jump)p.buffer=7;else p.buffer=Math.max(0,p.buffer-1);
  p.coyote=p.ground?7:Math.max(0,p.coyote-1);
  const direction=(mask&INPUT.right?1:0)-(mask&INPUT.left?1:0);
  if(direction)p.facing=direction;
  const speed=(p.buffs.speed>0?4.5:3.1)*(p.buffs.sluggish>0?.58:1)*(s.difficulty==='hard'?1.18:1);
  p.vx=direction*speed;
  if((pressed&INPUT.dodge)&&p.dashCooldown===0){p.dash=13;p.dashCooldown=52;event(s,'dash',p.x,p.y-14);}
  if(p.dash>0){p.dash--;p.vx=p.facing*7.2*(s.difficulty==='hard'?1.18:1);}
  if(p.buffer>0&&(p.coyote>0||p.buffs.jump>0&&!p.extraJump)){p.vy=-10.8;p.ground=false;p.buffer=0;p.extraJump=p.coyote<=0;p.coyote=0;event(s,'jump',p.x,p.y);}
  if(!(mask&INPUT.jump)&&p.vy<-4)p.vy=-4;
  const previousY=p.y;p.vy=Math.min(12,p.vy+.46);p.x=clamp(p.x+p.vx,s.stage==='boss'?ARENA:15,WORLD_END-25);p.y+=p.vy;p.ground=false;
  const teammate=s.players.find(q=>q.id!==p.id&&q.hp>0);
  if(teammate)p.x=clamp(p.x,teammate.x-680,teammate.x+680);
  for(const platform of s.level.platforms){if(p.vy>=0&&previousY<=platform.y+.01&&p.y>=platform.y&&p.x+11>platform.x&&p.x-11<platform.x+platform.w){p.y=platform.y;p.vy=0;p.ground=true;p.extraJump=false;}}
  if(p.y>610){damage(s,p);p.x=s.stage==='boss'?ARENA+120:s.checkpoint;p.y=FLOOR-65;p.vy=0;}
  if((mask&INPUT.pulse)&&p.attackCooldown===0){
    const down=s.players.find(q=>q.hp<=0&&Math.abs(q.x-p.x)<65&&Math.abs(q.y-p.y)<60&&q.revives<2);
    if(down){down.rescue++;if(down.rescue>=75){down.hp=1;down.rescue=0;down.revives++;down.invulnerable=150;event(s,'rescue',down.x,down.y-25);}}
    else{pulse(s,p);p.attackCooldown=s.difficulty==='hard'?17:20;}
  }
  const camp=p.ground&&Math.abs(p.y-FLOOR)<2?s.level.camps.find(x=>Math.abs(p.x-x)<90):undefined;
  if(camp&&s.stage==='path')s.checkpoint=camp;
  if((pressed&INPUT.upgrade)&&camp&&s.gold>=15&&s.upgrades<3){s.gold-=15;s.upgrades++;event(s,'upgrade',camp,FLOOR-30);}
  for(const coin of s.level.coins){if(!coin.used&&Math.abs(coin.x-p.x)<(p.buffs.magnet>0?125:22)&&Math.abs(coin.y-(p.y-20))<(p.buffs.magnet>0?100:32)){coin.used=true;pickup(s,p,{type:'coin'});if(s.frame%3===0)event(s,'coin',coin.x,coin.y);}}
  for(const item of s.level.pickups){if(!item.used&&!(item.type==='heal'&&p.hp>=p.maxHP)&&near({x:p.x,y:p.y-20},item,26,34)){item.used=true;pickup(s,p,item);}}
}
function riverBossAttack(s){
 const b=s.boss,d=DIFFICULTIES[s.difficulty];b.phase=b.hp<b.maxHP*.48?2:1;
 if(b.action==='sleep')return;
 if(--b.timer>0){
  if(['current','bubbles'].includes(b.action)){
   const amplitude=b.phase===2?210:150,rate=s.difficulty==='hard'?.027:.019;
   b.x=clamp(BOSS_HOME+Math.sin(s.frame*rate)*amplitude,ARENA+120,WORLD_END-120);
  }
  if(b.action==='quake'&&b.timer%24===0){
   event(s,'impact',b.x,FLOOR);
   for(const vx of [-6.2,6.2])s.hazards.push({type:'wave',x:b.x,y:FLOOR-12,vx,vy:0,life:200});
  }
  if(b.action==='current')for(const p of s.players)if(p.hp>0&&p.ground&&p.dash<=0)p.x=clamp(p.x-1.05-b.phase*.2,ARENA,WORLD_END-25);
  if(b.action==='current'&&b.timer%40===0)s.hazards.push({type:'wave',x:b.x-100,y:FLOOR-12,vx:-3.7,vy:0,life:250});
  if((b.action==='bubbles'||b.action==='current'&&b.phase===2)&&b.timer%(s.difficulty==='hard'?24:36)===0){
   const count=s.difficulty==='easy'?2:3;
   for(let i=0;i<count;i++)s.hazards.push({type:'bubble',x:ARENA+120+(b.cycle*97+i*247)%850,y:FLOOR+12,vx:Math.sin(i+b.cycle)*.25,vy:-2-b.phase*.3,life:160});
  }
  return;
 }
 if(b.action==='warning'){
  if(b.next==='quake'){b.action='quake';b.timer=b.phase===2?73:49;event(s,'impact',b.x,FLOOR);}
   else if(b.next==='tail'){b.action='recover';b.timer=45;for(const vx of [-5.4,5.4])s.hazards.push({type:'wave',x:b.x,y:FLOOR-12,vx,vy:0,life:220});event(s,'impact',b.x,FLOOR);}
  else {b.action=b.next==='stomp'?'current':b.next;b.timer=b.action==='bubbles'?150:120;}
  return;
 }
 if(['current','bubbles','recover','quake'].includes(b.action)){b.action='expose';b.timer=Math.round(d.recovery*.85);return;}
 if(b.action==='ward'){b.action='warning';b.next='current';b.timer=d.warning;return;}
 b.cycle++;
 if(s.difficulty!=='easy'&&b.cycle%4===0){b.action='ward';b.wardLocked=s.difficulty==='hard';b.timer=720;s.sigils=[-9999,-9999];event(s,'ward',b.x,FLOOR-90);return;}
 b.action='warning';b.next=b.cycle%5===0?'quake':['current','bubbles','tail'][b.cycle%3];b.timer=d.warning;event(s,'warning',b.x,FLOOR-100);
}
function bossAttack(s){
  if(s.chapter==='river')return riverBossAttack(s);
  const b=s.boss,d=DIFFICULTIES[s.difficulty];b.phase=b.hp<b.maxHP*.48?2:1;
  if(b.action==='sleep')return;
  if(--b.timer>0){
    if(b.action==='leaves'&&b.timer%32===0){
      for(let j=0;j<(s.difficulty==='easy'?2:3);j++)s.hazards.push({type:'leaf',x:b.x-75,y:FLOOR-35-j*43,vx:-3.5-b.phase*.45,vy:0,life:300});
      // The warning also signals aimed canopy leaves: neither ledge is a safe turret in hard.
      if(s.difficulty==='hard')for(const p of s.players){
        if(p.hp<=0||p.y>FLOOR-65)continue;
        const originX=b.x+Math.sign(p.x-b.x)*75,originY=FLOOR-100;
        const dx=p.x-originX,dy=p.y-20-originY,len=Math.max(1,Math.hypot(dx,dy));
        s.hazards.push({type:'leaf',x:originX,y:originY,vx:dx/len*4.4,vy:dy/len*4.4,life:220});
      }
    }
    if(b.action==='roll'){
      b.x+=b.vx;
      if(b.x<ARENA+85||b.x>WORLD_END-100){b.x=clamp(b.x,ARENA+85,WORLD_END-100);b.vx=-b.vx;b.rolls++;event(s,'impact',b.x,FLOOR);if(b.rolls>=2+b.phase){b.timer=1;}}
      for(const p of s.players)if(p.hp>0&&Math.abs(p.x-b.x)<94&&p.y>FLOOR-110)damage(s,p);
    }
    return;
  }
  if(b.action==='warning'){
    if(b.next==='roll'){b.action='roll';b.timer=420;b.rolls=0;b.vx=-d.rollSpeed;event(s,'roll',b.x,FLOOR);}
    else if(b.next==='stomp'){b.action='recover';b.timer=48;for(const vx of [-4.6,4.6])s.hazards.push({type:'wave',x:b.x,y:FLOOR-12,vx,vy:0,life:240});event(s,'impact',b.x,FLOOR);}
    else{b.action='leaves';b.timer=100+b.phase*25;}
    return;
  }
  if(['recover','leaves','roll'].includes(b.action)){
    if(b.wardLocked){b.action='ward';b.timer=720;s.sigils=[-9999,-9999];event(s,'ward',b.x,FLOOR-90);return;}
    b.action='expose';b.timer=d.recovery;return;
  }
  if(b.action==='ward'){b.wardLocked=s.difficulty==='hard';b.action='warning';b.next='stomp';b.timer=d.warning;event(s,'warning',b.x,FLOOR-100);return;}
  b.cycle++;
  if(s.difficulty!=='easy'&&b.cycle%4===0){b.action='ward';b.wardLocked=s.difficulty==='hard';b.timer=720;s.sigils=[-9999,-9999];event(s,'ward',b.x,FLOOR-90);return;}
  b.action='warning';b.next=s.difficulty==='hard'&&b.cycle%3===0?'roll':b.cycle%2===0?'leaves':'stomp';b.timer=d.warning;event(s,'warning',b.x,FLOOR-100);
}
export function stepGame(s,inputs=[0,0]){
  if(s.status!=='playing')return s;
  s.frame++;s.events=s.events.filter(e=>s.frame-e.frame<45);
  if(s.frame>60*360){s.status='defeat';return s;}
  for(let i=0;i<s.players.length;i++)updatePlayer(s,s.players[i],inputs[i]|0);
  const living=s.players.filter(p=>p.hp>0);
  if(s.chapter==='river'&&s.stage==='path'&&s.frame%360>=240)for(const p of living){
    if(p.ground&&s.level.currents.some(([a,b])=>p.x>a&&p.x<b))p.x=clamp(p.x+(s.difficulty==='hard'?1.05:.7),15,WORLD_END-25);
  }
  if(!living.length){s.status='defeat';event(s,'defeat',0,0);return s;}
  if(s.stage==='path'&&s.players.every(p=>p.x>ARENA-80||p.hp<=0)){s.stage='boss';s.boss.action='warning';s.boss.next='stomp';s.boss.timer=120;s.hazards=[];event(s,'boss',s.boss.x,FLOOR);}
  const slowed=living.some(p=>p.buffs.slow>0)&&s.frame%2===0;
  if(!slowed){
    for(const e of s.level.enemies){if(e.hp<=0)continue;
      const target=living.reduce((a,b)=>Math.abs(a.x-e.x)<Math.abs(b.x-e.x)?a:b);
      if(Math.abs(target.x-e.x)>650)continue;
      e.x=e.type===0?e.x+Math.sign(target.x-e.x)*(e.stolen?-.9:.65):e.origin+Math.sin(s.frame/(e.type===2?22:65)+e.phase)*(e.type===2?70:38);
      e.y=e.type===0||e.type===4?FLOOR-60+Math.sin(s.frame/25+e.phase)*18:FLOOR;
      if(--e.cooldown<=0&&e.type===5){e.cooldown=DIFFICULTIES[s.difficulty].enemyRate;const dx=target.x-e.x,dy=target.y-22-(e.y-28),len=Math.max(1,Math.hypot(dx,dy));s.hazards.push({type:'acorn',x:e.x,y:e.y-28,vx:dx/len*3,vy:dy/len*3,life:200});}
      for(const p of living)if(near({x:p.x,y:p.y-20},{x:e.x,y:e.y-15},27,30))damage(s,p,e);
    }
    if(s.stage==='boss')bossAttack(s);
    for(const h of s.hazards){h.x+=h.vx*(s.difficulty==='hard'?1.18:1);h.y+=h.vy*(s.difficulty==='hard'?1.18:1);h.life--;for(const p of living)if(near({x:p.x,y:p.y-17},h,h.type==='wave'?25:17,h.type==='wave'?24:17))damage(s,p);}
  }
  for(const shot of s.shots){shot.x+=shot.vx*(s.difficulty==='hard'?1.18:1);shot.y+=shot.vy*(s.difficulty==='hard'?1.18:1);shot.life--;
    const enemy=s.level.enemies.find(e=>e.hp>0&&near(shot,{x:e.x,y:e.y-20},25,30));
    if(enemy){enemy.hp-=shot.power;shot.life=0;event(s,'hit',shot.x,shot.y);if(enemy.hp<=0){s.gold+=3+enemy.stolen;enemy.stolen=0;event(s,'enemy',enemy.x,enemy.y-15);}continue;}
    const b=s.boss;
    if(s.stage==='boss'&&near(shot,{x:b.x,y:b.y-75},100,85)){
      shot.life=0;
      if(b.action==='expose'){const other=s.players.find(p=>p.id!==shot.owner);const link=s.mode==='partner'&&other&&s.frame-(other.lastHit??-9999)<45;b.hp-=shot.power*(link?1.55:1);s.players[shot.owner].lastHit=s.frame;event(s,link?'link':'hit',shot.x,shot.y);}
      else event(s,'blocked',shot.x,shot.y);
    }
  }
  s.shots=s.shots.filter(p=>p.life>0);s.hazards=s.hazards.filter(p=>p.life>0&&p.x>0&&p.x<WORLD_END);
  if(s.boss.hp<=0){s.boss.hp=0;s.status='victory';event(s,'victory',s.boss.x,FLOOR-100);}
  return s;
}
export function replay(seed,difficulty,mode,events,frames,species,chapter='forest'){
  if(!Number.isInteger(frames)||frames<1||frames>21600||!Array.isArray(events)||events.length>12000)throw Error('Registro inválido');
  const state=createGame(seed,difficulty,mode,species,chapter),inputs=[0,0];let index=0,previous=-1;
  for(const e of events){if(!Array.isArray(e)||e.length!==3||!e.every(Number.isInteger)||e[0]<previous||e[0]<0||e[0]>=frames||e[1]<0||e[1]>=state.players.length||e[2]<0||e[2]>63)throw Error('Entrada inválida');previous=e[0];}
  for(let f=0;f<frames;f++){while(index<events.length&&events[index][0]===f){const [,p,mask]=events[index++];inputs[p]=mask;}stepGame(state,inputs);if(state.status!=='playing'&&f<frames-1)throw Error('Registro posterior al final');}
  return {state,reward:rewardFor(state)};
}
