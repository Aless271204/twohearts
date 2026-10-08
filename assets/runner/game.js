import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { clone as cloneSkeleton } from 'three/addons/utils/SkeletonUtils.js';
import { LANES, jumpStep, crossesPlayer, hitsObstacle, collectsCoin } from './physics.js';
import { createRunnerEffects, createButterflies } from './tropical.js';
import { createRunnerCoin } from './runner-coin.js';
import { createBirds } from './forest-life.js';
import { createLivingForest } from './living-forest.js';
import { createBridgeBelt } from './loop-bridge.js';
import {runnerRow} from './patterns.js';
import { runnerDifficulty } from './difficulty.js';
import { AdventureMusic } from './music.js';
import { limitTextureMemory } from './texture_budget.js';
import { showRunnerError } from './diagnostics.js';
import { requestHost } from './bridge.js';
import { equipRunnerCosmetics } from './cosmetics.js';
import { seatPet } from './pet-rest-pose.js';
clearTimeout(window.runnerBootTimer);

const params=new URLSearchParams(location.search),petOnly=params.get('pet')==='1',petOrbit=params.get('orbit')==='1';
const $ = id => document.getElementById(id);
const panel=$('panel'), start=$('start'), pause=$('pause');
const scene=new THREE.Scene();
scene.background=null;scene.fog=new THREE.Fog('#a9d9db',55,110);
const camera=new THREE.PerspectiveCamera(56,innerWidth/innerHeight,0.08,300);
function frameCamera(){camera.aspect=innerWidth/innerHeight;camera.fov=THREE.MathUtils.radToDeg(2*Math.atan(Math.tan(THREE.MathUtils.degToRad(56)/2)*Math.max(1,.46/camera.aspect)));camera.updateProjectionMatrix();}frameCamera();
const backdrop=petOnly?{load:async()=>{},update(){},setPaused(){},dispose(){}}:createLivingForest(scene),music=new AdventureMusic(),birds=createBirds(scene);
const effects=createRunnerEffects(scene),butterflies=createButterflies(scene);
let visualTime=0,landingPulse=0,pickupStreak=0;
let seatedSole=null;
const renderer=new THREE.WebGLRenderer({antialias:true,alpha:petOnly,powerPreference:'high-performance'});
let renderScale=Math.min(devicePixelRatio,1.25);renderer.setPixelRatio(renderScale);renderer.setSize(innerWidth,innerHeight);
renderer.outputColorSpace=THREE.SRGBColorSpace;renderer.toneMapping=THREE.NoToneMapping;renderer.toneMappingExposure=1;
renderer.shadowMap.enabled=false;renderer.shadowMap.type=THREE.PCFSoftShadowMap;
document.body.prepend(renderer.domElement);
renderer.domElement.addEventListener('webglcontextlost',()=>showRunnerError('Android perdió el contexto gráfico 3D','gráficos'));
scene.add(new THREE.HemisphereLight(0xd3f5ff,0x435d45,1.35));
const sun=new THREE.DirectionalLight(0xffe4aa,2.5);sun.position.set(-10,18,-16);scene.add(sun);
sun.castShadow=true;sun.shadow.mapSize.set(1024,1024);sun.shadow.camera.left=-12;sun.shadow.camera.right=12;sun.shadow.camera.top=18;sun.shadow.camera.bottom=-18;sun.shadow.camera.far=65;sun.shadow.normalBias=.035;
const fill=new THREE.DirectionalLight(0xe1eeff,.8);fill.position.set(4,6,8);scene.add(fill);
const loader=new GLTFLoader(),templates={},paths=[],objects=[],pools=new Map();
const pool=key=>{if(!pools.has(key))pools.set(key,[]);return pools.get(key);};
function releaseObject(item){scene.remove(item.model);pool(item.model.userData.poolKey).push(item.model);}
const glowCanvas=document.createElement('canvas');glowCanvas.width=glowCanvas.height=64;
const glowContext=glowCanvas.getContext('2d');
const glowGradient=glowContext.createRadialGradient(32,32,2,32,32,32);
glowGradient.addColorStop(0,'rgba(255,218,103,.8)');glowGradient.addColorStop(.4,'rgba(255,197,55,.3)');glowGradient.addColorStop(1,'rgba(255,197,55,0)');
glowContext.fillStyle=glowGradient;glowContext.fillRect(0,0,64,64);
const glowMaterial=new THREE.SpriteMaterial({map:new THREE.CanvasTexture(glowCanvas),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending});
const coinTemplate=createRunnerCoin(),coinBatch=new THREE.InstancedMesh(coinTemplate.geometry,coinTemplate.material,128);
coinBatch.count=0;coinBatch.frustumCulled=false;coinBatch.instanceMatrix.setUsage(THREE.DynamicDrawUsage);scene.add(coinBatch);
const coinGlowPositions=new Float32Array(128*3),coinGlowGeometry=new THREE.BufferGeometry();
coinGlowGeometry.setAttribute('position',new THREE.BufferAttribute(coinGlowPositions,3));coinGlowGeometry.setDrawRange(0,0);
const coinGlows=new THREE.Points(coinGlowGeometry,new THREE.PointsMaterial({map:glowMaterial.map,color:'#ffe18a',size:.9,transparent:true,opacity:.7,depthWrite:false,blending:THREE.AdditiveBlending}));coinGlows.frustumCulled=false;scene.add(coinGlows);
function updateCoinBatch(){let count=0;for(const item of objects){if(item.kind!=='coin')continue;if(count>=128)break;item.model.updateMatrix();coinBatch.setMatrixAt(count,item.model.matrix);coinGlowPositions.set([item.x,item.model.position.y,item.z],count*3);count++;}coinBatch.count=count;coinBatch.instanceMatrix.needsUpdate=true;coinGlowGeometry.setDrawRange(0,count);coinGlowGeometry.attributes.position.needsUpdate=true;}
let penguin,mixer,actions={},activeAction,cameraX=0;
const floorY=.18;
const shadow=new THREE.Mesh(new THREE.CircleGeometry(.55,24),new THREE.MeshBasicMaterial({color:0x1b3020,transparent:true,opacity:.22,depthWrite:false}));
shadow.rotation.x=-Math.PI/2;shadow.position.y=floorY+.01;shadow.scale.y=.65;scene.add(shadow);
const particlePositions=new Float32Array(45*3);
for(let i=0;i<45;i++){particlePositions[i*3]=Math.sin(i*17)*8;particlePositions[i*3+1]=1+(i%7)*.55;particlePositions[i*3+2]=-i*2;}
const particlesGeometry=new THREE.BufferGeometry();particlesGeometry.setAttribute('position',new THREE.BufferAttribute(particlePositions,3));
const particles=new THREE.Points(particlesGeometry,new THREE.PointsMaterial({color:0xffe6a0,size:.05,transparent:true,opacity:.65,depthWrite:false}));scene.add(particles);
let ready=false,running=false,paused=false;
let checkpointIndex=1,checkpointElapsed=0,checkpointBusy=false,checkpointFailed=false,terminalAfterCheckpoint=false;
let bestDistance=0;
let sessionId=null,frames=[],pendingInputs=[],pendingSave=null,runElapsed=0;
let lane=1,x=0,height=0,velocity=0,distance=0,coins=0,row=0,untilRow=0,last=performance.now();
let toastUntil=0,animationId=0,needsRender=true;
const speed=()=>runnerDifficulty(distance).speed;
// Read-only diagnostics for the standalone preview; absent in the app WebView.
if(window.parent===window&&!window.RunnerBridge)window.runnerPreview=Object.freeze({stats:()=>({distance,height,lane,running,paused,coins,drawCalls:renderer.info.render.calls,triangles:renderer.info.render.triangles,textures:renderer.info.memory.textures,sceneryTime:visualTime,videoTime:backdrop.video?.currentTime??0,videoPaused:backdrop.video?.paused??true,fps:Math.round(measuredFps),renderScale}),rig:()=>{const bones=[];penguin?.traverse(o=>{if(o.isBone&&/(Head|Neck|Spine2|Hips|LeftUpLeg|RightUpLeg|LeftLeg|RightLeg|LeftFoot|RightFoot|LeftToeBase|RightToeBase|LeftToe_End|RightToe_End)$/.test(o.name))bones.push({name:o.name,position:penguin.worldToLocal(o.getWorldPosition(new THREE.Vector3())).toArray()});});const box=penguin?new THREE.Box3().setFromObject(penguin.children[0],true):null;return {bones,bounds:box?{min:box.min.toArray(),max:box.max.toArray()}:null};},screen:()=>{if(!penguin)return null;const b=new THREE.Box3().setFromObject(penguin,true),points=[];for(const x of [b.min.x,b.max.x])for(const y of [b.min.y,b.max.y])for(const z of [b.min.z,b.max.z])points.push(new THREE.Vector3(x,y,z).project(camera).toArray());return {points,feet:penguin.position.y,rotation:penguin.rotation.y};},replay:()=>({frames:frames.map(frame=>[frame[0],[...frame[1]]]),replay_version:4})});

function fitModel(source,dimensions) {
  const object=source.getObjectByProperty('isSkinnedMesh',true)?cloneSkeleton(source):source.clone(true);
  const bounds=new THREE.Box3().setFromObject(object),size=bounds.getSize(new THREE.Vector3());
  if(!Number.isFinite(size.y)||Math.max(size.x,size.y,size.z)<=0)throw Error('Modelo sin geometría');
  if(typeof dimensions==='number')object.scale.multiplyScalar(dimensions/Math.max(size.y,.001));
  else object.scale.multiply(new THREE.Vector3(dimensions[0]/Math.max(size.x,.001),dimensions[1]/Math.max(size.y,.001),dimensions[2]/Math.max(size.z,.001)));
  const fitted=new THREE.Box3().setFromObject(object),center=fitted.getCenter(new THREE.Vector3());
  object.position.sub(new THREE.Vector3(center.x,fitted.min.y,center.z));
  const group=new THREE.Group();group.add(object);return group;
}
function place(key,dimensions,x,z,list) {
  const model=pool(key).pop()??fitModel(templates[key],dimensions);model.userData.poolKey=key;model.position.set(x,0,z);scene.add(model);list.push(model);return model;
}
function addCoin(laneIndex,z,y=.7) {
  let model=pool('coin').pop();
  if(!model){model=createRunnerCoin();model.userData.poolKey='coin';}
  model.rotation.set(0,0,0);model.position.set(LANES[laneIndex],y+floorY,z);
  objects.push({model,kind:'coin',x:LANES[laneIndex],y,z});
}
function spawnRow() {
  const {obstacleLane,kind,coinLane,alternateLane}=runnerRow(row,distance);
  const model=place(kind,[1.15,.85,.75],LANES[obstacleLane],-68,[]);model.position.y=floorY;
  objects.push({model,kind:'obstacle',x:LANES[obstacleLane],z:-68});
  for(let i=0;i<5;i++)addCoin(coinLane,-60-i*4,i===2?1.8:.7);
  addCoin(alternateLane,-68,.7);row++;
}
let hudKey='',lastMilestone=0,frameSample=0,frameCount=0,measuredFps=60,lastHudTime=0;
function hud(){
 const level=runnerDifficulty(distance).level,m=Math.floor(distance),key=`${level}|${m}|${coins}|${bestDistance}`;
 if(key===hudKey)return;hudKey=key;
 $('difficulty').textContent=`Ritmo ${level}/5`;$('coins').textContent=`♥ ${coins}`;$('distance').textContent=`${m} m`;
 $('goal').textContent=`Siguiente hito · ${(Math.floor(distance/500)+1)*500} m`;
 $('progress').value=distance%500;$('record').textContent=`🏆 Récord: ${bestDistance} m`;
 const step=Math.floor(distance/500);
 if(step>lastMilestone){lastMilestone=step;music.effect('coin');$('toast').textContent=`${step*500} metros · ¡Sigue rompiendo récords!`;toastUntil=performance.now()+2400;}
}

function jump(){if(running&&!paused&&height===0&&pendingInputs.length<8){velocity=8;pendingInputs.push(0);music.effect('jump');}}
function move(delta){if(running&&!paused&&pendingInputs.length<8){lane=Math.max(0,Math.min(2,lane+delta));pendingInputs.push(delta);}}
function showPanel(title,message,label){$('title').textContent=title;$('message').textContent=message;start.textContent=label;panel.hidden=false;}
function reset(){
  for(const item of objects)releaseObject(item);objects.length=0;
  lane=1;x=height=velocity=distance=coins=row=cameraX=0;untilRow=0;paused=false;running=true;
  frames=[];pendingInputs=[];pendingSave=null;runElapsed=0;checkpointIndex=1;checkpointElapsed=0;checkpointBusy=false;checkpointFailed=terminalAfterCheckpoint=false;
  effects.reset();landingPulse=pickupStreak=lastMilestone=0;hudKey='';backdrop.setPaused(false);
  $('toast').textContent='';panel.hidden=true;pause.disabled=false;pause.textContent='Pausa';hud();
  music.start();
}
function togglePause(){
  if(!running)return;paused=!paused;pause.textContent=paused?'Continuar':'Pausa';
  if(paused)showPanel('Una pausa en el bosque',`♥ ${coins} monedas · ${Math.floor(distance)} metros`,'Continuar');else panel.hidden=true;
    backdrop.setPaused(paused);
    if(paused)music.pause();else music.start();
}
start.onclick=async()=>{
  if(!ready||start.disabled)return;
  if(pendingSave){await saveRun();return;}
  if(paused){togglePause();return;}
  start.disabled=true;
  try{const session=await requestHost('start');sessionId=session.session_id??null;bestDistance=session.best_distance??bestDistance;reset();}
  catch(error){showPanel('No pudimos iniciar la partida',error.message,'Volver a intentar');}
  finally{start.disabled=false;}
};
function finishPayload(){return {session_id:sessionId,frames,replay_version:4,checkpoint_index:checkpointIndex};}
async function saveRun(){
  start.disabled=true;const payload=pendingSave;
  try{
    const continuing=payload.checkpoint===true;
    const result=await requestHost(continuing?'checkpoint':'finish',payload);
    bestDistance=result.best_distance??Math.max(bestDistance,Math.floor(distance));hudKey='';
    pendingSave=null;
    if(continuing){
      checkpointIndex++;checkpointBusy=false;
      if(terminalAfterCheckpoint){terminalAfterCheckpoint=false;pendingSave=finishPayload();await saveRun();return;}
      if(checkpointFailed){checkpointFailed=false;paused=false;panel.hidden=true;music.start();}
      return;
    }
    const awarded=result.coins_awarded??0;
    showPanel('¡Partida guardada!',`Recorriste ${Math.floor(distance)} metros. Se sumaron ${awarded} monedas a tu saldo. Récord: ${result.best_distance??Math.floor(distance)} m.`,'Correr otra vez');
  }catch(error){pendingSave=payload;checkpointFailed=payload.checkpoint===true;if(running){paused=true;music.pause();}showPanel('Tu partida está pendiente',error.message,'Reintentar guardado');}
  finally{start.disabled=false;}
}
pause.onclick=togglePause;$('jump').onclick=jump;$('left').onclick=()=>move(-1);$('right').onclick=()=>move(1);
$('music').onclick=()=>{if(running&&!paused)music.start();const muted=music.toggleMute();$('music').textContent=muted?'♪ ×':'♪';$('music').setAttribute('aria-label',muted?'Activar audio':'Silenciar audio');};
let pointerStart=null;
renderer.domElement.addEventListener('pointerdown',e=>{pointerStart=[e.clientX,e.clientY];});
renderer.domElement.addEventListener('pointermove',e=>{if(petOnly&&petOrbit&&pointerStart&&penguin){penguin.rotation.y+=(e.clientX-pointerStart[0])*.015;pointerStart=[e.clientX,e.clientY];}});
renderer.domElement.addEventListener('pointerup',e=>{
  if(!pointerStart)return;
  if(petOnly){pointerStart=null;return;}
  const dx=e.clientX-pointerStart[0],dy=e.clientY-pointerStart[1];pointerStart=null;
  if(Math.abs(dx)>40&&Math.abs(dx)>Math.abs(dy))move(Math.sign(dx));else jump();
});
renderer.domElement.addEventListener('pointercancel',()=>{pointerStart=null;});
addEventListener('keydown',e=>{
  if(['Space','ArrowUp','ArrowLeft','ArrowRight'].includes(e.code))e.preventDefault();if(e.repeat)return;
  if(e.code==='Space'||e.code==='ArrowUp')jump();if(e.code==='ArrowLeft'||e.code==='KeyA')move(-1);
  if(e.code==='ArrowRight'||e.code==='KeyD')move(1);if(e.code==='Escape'||e.code==='KeyP')togglePause();
});
document.addEventListener('visibilitychange',()=>{if(document.hidden&&running&&!paused)togglePause();backdrop.setPaused(document.hidden||paused);});
addEventListener('resize',()=>{frameCamera();renderer.setSize(innerWidth,innerHeight);needsRender=true;});
function frame(now){
  animationId=requestAnimationFrame(frame);if(now-last<(running?16:33))return;
  if(running){frameCount++;frameSample+=now-last;}else{frameCount=0;frameSample=0;}
  if(frameSample>=2000){measuredFps=1000*frameCount/frameSample;frameSample=frameCount=0;
    if(measuredFps<42&&renderScale>.75){renderScale=Math.max(.75,renderScale-.125);renderer.setPixelRatio(renderScale);}}
  const microseconds=Math.max(1,Math.round(Math.min((now-last)/1000,.12)*1000000));const dt=microseconds/1000000;last=now;
  if(paused&&!needsRender)return;
  needsRender=false;
  const simulationTime=dt;
  for(let remaining=simulationTime; running&&!paused&&remaining>0;){
    const stepMicroseconds=Math.max(1,Math.min(40000,Math.round(remaining*1000000)));
    const dt=stepMicroseconds/1000000;remaining=Math.max(0,remaining-dt);
    frames.push([stepMicroseconds,pendingInputs.splice(0)]);
    runElapsed+=dt;
    const previousHeight=height;
    const travel=speed()*dt;distance+=travel;[height,velocity]=jumpStep(height,velocity,dt);
    if(previousHeight>0&&height===0){landingPulse=1;effects.burst(x,floorY+.05,0,true);music.effect('land');}
    x+=(LANES[lane]-x)*(1-Math.exp(-dt*10));untilRow-=travel;if(untilRow<=0){spawnRow();untilRow+=runnerDifficulty(distance).spacing;}
    for(const model of paths)model.position.z=distance%12;
    for(let i=objects.length-1;i>=0;i--){
      const item=objects[i],previous=item.z;item.z+=travel;item.model.position.z=item.z;
      if(item.kind==='coin'){item.model.rotation.y+=dt*2.4;item.model.position.y=item.y+floorY+Math.sin(runElapsed*3+item.z*.2)*.055;}
      if(crossesPlayer(previous,item.z)){
        if(item.kind==='obstacle'&&hitsObstacle(x,item.x,height)){
          running=false;music.stopForCollision();pause.disabled=true;
          showPanel('¡Vuelve a intentarlo!',`Recogiste ${coins} monedas y recorriste ${Math.floor(distance)} metros.`,'Correr otra vez');
          if(sessionId){$('message').textContent='Guardando tu partida…';if(checkpointBusy){terminalAfterCheckpoint=true;}else{pendingSave=finishPayload();saveRun();}}else{bestDistance=Math.max(bestDistance,Math.floor(distance));}
          break;
        }
        if(item.kind==='coin'&&collectsCoin(x,item.x,height,item.y)){
          coins++;pickupStreak++;music.effect('coin');effects.burst(item.x,item.y+floorY,0);releaseObject(item);objects.splice(i,1);
          $('coins').animate([{transform:'scale(1)'},{transform:'scale(1.2)'},{transform:'scale(1)'}],{duration:280});
          $('toast').textContent=pickupStreak%5===0?'¡5 seguidas! ✨':'+1 ♥';toastUntil=now+650;continue;
        }
      }
      if(item.kind==='coin'&&crossesPlayer(previous,item.z))pickupStreak=0;
      if(item.z>6){releaseObject(item);objects.splice(i,1);}
    }
    if(now-lastHudTime>80){hud();lastHudTime=now;}
  }
  if(running&&!paused&&runElapsed-checkpointElapsed>=90){
    if(sessionId&&!checkpointBusy){checkpointBusy=true;pendingSave={session_id:sessionId,frames,replay_version:4,checkpoint_index:checkpointIndex,checkpoint:true};frames=[];checkpointElapsed=runElapsed;saveRun();}
    else if(!sessionId){frames=[];checkpointElapsed=runElapsed;}
  }
  if(now>toastUntil)$('toast').textContent='';
  if(penguin){
    landingPulse=Math.max(0,landingPulse-dt*5);
    penguin.position.set(x,floorY+height,0);
    penguin.scale.set(1+landingPulse*.07,1-landingPulse*.09,1+landingPulse*.07);
    penguin.rotation.x=THREE.MathUtils.lerp(penguin.rotation.x,height>0?-.08:0,1-Math.exp(-dt*8));
    penguin.rotation.z=THREE.MathUtils.lerp(penguin.rotation.z,(LANES[lane]-x)*-.08,1-Math.exp(-dt*8));
    const name=petOnly?(params.get('animation')??'Idle_9'):running?(height>.01?'Regular_Jump':'Running'):'Idle_9';
    if(activeAction!==name&&actions[name]){
      const next=actions[name];next.reset().fadeIn(.16).play();
      if(activeAction)actions[activeAction].fadeOut(.16);activeAction=name;
    }
    if(!paused&&seatedSole===null)mixer.update(dt);
    if(petOnly){
      const feet=[];penguin.traverse(o=>{if(o.isBone&&/(LeftToeBase|RightToeBase)$/.test(o.name))feet.push(o.getWorldPosition(new THREE.Vector3()).y);});
      if(seatedSole!==null)penguin.position.y=floorY+.006-seatedSole;
      else if(feet.length)penguin.position.y+=floorY+.065-Math.min(...feet);
      document.body.dataset.petGrounded='true';
    }
    if(petOnly){document.body.dataset.petAnimation=activeAction??'';if(!petOrbit){penguin.rotation.set(0,0,0);document.body.dataset.petPosition=penguin.position.toArray().join(',');}}
  }
  shadow.position.x=x;shadow.material.opacity=.22/(1+height);shadow.scale.set(1+height*.18,.65+height*.1,1);
  cameraX=THREE.MathUtils.lerp(cameraX,petOnly?0:x*.72,1-Math.exp(-dt*9));
  camera.position.set(cameraX,petOnly?.75:2.35,petOnly?2.2:5.8);
  camera.lookAt(cameraX,petOnly?.62:.95,petOnly?0:-10);
  backdrop.update(paused?0:dt,camera.aspect,cameraX,distance);
  if(!paused){
    visualTime+=dt;effects.update(dt);butterflies.update(dt);birds.update(dt);
    particles.position.y=Math.sin(visualTime*.8)*.12;particles.position.z=distance%18;
  }
  if(!petOnly)updateCoinBatch();
  renderer.render(scene,camera);
}
function boardwalk(){const deck=createBridgeBelt();scene.add(deck);paths.push(deck);}
async function boot(){
  try{
    await backdrop.load();
    const manifest=await fetch('models.json').then(r=>{if(!r.ok)throw Error('Catálogo no disponible');return r.json();});
    const entries=Object.entries(manifest).filter(([key])=>(petOnly?['pip']:['pip','crate','fence','rock']).includes(key));
    for(let i=0;i<entries.length;i++){
      const [key,file]=entries[i];$('message').textContent=`Cargando bosque ${i+1}/${entries.length}…`;
      const gltf=await loader.loadAsync(`play-models/${file}`);templates[key]=gltf.scene;
      limitTextureMemory(gltf.scene);
      // The supplied maps carry the artwork. Keep them, but make natural props
      // non-metallic and soften exaggerated normal-map relief under sunlight.
      if(key!=='pip')gltf.scene.traverse(o=>{
        if(!o.isMesh)return;
        const tune=source=>{const material=source.clone();material.metalness=0;material.roughness=.85;if(material.normalMap)material.normalScale.set(.45,.45);return material;};
        o.material=Array.isArray(o.material)?o.material.map(tune):tune(o.material);
      });
      if(key==='pip'){
        penguin=fitModel(gltf.scene,1.15);penguin.rotation.y=petOnly?Number(params.get('angle')??0):Math.PI;scene.add(penguin);

        mixer=new THREE.AnimationMixer(penguin);
        for(const clip of gltf.animations)actions[clip.name]=mixer.clipAction(clip);
        if(actions.Regular_Jump){actions.Regular_Jump.setLoop(THREE.LoopOnce,1);actions.Regular_Jump.clampWhenFinished=true;}
        if(actions.Idle_9){actions.Idle_9.play();activeAction='Idle_9';if(petOnly&&!petOrbit&&(params.get('animation')??'Idle_9')==='Idle_9'){actions.Idle_9.time=Math.min(.75,actions.Idle_9.getClip().duration/2);actions.Idle_9.paused=true;}mixer.update(0);}
        if(petOnly&&!petOrbit&&(params.get('animation')??'Idle_9')==='Idle_9'){seatedSole=seatPet(penguin);document.body.dataset.petPose='seated';}
        (petOnly?Promise.resolve(JSON.parse(params.get('appearance')??'{}')):requestHost('cosmetics')).then(loadout=>{const equipped=equipRunnerCosmetics(penguin,loadout);if(petOnly)document.body.dataset.petAnchors=equipped.userData.slots.map(slot=>slot.parent.name).join(',');needsRender=true;}).catch(()=>{});
      }
    }
    if(!petOnly)boardwalk();
    penguin.traverse(o=>{if(o.isMesh)o.castShadow=true;});
    clearTimeout(window.runnerBootTimer);ready=true;start.disabled=false;
    showPanel('Un paseo con Pip','Un bosque lleno de vida. Recoge corazones y salta los obstáculos. El ritmo aumenta a medida que avanzas. Usa ← → o desliza para cambiar de carril; toca o pulsa espacio para saltar.','Correr con Pip');
    if(petOnly){document.body.classList.add('pet-only');scene.background=null;scene.fog=null;renderer.setClearColor(0,0);for(const child of scene.children)if(child!==penguin&&child!==shadow&&!child.isLight)child.visible=false;}
    last=performance.now();animationId=requestAnimationFrame(frame);
  }catch(error){
    clearTimeout(window.runnerBootTimer);$('title').textContent='No pudimos abrir el bosque';
    showRunnerError(error, 'modelo del bosque');console.error('Forest runner load failed',error);
  }
}
addEventListener('pagehide',()=>{
  music.dispose();
  backdrop.dispose();
  cancelAnimationFrame(animationId);const geometries=new Set(),materials=new Set(),textures=new Set();
  scene.traverse(o=>{if(o.geometry)geometries.add(o.geometry);for(const m of(Array.isArray(o.material)?o.material:[o.material])){if(!m)continue;materials.add(m);for(const value of Object.values(m))if(value?.isTexture)textures.add(value);}});
  for(const g of geometries)g.dispose();for(const t of textures)t.dispose();for(const m of materials)m.dispose();renderer.dispose();
},{once:true});
boot();
