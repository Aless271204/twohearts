import {SceneSound} from '../scene-sound.js';
// Packaged original music and generated mascot crowd; no network stream.
export class StadiumAudio{
 constructor(){this.ambientVolume=.45;this.effectsVolume=.7;this.nodes=[];this.enabled=false;this.active=false;this.samples={};this.sound=new SceneSound('penalty_theme.mp3',{crowdGoal:'penalty_crowd_goal.mp3',crowdMiss:'penalty_crowd_miss.mp3',click:'scene_click.mp3'});}
 async unlock(){
  if(!this.ctx){this.ctx=new (globalThis.AudioContext||globalThis.webkitAudioContext)();const c=this.ctx;
   this.master=c.createGain();this.master.gain.value=.7;this.master.connect(c.destination);
   this.ambient=c.createGain();this.ambient.gain.value=0;this.fx=c.createGain();this.ambient.connect(this.master);this.fx.connect(this.master);
   const buffer=c.createBuffer(1,c.sampleRate*4,c.sampleRate),data=buffer.getChannelData(0);let smooth=0;
   for(let i=0;i<data.length;i++){smooth=(smooth+(Math.random()*2-1)*.035)/1.035;data[i]=smooth*4;}
   this.noise=buffer;
   // Small original cues load without delaying the first interaction; synthesis is the fallback.
   for(const key of ['whistle','tick','timeup'])fetch(new URL(`../../sounds/penalty_${key}.wav`,import.meta.url)).then(r=>{if(!r.ok)throw Error('Audio unavailable');return r.arrayBuffer();}).then(b=>c.decodeAudioData(b)).then(b=>{if(c.state!=='closed')this.samples[key]=b;}).catch(()=>{});
   const crowd=c.createBufferSource(),filter=c.createBiquadFilter();crowd.buffer=buffer;crowd.loop=true;filter.type='bandpass';filter.frequency.value=650;filter.Q.value=.45;
   crowd.connect(filter);filter.connect(this.ambient);crowd.start();this.nodes.push(crowd);
   const lfo=c.createOscillator(),depth=c.createGain();lfo.frequency.value=.18;depth.gain.value=0;this.crowdDepth=depth;lfo.connect(depth);depth.connect(this.ambient.gain);lfo.start();this.nodes.push(lfo);
  }
  this.enabled=true;await this.sound.unlock();this.volumes();await this.ctx.resume();
 }
 async start(){if(this.active)return;this.active=true;try{await this.unlock();if(this.active)await this.sound.start();}catch{this.active=false;}}
 volumes(){this.sound.musicVolume=this.ambientVolume;this.sound.effectsVolume=this.effectsVolume;this.sound.volumes();if(!this.ctx)return;this.crowdDepth.gain.value=this.active?this.ambientVolume*.004:0;this.ambient.gain.setTargetAtTime(this.active?this.ambientVolume*.055:0,this.ctx.currentTime,.12);this.fx.gain.setTargetAtTime(this.effectsVolume*.65,this.ctx.currentTime,.05);}
 tone(freq,end,duration,volume=.2,type='sine',delay=0){
  if(!this.ctx||!this.enabled)return;const c=this.ctx,t=c.currentTime+delay,o=c.createOscillator(),g=c.createGain();o.type=type;o.frequency.setValueAtTime(freq,t);o.frequency.exponentialRampToValueAtTime(Math.max(20,end),t+duration);g.gain.setValueAtTime(.0001,t);g.gain.exponentialRampToValueAtTime(volume,t+.012);g.gain.exponentialRampToValueAtTime(.0001,t+duration);o.connect(g);g.connect(this.fx);o.start(t);o.stop(t+duration+.02);o.onended=()=>{o.disconnect();g.disconnect();};
 }
 burst(duration,freq,volume,delay=0){
  if(!this.ctx||!this.enabled)return;const c=this.ctx,t=c.currentTime+delay,n=c.createBufferSource(),f=c.createBiquadFilter(),g=c.createGain();n.buffer=this.noise;f.type='bandpass';f.frequency.value=freq;f.Q.value=.6;g.gain.setValueAtTime(.0001,t);g.gain.exponentialRampToValueAtTime(volume,t+.04);g.gain.exponentialRampToValueAtTime(.0001,t+duration);n.connect(f);f.connect(g);g.connect(this.fx);n.start(t,Math.random()*2);n.stop(t+duration+.02);n.onended=()=>{n.disconnect();f.disconnect();g.disconnect();};
 }
 play(kind){
  if(!this.ctx||!this.enabled||!this.active)return;
  if(this.samples[kind]){const n=this.ctx.createBufferSource();n.buffer=this.samples[kind];n.connect(this.fx);n.start();n.onended=()=>n.disconnect();return;}
  if(kind==='tick')this.tone(660,660,.16,.12);
  if(kind==='timeup')this.tone(440,115,.48,.14);
  if(kind==='kick'){this.tone(145,42,.19,.7);this.burst(.09,1700,.32);}
  if(kind==='dive')this.burst(.38,900,.42);
  if(kind==='save'){this.burst(.16,430,.9);this.tone(105,55,.13,.25);}
  if(kind==='post'){this.tone(690,650,.75,.28,'triangle');this.tone(1330,1280,.4,.12);}
  if(kind==='whistle')this.tone(2400,2600,.35,.07);
  if(kind==='goal'){
   this.sound.effect('crowdGoal');
  }
  if(kind==='miss'||kind==='post'||kind==='save'){
   this.sound.effect('crowdMiss',.9);
  }
 }
 pause(){this.active=false;this.enabled=false;this.sound.pause();this.ctx?.suspend();}
 close(){this.pause();this.sound.close();for(const n of this.nodes)n.stop();this.nodes=[];this.ctx?.close();}
}
