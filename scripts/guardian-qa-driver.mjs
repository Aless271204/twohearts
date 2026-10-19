import {createGame,stepGame} from '../assets/runner/guardian/engine.js';import {INPUT,ARENA,RUNE_X} from '../assets/runner/guardian/config.js';
export function driveExpedition(seed=17,difficulty='easy',mode='solo',species=['penguin','bear'],chapter='forest'){const s=createGame(seed,difficulty,mode,species,chapter);
const jumps=[0,0],previous=[0,0],seq=[0,0],events=[],refs=[],packets=[[],[]];
while(s.status==='playing'){
 const masks=s.players.map((p,i)=>{
  let m=INPUT.pulse;
  if(s.stage==='path'){
   const fallen=s.players.find(q=>q.id!==p.id&&q.hp<=0&&q.revives<2&&Math.abs(q.x-p.x)<60);
   if(!fallen)m|=INPUT.right;
   if(p.ground&&!(p.previous&INPUT.jump)&&s.hazards.some(h=>Math.abs(h.x-p.x)<110&&Math.abs(h.y-(p.y-20))<50))jumps[i]=35;
   const pit=s.level.pits.find(([a,b])=>p.x>a-25&&p.x<b);
   if(p.ground&&!(p.previous&INPUT.jump)&&pit)jumps[i]=35;
   if(pit&&jumps[i]===35)m|=INPUT.dodge;
   if(p.dashCooldown===0&&s.hazards.some(h=>Math.abs(h.x-p.x)<65&&Math.abs(h.y-(p.y-20))<40))m|=INPUT.dodge;
   if(p.dashCooldown===0&&s.level.enemies.some(e=>e.hp>0&&Math.abs(e.x-p.x)<75&&Math.abs(e.y-p.y)<40))m|=INPUT.dodge;
   if(p.ground&&s.level.camps.some(x=>Math.abs(x-p.x)<80)&&s.gold>=15&&s.upgrades<3)m|=INPUT.upgrade;
  }else{
   let target=ARENA+(i===0?150:880);
   if(difficulty==='hard'&&s.boss.action==='leaves'&&p.ground&&!(p.previous&INPUT.jump))jumps[i]=35;
   if(s.boss.action==='ward')target=s.players.filter(q=>q.hp>0).length===1?(s.frame-s.sigils[0]>320?RUNE_X[0]:RUNE_X[1]):RUNE_X[i];
   if(p.x<target-10)m|=INPUT.right;if(p.x>target+10)m|=INPUT.left;
   if(s.boss.action!=='ward'&&p.ground&&p.y>400&&!(p.previous&INPUT.jump))jumps[i]=35;
  }
  if(p.ground&&!(p.previous&INPUT.jump)&&s.hazards.some(h=>Math.abs(h.x-p.x)<115&&Math.abs(h.y-(p.y-20))<70))jumps[i]=35;
  if(p.dashCooldown===0&&s.hazards.some(h=>Math.abs(h.x-p.x)<55&&Math.abs(h.y-(p.y-20))<40))m|=INPUT.dodge;
  if(jumps[i]-->0)m|=INPUT.jump;return m;
 });
 for(let i=0;i<masks.length;i++)if(masks[i]!==previous[i]){seq[i]++;events.push([s.frame,i,masks[i]]);refs.push(seq[i]);packets[i].push([seq[i],masks[i]]);previous[i]=masks[i];}
 stepGame(s,masks);
}
return {state:s,events,refs,packets};}
