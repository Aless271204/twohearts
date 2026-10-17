import test from 'node:test';
import assert from 'node:assert/strict';
import {GuardianAudio} from '../assets/runner/guardian/audio.js';
const param=()=>({value:0,setTargetAtTime(){},setValueAtTime(){},exponentialRampToValueAtTime(){},cancelScheduledValues(){}});
test('gesture unlock precedes online setup, music starts once and defeat has no voices',async()=>{
 let notes=0;
 const previous=globalThis.AudioContext;
 globalThis.AudioContext=class{
  constructor(){this.currentTime=0;this.state='suspended';this.destination={};}
  createGain(){return {gain:param(),connect(){},disconnect(){}};}
  createOscillator(){notes++;return {frequency:param(),connect(){},disconnect(){},start(){},stop(){}};}
  createBufferSource(){throw Error('Voices must remain disabled');}
  async resume(){this.state='running';}async suspend(){this.state='suspended';}async close(){this.state='closed';}
 };
 const audio=new GuardianAudio();
 try{await audio.unlock();assert.equal(audio.ctx.state,'running');assert.equal(audio.timer,null);
  await audio.start();assert.ok(notes>0);const timer=audio.timer;await audio.start();assert.equal(audio.timer,timer);
  audio.defeat('pig');assert.equal(audio.timer,null);await audio.start();audio.pause();assert.equal(audio.timer,null);
 }finally{audio.dispose();globalThis.AudioContext=previous;}
});
