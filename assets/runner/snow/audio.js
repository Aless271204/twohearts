// Original upbeat snow-party score: bouncy bells, bass and soft percussion. No downloaded tracks.
export class SnowAudio{
 constructor(){this.music=.35;this.effects=.6;this.active=false;this.beat=0;}
 async start(){try{this.ctx??=new (globalThis.AudioContext??globalThis.webkitAudioContext)();await this.ctx.resume();if(this.active)return;this.active=true;this.next=this.ctx.currentTime+.08;this.timer=setInterval(()=>this.schedule(),100);this.schedule();}catch{}}
 tone(f,t,length,volume,type='sine',slide=null){if(!this.ctx||!volume)return;const o=this.ctx.createOscillator(),g=this.ctx.createGain();o.type=type;o.frequency.setValueAtTime(f,t);if(slide)o.frequency.exponentialRampToValueAtTime(slide,t+length);g.gain.setValueAtTime(.0001,t);g.gain.exponentialRampToValueAtTime(Math.max(.0002,volume),t+.015);g.gain.exponentialRampToValueAtTime(.0001,t+length);o.connect(g);g.connect(this.ctx.destination);o.start(t);o.stop(t+length+.03);o.onended=()=>{o.disconnect();g.disconnect();};}
 percussion(t,kind){if(!this.ctx||!this.music)return;const v=this.music*.09;if(kind==='kick'){this.tone(130,t,.13,v*1.4,'sine',48);return;}if(!this.noise){this.noise=this.ctx.createBuffer(1,Math.floor(this.ctx.sampleRate*.15),this.ctx.sampleRate);const a=this.noise.getChannelData(0);for(let i=0;i<a.length;i++)a[i]=Math.random()*2-1;}const n=this.ctx.createBufferSource(),filter=this.ctx.createBiquadFilter(),g=this.ctx.createGain();n.buffer=this.noise;filter.type='bandpass';filter.frequency.value=kind==='clap'?1300:3600;filter.Q.value=.6;g.gain.setValueAtTime(v*(kind==='clap'?.7:.17),t);g.gain.exponentialRampToValueAtTime(.0001,t+(kind==='clap'?.09:.035));n.connect(filter);filter.connect(g);g.connect(this.ctx.destination);n.start(t);n.stop(t+.14);n.onended=()=>{n.disconnect();filter.disconnect();g.disconnect();};}
 schedule(){if(!this.active)return;const melody=[74,78,81,78,83,81,78,76,74,78,81,86,83,81,78,76,71,74,78,74,81,78,76,74,73,76,81,85,83,81,78,76],chords=[[62,66,69],[67,71,74],[64,67,71],[69,73,76]];
  if(this.next<this.ctx.currentTime-.5)this.next=this.ctx.currentTime+.03;
  while(this.next<this.ctx.currentTime+.25){const b=this.beat++%32,ch=chords[Math.floor(b/8)],m=melody[b];this.tone(440*2**((m-69)/12),this.next,.15,this.music*(b%4===0?.13:.075),'triangle');if(b%4===0)this.tone(440*2**((m+12-69)/12),this.next,.22,this.music*.025,'sine');if(b%8===0)for(const n of ch)this.tone(440*2**((n-69)/12),this.next,.45,this.music*.03,'triangle');if(b%2===0)this.tone(440*2**((ch[b%4===0?0:2]-12-69)/12),this.next,.16,this.music*.12,'sine');if(b%8===0||b%8===3)this.percussion(this.next,'kick');if(b%8===4)this.percussion(this.next,'clap');this.percussion(this.next,'shaker');this.next+=60/144/2;}
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
