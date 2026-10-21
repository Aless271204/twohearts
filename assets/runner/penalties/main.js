import {celebrateVictory} from '../celebration.js';
import {PenaltyScene} from './scene.js?revision=centered-striker-9';
import {StadiumAudio} from './audio.js?revision=stadium-sound-8';
import {newMatch,resolveShot,advanceMatch,shooter} from './rules.js';
import {watchAppearance} from '../live-appearance.js';
let whistleRound='',celebrated='',closeCelebration=()=>{};
const $=id=>document.getElementById(id),audio=new StadiumAudio(),aim={x:.5,y:.5};let scene,room=null,practice=false,pending=false,local=newMatch(),lastRound=-1,generation=-1,animationUntil=0,polling=false,stopped=false,botChoice=null;
let modelsReady=false,modelKey='',loadingModels=null;let localDeadline=0,serverOffset=0;let timer=null,requestID=0,frameID=0;const requests=new Map(),params=new URLSearchParams(location.search),species=params.get('species')||'penguin';
const hasBridge=()=>!!globalThis.RunnerBridge||parent!==globalThis;
let ownAppearance={},ownAppearanceSide=0;try{ownAppearance=JSON.parse(params.get('appearance')??'{}');}catch{}
let appliedAppearanceKey='',pendingAppearanceKey='';
async function refreshAppearance(){if(scene&&modelsReady){
 const side=practice?0:room?.side??0,look=structuredClone(ownAppearance),key=JSON.stringify([scene.actors?.[side]?.children[0]?.uuid??modelKey,side,look]);
 if(key===appliedAppearanceKey||key===pendingAppearanceKey)return;
 pendingAppearanceKey=key;
 try{if(side!==ownAppearanceSide)await scene.setAppearance({},ownAppearanceSide);ownAppearanceSide=side;await scene.setAppearance(look,side);appliedAppearanceKey=key;}
 finally{if(pendingAppearanceKey===key)pendingAppearanceKey='';}
}}
watchAppearance(async value=>{ownAppearance=value;try{await refreshAppearance();}catch(error){status('No se pudo actualizar la ropa. '+error.message);}});
// Restoring a room is optional: restricted WebViews may deny storage entirely.
const roomStorage={
 get(){try{return sessionStorage.getItem('nido-penalty-room');}catch{return null;}},
 set(id){try{sessionStorage.setItem('nido-penalty-room',id);}catch{}},
 clear(){try{sessionStorage.removeItem('nido-penalty-room');}catch{}},
};
function request(action,data={}){
 if(!hasBridge())return Promise.reject(Error('Abre el juego desde NIDO para jugar online. Puedes probar Entrenar aquí.'));
 const id=++requestID,m=JSON.stringify({type:'runner-request',id,action:'penalties',payload:{p_action:action,...data}});
 return new Promise((resolve,reject)=>{const timeout=setTimeout(()=>{requests.delete(id);reject(Error('No hubo respuesta. Reintenta con la misma sala.'));},18000);requests.set(id,{resolve,reject,timeout});if(globalThis.RunnerBridge)RunnerBridge.postMessage(m);else parent.postMessage(m,location.origin);});
}
function receive(m){if(typeof m==='string'){try{m=JSON.parse(m);}catch{return;}}if(m?.type!=='runner-response')return;const r=requests.get(m.id);if(!r)return;clearTimeout(r.timeout);requests.delete(m.id);m.ok?r.resolve(m.result):r.reject(Error(m.error||'No se pudo conectar.'));}
globalThis.runnerBridgeResponse=receive;addEventListener('message',e=>{if(e.origin===location.origin&&e.source===parent)receive(e.data);});
const status=t=>$('message').textContent=t;
let lastCountdownCue='';
async function unlock(){try{await audio.unlock();}catch{/* Sound may be unavailable; controls remain playable. */}}
function panels(id){for(const name of ['menu','lobby','result'])$(name).hidden=name!==id;$('controls').hidden=!!id;}
function snapshot(){return practice?{state:local,side:0,status:local.winner===null?'playing':'finished',generation:0,species:[species,'bear']}:room;}
function accept(next){room=next;
 const key=JSON.stringify(next.species);if(next.joined&&key!==modelKey&&!loadingModels){modelsReady=false;loadingModels=scene.load(next.species).then(()=>{modelKey=key;modelsReady=true;lastRound=-1;return refreshAppearance();}).catch(()=>status('No se pudo cargar la mascota. Recarga para reintentar.')).finally(()=>loadingModels=null);}
 if(modelsReady&&!loadingModels)refreshAppearance().catch(error=>status('No se pudo actualizar la ropa. '+error.message));
 serverOffset=Date.parse(next.server_time)-Date.now();return next;}
function update(){
 const info=snapshot();if(!info)return;const s=info.state,side=info.side,mine=side===shooter(s),now=performance.now()/1000;
 if(info.status==='playing'&&!document.hidden&&audio.enabled&&!audio.active)audio.start();
 const seconds=Math.max(0,Math.min(15,Math.ceil(((practice?localDeadline:Date.parse(info.deadline)-serverOffset)-Date.now())/1000)));
 $('clock').textContent=`⏱ ${seconds} s`;
 const countdownCue=`${info.generation}:${s.round}:${seconds}`;
 if(info.status==='playing'&&now>=animationUntil&&seconds<=5&&lastCountdownCue!==countdownCue){lastCountdownCue=countdownCue;audio.play(seconds===0?'timeup':'tick');}
 if(practice&&seconds===0&&now>=animationUntil&&local.winner===null&&localDeadline){
  const bot=botChoice??{x:.5,y:.5,power:.6},timeout={x:0,y:1,power:1},center={x:.5,y:.5,power:.5};
  local=advanceMatch(local,shooter(local)===0?resolveShot(timeout,bot):resolveShot(bot,center));localDeadline=Date.now()+17800;botChoice=null;update();return;
 }
 $('score').textContent=`🔵 ${s.score[0]} — ${s.score[1]} 🔴`;
 $('attempts').textContent=s.attempts.map((a,i)=>(i?'Rojo ':'Azul ')+(a.map(g=>g?'●':'×').join(' ')||'—')).join('   ·   ');
 $('turn').textContent=s.round>=10?'MUERTE SÚBITA':`Tiro ${Math.floor(s.round/2)+1} / 5`;
 if(info.status==='waiting'){
  panels('lobby');$('roomcode').textContent=info.code;$('lobbystatus').textContent=info.joined?(info.ready[1-side]?'Tu pareja está lista.':'Tu pareja ya entró.'):'Comparte este código con tu pareja.';$('ready').disabled=info.ready[side];return;
 }
 if(info.status==='cancelled'){audio.pause();panels('menu');$('error').textContent='La otra persona salió de la sala.';stopPolling();roomStorage.clear();return;}
 if(generation!==info.generation){generation=info.generation;lastRound=-1;animationUntil=0;pending=false;}
 if(s.round!==lastRound){
  if(lastRound>=0&&s.last){
   scene.setTurn(s.last.side,side);scene.animate(s.last,now);setTimeout(()=>{if(!stopped&&!document.hidden)audio.play('kick');},340);setTimeout(()=>{if(!stopped&&!document.hidden)audio.play('dive');},460);
   setTimeout(()=>{if(!stopped&&!document.hidden)audio.play(s.last.kind);},1240);
   animationUntil=now+2.8;status(({goal:'¡GOOOL!',save:'¡Atajada!',post:'¡Al poste!',miss:'¡Se fue afuera!'})[s.last.kind]);
  }else {scene.setTurn(shooter(s),side);}
  lastRound=s.round;pending=false;
 }
 if(now<animationUntil){$('controls').hidden=true;return;}
 if(info.status==='finished'){
  const victoryKey=String(info.id??'practice')+':'+info.generation+':'+s.round+':'+s.winner;if(victoryKey!==celebrated){celebrated=victoryKey;if(s.winner===side){closeCelebration();closeCelebration=celebrateVictory({sound:()=>audio.play('firework')});audio.play('goal');}}
  panels('result');$('resultTitle').textContent=s.winner===side?'¡Ganaste la tanda!':'¡Buena partida!';$('resultScore').textContent=`Azul ${s.score[0]} — ${s.score[1]} Rojo`;
  $('reward').textContent=practice?'Entrenamiento · Sin premio de oro':((room?.reward??0)+' de oro guardado.'+(room?.record_bonus?' · ¡Récord! +'+room.record_bonus+' extra.':''));
  $('again').disabled=!practice&&info.ready[side];$('rematchStatus').textContent=!practice&&info.ready[side]?'Esperando a que tu pareja pulse Volver a jugar…':'';return;
 }
 const whistleKey=String(info.id??'practice')+':'+info.generation+':'+s.round;if(whistleKey!==whistleRound&&audio.active){whistleRound=whistleKey;audio.play('whistle');}
 panels(null);scene.setTurn(shooter(s),side);$('powerWrap').hidden=!mine;$('action').textContent=mine?'PATEAR':'ATAJAR';$('action').className=mine?'primary':'blue';$('aimlabel').textContent=mine?'APUNTAR':'DIRECCIÓN';
 $('action').disabled=pending||info.chosen||!modelsReady;status(pending||info.chosen?'Elección confirmada. Esperando a tu pareja…':mine?'Apunta, ajusta la fuerza y patea.':'Elige dónde lanzarte y confirma la atajada.');
}
async function online(action){
 try{await unlock();practice=false;room=accept(await request(action,{p_code:$('code').value.trim().toUpperCase(),p_data:{species}}));roomStorage.set(room.id);generation=-1;lastRound=-1;update();startPolling();}
 catch(e){$('error').textContent=e.message;}
}
function startPolling(){stopPolling();timer=setInterval(async()=>{if(polling||document.hidden||!room||stopped)return;polling=true;try{room=accept(await request('status',{p_id:room.id}));update();}catch(e){status(e.message);}finally{polling=false;}},650);}
function stopPolling(){clearInterval(timer);timer=null;}
function startPractice(){if(!modelsReady)return;closeCelebration();celebrated=whistleRound='';stopPolling();practice=true;room=null;local=newMatch();generation=-1;lastRound=-1;animationUntil=0;pending=false;botChoice=null;localDeadline=Date.now()+15000;update();}
async function choose(){
 const info=snapshot();if(!modelsReady||!info||pending||info.chosen||performance.now()/1000<animationUntil||info.status!=='playing')return;
 await unlock();pending=true;update();const choice={x:info.side===shooter(info.state)?aim.x:1-aim.x,y:aim.y,power:Number($('power').value)/100};
 if(practice){
  // Bot chooses independently before receiving the player's direction.
  const bot=botChoice??{x:.08+Math.random()*.84,y:.15+Math.random()*.7,power:.4+Math.random()*.48};botChoice=null;
  const result=shooter(local)===0?resolveShot(choice,bot):resolveShot(bot,choice);local=advanceMatch(local,result);localDeadline=Date.now()+17800;update();
 }else try{room=accept(await request('choose',{p_id:room.id,p_data:{round:info.state.round,generation:info.generation,choice}}));update();}catch(e){pending=false;status(e.message);$('action').disabled=false;}
}
function pointer(e){const b=$('aim').getBoundingClientRect(),x=Math.max(0,Math.min(1,(e.clientX-b.left)/b.width)),y=Math.max(0,Math.min(1,1-(e.clientY-b.top)/b.height));aim.x=x;aim.y=y;$('stick').style.left=`${x*(b.width-42)}px`;$('stick').style.top=`${(1-y)*(b.height-42)}px`;}
$('aim').onpointerdown=e=>{e.currentTarget.setPointerCapture(e.pointerId);pointer(e);};$('aim').onpointermove=e=>{if(e.currentTarget.hasPointerCapture(e.pointerId))pointer(e);};
$('aim').onkeydown=e=>{const delta={ArrowLeft:[-.1,0],ArrowRight:[.1,0],ArrowUp:[0,.1],ArrowDown:[0,-.1]}[e.key];if(delta){e.preventDefault();aim.x=Math.max(0,Math.min(1,aim.x+delta[0]));aim.y=Math.max(0,Math.min(1,aim.y+delta[1]));}};
$('action').onclick=choose;$('create').onclick=()=>online('create');$('join').onclick=()=>{if(!/^[0-9A-F]{8}$/i.test($('code').value.trim())){$('error').textContent='Introduce los ocho caracteres de la sala.';return;}online('join');};
$('retryLoad').onclick=()=>location.reload();
$('practice').onclick=async()=>{await unlock();startPractice();};
$('ready').onclick=async()=>{try{await unlock();room=accept(await request('ready',{p_id:room.id}));update();}catch(e){$('lobbystatus').textContent=e.message;}};
$('again').onclick=async()=>{await unlock();if(practice){startPractice();return;}try{room=accept(await request('rematch',{p_id:room.id}));update();}catch(e){$('rematchStatus').textContent=e.message;}};
async function exit(){if(room){try{await request('leave',{p_id:room.id});}catch{/* Local exit is always available. */}}stopPolling();room=null;practice=false;roomStorage.clear();audio.pause();panels('menu');if(hasBridge()){const m=JSON.stringify({type:'runner-exit'});if(globalThis.RunnerBridge)RunnerBridge.postMessage(m);else parent.postMessage(m,location.origin);}}
$('exit').onclick=exit;$('resultExit').onclick=exit;$('settingsButton').onclick=()=>{$('settings').hidden=false;};$('closeSettings').onclick=async()=>{$('settings').hidden=true;await unlock();};
for(const [id,key]of [['ambient','ambientVolume'],['effects','effectsVolume']]){try{const v=localStorage.getItem('penalty-'+id);if(v!==null)$(id).value=v;}catch{}audio[key]=Number($(id).value)/100;$(id).oninput=()=>{audio[key]=Number($(id).value)/100;audio.volumes();try{localStorage.setItem('penalty-'+id,$(id).value);}catch{}};}
document.addEventListener('visibilitychange',()=>{if(document.hidden)audio.pause();else if(snapshot())status('Toca un control para reactivar el sonido.');});
let previous=performance.now(),nextUI=0;
function frame(now){if(stopped)return;const t=now/1000,dt=Math.min(.06,(now-previous)/1000);previous=now;if(!document.hidden){scene?.draw(t,dt,aim);if(t>nextUI){nextUI=t+.12;if(practice&&!botChoice)botChoice={x:.08+Math.random()*.84,y:.15+Math.random()*.7,power:.4+Math.random()*.48};update();}}frameID=requestAnimationFrame(frame);}
try{scene=new PenaltyScene($('scene'));await scene.load([species,species==='bear'?'penguin':'bear'],text=>$('load').textContent=text);modelKey=JSON.stringify([species,species==='bear'?'penguin':'bear']);modelsReady=true;await refreshAppearance();$('load').textContent='Tu mascota está lista para jugar.';frameID=requestAnimationFrame(frame);
 const saved=roomStorage.get();if(saved&&hasBridge())try{room=accept(await request('status',{p_id:saved}));if(room.status!=='cancelled'){update();startPolling();}}catch{roomStorage.clear();}
}catch(e){$('load').textContent='No se pudo preparar el estadio. '+(e?.message||'Revisa la conexión o libera memoria.');$('retryLoad').hidden=false;globalThis.penaltyLoadError={message:e?.message,stage:'stadium'};console.error(e);}
addEventListener('pagehide',()=>{stopped=true;stopPolling();cancelAnimationFrame(frameID);audio.close();scene?.dispose();for(const r of requests.values()){clearTimeout(r.timeout);r.reject(Error('Juego cerrado'));}requests.clear();},{once:true});
