import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {kilometreEvent} from '../assets/runner/kilometre-events.js';
import {runnerDifficulty} from '../assets/runner/difficulty.js';
import {runnerRow} from '../assets/runner/patterns.js';
import {replayChunk} from '../supabase/functions/forest-runner/replay.js';
test('events change exactly at each kilometre without resetting seasonal progression',()=>{
 for(let km=1;km<=25;km++){
  assert.equal(kilometreEvent(km*1000-1).km,km-1);
  assert.equal(kilometreEvent(km*1000).km,km);
  assert.ok(runnerDifficulty(km*1000,11).speed>=runnerDifficulty((km-1)*1000,11).speed);
 }
 assert.equal(kilometreEvent(8000).id,'collapse');assert.equal(kilometreEvent(10000).id,'trees');
});
test('all event patterns preserve an empty lane and client/server rules match',()=>{
 for(const file of ['patterns.js','difficulty.js','kilometre-events.js'])assert.equal(readFileSync(new URL('../assets/runner/'+file,import.meta.url),'utf8').replaceAll('\r\n','\n'),readFileSync(new URL('../supabase/functions/forest-runner/'+file,import.meta.url),'utf8').replaceAll('\r\n','\n'));
 for(let km=0;km<25;km++)for(let row=0;row<100;row++){
  const p=runnerRow(row,km*1000,11,418);assert.ok(p.obstacleLanes.length>=1&&p.obstacleLanes.length<=2);
  assert.ok(!p.obstacleLanes.includes(p.safeLane));assert.deepEqual(p,runnerRow(row,km*1000,11,418));
 }
 const checkpoint=replayChunk([[16667,[]]],null,11);assert.equal(checkpoint.state.version,11);
 const legacy=replayChunk([[16667,[]]],null,10);assert.equal(legacy.state.version,10);
});
