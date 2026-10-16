import test from 'node:test';import assert from 'node:assert/strict';
import {createGame,stepGame,replay} from '../assets/runner/guardian/engine.js';
import {createLevel,DIFFICULTIES,INPUT,FLOOR,ARENA,RUNE_X,rewardFor} from '../assets/runner/guardian/config.js';
test('seed reproduces route and changes collectible/enemy variation',()=>{assert.deepEqual(createLevel(8,'hard'),createLevel(8,'hard'));assert.notDeepEqual(createLevel(8,'hard').pickups,createLevel(9,'hard').pickups);});
test('solo grants exactly half per-player partner reward at every difficulty and loot threshold',()=>{for(const difficulty of Object.keys(DIFFICULTIES))for(const gold of [0,39,40,99,200,999]){const a=createGame(1,difficulty,'solo'),b=createGame(1,difficulty,'partner');a.status=b.status='victory';a.gold=b.gold=gold;assert.equal(rewardFor(a)*2,rewardFor(b));}assert.ok(DIFFICULTIES.easy.rewardUnits<DIFFICULTIES.medium.rewardUnits&&DIFFICULTIES.medium.rewardUnits<DIFFICULTIES.hard.rewardUnits);});
test('no reward for defeat, unfinished runs, or merely selecting hard',()=>{const s=createGame(1,'hard');assert.equal(rewardFor(s),0);s.status='defeat';assert.equal(rewardFor(s),0);});
test('movement and recorded inputs replay identically including jump/dodge and pickups',()=>{const s=createGame(234,'medium'),events=[[0,0,INPUT.right],[60,0,INPUT.right|INPUT.jump],[91,0,INPUT.right|INPUT.pulse],[130,0,INPUT.left|INPUT.dodge],[145,0,0]];let mask=0,index=0;for(let f=0;f<180;f++){if(events[index]?.[0]===f)mask=events[index++][2];stepGame(s,[mask]);}assert.deepEqual(replay(234,'medium','solo',events,180).state,s);});
test('jump clears first optional ledge and release gives lower jump',()=>{function height(held){const s=createGame(),p=s.players[0];let min=FLOOR;for(let f=0;f<55;f++){stepGame(s,[f<held?INPUT.jump:0]);min=Math.min(min,p.y);}return FLOOR-min;}assert.ok(height(30)>100);assert.ok(height(1)<height(30));});
test('shield absorbs a hit and thief removes only recoverable expedition loot',()=>{const s=createGame(),p=s.players[0];s.level.coins=[];s.level.pickups=[];const e={id:0,type:0,x:p.x,y:p.y,hp:99,origin:p.x,phase:0,stolen:0,cooldown:99};s.level.enemies=[e];s.gold=9;p.y=FLOOR-60;p.buffs.shield=1;for(let i=0;i<10;i++){e.x=p.x;e.y=p.y;stepGame(s);}assert.equal(p.hp,p.maxHP);assert.equal(p.buffs.shield,0);assert.equal(s.gold,9);p.invulnerable=0;p.y=FLOOR-60;p.vy=0;for(let i=0;i<80&&s.gold===9;i++){e.x=p.x;stepGame(s);}assert.ok(s.gold<9);assert.equal(s.gold+e.stolen,9);});
test('hard boss retracts, rolls, rebounds and gives exposure; easier bosses never roll',()=>{for(const difficulty of Object.keys(DIFFICULTIES)){const s=createGame(5,difficulty);s.stage='boss';s.level.enemies=[];s.level.coins=[];s.level.pickups=[];const p=s.players[0];p.x=6030;p.y=320;p.hp=p.maxHP=999;s.boss.action='expose';s.boss.timer=1;let rolled=false,exposedAfterRoll=false;for(let f=0;f<2800;f++){p.invulnerable=999;stepGame(s);if(s.boss.action==='roll')rolled=true;if(rolled&&s.boss.action==='expose')exposedAfterRoll=true;}assert.equal(rolled,difficulty==='hard');if(rolled)assert.ok(exposedAfterRoll);}});
test('partner can rescue a fallen player, but rescue count is limited',()=>{const s=createGame(1,'easy','partner');s.level.enemies=[];s.level.coins=[];s.level.pickups=[];s.players[1].hp=0;s.players[1].x=s.players[0].x;for(let i=0;i<80;i++)stepGame(s,[INPUT.pulse,0]);assert.equal(s.players[1].hp,1);assert.equal(s.players[1].revives,1);s.players[1].hp=0;s.players[1].revives=2;for(let i=0;i<90;i++)stepGame(s,[INPUT.pulse,0]);assert.equal(s.players[1].hp,0);});
test('invalid replay packets and unknown difficulty are rejected',()=>{assert.throws(()=>createGame(1,'legend'));for(const events of [[[0,2,0]],[[1,0,64]],[[2,0,0],[1,0,0]],[[-1,0,0]]])assert.throws(()=>replay(1,'easy','solo',events,20));});
test('ward requires both runes rather than rewarding waiting without coordination',()=>{const s=createGame(1,'hard','partner');s.stage='boss';s.level.enemies=[];s.level.coins=[];s.level.pickups=[];s.boss.action='ward';s.boss.timer=1;stepGame(s);assert.equal(s.boss.action,'warning');s.boss.action='ward';s.boss.timer=100;s.players[0].x=RUNE_X[0];s.players[1].x=RUNE_X[1];stepGame(s,[INPUT.pulse,INPUT.pulse]);assert.equal(s.boss.action,'expose');});

test('hard ward cannot be bypassed by waiting for exposure and runes stay reachable after rolling',()=>{const s=createGame(1,'hard');s.stage='boss';s.level.enemies=[];s.boss.x=ARENA+90;s.boss.action='ward';s.boss.timer=1;s.players[0].hp=999;for(let f=0;f<1400;f++){s.players[0].invulnerable=999;stepGame(s);assert.notEqual(s.boss.action,'expose');}assert.ok(RUNE_X.every(x=>x>=ARENA&&x<7060));});
test('both local players stay within the shared camera and releases stop movement',()=>{const s=createGame(9,'easy','partner');s.level.enemies=[];s.level.pits=[];s.level.platforms=[{x:0,y:FLOOR,w:7060}];for(let f=0;f<500;f++)stepGame(s,[INPUT.right,0]);assert.ok(s.players[0].x-s.players[1].x<=680);const x=s.players[0].x;stepGame(s,[0,0]);assert.equal(s.players[0].x,x);});

test('full expeditions can be completed without extra health or invulnerability at all difficulties',()=>{
 for(const difficulty of Object.keys(DIFFICULTIES)){
  const s=createGame(17,difficulty);let jump=0;
  while(s.status==='playing'){
   const p=s.players[0];let mask=INPUT.pulse;
   if(s.stage==='path'){
    mask|=INPUT.right;const pit=s.level.pits.find(([a,b])=>p.x>a-25&&p.x<b);
    if(p.ground&&!(p.previous&INPUT.jump)&&(pit||s.frame%80<3))jump=35;
    if(pit&&jump===35)mask|=INPUT.dodge;
   }else{
    let target=6050;if(s.boss.action==='ward')target=s.frame-s.sigils[0]>320?RUNE_X[0]:RUNE_X[1];
    if(p.x<target-10)mask|=INPUT.right;if(p.x>target+10)mask|=INPUT.left;
    if(s.boss.action!=='ward'&&p.ground&&p.y>400&&p.x<6140&&!(p.previous&INPUT.jump))jump=35;
   }
   if(jump-->0)mask|=INPUT.jump;stepGame(s,[mask]);
  }
  assert.equal(s.status,'victory',difficulty+' must have a viable route and boss solution');
  assert.ok(s.players[0].hp>0);assert.equal(s.boss.hp,0);
 }
});
