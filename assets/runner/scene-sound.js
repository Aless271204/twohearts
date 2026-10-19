// One owner per game. Unlocking a button never starts music in a menu.
export class SceneSound{
 constructor(theme,files={}){this.theme=theme;this.files=files;this.buffers=new Map();this.active=false;this.generation=0;this.musicVolume=.4;this.effectsVolume=.65;this.live=new Set();}
 async unlock(){
  try{
   if(!this.ctx){this.ctx=new (globalThis.AudioContext??globalThis.webkitAudioContext)();this.music=this.ctx.createGain();this.fx=this.ctx.createGain();this.music.connect(this.ctx.destination);this.fx.connect(this.ctx.destination);
    this.ready=Promise.allSettled(Object.entries({theme:this.theme,...this.files}).map(async([key,file])=>{const r=await fetch(new URL('../sounds/'+file,import.meta.url));if(!r.ok)throw Error('Audio no disponible');const b=await this.ctx.decodeAudioData(await r.arrayBuffer());if(this.ctx.state!=='closed')this.buffers.set(key,b);}));
   }
   await this.ctx.resume();this.volumes();return true;
  }catch{return false;}
 }
 volumes(){if(!this.ctx)return;this.music.gain.setTargetAtTime(this.active?this.musicVolume*.33:0,this.ctx.currentTime,.12);this.fx.gain.setTargetAtTime(this.effectsVolume*.7,this.ctx.currentTime,.025);}
 async start(){if(this.active)return;this.active=true;const generation=++this.generation;if(!await this.unlock()){this.active=false;return;}await this.ready;if(generation!==this.generation||!this.active||this.ctx.state==='closed')return;this.volumes();if(!this.source&&this.buffers.has('theme')){this.source=this.ctx.createBufferSource();this.source.buffer=this.buffers.get('theme');this.source.loop=true;this.source.connect(this.music);this.source.start();}}
 effect(kind,volume=1){if(!this.active||this.ctx?.state!=='running'||!this.buffers.has(kind))return false;const n=this.ctx.createBufferSource(),g=this.ctx.createGain();n.buffer=this.buffers.get(kind);g.gain.value=volume;n.connect(g);g.connect(this.fx);this.live.add(n);n.start();n.onended=()=>{this.live.delete(n);n.disconnect();g.disconnect();};return true;}
 pause(){this.active=false;++this.generation;this.source?.stop();this.source?.disconnect();this.source=null;for(const n of this.live)n.stop();this.live.clear();this.volumes();this.ctx?.suspend();}
 close(){this.pause();this.ctx?.close();}
}
