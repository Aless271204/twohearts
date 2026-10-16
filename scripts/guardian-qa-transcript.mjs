// Input-only regression driver; never edits health, position, loot or boss state.
import fs from 'node:fs';import {createGame,stepGame} from '../assets/runner/guardian/engine.js';import {INPUT,ARENA,RUNE_X} from '../assets/runner/guardian/config.js';import {transcriptHash} from '../assets/runner/guardian/transcript.js';
const room=JSON.parse(fs.readFileSync(process.argv[2]??'outputs/guardian-backend-room.json','utf8')),s=createGame(Number(room.seed),room.difficulty,room.mode,room.species);
const jumps=[0,0],previous=[0,0],seq=[0,0],events=[],refs=[],packets=[[],[]];
while(s.status==='playing'){
 const masks=s.players.map((p,i)=>{
  let m=INPUT.pulse;
  if(s.stage==='path'){
   const fallen=s.players.find(q=>q.id!==p.id&&q.hp<=0&&q.revives<2&&Math.abs(q.x-p.x)<60);
   if(!fallen)m|=INPUT.right;
   const pit=s.level.pits.find(([a,b])=>p.x>a-25&&p.x<b);
   if(p.ground&&!(p.previous&INPUT.jump)&&pit)jumps[i]=35;
   if(pit&&jumps[i]===35)m|=INPUT.dodge;
   if(p.dashCooldown===0&&s.level.enemies.some(e=>e.hp>0&&Math.abs(e.x-p.x)<75&&Math.abs(e.y-p.y)<40))m|=INPUT.dodge;
   if(p.ground&&s.level.camps.some(x=>Math.abs(x-p.x)<80)&&s.gold>=15&&s.upgrades<3)m|=INPUT.upgrade;
  }else{
   let target=ARENA+(i===0?150:880);
   if(s.boss.action==='ward')target=s.players.filter(q=>q.hp>0).length===1?(s.frame-s.sigils[0]>320?RUNE_X[0]:RUNE_X[1]):RUNE_X[i];
   if(p.x<target-10)m|=INPUT.right;if(p.x>target+10)m|=INPUT.left;
   if(s.boss.action!=='ward'&&p.ground&&p.y>400&&!(p.previous&INPUT.jump))jumps[i]=35;
  }
  if(jumps[i]-->0)m|=INPUT.jump;return m;
 });
 for(let i=0;i<masks.length;i++)if(masks[i]!==previous[i]){seq[i]++;events.push([s.frame,i,masks[i]]);refs.push(seq[i]);packets[i].push([seq[i],masks[i]]);previous[i]=masks[i];}
 stepGame(s,masks);
}
console.log(room.difficulty,room.mode,s.status,s.frame,s.players.map(p=>p.hp),'boss',s.boss.hp,s.boss.action);
if(s.status!=='victory')process.exit(1);
const hash=await transcriptHash(room.id,s.frame,events,refs);fs.writeFileSync('outputs/guardian-qa-victory.json',JSON.stringify({room:room.id,frames:s.frame,events,refs,packets,hash}));
