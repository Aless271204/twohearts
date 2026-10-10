import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {replayChunk} from '../assets/runner/replay.js';
import {freshPowers,activatePower,tickPowers,canJump,registerJump,powerForRow} from '../assets/runner/power-ups.js';
const frame=[40000,[]];
const state=(objects=[],powers=freshPowers())=>({version:6,untilRow:100,distance:1000,elapsed:80,objects,powers});
test('all effects expire and cannot accumulate; pickups rotate in a free lane',()=>{
 const p=freshPowers();activatePower(p,'shield');tickPowers(p,2);activatePower(p,'shield');assert.equal(p.shield,20);tickPowers(p,21);assert.equal(p.shield,0);
 const keys=new Set();for(let row=0;row<100;row++){const pickup=powerForRow(row,200,1);if(pickup){keys.add(pickup.power);assert.notEqual(pickup.lane,1);}}
 assert.equal(keys.size,5);assert.equal(powerForRow(8,100,1),null);
});
test('magnet reaches other lanes and coin multiplier is server reconstructed',()=>{
 const p=freshPowers();activatePower(p,'magnet');activatePower(p,'doubleCoins');
 const result=replayChunk([frame],state([{kind:'coin',x:1.6,z:-3.1,y:1.8}],p),6);
 assert.equal(result.state.coins,2);assert.equal(result.state.objects.length,0);
});
test('shield consumes one collision; boost doubles travel and protects temporarily',()=>{
 const obstacle={kind:'obstacle',x:0,z:-.1};const p=freshPowers();activatePower(p,'shield');
 const first=replayChunk([frame],state([obstacle],p),6);assert.equal(first.ended,false);assert.equal(first.state.powers.shield,0);
 assert.equal(replayChunk([frame],{...first.state,objects:[obstacle]},6).ended,true);
 const boost=freshPowers();activatePower(boost,'boost');
 const normal=replayChunk([frame],state(),6),fast=replayChunk([frame],state([obstacle],boost),6);
 assert.ok(Math.abs((fast.state.distance-1000)/(normal.state.distance-1000)-2)<1e-9);assert.equal(fast.ended,false);
 const expired=freshPowers();expired.boost=.01;assert.equal(replayChunk([frame],state([obstacle],expired),6).ended,true);
});
test('triple jump allows three impulses and resets on landing',()=>{
 const p=freshPowers();activatePower(p,'tripleJump');registerJump(p,0);registerJump(p,1);registerJump(p,2);assert.equal(canJump(p,2),false);
 const result=replayChunk([[20000,[0,0,0,0]]],state([],freshPowers()),6);assert.equal(result.state.powers.jumps,1);
 const active=freshPowers();activatePower(active,'tripleJump');const tripled=replayChunk([[20000,[0]], [20000,[0]], [20000,[0]], [20000,[0]]],state([],active),6);
 assert.equal(tripled.state.powers.jumps,3);
 const landed=replayChunk(Array.from({length:60},()=>[40000,[]]),tripled.state,6);assert.equal(landed.state.powers.jumps,0);
});
test('power effects survive checkpoints exactly, legacy v5 ignores pickups',()=>{
 const p=freshPowers();activatePower(p,'boost');activatePower(p,'tripleJump');
 const frames=Array.from({length:30},()=>frame);const initial=state([],p);
 const once=replayChunk(frames,initial,6),first=replayChunk(frames.slice(0,15),initial,6);
 assert.deepEqual(replayChunk(frames.slice(15),first.state,6),once);
 const legacy=replayChunk([frame],{...state(),version:5},5);assert.equal(legacy.state.powers,undefined);
 for(const name of ['replay.js','power-ups.js'])assert.equal(readFileSync('assets/runner/'+name,'utf8'),readFileSync('supabase/functions/forest-runner/'+name,'utf8'));
});
