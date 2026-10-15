// Original expedition theme v2: orchestral fanfare, running strings, hand drums and bells.
export class AdventureMusic {
  constructor(){this.context=null;this.timer=null;this.muted=false;this.step=0;this.endTimer=null;this.generation=0;this.intensity=0;this.wantsPlayback=false;}
  async start(){
    const generation=++this.generation;this.wantsPlayback=true;
    try{
      clearTimeout(this.endTimer);
      if(!this.context)this.create();
      await this.context.resume();
      if(generation!==this.generation){if(!this.wantsPlayback&&this.context.state==='running')await this.context.suspend();return;}
      if(this.timer)return;
      this.next=this.context.currentTime+.08;
      this.timer=setInterval(()=>this.schedule(),80);this.schedule();
    }catch(error){console.warn('Music unavailable',error);}
  }
  create(){
    const AudioContext=window.AudioContext||window.webkitAudioContext;
    this.context=new AudioContext();const ctx=this.context;
    this.master=ctx.createGain();this.master.gain.value=this.muted?0:.34;
    const compressor=ctx.createDynamicsCompressor();compressor.threshold.value=-20;compressor.ratio.value=3;
    this.master.connect(compressor);compressor.connect(ctx.destination);
    this.reverb=ctx.createConvolver();
    const impulse=ctx.createBuffer(2,ctx.sampleRate*1.7,ctx.sampleRate);
    for(let channel=0;channel<2;channel++){const data=impulse.getChannelData(channel);for(let i=0;i<data.length;i++)data[i]=(Math.random()*2-1)*Math.pow(1-i/data.length,3)*.35;}
    this.reverb.buffer=impulse;const wet=ctx.createGain();wet.gain.value=.26;this.reverb.connect(wet);wet.connect(this.master);
  }
  note(midi,time,duration,volume,type='pluck'){
    const ctx=this.context,frequency=440*Math.pow(2,(midi-69)/12);
    const voice=ctx.createGain(),pan=ctx.createStereoPanner();pan.pan.value=type==='flute'?.12:-.16;
    const filter=ctx.createBiquadFilter();filter.type='lowpass';filter.frequency.value=type==='pad'?1700:type==='brass'?2200:3600;
    voice.connect(filter);filter.connect(pan);pan.connect(this.master);pan.connect(this.reverb);
    const attack=type==='pad'?.16:type==='brass'?.035:type==='flute'?.045:.012;
    voice.gain.setValueAtTime(.0001,time);voice.gain.exponentialRampToValueAtTime(volume,time+attack);
    voice.gain.exponentialRampToValueAtTime(.0001,time+duration);
    const oscillators=[];
    for(const [ratio,strength] of(type==='pluck'?[[1,1],[2,.23],[3,.06]]:type==='flute'?[[1,1],[2,.1]]:[[1,1],[1.002,.35]])){
      const oscillator=ctx.createOscillator(),level=ctx.createGain();oscillator.type=type==='pad'?'sawtooth':type==='brass'?'triangle':'sine';oscillator.frequency.value=frequency*ratio;level.gain.value=strength;
      oscillator.connect(level);level.connect(voice);oscillator.start(time);oscillator.stop(time+duration+.05);oscillators.push(oscillator);
    }
    oscillators[0].onended=()=>{voice.disconnect();filter.disconnect();pan.disconnect();};
  }
  schedule(){
    const eighth=60/(126+this.intensity*12)/2;
    const chords=[[50,57,62,66,69],[43,55,59,62,67],[47,59,62,66,71],[45,57,61,64,69],
      [50,57,62,66,69],[43,55,59,62,67],[52,59,64,67,71],[45,57,61,64,69]];
    const melody=[[74,0,78,81,83,81,78,0],[79,0,78,74,71,74,78,0],
      [78,0,81,83,86,83,81,78],[76,0,73,76,81,0,73,0],
      [86,0,83,81,78,81,83,86],[83,0,79,78,74,78,79,83],
      [88,86,83,79,76,79,83,86],[81,0,76,73,74,0,0,0]];
    while(this.next<this.context.currentTime+.25){
      const bar=Math.floor(this.step/8)%8,beat=this.step%8,chord=chords[bar];
      // Short moving strings keep a forward pulse rather than an ambient drone.
      this.note(chord[[1,2,3,2,4,3,2,1][beat]],this.next,eighth*.85,.035,'pad');
      if(beat===0||beat===4){this.drum(this.next,92,.16);this.note(chord[0],this.next,eighth*1.8,.18);}
      if(beat===2||beat===6){this.drum(this.next,210,.095);this.shaker(this.next,.055);}
      this.shaker(this.next,beat%2===0?.018:.032);
      if(beat===7)this.drum(this.next+eighth*.5,330,.045);
      if(beat===0)for(const n of chord.slice(2,5))this.note(n,this.next,eighth*7.5,.024,'pad');
      if(melody[bar][beat]){
        this.note(melody[bar][beat],this.next,eighth*(beat===0?1.65:.85),.14,'brass');
        if(bar>=4)this.note(melody[bar][beat]+12,this.next,eighth*1.6,.025,'pluck');
      }
      this.step=(this.step+1)%64;this.next+=eighth;
    }
  }
  shaker(time,volume){
    const ctx=this.context,buffer=ctx.createBuffer(1,Math.ceil(ctx.sampleRate*.075),ctx.sampleRate);
    const data=buffer.getChannelData(0);for(let i=0;i<data.length;i++)data[i]=(Math.random()*2-1)*(1-i/data.length);
    const source=ctx.createBufferSource(),gain=ctx.createGain(),filter=ctx.createBiquadFilter();
    source.buffer=buffer;filter.type='highpass';filter.frequency.value=2500;gain.gain.value=volume;
    source.connect(filter);filter.connect(gain);gain.connect(this.master);source.start(time);
    source.onended=()=>{source.disconnect();filter.disconnect();gain.disconnect();};
  }

  drum(time,frequency,volume){
    const ctx=this.context,oscillator=ctx.createOscillator(),gain=ctx.createGain();
    oscillator.type='sine';oscillator.frequency.setValueAtTime(frequency,time);oscillator.frequency.exponentialRampToValueAtTime(frequency*.45,time+.12);
    gain.gain.setValueAtTime(.0001,time);gain.gain.exponentialRampToValueAtTime(volume,time+.005);gain.gain.exponentialRampToValueAtTime(.0001,time+.16);
    oscillator.connect(gain);gain.connect(this.master);oscillator.start(time);oscillator.stop(time+.18);
    oscillator.onended=()=>{oscillator.disconnect();gain.disconnect();};
  }
  effect(kind){
    const ctx=this.context;if(!ctx||ctx.state!=='running'||this.muted)return;
    const time=ctx.currentTime;
    const tone=(from,to,delay,duration,volume,type='sine')=>{
      const oscillator=ctx.createOscillator(),gain=ctx.createGain();
      oscillator.type=type;oscillator.frequency.setValueAtTime(from,time+delay);
      oscillator.frequency.exponentialRampToValueAtTime(to,time+delay+duration);
      gain.gain.setValueAtTime(.0001,time+delay);
      gain.gain.exponentialRampToValueAtTime(volume,time+delay+.012);
      gain.gain.exponentialRampToValueAtTime(.0001,time+delay+duration);
      oscillator.connect(gain);gain.connect(this.master);
      oscillator.start(time+delay);oscillator.stop(time+delay+duration+.02);
      oscillator.onended=()=>{oscillator.disconnect();gain.disconnect();};
    };
    if(kind==='coin'){tone(880,1108,0,.12,.55);tone(1320,1760,.07,.22,.35);}
    if(kind==='jump')tone(240,650,0,.2,.42,'triangle');
    if(kind==='land')tone(95,55,0,.09,.12,'triangle');
    if(kind==='collision'){tone(150,45,0,.38,.8,'triangle');tone(85,35,.03,.25,.45);}
  }
  stopForCollision(){
    if(this.timer){clearInterval(this.timer);this.timer=null;}
    this.effect('collision');
    // Let the impact finish before suspending the audio context.
    this.endTimer=setTimeout(()=>this.pause(),500);
  }
  toggleMute(){this.muted=!this.muted;if(this.master)this.master.gain.setTargetAtTime(this.muted?0:.34,this.context.currentTime,.12);return this.muted;}
  async pause(){this.wantsPlayback=false;this.generation++;clearTimeout(this.endTimer);if(this.timer){clearInterval(this.timer);this.timer=null;}if(this.context?.state==='running')await this.context.suspend();}
  dispose(){this.wantsPlayback=false;this.generation++;clearTimeout(this.endTimer);if(this.timer)clearInterval(this.timer);this.context?.close();this.timer=null;}
}
