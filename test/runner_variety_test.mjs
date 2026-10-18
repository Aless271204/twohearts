import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {seedFromSession,runnerRow} from '../assets/runner/patterns.js';
import {powerForRow} from '../assets/runner/power-ups.js';
import {runnerDifficulty} from '../assets/runner/difficulty.js';
import {replayChunk} from '../assets/runner/replay.js';
test('each server-issued session produces reproducible distinct coin and obstacle layouts',()=>{
 const signatures=new Set();
 for(let id=0;id<16;id++){
  const seed=seedFromSession('server-session-'+id);
  const rows=Array.from({length:70},(_,i)=>runnerRow(i,i*25,7,seed));
  assert.deepEqual(rows,Array.from({length:70},(_,i)=>runnerRow(i,i*25,7,seed)));
  for(const row of rows){assert.ok(row.obstacleLane>=0&&row.obstacleLane<3);assert.ok(row.coins.length>=3&&row.coins.length<=7);assert.equal(new Set(row.coins.map(c=>c.z)).size,row.coins.length);}
  signatures.add(JSON.stringify(rows));
 }assert.equal(signatures.size,16);
});
test('power types, pickup spacing and safe lanes change with the run seed',()=>{
 const signatures=new Set();
 for(let seed=1;seed<12;seed++){
  const picks=[];
  for(let row=10;row<110;row++){const p=powerForRow(row,1000,1,seed);if(p){assert.notEqual(p.lane,1);picks.push([row,p.power,p.lane]);}}
  assert.equal(new Set(picks.map(p=>p[1])).size,5);assert.equal(picks.length,10);signatures.add(JSON.stringify(picks));
 }assert.equal(signatures.size,11);
});
test('stage transitions accelerate smoothly without exceeding the validated 48 m/s boost',()=>{
 let previous=0;
 for(let d=0;d<12000;d++){const p=runnerDifficulty(d,7);assert.ok(p.speed>=previous&&p.speed<=24);assert.ok(p.spacing/p.speed>=1.4-1e-10);previous=p.speed;}
 assert.ok(runnerDifficulty(1000,7).speed>runnerDifficulty(1000,6).speed);
});
test('random layouts and pickups survive checkpoint splitting identically',()=>{
 const frames=Array.from({length:100},()=>[20000,[]]);
 const initial={version:7,seed:seedFromSession('validated-server-id')};
 const once=replayChunk(frames,initial,7),first=replayChunk(frames.slice(0,40),initial,7);
 assert.deepEqual(replayChunk(frames.slice(40),first.state,7),once);
 for(const f of ['patterns.js','difficulty.js','power-ups.js','replay.js'])assert.equal(readFileSync('assets/runner/'+f,'utf8'),readFileSync('supabase/functions/forest-runner/'+f,'utf8'));
 assert.ok(!readFileSync('supabase/functions/forest-runner/index.ts','utf8').includes('body.seed'));
});

test('storm expedition starts faster, introduces collapsing tiles only beyond 1.5 km and keeps replay deterministic',()=>{
 assert.equal(runnerDifficulty(0,8).speed,12);assert.ok(runnerDifficulty(2050,8).speed>runnerDifficulty(1500,8).speed);
 assert.ok(Array.from({length:150},(_,r)=>runnerRow(r,1499,8,42)).every(p=>p.kind!=='collapse'));
 assert.ok(Array.from({length:150},(_,r)=>runnerRow(r,1600,8,42)).some(p=>p.kind==='collapse'));
 for(let r=0;r<60;r++){const p=runnerRow(r,2000,8,42);assert.deepEqual(p,runnerRow(r,2000,8,42));assert.ok(p.obstacleLane>=0&&p.obstacleLane<3);}
 const frames=Array.from({length:50},()=>[20000,[]]),initial={version:8,seed:42,distance:1600,untilRow:0};
 const first=replayChunk(frames.slice(0,20),initial,8);
 assert.deepEqual(replayChunk(frames.slice(20),first.state,8),replayChunk(frames,initial,8));
});
