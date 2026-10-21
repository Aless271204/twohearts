export const WIDTH=1280,HEIGHT=720,TICK=1/30;
export const PLATFORMS=[{x:150,y:510,w:980},{x:35,y:350,w:300},{x:945,y:350,w:300},{x:515,y:280,w:250}];
export const MAPS=[{name:'Refugio de Copitos',platforms:PLATFORMS},{name:'Terrazas de Aurora',platforms:[{x:150,y:510,w:980},{x:45,y:395,w:270},{x:965,y:395,w:270},{x:350,y:315,w:240},{x:690,y:315,w:240},{x:505,y:175,w:270}]},{name:'Cumbres de Cristal',platforms:[{x:150,y:510,w:980},{x:170,y:390,w:240},{x:870,y:390,w:240},{x:510,y:295,w:260},{x:65,y:220,w:260},{x:955,y:220,w:260},{x:465,y:125,w:350}]}];
export const platformsFor=s=>MAPS[s.map??0]?.platforms??PLATFORMS;
export const WEAPONS=['copito','rafaga','rebote','bola_grande'];
export const POWERS=['triple','speed','mini','shield'];
const clamp=(x,a,b)=>Math.max(a,Math.min(b,x));
function random(s){s.rng=(Math.imul(s.rng,1664525)+1013904223)>>>0;return s.rng/4294967296;}
function event(s,type,x,y,extra={}){s.events.push({id:++s.eventId,type,x,y,...extra});if(s.events.length>32)s.events.shift();}
export function newArena(seed=1,people=[{id:'me',species:'penguin'},{id:'bot',species:'bear',bot:true}],duration=60){
 if(!Array.isArray(people)||people.length<2||people.length>4||!Number.isFinite(duration)||duration<15||duration>180)throw Error('Arena inválida');
 return {version:2,map:(seed>>>0)%MAPS.length,rng:seed>>>0,time:0,duration,status:'playing',nextGift:5,nextPower:8,sequence:0,eventId:0,events:[],shots:[],drops:[],players:people.map((p,i)=>({id:String(p.id),species:['penguin','bear','pig','chick'].includes(p.species)?p.species:'penguin',name:String(p.name??['Tú','Nube','Luna','Copito'][i]).slice(0,24),bot:!!p.bot,x:350+i*185,y:510,vx:0,vy:0,ground:true,jumps:0,heldJump:false,heldSuper:false,face:i%2?-1:1,score:0,falls:0,stacks:0,rescue:0,invulnerable:2,charge:0,shot:0,weapon:'copito',weaponTime:0,buffs:{},lastHit:null,lastHitTime:-100}))};
}
export function safeInput(raw={}){return {left:raw.left===true,right:raw.right===true,jump:raw.jump===true,fire:raw.fire===true,super:raw.super===true,aimX:Number.isFinite(raw.aimX)?clamp(raw.aimX,-1,1):0,aimY:Number.isFinite(raw.aimY)?clamp(raw.aimY,-1,1):0};}
export function botInput(s,p){
 const others=s.players.filter(q=>q.id!==p.id&&!q.rescue),target=others.sort((a,b)=>Math.abs(a.x-p.x)-Math.abs(b.x-p.x))[0];if(!target)return {};
 const dx=target.x-p.x,dy=(target.y-35)-(p.y-35),distance=Math.hypot(dx,dy),danger=p.y>570||p.x<185||p.x>1095;
 const toward=danger?640-p.x:Math.abs(dx)>220?dx:Math.abs(dx)<100?-dx:0;
 return {left:toward<-12,right:toward>12,jump:(danger||dy<-70||s.shots.some(b=>b.owner!==p.id&&Math.abs(b.x-p.x)<110&&Math.abs(b.y-(p.y-35))<65))&&!p.heldJump,fire:distance<650,aimX:dx/Math.max(1,distance),aimY:(dy-distance*.22)/Math.max(1,distance),super:p.charge>=100&&distance<250};
}
function push(s,p,owner,dx,power){
 if(p.rescue||p.invulnerable>0)return;
 if((p.buffs.shield??0)>0){p.buffs.shield=0;p.invulnerable=.4;event(s,'shield',p.x,p.y-35);return;}
 p.stacks=Math.min(8,p.stacks+1);p.vx+=Math.sign(dx||1)*(power+p.stacks*22);p.vy=-210-p.stacks*7;p.ground=false;p.lastHit=owner;p.lastHitTime=s.time;
 const attacker=s.players.find(q=>q.id===owner);if(attacker)attacker.charge=clamp(attacker.charge+7,0,100);
 event(s,'hit',p.x,p.y-30,{player:p.id});
}
function launch(s,p,input){
 let dx=input.aimX,dy=input.aimY;if(Math.hypot(dx,dy)<.1){dx=p.face;dy=-.23;}const length=Math.hypot(dx,dy);dx/=length;dy/=length;
 const count=p.weapon==='rafaga'?3:1;
 for(let i=0;i<count;i++){if(s.shots.length>=48)break;const a=Math.atan2(dy,dx)+(i-(count-1)/2)*.16,v=p.weapon==='bola_grande'?310:440;
  s.shots.push({id:++s.sequence,owner:p.id,x:p.x+dx*33,y:p.y-39, vx:Math.cos(a)*v,vy:Math.sin(a)*v,r:p.weapon==='bola_grande'?15:8,type:p.weapon,ttl:2.7,bounces:0});}
 p.shot=p.weapon==='rafaga'?.72:p.weapon==='bola_grande'?.95:.42;event(s,'throw',p.x,p.y-35,{player:p.id});
}
export function stepArena(s,inputs={},dt=TICK){
 if(s.status!=='playing')return s;dt=clamp(dt,.001,TICK);s.time=Math.min(s.duration,s.time+dt);
 if(s.time>=s.nextGift){s.nextGift+=12;const kind=WEAPONS[1+Math.floor(random(s)*3)];s.drops.push({id:++s.sequence,type:'weapon',kind,x:225+random(s)*830,y:-30,vy:0,ttl:18});event(s,'gift',640,90);}
 if(s.time>=s.nextPower){s.nextPower+=10;const kind=POWERS[Math.floor(random(s)*POWERS.length)];s.drops.push({id:++s.sequence,type:'power',kind,x:225+random(s)*830,y:-30,vy:0,ttl:16});}
 for(const p of s.players){
  p.invulnerable=Math.max(0,p.invulnerable-dt);p.shot=Math.max(0,p.shot-dt);p.charge=clamp(p.charge+dt*3.2,0,100);p.weaponTime=Math.max(0,p.weaponTime-dt);if(!p.weaponTime)p.weapon='copito';
  for(const k of Object.keys(p.buffs))p.buffs[k]=Math.max(0,p.buffs[k]-dt);
  if(p.rescue>0){p.rescue=Math.max(0,p.rescue-dt);p.y=510-90*Math.sin(Math.PI*p.rescue/1.5);if(!p.rescue){p.y=510;p.invulnerable=2;p.ground=true;p.jumps=0;}continue;}
  const input=safeInput(p.bot?botInput(s,p):inputs[p.id]),mini=(p.buffs.mini??0)>0,scale=mini?.5:1;
  const target=((input.right?1:0)-(input.left?1:0))*((p.buffs.speed??0)>0?290:205);p.vx+=(target-p.vx)*Math.min(1,dt*(p.ground?9:2.7));if(target)p.face=Math.sign(target);
  if(input.jump&&!p.heldJump&&p.jumps<((p.buffs.triple??0)>0?3:2)){p.vy=-365;p.jumps++;p.ground=false;event(s,'jump',p.x,p.y);}
  p.heldJump=input.jump;
  if(input.fire&&p.shot<=0)launch(s,p,input);
  if(input.super&&!p.heldSuper&&p.charge>=100){p.charge=0;const angle=Math.hypot(input.aimX,input.aimY)>.1?Math.atan2(input.aimY,input.aimX):Math.atan2(-.12,p.face);for(let i=0;i<9&&s.shots.length<48;i++){const a=angle+(i-4)*.09;s.shots.push({id:++s.sequence,owner:p.id,x:p.x+Math.cos(a)*35,y:p.y-39,vx:Math.cos(a)*650,vy:Math.sin(a)*650,r:12,type:'super',ttl:1.8,bounces:0});}p.shot=Math.max(p.shot,.65);event(s,'super',p.x,p.y-32,{player:p.id});}p.heldSuper=input.super;
  const previous=p.y;p.vy=Math.min(640,p.vy+dt*800);p.x+=p.vx*dt;p.y+=p.vy*dt;p.ground=false;
  for(const platform of platformsFor(s))if(p.vy>=0&&previous<=platform.y+.5&&p.y>=platform.y&&p.x>platform.x-12*scale&&p.x<platform.x+platform.w+12*scale){p.y=platform.y;p.vy=0;p.ground=true;p.jumps=0;break;}
  if(p.y>HEIGHT+50||p.x<-70||p.x>WIDTH+70){const scorer=s.players.find(q=>q.id===p.lastHit&&s.time-p.lastHitTime<8);if(scorer)scorer.score++;p.falls++;event(s,'rescue',clamp(p.x,40,1240),Math.min(p.y,620),{player:p.id});p.x=350+Math.floor(random(s)*4)*185;p.y=510;p.vx=p.vy=0;p.rescue=1.5;p.stacks=0;p.lastHit=null;p.buffs={};p.weapon='copito';p.weaponTime=0;}
 }
 for(const b of s.shots){const previous=b.y;b.ttl-=dt;b.vy+=dt*260;b.x+=b.vx*dt;b.y+=b.vy*dt;
  if(b.type==='rebote'&&b.bounces<2)for(const plat of platformsFor(s))if(b.vy>0&&previous<=plat.y&&b.y>=plat.y&&b.x>plat.x&&b.x<plat.x+plat.w){b.y=plat.y-b.r;b.vy=-Math.abs(b.vy)*.8;b.bounces++;event(s,'bounce',b.x,b.y);break;}
  for(const p of s.players)if(p.id!==b.owner&&!p.rescue&&p.invulnerable<=0&&Math.hypot(p.x-b.x,p.y-35*((p.buffs.mini??0)>0?.5:1)-b.y)<(b.r+24*((p.buffs.mini??0)>0?.5:1))){push(s,p,b.owner,b.vx,b.type==='super'?490:b.type==='bola_grande'?370:220);b.ttl=0;break;}
 }
 s.shots=s.shots.filter(b=>b.ttl>0&&b.y<800&&b.x>-100&&b.x<1380);
 for(const d of s.drops){const previous=d.y;d.ttl-=dt;d.vy+=dt*360;d.y+=d.vy*dt;for(const plat of platformsFor(s))if(previous<=plat.y-15&&d.y>=plat.y-15&&d.x>plat.x&&d.x<plat.x+plat.w){d.y=plat.y-15;d.vy=0;break;}
  for(const p of s.players)if(!p.rescue&&Math.hypot(p.x-d.x,p.y-28-d.y)<46){if(d.type==='weapon'){p.weapon=d.kind;p.weaponTime=16;}else p.buffs[d.kind]=d.kind==='shield'?9:12;d.ttl=0;event(s,'pickup',d.x,d.y,{kind:d.kind,player:p.id});break;}}
 s.drops=s.drops.filter(d=>d.ttl>0&&d.y<800);
 if(s.time>=s.duration){s.status='finished';event(s,'finish',640,250);}
 return s;
}
export function rewardFor(s,id){if(s.status!=='finished')return 0;const p=s.players.find(q=>q.id===id);if(!p||p.bot)return 0;return Math.min(18,5+p.score*2);}
