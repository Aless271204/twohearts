import * as THREE from 'three';
import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';
import {createNaturalRest} from './pet-rest-pose.js';
import {limitTextureMemory} from './texture_budget.js';
const params=new URLSearchParams(location.search),arrival=params.get('arrival')==='1',reduced=matchMedia('(prefers-reduced-motion: reduce)').matches;
const names={penguin:'Meshy_AI_Pip_the_Penguin_All_Animations.glb',bear:'bear.glb',pig:'pig.glb',chick:'chick.glb'};
const species=Object.hasOwn(names,params.get('species'))?params.get('species'):'penguin';
const renderer=new THREE.WebGLRenderer({alpha:true,antialias:true});renderer.setPixelRatio(Math.min(devicePixelRatio,1.25));document.body.prepend(renderer.domElement);
renderer.outputColorSpace=THREE.SRGBColorSpace;
const scene=new THREE.Scene(),camera=new THREE.PerspectiveCamera(35,1,.05,40);camera.position.set(0,1.5,5);camera.lookAt(0,1.1,0);
scene.add(new THREE.HemisphereLight(0xfff4e4,0xb4a2ad,2.4));const light=new THREE.DirectionalLight(0xfff4da,2.2);light.position.set(-3,5,4);scene.add(light);
const soft=new THREE.MeshStandardMaterial({color:'#fff8ec',roughness:.95}),coral=new THREE.MeshStandardMaterial({color:'#efb4ab',roughness:1}),gold=new THREE.MeshStandardMaterial({color:'#efba65',roughness:.8});
function ball(parent,material,x,y,z,sx,sy,sz){const m=new THREE.Mesh(new THREE.SphereGeometry(1,20,12),material);m.position.set(x,y,z);m.scale.set(sx,sy,sz);parent.add(m);return m;}
const floor=ball(scene,soft,0,-.13,0,2.1,.13,1.6);
const nest=new THREE.Group();scene.add(nest);nest.position.set(0,.12,0);
for(let i=0;i<7;i++){const ring=new THREE.Mesh(new THREE.TorusGeometry(.48+i*.016,.045,6,44),new THREE.MeshStandardMaterial({color:i%2?'#cfa67c':'#dfbc95',roughness:1}));ring.rotation.x=Math.PI/2;ring.rotation.z=i*.7;ring.position.y=i*.023;nest.add(ring);}
ball(nest,coral,0,.08,0,.48,.12,.42);nest.visible=arrival;
const bird=new THREE.Group();scene.add(bird);bird.visible=arrival;
ball(bird,soft,0,0,0,.27,.19,.38);ball(bird,soft,0,.17,.26,.19,.19,.19);
const dark=new THREE.MeshStandardMaterial({color:'#493c3c',roughness:.75});
ball(bird,dark,-.065,.205,.421,.022,.028,.018);ball(bird,dark,.065,.205,.421,.022,.028,.018);
ball(bird,gold,0,.135,.46,.065,.042,.14);
const wingL=new THREE.Group(),wingR=new THREE.Group();bird.add(wingL,wingR);wingL.position.x=-.19;wingR.position.x=.19;
ball(wingL,soft,-.35,0,0,.43,.05,.19);ball(wingR,soft,.35,0,0,.43,.05,.19);
ball(bird,coral,0,-.32,.04,.30,.22,.25);
const loader=new GLTFLoader(),mixers=[],pets=[];
const caption=document.getElementById('caption');
let time=0,last=0,done=false,raf=0;
function resize(){renderer.setSize(innerWidth,innerHeight);camera.aspect=innerWidth/innerHeight;camera.position.z=5*Math.max(1,.65/camera.aspect);camera.updateProjectionMatrix();}resize();addEventListener('resize',resize);
const smooth=t=>{t=THREE.MathUtils.clamp(t,0,1);return t*t*(3-2*t);};
async function loadPet(key,index){
 const gltf=await loader.loadAsync('./play-models/'+names[key]);limitTextureMemory(gltf.scene);
 const mixer=new THREE.AnimationMixer(gltf.scene);mixer.clipAction(createNaturalRest(gltf.scene)).play();mixer.update(0);mixers.push(mixer);
 const bounds=new THREE.Box3().setFromObject(gltf.scene),size=bounds.getSize(new THREE.Vector3()),center=bounds.getCenter(new THREE.Vector3());
 const root=new THREE.Group(),normalized=new THREE.Group();normalized.scale.setScalar(1/size.y);gltf.scene.position.sub(new THREE.Vector3(center.x,bounds.min.y,center.z));normalized.add(gltf.scene);root.add(normalized);scene.add(root);
 if(!arrival){const col=index%2,row=Math.floor(index/2);root.position.set((col-.5)*1.30,.05+row*1.15,0);root.scale.setScalar(.85);ball(scene,index%2?coral:soft,root.position.x,root.position.y-.06,0,.52,.065,.4);}
 pets.push(root);return root;
}
function finish(){if(done)return;done=true;const message=JSON.stringify({type:'runner-exit'});if(globalThis.RunnerBridge)RunnerBridge.postMessage(message);else if(parent!==window)parent.postMessage(message,location.origin);}
function frame(now){raf=requestAnimationFrame(frame);const dt=document.hidden?0:Math.min(.05,(now-(last||now))/1000);last=now;time+=dt;for(const m of mixers)m.update(dt);
 if(arrival&&pets[0]){
  const fly=smooth(time/4.5),land=smooth((time-4.5)/1.4),grow=smooth((time-6)/2.3);
  bird.position.set(THREE.MathUtils.lerp(-2.8,0,fly),THREE.MathUtils.lerp(2.8,1.35,fly),-.15);
  const flap=reduced?0:Math.sin(time*8)*.48;wingL.rotation.z=-flap;wingR.rotation.z=flap;
  bird.position.x+=smooth((time-6)/2)*3;bird.position.y+=smooth((time-6)/2)*1.4;
  bird.visible=time<8.5;
  const pet=pets[0];pet.position.set(THREE.MathUtils.lerp(-2.8,0,fly),THREE.MathUtils.lerp(2.05,.28,land),.17);pet.scale.setScalar(.48+grow*.52);
  if(time<4.5)pet.position.y=bird.position.y-.65;
  pet.rotation.y=Math.sin(time*.8)*.025;
  caption.textContent=time<4.5?'Una pequeña compañía viene en camino…':time<6.2?'Un hogar para crecer juntos':'Bienvenidos a su Nido ♥';
  if(time>9)finish();
 }else if(!arrival){caption.textContent='Cuatro pequeñas compañías, un nuevo comienzo';for(const [i,p]of pets.entries())p.rotation.y=reduced?0:Math.sin(time*.55+i)*.06;}
 renderer.render(scene,camera);
}
try{await Promise.all((arrival?[species]:Object.keys(names)).map(loadPet));document.getElementById('loading').hidden=true;raf=requestAnimationFrame(frame);}catch(e){document.getElementById('loading').textContent='No pudimos cargar la bienvenida. Vuelve a abrir esta pestaña.';console.error(e);}
globalThis.runnerSuspend=()=>{last=performance.now();};
addEventListener('pagehide',()=>{cancelAnimationFrame(raf);scene.traverse(o=>{o.geometry?.dispose();if(o.material){for(const m of Array.isArray(o.material)?o.material:[o.material])m.dispose();}});renderer.dispose();});
