import {createGame,replay} from './engine.js';
import {transcriptHash} from './transcript.js';
const pending=new Map();let requestSeq=0;
export const hasAppBridge=()=>new URLSearchParams(globalThis.location?.search??'').get('preview')!=='1'&&(!!globalThis.RunnerBridge||!!globalThis.parent&&globalThis.parent!==globalThis);
export function request(action,payload={}){
 if(!hasAppBridge())return Promise.reject(Error('Abre Guardianes desde NIDO e inicia sesión para jugar online.'));
 const id=++requestSeq,message=JSON.stringify({type:'guardian-request',id,action,payload});
 return new Promise((resolve,reject)=>{const timer=setTimeout(()=>{pending.delete(id);reject(Error('La conexión tardó demasiado. Vuelve a intentarlo.'));},25000);pending.set(id,{resolve,reject,timer});if(globalThis.RunnerBridge)RunnerBridge.postMessage(message);else parent.postMessage(message,location.origin);});
}
let receiver=null;
function receive(m){if(typeof m==='string'){try{m=JSON.parse(m);}catch{return;}}if(m?.type==='guardian-event'){receiver?.(m.data);return;}if(m?.type!=='guardian-response')return;const p=pending.get(m.id);if(!p)return;clearTimeout(p.timer);pending.delete(m.id);if(m.ok)p.resolve(m.result);else p.reject(Error(m.error??'No pudimos conectar.'));}
globalThis.guardianBridgeResponse=receive;
if(globalThis.addEventListener)globalThis.addEventListener('message',e=>{if(e.origin===location.origin&&e.source===parent)receive(e.data);});
const wait=ms=>new Promise(r=>setTimeout(r,ms));
export function packState(s,paused,ack){return {v:2,combat:s.combat??'legacy',route:s.level.routeVersion??0,chapter:s.chapter??'forest',f:s.frame,status:s.status,stage:s.stage,gold:s.gold,upgrades:s.upgrades,checkpoint:s.checkpoint,players:s.players,boss:s.boss,en:s.level.enemies.map(e=>[e.id,e.x,e.y,e.hp]),co:s.level.coins.filter(c=>c.used).map(c=>c.id),pu:s.level.pickups.filter(c=>c.used).map(c=>c.id),shots:s.shots,hazards:s.hazards,events:s.events,eventSeq:s.eventSeq??0,sigils:s.sigils,paused,ack};}
export function applyState(s,p){if((p?.combat??'legacy')!==(s.combat??'legacy')||(p?.route??0)!==(s.level.routeVersion??0)||(p?.chapter??'forest')!==(s.chapter??'forest')||p?.v!==2||!Number.isInteger(p.f)||p.f<s.frame||!Array.isArray(p.players)||p.players.length!==2)return false;
 for(const k of ['status','stage','gold','upgrades','checkpoint','players','boss','shots','hazards','events','eventSeq','sigils'])s[k]=p[k];s.frame=p.f;
 for(const [id,x,y,hp]of p.en){const e=s.level.enemies[id];if(e){e.x=x;e.y=y;e.hp=hp;}}
 const coins=new Set(p.co),pickups=new Set(p.pu);for(const c of s.level.coins)c.used=coins.has(c.id);for(const c of s.level.pickups)c.used=pickups.has(c.id);return true;
}
export class GuardianSession{
 constructor(info){this.info=info;this.role=info.role;this.id=info.id;this.ownSeq=0;this.lastMask=0;this.remoteSeq=0;this.remoteMask=0;this.remoteQueue=new Map();this.ownHistory=new Map();this.unacked=[];this.databaseQueue=[];this.flushing=null;this.lastPeer=performance.now();this.lastSnapshot=0;this.closed=false;this.chunks=new Map();this.ack=0;this.remotePaused=false;this.onPacket=()=>{};this.onPause=()=>{};this.onLeave=()=>{};this.peerReceipt=false;receiver=p=>this.receive(p);}
 static async create(mode,difficulty,species,code=null,chapter='forest'){const info=await request('room',{p_packets:{engine_version:7,chapter},p_action:mode==='solo'?'solo':code?'join':'create',p_difficulty:difficulty,p_species:species,...(code?{p_code:code}:{})});return new GuardianSession(info);}
 rpc(action,extra={}){return request('room',{p_action:action,p_id:this.id,...extra});}
 send(data){if(this.closed||this.info.mode==='solo')return Promise.resolve();return request('send',{data});}
 async connect(onStatus){
  if(this.info.mode==='solo'){this.startMaintenance();return this.info;}
  await request('watch',{room:this.id});
  for(let i=0;i<600&&!this.closed;i++){const info=await this.rpc('status');this.info=info;onStatus(info);if(info.status==='cancelled')throw Error('La sala se cerró. Crea una nueva.');if(info.status==='running'){const delay=Math.max(0,Date.parse(info.started_at)-Date.parse(info.server_time));await wait(delay);this.startMaintenance();return info;}await wait(1000);}
  throw Error('La sala ha caducado. Crea otra para jugar.');
 }
 startMaintenance(){this.lastPeer=performance.now();this.timer=setInterval(()=>{this.flush().catch(()=>{});if(this.info.mode==='partner'){this.send({kind:'input',packets:this.role===1?this.unacked.slice(0,100):[],heartbeat:true}).catch(()=>{});}},500);}
 capture(mask){if(mask===this.lastMask)return;this.lastMask=mask;const p=[++this.ownSeq,mask];this.ownHistory.set(p[0],p[1]);this.databaseQueue.push(p);this.unacked.push(p);if(this.role===1)this.send({kind:'input',packets:this.unacked.slice(0,100)}).catch(()=>{});}
 consumeRemote(){const next=this.remoteQueue.get(this.remoteSeq+1);if(next!==undefined){this.remoteSeq++;this.remoteMask=next;this.remoteQueue.delete(this.remoteSeq);}return this.remoteMask;}
 async flush(){if(this.flushing)return this.flushing;if(!this.databaseQueue.length)return;
  this.flushing=(async()=>{while(this.databaseQueue.length){const batch=this.databaseQueue.slice(0,128);await this.rpc('inputs',{p_packets:batch});this.databaseQueue.splice(0,batch.length);}})();
  try{await this.flushing;}finally{this.flushing=null;}
 }
 receive(raw){const p=raw?.payload??raw;if(!p||this.closed)return;this.lastPeer=performance.now();
  if(this.role===0&&p.kind==='input'&&Array.isArray(p.packets)){for(const [seq,mask]of p.packets)if(Number.isInteger(seq)&&seq>this.remoteSeq&&seq<=this.remoteSeq+128&&Number.isInteger(mask)&&mask>=0&&mask<=63)this.remoteQueue.set(seq,mask);}
  if(this.role===1&&p.kind==='state'){if(p.state.f<this.lastSnapshot)return;this.lastSnapshot=p.state.f;this.ack=p.state.ack??0;this.unacked=this.unacked.filter(([seq])=>seq>this.ack);this.onPacket(p.state);}
  if(p.kind==='pause')this.onPause(true);if(p.kind==='resume')this.onPause(false);if(p.kind==='leave')this.onLeave();
  if(p.kind==='wardrobe'&&Array.isArray(p.loadout)&&p.loadout.length<=5)this.onWardrobe?.(p.loadout);
  if(this.role===1&&p.kind==='replay'){this.chunks.set(p.index,p);if(this.chunks.size===p.total&&!this.confirming){this.confirming=this.confirmChunks(p).catch(error=>{this.confirming=null;this.confirmError=error;});}}
 }
 async confirmChunks(packet){if(!Number.isInteger(packet.total)||packet.total<1||packet.total>60)throw Error('Repetición inválida');const events=[],refs=[];
  for(let i=0;i<packet.total;i++){const c=this.chunks.get(i);if(!c||c.hash!==packet.hash||!Array.isArray(c.events)||c.events.length>200)throw Error('Repetición incompleta');events.push(...c.events);refs.push(...c.refs);}
  for(let i=0;i<events.length;i++)if(events[i][1]===1&&this.ownHistory.get(refs[i])!==events[i][2])throw Error('Las entradas de tu mascota no coinciden');
  const hash=await transcriptHash(this.id,packet.frames,events,refs);if(hash!==packet.hash)throw Error('La repetición no coincide');
  const r=replay(Number(this.info.seed),this.info.difficulty,'partner',events,packet.frames,this.info.species,[4,5,7].includes(this.info.engine_version)?'river':'forest',this.info.engine_version<5?'legacy':'stones',this.info.engine_version>=6?'aerial':'legacy');if(!['victory','defeat'].includes(r.state.status))throw Error('La partida todavía no ha terminado');
  await this.flush();await this.rpc('confirm',{p_packets:{hash}});this.peerReceipt=true;
 }
 snapshot(s,paused){return this.send({kind:'state',state:packState(s,paused,this.remoteSeq)});}
 async save(s,events,refs){
  await this.flush();
  if(this.role===1){for(let i=0;i<60;i++){const info=await this.rpc('status');if(info.status==='finished')return {saved:true,reward:info.reward,total_reward:info.total_reward,prize:info.prize};if(info.status==='cancelled')throw Error('La partida se cerró sin guardar');if(this.confirmError)throw this.confirmError;await wait(750);}throw Error('Esperando la confirmación de la partida. Puedes volver a guardar.');}
  const hash=await transcriptHash(this.id,s.frame,events,refs);
  if(this.info.mode==='partner'){
   const total=Math.max(1,Math.ceil(events.length/200));let confirmed=false;
   for(let attempt=0;attempt<20;attempt++){
    if(attempt%3===0)for(let i=0;i<total;i++)await this.send({kind:'replay',index:i,total,frames:s.frame,hash,events:events.slice(i*200,(i+1)*200),refs:refs.slice(i*200,(i+1)*200)});
    const info=await this.rpc('status');if(info.confirmed){confirmed=true;break;}await wait(750);
   }
   if(!confirmed)throw Error('Falta la confirmación de tu pareja. Mantén ambos celulares conectados.');
  }
  return request('finish',{room:this.id,frames:s.frame,events,refs});
 }
 async close(cancel=true){if(this.closed)return;clearInterval(this.timer);try{if(cancel){await this.send({kind:'leave'});await this.rpc('cancel');}}catch{}this.closed=true;receiver=null;await request('close').catch(()=>{});}
}
