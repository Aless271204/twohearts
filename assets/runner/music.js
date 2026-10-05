// An original, gently paced score synthesized locally. No audio downloads.
export class AdventureMusic {
  constructor(){this.context=null;this.timer=null;this.muted=false;this.step=0;this.endTimer=null;}
  async start(){
    try{
      clearTimeout(this.endTimer);
      if(!this.context)this.create();
      await this.context.resume();
      if(this.timer)return;
      this.next=this.context.currentTime+.08;
      this.timer=setInterval(()=>this.schedule(),80);this.schedule();
    }catch(error){console.warn('Music unavailable',error);}
  }
  create(){
    const AudioContext=window.AudioContext||window.webkitAudioContext;
    this.context=new AudioContext();const ctx=this.context;
    this.master=ctx.createGain();this.master.gain.value=this.muted?0:.24;
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
    const filter=ctx.createBiquadFilter();filter.type='lowpass';filter.frequency.value=type==='pad'?1000:2400;
    voice.connect(filter);filter.connect(pan);pan.connect(this.master);pan.connect(this.reverb);
    const attack=type==='pad'?.3:type==='flute'?.08:.012;
    voice.gain.setValueAtTime(.0001,time);voice.gain.exponentialRampToValueAtTime(volume,time+attack);
    voice.gain.exponentialRampToValueAtTime(.0001,time+duration);
    const oscillators=[];
    for(const [ratio,strength] of(type==='pluck'?[[1,1],[2,.23],[3,.06]]:type==='flute'?[[1,1],[2,.1]]:[[1,1],[1.002,.35]])){
      const oscillator=ctx.createOscillator(),level=ctx.createGain();oscillator.type='sine';oscillator.frequency.value=frequency*ratio;level.gain.value=strength;
      oscillator.connect(level);level.connect(voice);oscillator.start(time);oscillator.stop(time+duration+.05);oscillators.push(oscillator);
    }
    oscillators[0].onended=()=>{voice.disconnect();filter.disconnect();pan.disconnect();};
  }
  schedule(){
    const eighth=60/84/2;
    const chords=[[48,55,60,64,67],[43,55,59,62,67],[45,57,60,64,69],[41,53,57,60,65],[48,55,60,64,67],[45,57,60,64,69],[50,57,62,65,69],[43,55,59,62,67]];
    const melody=[[72,76,79,76],[74,71,67,71],[72,76,81,79],[77,76,72,69],[76,79,84,79],[81,79,76,72],[74,77,81,77],[79,74,71,72]];
    while(this.next<this.context.currentTime+.25){
      const bar=Math.floor(this.step/8)%8,beat=this.step%8,chord=chords[bar];
      this.note(chord[[1,2,3,2,4,3,2,1][beat]],this.next,.75,.085);
      if(beat===0){this.note(chord[0],this.next,2.5,.15);for(const note of chord.slice(2,4))this.note(note,this.next,2.7,.025,'pad');}
      if(beat%2===0)this.note(melody[bar][beat/2],this.next,1.1,.07,'flute');
      this.step=(this.step+1)%64;this.next+=eighth;
    }
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
    if(kind==='collision'){tone(150,45,0,.38,.8,'triangle');tone(85,35,.03,.25,.45);}
  }
  stopForCollision(){
    if(this.timer){clearInterval(this.timer);this.timer=null;}
    this.effect('collision');
    // Let the impact finish before suspending the audio context.
    this.endTimer=setTimeout(()=>this.pause(),500);
  }
  toggleMute(){this.muted=!this.muted;if(this.master)this.master.gain.setTargetAtTime(this.muted?0:.24,this.context.currentTime,.12);return this.muted;}
  async pause(){if(this.timer){clearInterval(this.timer);this.timer=null;}if(this.context?.state==='running')await this.context.suspend();}
  dispose(){clearTimeout(this.endTimer);if(this.timer)clearInterval(this.timer);this.context?.close();this.timer=null;}
}
