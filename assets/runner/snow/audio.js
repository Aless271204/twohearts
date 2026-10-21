// Original celesta/warm-bass loop and soft toy effects; no downloaded tracks.
export class SnowAudio{
 constructor(){this.music=.35;this.effects=.6;this.active=false;this.beat=0;}
 async start(){try{this.ctx??=new (globalThis.AudioContext??globalThis.webkitAudioContext)();await this.ctx.resume();if(this.active)return;this.active=true;this.next=this.ctx.currentTime+.08;this.timer=setInterval(()=>this.schedule(),100);this.schedule();}catch{}}
 tone(f,t,length,volume,type='sine',slide=null){if(!this.ctx||!volume)return;const o=this.ctx.createOscillator(),g=this.ctx.createGain();o.type=type;o.frequency.setValueAtTime(f,t);if(slide)o.frequency.exponentialRampToValueAtTime(slide,t+length);g.gain.setValueAtTime(.0001,t);g.gain.exponentialRampToValueAtTime(Math.max(.0002,volume),t+.015);g.gain.exponentialRampToValueAtTime(.0001,t+length);o.connect(g);g.connect(this.ctx.destination);o.start(t);o.stop(t+length+.03);o.onended=()=>{o.disconnect();g.disconnect();};}
 schedule(){if(!this.active)return;const melody=[76,79,83,79,74,78,81,78,72,76,79,76,74,78,81,86],chords=[[60,64,67],[62,66,69],[57,60,64],[59,62,67]];
  while(this.next<this.ctx.currentTime+.25){const b=this.beat++%32,ch=chords[Math.floor(b/8)],m=melody[Math.floor(b/2)];if(b%2===0)this.tone(440*2**((m-69)/12),this.next,.34,this.music*.11,'sine');if(b%8===0)for(const n of ch)this.tone(440*2**((n-69)/12),this.next,.95,this.music*.035,'triangle');if(b%4===0)this.tone(440*2**((ch[0]-12-69)/12),this.next,.22,this.music*.10,'sine');if(b%2===1)this.tone(1400,this.next,.035,this.music*.012,'triangle');this.next+=60/108/2;}
 }
 fx(kind,volume=1){if(!this.active||!this.ctx)return;const t=this.ctx.currentTime,v=this.effects*volume*.12;
  if(kind==='countdown')this.tone(660,t,.12,v*.8);
  else if(kind==='go'){this.tone(880,t,.16,v);this.tone(1100,t+.12,.22,v);}
  else if(kind==='throw')this.tone(260,t,.10,v,'sine',140);
  else if(kind==='hit')this.tone(170,t,.16,v*1.5,'triangle',80);
  else if(kind==='jump')this.tone(280,t,.15,v*.55,'sine',440);
  else if(kind==='pickup'||kind==='gift')for(const [i,f]of [523,659,784].entries())this.tone(f,t+i*.075,.18,v*.65);
  else if(kind==='super')for(const [i,f]of [196,294,392,588].entries())this.tone(f,t+i*.05,.42,v,'triangle');
  else if(kind==='shield')this.tone(880,t,.3,v,'sine',440);
  else if(kind==='rescue')for(const [i,f]of [392,523,659].entries())this.tone(f,t+i*.10,.25,v);
  else if(kind==='finish')for(const [i,f]of [523,659,784,1046].entries())this.tone(f,t+i*.12,.4,v);
  else this.tone(360,t,.06,v*.5);
 }
 pause(){this.active=false;clearInterval(this.timer);this.ctx?.suspend();}
 close(){this.pause();this.ctx?.close();}
}
