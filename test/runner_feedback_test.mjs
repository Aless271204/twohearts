import {test} from 'node:test';
import assert from 'node:assert/strict';
import {runnerDifficulty} from '../assets/runner/difficulty.js';
import {AdventureMusic} from '../assets/runner/music.js';
import {replayRun} from '../assets/runner/replay.js';

test('difficulty grows smoothly, stays bounded and leaves time to jump',()=>{
  let previous=runnerDifficulty(0);
  for(let distance=1;distance<=3000;distance++){
    const next=runnerDifficulty(distance);
    assert.ok(next.speed>=previous.speed&&next.speed<=14);
    assert.ok(next.spacing<=previous.spacing&&next.spacing>=18);
    assert.ok(next.spacing/next.speed>1.2);
    assert.ok(next.level>=1&&next.level<=5);
    previous=next;
  }
  assert.deepEqual(runnerDifficulty(0),{speed:8,spacing:28,level:1});
  assert.deepEqual(runnerDifficulty(900),{speed:14,spacing:18,level:5});
});

test('new replays validate and older installed apps retain their rules',()=>{
  const frames=[];let result;
  for(let i=0;i<1000;i++){
    frames.push([16667,[]]);
    try{result=replayRun(frames,2);break;}catch(error){assert.equal(error.message,'Run has no terminal collision');}
  }
  assert.ok(result.distance>=90&&result.distance<=96);
  assert.ok(result.coins>0);
  assert.throws(()=>replayRun(frames,4),/version/);
  assert.equal(runnerDifficulty(720,1).spacing,28);
});

test('effects produce distinct short sounds and obey mute and suspension',()=>{
  const voices=[];
  const param=()=>({setValueAtTime(){},exponentialRampToValueAtTime(){}});
  const music=new AdventureMusic();
  music.master={};
  music.context={state:'running',currentTime:0,
    createGain:()=>({gain:param(),connect(){},disconnect(){}}),
    createOscillator:()=>{const voice={frequency:param(),connect(){},disconnect(){},start(time){this.startTime=time;},stop(time){this.stopTime=time;}};voices.push(voice);return voice;}};
  for(const kind of ['coin','jump','collision'])music.effect(kind);
  assert.equal(voices.length,5);
  assert.ok(voices.every(voice=>voice.stopTime-voice.startTime<.5));
  assert.ok(voices.some(voice=>voice.type==='triangle'));
  music.muted=true;music.effect('coin');assert.equal(voices.length,5);
  music.muted=false;music.context.state='suspended';music.effect('jump');assert.equal(voices.length,5);
});


test('version 3 offers a safe starting coin lane and preserves historical patterns', async()=>{
  const {runnerRow}=await import('../assets/runner/patterns.js');
  for(let row=0;row<40;row++){
    const early=runnerRow(row,100);assert.notEqual(early.coinLane,early.obstacleLane);
    const old=runnerRow(row,100,2);assert.equal(old.obstacleLane,row%3);assert.equal(old.coinLane,row%3);
  }
  assert.notEqual(runnerDifficulty(300,3).speed,runnerDifficulty(300,2).speed);
  assert.throws(()=>replayRun([[16667,[]]],3),/terminal collision/);
});
