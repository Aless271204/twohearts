import test from 'node:test';import assert from 'node:assert/strict';
import {createGame,stepGame,replay} from '../assets/runner/guardian/engine.js';
import {INPUT,ARENA,FLOOR,rewardFor} from '../assets/runner/guardian/config.js';
import {createGame as legacyGame,stepGame as legacyStep} from '../design/guardian-river-v5/legacy-reference/engine.js';

test('river rocks require a new route, every successive landing is reachable without powers, and checkpoints stay safe',()=>{
 for(const difficulty of ['easy','medium','hard']){
  const s=createGame(17,difficulty,'solo',['bear'],'river'),route=s.level.platforms.filter(p=>p.kind!=='bonus-rock'&&p.x<ARENA&&!(p.y===320)).sort((a,b)=>a.x-b.x);
  assert.equal(s.level.routeVersion,5);assert.ok(route.filter(p=>p.kind==='rock').length>15);assert.ok(s.level.pits.length>20);
  for(let i=0;i<route.length-1;i++){
   const a=route[i],b=route[i+1];if(b.x<=a.x+a.w+.1)continue;
   let reachable=false;
   for(const offset of [12,24,5]){
    const attempt=createGame(17,difficulty,'solo',['bear'],'river');attempt.level.platforms=attempt.level.platforms.filter(p=>p.kind!=='bonus-rock');attempt.level.enemies=[];attempt.level.coins=[];attempt.level.pickups=[];const p=attempt.players[0];p.x=a.x+a.w-offset;p.y=a.y;p.ground=true;
    for(let f=0;f<65;f++){stepGame(attempt,[INPUT.right|(f<36?INPUT.jump:0)]);if(p.ground&&p.x>b.x-11&&p.x<b.x+b.w+11&&Math.abs(p.y-b.y)<1){reachable=true;break;}}
    if(reachable)break;
   }
   assert.ok(reachable,`${difficulty}: ${a.x.toFixed(0)} -> ${b.x.toFixed(0)} (${a.y} -> ${b.y})`);
  }
 }
});
test('old river rooms replay identically to the retained version-four engine',()=>{
 for(const mode of ['solo','partner']){const old=legacyGame(17,'medium',mode,['bear','pig'],'river'),now=createGame(17,'medium',mode,['bear','pig'],'river','legacy');assert.deepEqual(now,old);for(let f=0;f<300;f++){const inputs=[INPUT.right|(f%80<35?INPUT.jump:0)|INPUT.pulse,INPUT.right|INPUT.pulse];stepGame(now,inputs);legacyStep(old,inputs);}assert.deepEqual(now,old);}
});
test('river is a distinct seeded route; hard never spawns hearts and checkpoints are on ground',()=>{
 for(const difficulty of ['easy','medium','hard']){
  const r=createGame(17,difficulty,'solo',['bear'],'river'),forest=createGame(17,difficulty);
  assert.notDeepEqual(r.level.pits,forest.level.pits);assert.equal(r.level.currents.length,3);
  assert.ok(r.level.camps.every(x=>!r.level.pits.some(([a,b])=>x>=a&&x<=b)));
  if(difficulty==='hard')assert.ok(r.level.pickups.every(p=>!['heal','heart'].includes(p.type)));
  r.status='victory';const partner={...r,mode:'partner'};assert.equal(rewardFor(r)*2,rewardFor(partner));
 }
});
test('Bruma has warned waves, rising bubbles, tail sweep and vulnerability rather than turtle rolling',()=>{
 for(const next of ['current','bubbles','tail']){
  const r=createGame(17,'medium','solo',['pig'],'river');r.stage='boss';r.level.enemies=[];
  r.players[0].x=ARENA+100;r.boss.action='warning';r.boss.next=next;r.boss.timer=1;
  stepGame(r);assert.notEqual(r.boss.action,'roll');
  if(next==='tail')assert.ok(r.hazards.some(h=>h.type==='wave'));
  if(next==='bubbles'){for(let i=0;i<45;i++)stepGame(r);assert.ok(r.hazards.some(h=>h.type==='bubble'&&h.vy<0));}
  r.boss.timer=1;stepGame(r);assert.equal(r.boss.action,'expose');
 }
});
test('river input transcripts reconstruct exactly, including chapter-specific level',()=>{
 const r=createGame(17,'easy','solo',['penguin'],'river'),events=[[0,0,INPUT.right],[60,0,INPUT.right|INPUT.jump],[90,0,0]];
 for(let f=0;f<120;f++)stepGame(r,[f<60?INPUT.right:f<90?INPUT.right|INPUT.jump:0]);
 assert.deepEqual(replay(17,'easy','solo',events,120,['penguin'],'river').state,r);
 assert.throws(()=>createGame(17,'easy','solo',[], 'unknown'));
});

test('Bruma is tougher, moves while casting and telegraphs repeated earthquake waves',()=>{
 const r=createGame(17,'hard','solo',['bear'],'river'),f=createGame(17,'hard');
 assert.ok(r.boss.maxHP>f.boss.maxHP);r.stage='boss';r.level.enemies=[];r.players[0].x=ARENA+50;
 r.boss.action='bubbles';r.boss.timer=100;const x=r.boss.x;stepGame(r);assert.notEqual(r.boss.x,x);
 r.boss.action='warning';r.boss.next='quake';r.boss.timer=1;stepGame(r);assert.equal(r.boss.action,'quake');
 for(let i=0;i<30;i++)stepGame(r);
 assert.ok(r.hazards.filter(h=>h.type==='wave').length>=2);
 assert.ok(r.events.some(e=>e.type==='impact'));
});
