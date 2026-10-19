import test from 'node:test';import assert from 'node:assert/strict';
import {createGame,stepGame,replay} from '../assets/runner/guardian/engine.js';
import {FLOOR,ARENA,WORLD_END,INPUT} from '../assets/runner/guardian/config.js';
import {bossFacing} from '../assets/runner/guardian/aerial-attacks.js';
import {packState,applyState} from '../assets/runner/guardian/network.js';

test('both bosses hit campers on high ledges and at either arena edge, with warning first',()=>{
 for(const chapter of ['forest','river'])for(const difficulty of ['easy','medium','hard'])for(const x of [ARENA+25,WORLD_END-40]){
  const s=createGame(19,difficulty,'solo',['bear'],chapter,'stones','aerial');s.stage='boss';s.level.enemies=[];s.level.coins=[];s.level.pickups=[];
  s.boss.action=chapter==='river'?'bubbles':'leaves';s.boss.timer=1000;
  const p=s.players[0];p.x=x;p.y=FLOOR-155;p.hp=p.maxHP=100;
  s.level.platforms.push({x:x-30,y:p.y,w:60});let warned=false;
  for(let i=0;i<640;i++){stepGame(s,[INPUT.pulse]);if(s.hazards.some(h=>h.source==='boss'&&h.delay>0))warned=true;}
  assert.ok(warned,chapter+' must telegraph aerial shots');
  assert.ok(p.hp<100,chapter+' '+difficulty+' '+x+' must not be a safe turret');
  assert.equal(bossFacing(s),x<s.boss.x?-1:1);
 }
});
test('water fish leap upward and attack in both horizontal directions, with advance ripples',()=>{
 const s=createGame(7,'medium','solo',['pig'],'river','stones','aerial');s.level.enemies=[];s.players[0].hp=100;s.players[0].x=2500;
 const directions=new Set();let above=false,warned=false;
 for(let i=0;i<900;i++){stepGame(s,[0]);for(const h of s.hazards.filter(h=>h.type==='fish')){directions.add(Math.sign(h.vx));above||=h.y<FLOOR-120;warned||=h.delay>0;}}
 assert.deepEqual([...directions].sort(),[-1,0,1]);assert.ok(above);assert.ok(warned);
});
test('aerial replay is deterministic and guests reject a different combat version',()=>{
 const s=createGame(29,'easy','partner',['chick','bear'],'river','stones','aerial');
 for(let i=0;i<120;i++)stepGame(s,[0,0]);
 const replayed=replay(29,'easy','partner',[],120,['chick','bear'],'river','stones','aerial').state;
 assert.deepEqual(s,replayed);
 const old=createGame(29,'easy','partner',['chick','bear'],'river');assert.equal(applyState(old,packState(s,false,0)),false);
});
