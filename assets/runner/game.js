import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { clone as cloneSkeleton } from 'three/addons/utils/SkeletonUtils.js';
import { LANES, jumpStep, crossesPlayer, hitsObstacle, collectsCoin } from './physics.js';
import { createLandscape } from './landscape.js';
import { runnerDifficulty } from './difficulty.js';
import { AdventureMusic } from './music.js';
import { limitTextureMemory } from './texture_budget.js';
import { showRunnerError } from './diagnostics.js';
import { requestHost } from './bridge.js';
clearTimeout(window.runnerBootTimer);

const $ = id => document.getElementById(id);
const panel=$('panel'), start=$('start'), pause=$('pause');
const scene=new THREE.Scene();
scene.background=new THREE.Color('#c5dfbd');scene.fog=new THREE.Fog('#c5dfbd',34,100);
const camera=new THREE.PerspectiveCamera(56,innerWidth/innerHeight,0.08,300);
const landscape=createLandscape(scene),music=new AdventureMusic();
const renderer=new THREE.WebGLRenderer({antialias:true,powerPreference:'high-performance'});
renderer.setPixelRatio(Math.min(devicePixelRatio,1.5));renderer.setSize(innerWidth,innerHeight);
renderer.outputColorSpace=THREE.SRGBColorSpace;renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.22;
document.body.prepend(renderer.domElement);
renderer.domElement.addEventListener('webglcontextlost',()=>showRunnerError('Android perdió el contexto gráfico 3D','gráficos'));
scene.add(new THREE.HemisphereLight(0xf4ffe2,0x715632,2.3));
const sun=new THREE.DirectionalLight(0xffdf9c,3.4);sun.position.set(-10,18,-16);scene.add(sun);
const fill=new THREE.DirectionalLight(0xd5eaff,1.2);fill.position.set(4,6,8);scene.add(fill);
const ground=new THREE.Mesh(new THREE.PlaneGeometry(200,220),new THREE.MeshStandardMaterial({color:'#6b9146',roughness:1}));
ground.rotation.x=-Math.PI/2;ground.position.z=-60;ground.position.y=-0.04;scene.add(ground);
const loader=new GLTFLoader(),templates={},decor=[],paths=[],objects=[];
const glowCanvas=document.createElement('canvas');glowCanvas.width=glowCanvas.height=64;
const glowContext=glowCanvas.getContext('2d');
const glowGradient=glowContext.createRadialGradient(32,32,2,32,32,32);
glowGradient.addColorStop(0,'rgba(255,218,103,.8)');glowGradient.addColorStop(.4,'rgba(255,197,55,.3)');glowGradient.addColorStop(1,'rgba(255,197,55,0)');
glowContext.fillStyle=glowGradient;glowContext.fillRect(0,0,64,64);
const glowMaterial=new THREE.SpriteMaterial({map:new THREE.CanvasTexture(glowCanvas),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending});
let penguin,mixer,actions={},activeAction,cameraX=0;
const floorY=.18;
const shadow=new THREE.Mesh(new THREE.CircleGeometry(.55,24),new THREE.MeshBasicMaterial({color:0x1b3020,transparent:true,opacity:.22,depthWrite:false}));
shadow.rotation.x=-Math.PI/2;shadow.position.y=floorY+.01;shadow.scale.y=.65;scene.add(shadow);
const particlePositions=new Float32Array(45*3);
for(let i=0;i<45;i++){particlePositions[i*3]=Math.sin(i*17)*8;particlePositions[i*3+1]=1+(i%7)*.55;particlePositions[i*3+2]=-i*2;}
const particlesGeometry=new THREE.BufferGeometry();particlesGeometry.setAttribute('position',new THREE.BufferAttribute(particlePositions,3));
const particles=new THREE.Points(particlesGeometry,new THREE.PointsMaterial({color:0xffe6a0,size:.05,transparent:true,opacity:.65,depthWrite:false}));scene.add(particles);
let ready=false,running=false,paused=false;
let sessionId=null,frames=[],pendingInputs=[],pendingSave=null,runElapsed=0;
let lane=1,x=0,height=0,velocity=0,distance=0,coins=0,row=0,untilRow=0,last=performance.now();
let toastUntil=0,animationId=0,needsRender=true;
const speed=()=>runnerDifficulty(distance).speed;

function fitModel(source,dimensions) {
  const object=cloneSkeleton(source);
  const bounds=new THREE.Box3().setFromObject(object),size=bounds.getSize(new THREE.Vector3());
  if(!Number.isFinite(size.y)||Math.max(size.x,size.y,size.z)<=0)throw Error('Modelo sin geometría');
  if(typeof dimensions==='number')object.scale.multiplyScalar(dimensions/Math.max(size.y,.001));
  else object.scale.multiply(new THREE.Vector3(dimensions[0]/Math.max(size.x,.001),dimensions[1]/Math.max(size.y,.001),dimensions[2]/Math.max(size.z,.001)));
  const fitted=new THREE.Box3().setFromObject(object),center=fitted.getCenter(new THREE.Vector3());
  object.position.sub(new THREE.Vector3(center.x,fitted.min.y,center.z));
  const group=new THREE.Group();group.add(object);return group;
}
function place(key,dimensions,x,z,list) {
  const model=fitModel(templates[key],dimensions);model.position.set(x,0,z);scene.add(model);list.push(model);return model;
}
function addCoin(laneIndex,z,y=.7) {
  const model=place('coin',.55,LANES[laneIndex],z,[]);model.position.y=y-.275+floorY;
  const halo=new THREE.Sprite(glowMaterial);halo.position.y=.275;halo.scale.set(1.1,1.1,1);model.add(halo);
  objects.push({model,kind:'coin',x:LANES[laneIndex],y,z});
}
function spawnRow() {
  const obstacleLane=row%3,kind=['crate','fence','rock'][row%3];
  const model=place(kind,[1.15,.85,.75],LANES[obstacleLane],-68,[]);model.position.y=floorY;
  objects.push({model,kind:'obstacle',x:LANES[obstacleLane],z:-68});
  for(let i=0;i<5;i++)addCoin(obstacleLane,-60-i*4,i===2?1.8:.7);
  addCoin((obstacleLane+1)%3,-68,.7);row++;
}
function hud(){const level=runnerDifficulty(distance).level;$('difficulty').textContent=`Ritmo ${level}/5`;$('coins').textContent=`♥ ${coins}`;$('distance').textContent=`${Math.floor(distance)} m`;}
function jump(){if(running&&!paused&&height===0&&pendingInputs.length<8){velocity=8;pendingInputs.push(0);music.effect('jump');}}
function move(delta){if(running&&!paused&&pendingInputs.length<8){lane=Math.max(0,Math.min(2,lane+delta));pendingInputs.push(delta);}}
function showPanel(title,message,label){$('title').textContent=title;$('message').textContent=message;start.textContent=label;panel.hidden=false;}
function reset(){
  for(const item of objects)scene.remove(item.model);objects.length=0;
  lane=1;x=height=velocity=distance=coins=row=cameraX=0;untilRow=0;paused=false;running=true;
  frames=[];pendingInputs=[];pendingSave=null;runElapsed=0;
  $('toast').textContent='';panel.hidden=true;pause.disabled=false;pause.textContent='Pausa';hud();
  music.start();
}
function togglePause(){
  if(!running)return;paused=!paused;pause.textContent=paused?'Continuar':'Pausa';
  if(paused)showPanel('Una pausa en el bosque',`♥ ${coins} monedas · ${Math.floor(distance)} metros`,'Continuar');else panel.hidden=true;
  if(paused)music.pause();else music.start();
}
start.onclick=async()=>{
  if(!ready||start.disabled)return;
  if(pendingSave){await saveRun();return;}
  if(paused){togglePause();return;}
  start.disabled=true;
  try{const session=await requestHost('start');sessionId=session.session_id??null;reset();}
  catch(error){showPanel('No pudimos iniciar la partida',error.message,'Volver a intentar');}
  finally{start.disabled=false;}
};
async function saveRun(){
  start.disabled=true;
  try{
    const result=await requestHost('finish',pendingSave);
    pendingSave=null;
    const awarded=result.coins_awarded??0;
    showPanel('¡Partida guardada!',`Recorriste ${Math.floor(distance)} metros. Se sumaron ${awarded} monedas a tu saldo. Récord: ${result.best_distance??Math.floor(distance)} m.`,'Correr otra vez');
  }catch(error){showPanel('Tu partida está pendiente',error.message,'Reintentar guardado');}
  finally{start.disabled=false;}
}
pause.onclick=togglePause;$('jump').onclick=jump;$('left').onclick=()=>move(-1);$('right').onclick=()=>move(1);
$('music').onclick=()=>{if(running&&!paused)music.start();const muted=music.toggleMute();$('music').textContent=muted?'♪ ×':'♪';$('music').setAttribute('aria-label',muted?'Activar audio':'Silenciar audio');};
let pointerStart=null;
renderer.domElement.addEventListener('pointerdown',e=>{pointerStart=[e.clientX,e.clientY];});
renderer.domElement.addEventListener('pointerup',e=>{
  if(!pointerStart)return;
  const dx=e.clientX-pointerStart[0],dy=e.clientY-pointerStart[1];pointerStart=null;
  if(Math.abs(dx)>40&&Math.abs(dx)>Math.abs(dy))move(Math.sign(dx));else jump();
});
renderer.domElement.addEventListener('pointercancel',()=>{pointerStart=null;});
addEventListener('keydown',e=>{
  if(['Space','ArrowUp','ArrowLeft','ArrowRight'].includes(e.code))e.preventDefault();if(e.repeat)return;
  if(e.code==='Space'||e.code==='ArrowUp')jump();if(e.code==='ArrowLeft'||e.code==='KeyA')move(-1);
  if(e.code==='ArrowRight'||e.code==='KeyD')move(1);if(e.code==='Escape'||e.code==='KeyP')togglePause();
});
document.addEventListener('visibilitychange',()=>{if(document.hidden&&running&&!paused)togglePause();});
addEventListener('resize',()=>{camera.aspect=innerWidth/innerHeight;camera.updateProjectionMatrix();renderer.setSize(innerWidth,innerHeight);needsRender=true;});
function frame(now){
  animationId=requestAnimationFrame(frame);if(now-last<16)return;
  const microseconds=Math.max(1,Math.round(Math.min((now-last)/1000,.04)*1000000));const dt=microseconds/1000000;last=now;
  if(paused&&!needsRender)return;
  needsRender=false;
  if(running&&!paused){
    frames.push([microseconds,pendingInputs.splice(0)]);
    runElapsed+=dt;
    const travel=speed()*dt;distance+=travel;[height,velocity]=jumpStep(height,velocity,dt);
    x+=(LANES[lane]-x)*(1-Math.exp(-dt*10));untilRow-=travel;if(untilRow<=0){spawnRow();untilRow+=runnerDifficulty(distance).spacing;}
    for(const model of decor){model.position.z+=travel;if(model.position.z>12)model.position.z-=104;}
    for(const model of paths){model.position.z+=travel;if(model.position.z>18)model.position.z-=108;}
    for(let i=objects.length-1;i>=0;i--){
      const item=objects[i],previous=item.z;item.z+=travel;item.model.position.z=item.z;
      if(item.kind==='coin')item.model.rotation.y+=dt*2;
      if(crossesPlayer(previous,item.z)){
        if(item.kind==='obstacle'&&hitsObstacle(x,item.x,height)){
          running=false;music.stopForCollision();pause.disabled=true;
          showPanel('¡Vuelve a intentarlo!',`Recogiste ${coins} monedas y recorriste ${Math.floor(distance)} metros.`,'Correr otra vez');
          if(sessionId){pendingSave={session_id:sessionId,frames,replay_version:2};$('message').textContent='Guardando tu partida…';saveRun();}
          break;
        }
        if(item.kind==='coin'&&collectsCoin(x,item.x,height,item.y)){
          coins++;music.effect('coin');scene.remove(item.model);objects.splice(i,1);$('toast').textContent='+1 ♥';toastUntil=now+650;continue;
        }
      }
      if(item.z>6){scene.remove(item.model);objects.splice(i,1);}
    }
    if(running&&runElapsed>=1199.96){
      running=false;music.pause();pause.disabled=true;showPanel('¡Buen recorrido!',`Recogiste ${coins} monedas y recorriste ${Math.floor(distance)} metros.`,'Correr otra vez');
      if(sessionId){pendingSave={session_id:sessionId,frames,replay_version:2};$('message').textContent='Guardando tu partida…';saveRun();}
    }
    hud();
  }
  if(now>toastUntil)$('toast').textContent='';
  if(penguin){
    penguin.position.set(x,floorY+height,0);
    penguin.rotation.z=THREE.MathUtils.lerp(penguin.rotation.z,(LANES[lane]-x)*-.08,1-Math.exp(-dt*8));
    const name=running?(height>.01?'Regular_Jump':'Running'):'Idle_9';
    if(activeAction!==name&&actions[name]){
      const next=actions[name];next.reset().fadeIn(.16).play();
      if(activeAction)actions[activeAction].fadeOut(.16);activeAction=name;
    }
    if(!paused)mixer.update(dt);
  }
  shadow.position.x=x;shadow.material.opacity=.22/(1+height);shadow.scale.set(1+height*.18,.65+height*.1,1);
  cameraX=THREE.MathUtils.lerp(cameraX,x*.28,1-Math.exp(-dt*4));
  camera.position.set(cameraX,2.45+height*.22,4.8);
  camera.lookAt(cameraX*.7,.9+height*.16,-5);
  if(!paused){particles.position.y=Math.sin(now*.0008)*.12;particles.position.z=distance%18;landscape.update(dt);}
  renderer.render(scene,camera);
}
function boardwalk(z){
  const deck=new THREE.Group();deck.position.z=z;
  const geometry=new THREE.BoxGeometry(5.4,.11,.63),material=new THREE.MeshStandardMaterial({color:0xffffff,roughness:.85});
  const boards=new THREE.InstancedMesh(geometry,material,20),matrix=new THREE.Matrix4();
  const colors=['#c48c4c','#d3a268','#bb854b','#dfb27a'];
  for(let i=0;i<20;i++){matrix.makeTranslation(0,.115,-5.7+i*.6);boards.setMatrixAt(i,matrix);boards.setColorAt(i,new THREE.Color(colors[i%4]));}
  deck.add(boards);
  const wood=new THREE.MeshStandardMaterial({color:'#795635',roughness:1});
  for(const side of [-1,1]){
    for(let i=0;i<3;i++){
      const post=new THREE.Mesh(new THREE.BoxGeometry(.13,.7,.13),wood);post.position.set(side*2.85,.35,-4+i*4);deck.add(post);
    }
    const rail=new THREE.Mesh(new THREE.BoxGeometry(.08,.08,12.1),wood);rail.position.set(side*2.85,.59,0);deck.add(rail);
  }
  scene.add(deck);paths.push(deck);
}
function planting(side,z,index){
  const group=new THREE.Group();group.position.set(side*3.35,.05,z);
  const leafMaterial=new THREE.MeshStandardMaterial({color:index%2?'#66a541':'#88b94e',roughness:1});
  for(let i=0;i<4;i++){
    const bush=new THREE.Mesh(new THREE.IcosahedronGeometry(.48,0),leafMaterial);bush.position.set(Math.sin(i*2)*.45,.25,Math.cos(i*2)*.5);bush.scale.set(1,.65,1);group.add(bush);
  }
  const flowerMaterial=new THREE.MeshStandardMaterial({color:index%2?'#f6c766':'#ee8ba4',roughness:.7});
  for(let i=0;i<3;i++){
    const flower=new THREE.Mesh(new THREE.IcosahedronGeometry(.085,0),flowerMaterial);flower.position.set(Math.sin(i*4)*.4,.52,Math.cos(i*4)*.45);group.add(flower);
  }
  scene.add(group);decor.push(group);
}
async function boot(){
  try{
    const manifest=await fetch('models.json').then(r=>{if(!r.ok)throw Error('Catálogo no disponible');return r.json();});
    const entries=Object.entries(manifest);
    for(let i=0;i<entries.length;i++){
      const [key,file]=entries[i];$('message').textContent=`Cargando bosque ${i+1}/${entries.length}…`;
      const gltf=await loader.loadAsync(`models/${file}`);templates[key]=gltf.scene;
      limitTextureMemory(gltf.scene);
      if(key==='coin')gltf.scene.traverse(o=>{if(o.isMesh){o.material=o.material.clone();o.material.emissive=new THREE.Color('#be6a05');o.material.emissiveIntensity=.3;}});
      if(key==='pip'){
        penguin=fitModel(gltf.scene,1.15);penguin.rotation.y=Math.PI;scene.add(penguin);
        mixer=new THREE.AnimationMixer(penguin);
        for(const clip of gltf.animations)actions[clip.name]=mixer.clipAction(clip);
        if(actions.Regular_Jump){actions.Regular_Jump.setLoop(THREE.LoopOnce,1);actions.Regular_Jump.clampWhenFinished=true;}
      }
    }
    for(let i=0;i<9;i++){place('path',[6.6,.06,12.15],0,8-i*12,paths);boardwalk(8-i*12);}
    const trees=['treeA','treeB','guardian'];
    for(let i=0;i<26;i++){
      const side=i%2===0?-1:1,z=4-Math.floor(i/2)*8;
      place(trees[i%3],6+(i%3),side*(4.8+(i%4)*.65),z,decor);
      planting(side,z-1,i);
      if(i%3===0)place('mushrooms',.65,side*3.6,z-2,decor);
    }
    for(let i=0;i<6;i++)place('rock',.65,(i%2?1:-1)*3.7,-i*16,decor);
    place('bridgeA',[3,1.2,5],7,-28,decor);place('bridgeB',[3,1.2,5],-7,-64,decor);
    place('guardian',5.5,8,-8,decor);
    clearTimeout(window.runnerBootTimer);ready=true;start.disabled=false;
    showPanel('Un paseo con Pip','Un bosque lleno de vida. Recoge corazones y salta los obstáculos. El ritmo aumenta a medida que avanzas. Usa ← → o desliza para cambiar de carril; toca o pulsa espacio para saltar.','Correr con Pip');
    last=performance.now();animationId=requestAnimationFrame(frame);
  }catch(error){
    clearTimeout(window.runnerBootTimer);$('title').textContent='No pudimos abrir el bosque';
    showRunnerError(error, 'modelo del bosque');console.error('Forest runner load failed',error);
  }
}
addEventListener('pagehide',()=>{
  music.dispose();
  cancelAnimationFrame(animationId);const geometries=new Set(),materials=new Set(),textures=new Set();
  scene.traverse(o=>{if(o.geometry)geometries.add(o.geometry);for(const m of(Array.isArray(o.material)?o.material:[o.material])){if(!m)continue;materials.add(m);for(const value of Object.values(m))if(value?.isTexture)textures.add(value);}});
  for(const g of geometries)g.dispose();for(const t of textures)t.dispose();for(const m of materials)m.dispose();renderer.dispose();
},{once:true});
boot();
