import test from 'node:test';
import assert from 'node:assert/strict';
import {replayChunk} from '../assets/runner/replay.js';
import {runnerDifficulty} from '../assets/runner/difficulty.js';

test('v5 keeps the opening pace then accelerates beyond 600m and 5km',()=>{
 for(const d of [0,150,500,600]) assert.deepEqual(runnerDifficulty(d,5),runnerDifficulty(d,3));
 let last=14;
 for(let d=601;d<=20000;d++){
  const next=runnerDifficulty(d,5);
  assert.ok(next.speed>last&&next.speed<24);
  assert.ok(next.speed-last<.004);
  assert.ok(next.spacing/next.speed>1.28);
  last=next.speed;
 }
 assert.ok(runnerDifficulty(5000,5).speed>21);
 assert.ok(runnerDifficulty(10000,5).speed>runnerDifficulty(5000,5).speed);
 const initial={distance:5000,elapsed:400,untilRow:100,objects:[],version:5};
 const frames=Array.from({length:40},()=>[20000,[]]);
 const all=replayChunk(frames,initial,5);
 const first=replayChunk(frames.slice(0,20),initial,5);
 assert.deepEqual(all,replayChunk(frames.slice(20),first.state,5));
 assert.throws(()=>replayChunk(frames,initial,4),/version/);
});

function longRun(seconds){
  let state=null;const frames=[];
  for(let i=0;i<seconds*50;i++){
    const imminent=state?.objects.find(o=>o.kind==='obstacle'&&Math.abs(o.x-state.x)<.5&&o.z>-5&&o.z<0);
    const frame=[20000,imminent&&state.height===0?[0]:[]];
    const result=replayChunk([frame],state);
    assert.equal(result.ended,false,'Auto-jumping run must remain alive');state=result.state;frames.push(frame);
  }
  return {state,frames};
}
test('the endless run passes 600m and checkpoints reconstruct the exact state',()=>{
 const {state,frames}=longRun(150);
 assert.ok(state.distance>1500);
 const once=replayChunk(frames);
 const first=replayChunk(frames.slice(0,4500));
 const continued=replayChunk(frames.slice(4500),first.state);
 assert.deepEqual(once,continued);assert.deepEqual(continued.state,state);
 assert.equal(continued.ended,false);assert.ok(continued.state.objects.length<40);
});
test('checkpoint validation rejects malformed input and never accepts frames after collision',()=>{
 assert.throws(()=>replayChunk([[40001,[]]]),/frame/);
 assert.throws(()=>replayChunk([[20000,[5]]]),/input/);
 const frames=Array.from({length:1000},()=>[20000,[]]);
 assert.throws(()=>replayChunk(frames),/after game over/);
});
