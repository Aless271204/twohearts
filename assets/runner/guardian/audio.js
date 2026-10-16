// Original lightweight score. Every layer shares the same transport and harmony.
// Intensities change at bar boundaries: exploration -> tension -> boss -> climax.
export class GuardianAudio{
 constructor(){this.ctx=null;this.timer=null;this.step=0;this.level=0;this.pending=0;this.lastEvent=0;this.musicVolume=.55;this.effectsVolume=.75;}
 async start(){try{if(!this.ctx){const Context=globalThis.AudioContext??globalThis.webkitAudioContext;this.ctx=new Context();this.music=this.ctx.createGain();this.fx=this.ctx.createGain();this.music.connect(this.ctx.destination);this.fx.connect(this.ctx.destination);this.applyVolumes();}await this.ctx.resume();if(this.timer)return;this.next=this.ctx.currentTime+.06;this.timer=setInterval(()=>this.schedule(),80);}catch{ /* Silent play remains available if audio is denied. */ }}
 applyVolumes(){if(!this.ctx)return;this.music.gain.setTargetAtTime(this.musicVolume*.24,this.ctx.currentTime,.08);this.fx.gain.setTargetAtTime(this.effectsVolume*.22,this.ctx.currentTime,.02);}
 tone(midi,time,duration,volume,type='triangle',destination=this.music){
  if(!this.ctx||!destination)return;const o=this.ctx.createOscillator(),g=this.ctx.createGain();o.type=type;o.frequency.value=440*2**((midi-69)/12);g.gain.setValueAtTime(.0001,time);g.gain.exponentialRampToValueAtTime(Math.max(.001,volume),time+.012);g.gain.exponentialRampToValueAtTime(.0001,time+duration);o.connect(g);g.connect(destination);o.start(time);o.stop(time+duration+.03);o.onended=()=>{o.disconnect();g.disconnect();};
 }
 schedule(){if(!this.ctx||this.ctx.state!=='running')return;const tick=60/116/2;
  if(this.next<this.ctx.currentTime-.3)this.next=this.ctx.currentTime+.03;
  const chords=[[50,57,62,65],[46,53,58,62],[48,55,60,64],[45,52,57,61]],melody=[74,0,77,76,74,69,72,0,70,0,74,77,76,74,72,69];
  while(this.next<this.ctx.currentTime+.18){const beat=this.step%8,bar=Math.floor(this.step/8)%4,c=chords[bar];if(beat===0)this.level=this.pending;
   if(beat===0)for(const n of c.slice(1))this.tone(n,this.next,tick*7,.045,'sine');
   if(beat%2===0)this.tone(c[0],this.next,tick*1.6,.18,'triangle');
   if(this.level>=1)this.tone(c[1+(beat%3)],this.next,tick*.65,.09,'triangle');
   const n=melody[this.step%16];if(n&&this.step%2===0)this.tone(n,this.next,tick*1.65,.12,'sine');
   if(this.level>=2){this.tone(beat%4===0?29:beat%2===0?43:86,this.next,.08,beat%4===0?.4:.10,beat%2?'square':'sine');if(beat%2)this.tone(c[2]+12,this.next,tick*.42,.045,'triangle');}
   if(this.level>=3)this.tone(c[1+((beat+1)%3)]+12,this.next,tick*.5,.07,'sawtooth');
   this.step++;this.next+=tick;
  }
 }
 update(s){this.pending=s.stage==='boss'?(s.difficulty==='hard'||s.boss.phase===2?3:2):s.players.some(p=>p.x>4400)?1:0;
  for(const e of s.events){if(e.id<=this.lastEvent)continue;this.lastEvent=e.id;this.effect(e.type);}
 }
 effect(type){if(!this.ctx||this.ctx.state!=='running')return;const t=this.ctx.currentTime;
  const notes={coin:[86,93],pickup:[76,81,88],jump:[62,69],dash:[74,67],pulse:[81,86],hit:[62],hurt:[40,35],shield:[88,81],warning:[46,46,53],impact:[29,34],roll:[38,41,45],link:[74,78,81,86],upgrade:[69,74,78,81],rescue:[74,81,86],victory:[74,78,81,86],defeat:[62,58,50],blocked:[43],theft:[76,64]};
  for(const [i,n] of (notes[type]??[]).entries())this.tone(n,t+i*.075,type==='impact'?.25:.13,.3,type==='hurt'?'sawtooth':'triangle',this.fx);
  if(type==='warning'){this.music.gain.cancelScheduledValues(t);this.music.gain.setTargetAtTime(this.musicVolume*.09,t,.03);this.music.gain.setTargetAtTime(this.musicVolume*.24,t+.35,.12);}
 }
 pause(){clearInterval(this.timer);this.timer=null;this.ctx?.suspend().catch(()=>{});}
 dispose(){this.pause();this.ctx?.close().catch(()=>{});this.ctx=null;}
}
