import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {replayRun} from '../assets/runner/replay.js';

function terminalRun(dt=16667,inputs=[]) {
  const frames=[];
  for(let i=0;i<1500;i++){
    frames.push([dt,inputs[i]??[]]);
    try{return {frames,result:replayRun(frames)};}catch(error){if(error.message!=='Run has no terminal collision')throw error;}
  }
  throw Error('No collision reached');
}
test('server calculates distance and coins from the actual collision',()=>{
  const {frames,result}=terminalRun();
  assert.equal(result.distance,95);assert.equal(result.coins,3);
  assert.ok(result.elapsed>11&&result.elapsed<12);
  assert.throws(()=>replayRun([...frames,[16667,[]]]),/after game over/);
});
test('lane changes change the collision that ends the run',()=>{
  const {result}=terminalRun(16667,[[-1]]);
  assert.equal(result.distance,68);assert.ok(result.coins>=1);
});
test('incomplete, oversized and invalid replays cannot claim rewards',()=>{
  assert.throws(()=>replayRun([[16667,[]]]),/terminal collision/);
  assert.throws(()=>replayRun([[1000000,[]]]),/Invalid replay frame/);
  assert.throws(()=>replayRun([[16667,[9]]]),/Invalid input/);
  assert.throws(()=>replayRun([[16667,[],999999]]),/Invalid replay frame/);
  assert.throws(()=>replayRun([]),/length/);
});
test('the deployed simulator and physics exactly match the browser',()=>{
  for(const name of ['physics.js','replay.js','difficulty.js'])
    assert.equal(readFileSync(new URL(`../assets/runner/${name}`,import.meta.url),'utf8'),readFileSync(new URL(`../supabase/functions/forest-runner/${name}`,import.meta.url),'utf8'));
});
