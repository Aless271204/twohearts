import test from 'node:test';import assert from 'node:assert/strict';
import {runtimeUrl} from './three-runtime.mjs';
const {SceneSound}=await import(runtimeUrl('../assets/runner/scene-sound.js'));
test('unlock stays silent; exiting during decoding cannot start music later; game starts only one loop',async()=>{
 const oldContext=globalThis.AudioContext,oldFetch=globalThis.fetch;let release,started=0,stopped=0;
 const pending=new Promise(r=>release=r);
 class Context{
  state='suspended';currentTime=0;destination={};
  async resume(){this.state='running';}suspend(){this.state='suspended';}close(){this.state='closed';}
  createGain(){return {gain:{value:0,setTargetAtTime(){}},connect(){},disconnect(){}};}
  createBufferSource(){return {connect(){},disconnect(){},start(){started++;},stop(){stopped++;this.onended?.();}};}
  async decodeAudioData(){await pending;return {};}
 }
 globalThis.AudioContext=Context;globalThis.fetch=async()=>({ok:true,arrayBuffer:async()=>new ArrayBuffer(8)});
 try{
  const audio=new SceneSound('maze_theme.mp3',{chest:'maze_chest.mp3'});
  await audio.unlock();assert.equal(started,0,'No menu music');
  const start=audio.start();await Promise.resolve();audio.pause();release();await start;
  assert.equal(started,0,'An old decode cannot revive a closed game');
  await audio.start();assert.equal(started,1);await audio.start();assert.equal(started,1,'One loop only');
  assert.equal(audio.effect('chest'),true);assert.equal(started,2);assert.equal(audio.effect('missing'),false);
  audio.close();assert.equal(audio.ctx.state,'closed');assert.ok(stopped>=2);
 }finally{globalThis.AudioContext=oldContext;globalThis.fetch=oldFetch;}
});
