import * as T from 'three';
import {GLTFLoader} from '../vendor/loaders/GLTFLoader.js';
import {addHalloweenDecor} from './halloween.js';
import {limitTextureMemory} from '../texture_budget.js';
import {createMazePartnerMotion} from './partner-motion.js';
import {createLanternStation,updateLanternStation,createBridge,addGarden,createFriendlyBats} from './garden.js';
import {bridgeIsOpen} from './engine.js';
import {doorFacing} from './navigation.js';
const PALETTES={halloween:{wall:'#a18ca4',ground:'#b7a08b',fog:'#494361',accent:'#ffb256',decor:'#dc813e'},christmas:{wall:'#8ba7a6',ground:'#cbd9db',fog:'#263d54',accent:'#ffd890',decor:'#dc6d6b'},easter:{wall:'#93ac85',ground:'#bda38e',fog:'#354951',accent:'#ffe6ab',decor:'#edbdd1'},garden:{wall:'#81976f',ground:'#9e8c6c',fog:'#243c3c',accent:'#f9d48c',decor:'#f1c882'}};
function roundedBox(w,h,d,r=.12){const s=new T.Shape(),x=-w/2,y=-h/2;s.moveTo(x+r,y);s.lineTo(x+w-r,y);s.quadraticCurveTo(x+w,y,x+w,y+r);s.lineTo(x+w,y+h-r);s.quadraticCurveTo(x+w,y+h,x+w-r,y+h);s.lineTo(x+r,y+h);s.quadraticCurveTo(x,y+h,x,y+h-r);s.lineTo(x,y+r);s.quadraticCurveTo(x,y,x+r,y);const g=new T.ExtrudeGeometry(s,{depth:d-2*r,bevelEnabled:true,bevelSize:r,bevelThickness:r,bevelSegments:2,steps:1,curveSegments:3});g.translate(0,0,-d/2+r);return g;}
export class MazeScene{
 constructor(canvas){
  this.renderer=new T.WebGLRenderer({canvas,antialias:true,powerPreference:'low-power'});this.renderer.setPixelRatio(Math.min(devicePixelRatio,1.25));this.renderer.outputColorSpace=T.SRGBColorSpace;this.renderer.toneMapping=T.ACESFilmicToneMapping;this.renderer.toneMappingExposure=1.25;
  this.scene=new T.Scene();this.camera=new T.PerspectiveCamera(68,1,.05,45);this.scene.add(this.camera);this.ambient=new T.HemisphereLight('#fff0df','#a99d94',2.2);this.scene.add(this.ambient);this.scene.add(new T.AmbientLight('#fce4d3',.85));const moonlight=new T.DirectionalLight('#c9c5f0',2);moonlight.position.set(-4,9,3);this.scene.add(moonlight);
  this.lamp=new T.SpotLight('#ffe8ba',24,9.5,.45,.65,1.3);this.lamp.position.set(.17,-.1,0);this.camera.add(this.lamp);this.lampTarget=new T.Object3D();this.lampTarget.position.set(0,-.18,-6);this.camera.add(this.lampTarget);this.lamp.target=this.lampTarget;
  const hand=new T.Mesh(new T.SphereGeometry(.14,12,8),new T.MeshStandardMaterial({color:'#263c55',roughness:.9}));hand.scale.set(.85,.85,1.6);hand.position.set(.28,-.3,-.45);this.camera.add(hand);
  const torch=new T.Mesh(new T.CylinderGeometry(.075,.065,.38,12),new T.MeshStandardMaterial({color:'#b29868',metalness:.45,roughness:.5}));torch.rotation.x=Math.PI/2;torch.position.set(.28,-.26,-.57);this.camera.add(torch);
  this.world=new T.Group();this.scene.add(this.world);this.chests=new Map();this.traps=new Map();this.stations=new Map();this.bridges=new Map();this.yaw=0;this.pitch=0;this.viewYaw=0;this.viewPitch=0;this.preview=null;this.target=new T.Vector3();this.partner=new T.Group();this.partnerTarget=new T.Vector3();this.scene.add(this.partner);this.partner.visible=false;
  this.resize=()=>{this.renderer.setSize(innerWidth,innerHeight,false);this.camera.aspect=innerWidth/innerHeight;this.camera.updateProjectionMatrix();};addEventListener('resize',this.resize);this.resize();this.loadedKey='';this.time=0;
 }
 material(color){return new T.MeshStandardMaterial({color,roughness:.95});}
 clearWorld(){const geos=new Set(),mats=new Set();this.world.traverse(o=>{if(o.geometry)geos.add(o.geometry);if(o.material)for(const m of Array.isArray(o.material)?o.material:[o.material])mats.add(m);});this.world.clear();geos.forEach(g=>g.dispose());mats.forEach(m=>{m.map?.dispose();m.dispose();});this.chests.clear();this.traps.clear();this.stations.clear();this.bridges.clear();this.bats=null;this.garden=null;}
 build(s,side){
  const key=`${s.seed}:${s.theme}:${s.size}`;if(this.loadedKey===key)return;this.loadedKey=key;this.clearWorld();this.partnerInitialized=false;const p=PALETTES[s.theme];this.scene.background=new T.Color(p.fog);this.scene.fog=new T.FogExp2(p.fog,.045);
  const walls=s.grid.reduce((a,v,i)=>v?[...a,i]:a,[]),wall=new T.InstancedMesh(roundedBox(2,1.65,2),this.material(p.wall),walls.length),floor=new T.InstancedMesh(roundedBox(.97,.12,.97,.05),this.material(p.ground),s.size*s.size*4),m=new T.Matrix4();
  walls.forEach((cell,i)=>{m.makeTranslation(cell%s.size*2,.78,Math.floor(cell/s.size)*2);wall.setMatrixAt(i,m);wall.setColorAt(i,new T.Color(p.wall).multiplyScalar(.86+(cell%7)*.025));});
  for(let z=0;z<s.size;z++)for(let x=0;x<s.size;x++)for(let k=0;k<4;k++){const index=(z*s.size+x)*4+k;m.makeTranslation(x*2+(k%2-.5),-.1,z*2+(Math.floor(k/2)-.5));floor.setMatrixAt(index,m);floor.setColorAt(index,new T.Color(p.ground).multiplyScalar(.86+((x*7+z*3+k)%7)*.035));}this.world.add(wall,floor);
  const wood=this.material('#91663d'),gold=this.material('#e6bd74'),stone=this.material('#403e45');
  for(const c of s.chests){if(c.lantern){const item=createLanternStation(c);item.group.position.set(c.x*2,0,c.z*2);this.world.add(item.group);this.stations.set(c.id,item);continue;}const group=new T.Group();group.position.set(c.x*2,.2,c.z*2);const body=new T.Mesh(roundedBox(.74,.45,.5,.08),wood),lid=new T.Group(),top=new T.Mesh(roundedBox(.76,.2,.54,.08),wood.clone());lid.position.set(0,.32,-.27);top.position.z=.27;lid.add(top);const lock=new T.Mesh(roundedBox(.12,.18,.04,.02),gold);lock.position.set(0,.15,.29);const shape=new T.Shape();shape.moveTo(0,-.16);shape.bezierCurveTo(-.21,-.05,-.17,.2,.06,.2);shape.bezierCurveTo(.23,.07,.13,-.1,0,-.16);const clue=new T.Mesh(c.hint==='leaf'?new T.ShapeGeometry(shape):new T.TorusGeometry(.12,.035,4,12),new T.MeshBasicMaterial({color:c.hint==='leaf'?'#abe5a1':'#dfb0d2',side:T.DoubleSide}));clue.position.set(0,.8,0);group.add(body,lid,lock,clue);this.world.add(group);this.chests.set(c.id,{group,lid,clue});}
  for(const b of s.bridges??[]){const item=this.bridges.get(b.id);if(item){const open=bridgeIsOpen(s,b);item.deck.position.y+=((open?0:-.45)-item.deck.position.y)*(1-Math.exp(-dt*7));item.deck.visible=open;item.plate.material.emissiveIntensity=open?.5:0;}}
  if(this.bats){const fx=this.bats;fx.age+=dt;fx.group.children.forEach((bat,i)=>{bat.position.set(Math.sin(i*2+fx.age*3)*(.2+fx.age*.3),fx.age*.6+i*.07,Math.cos(i+fx.age*2)*.4);bat.rotation.z=Math.sin(fx.age*13+i)*.22;});if(fx.age>2.8){fx.group.removeFromParent();fx.group.traverse(o=>{o.geometry?.dispose();o.material?.dispose();});this.bats=null;}}
  for(const trap of s.traps){const mark=new T.Group();mark.position.set(trap.x*2,.005,trap.z*2);for(let i=0;i<3;i++){const crack=new T.Mesh(new T.BoxGeometry(.025,.018,.6),stone);crack.rotation.y=i*.7;mark.add(crack);}this.world.add(mark);this.traps.set(trap.id,mark);}
  this.garden=addGarden(this.world,s);for(const b of s.bridges??[]){const item=createBridge(b);this.world.add(item.group);this.bridges.set(b.id,item);}
  const points=[];for(let i=0;i<s.grid.length&&points.length<18;i++)if(!s.grid[i]&&i%s.size>0&&Math.floor(i/s.size)>0&&i%4===0)points.push([i%s.size*2+.65,Math.floor(i/s.size)*2+.6]);addHalloweenDecor(this.world,points);
  const door=new T.Group();door.position.set(s.exit.x*2,0,s.exit.z*2);door.rotation.y=doorFacing(s);
  const arch=new T.Shape();arch.moveTo(-.88,0);arch.lineTo(-.88,1.52);arch.absarc(0,1.52,.88,Math.PI,0,true);arch.lineTo(.88,0);arch.lineTo(-.88,0);
  const opening=new T.Path();opening.moveTo(-.77,.02);opening.lineTo(.77,.02);opening.lineTo(.77,1.5);opening.absarc(0,1.5,.77,0,Math.PI,false);opening.lineTo(-.77,.02);arch.holes.push(opening);
  const frame=new T.Mesh(new T.ExtrudeGeometry(arch,{depth:.22,bevelEnabled:true,bevelThickness:.025,bevelSize:.025,bevelSegments:2,steps:1,curveSegments:16}),gold);frame.position.z=-.16;door.add(frame);
  const panelShape=new T.Shape();panelShape.moveTo(-.74,0);panelShape.lineTo(-.74,1.5);panelShape.absarc(0,1.5,.74,Math.PI,0,true);panelShape.lineTo(.74,0);panelShape.lineTo(-.74,0);
  const hinge=new T.Group();hinge.position.set(-.74,0,.12);const panel=new T.Mesh(new T.ExtrudeGeometry(panelShape,{depth:.12,bevelEnabled:true,bevelSize:.035,bevelThickness:.035,bevelSegments:2,curveSegments:16}),wood);panel.position.x=.74;hinge.add(panel);door.add(hinge);
  const knob=new T.Mesh(new T.SphereGeometry(.075,10,8),gold);knob.position.set(1.28,1,.22);hinge.add(knob);
  this.gateLanterns=[];for(let i=0;i<3;i++){const hanging=createLanternStation({id:i});hanging.group.scale.setScalar(.3);hanging.group.position.set((i-1)*.47,2.14,.05);door.add(hanging.group);this.gateLanterns.push(hanging);}
  this.doorSeals=[];for(let i=0;i<3;i++){const seal=new T.Mesh(new T.TorusGeometry(.11,.035,6,16),new T.MeshBasicMaterial({color:'#685568'}));seal.position.set(.74+(i-1)*.34,1.4,.21);hinge.add(seal);this.doorSeals.push(seal);}this.world.add(door);this.door=door;this.doorHinge=hinge;this.keyEffects=[];
  const beacon=new T.PointLight(p.accent,3,5);beacon.position.set(s.exit.x*2,1.8,s.exit.z*2);this.world.add(beacon);this.beacon=beacon;
  const player=s.players[side];this.camera.position.set(player.x*2,1.25,player.z*2);const exits=[[1,0],[0,1],[-1,0],[0,-1]].filter(([a,b])=>!s.grid[(player.z+b)*s.size+player.x+a]);if(exits.length)this.yaw=Math.atan2(-exits[0][0],-exits[0][1]);this.viewYaw=this.yaw;this.viewPitch=this.pitch=0;this.preview=null;
 }
 async loadPartner(species='bear'){
  this.partnerMotion?.dispose();this.partner.clear();const files={penguin:'Meshy_AI_Pip_the_Penguin_All_Animations.glb',bear:'bear.glb',pig:'pig.glb',chick:'chick.glb'},gltf=await new GLTFLoader().loadAsync(new URL('../play-models/'+(files[species]??files.bear),import.meta.url).href),b=new T.Box3().setFromObject(gltf.scene),center=b.getCenter(new T.Vector3()),scale=1.25/(b.max.y-b.min.y);gltf.scene.position.set(-center.x,-b.min.y,-center.z);const group=new T.Group();group.scale.setScalar(scale);group.add(gltf.scene);this.partner.add(group);limitTextureMemory(group,768);this.partnerMotion=createMazePartnerMotion(gltf.scene,gltf.animations);this.partnerInitialized=false;
  const heart=new T.Mesh(new T.SphereGeometry(.075,8,6),new T.MeshBasicMaterial({color:'#ffb4cb'}));heart.position.y=1.45;this.partner.add(heart);
 }
 celebrate(kind,x,z){
  if(kind!=='key'||!Number.isFinite(x)||!Number.isFinite(z))return;
  const group=new T.Group(),mat=new T.MeshStandardMaterial({color:'#ffd485',emissive:'#eebc4d',emissiveIntensity:.6,roughness:.35});
  const ring=new T.Mesh(new T.TorusGeometry(.18,.035,6,16),mat);ring.position.y=.3;group.add(ring);
  const shaft=new T.Mesh(new T.CylinderGeometry(.12,.15,.3,8),mat);shaft.position.y=.04;group.add(shaft);
  for(let i=0;i<8;i++){const spark=new T.Mesh(new T.OctahedronGeometry(.035),new T.MeshBasicMaterial({color:'#ffe9a6'}));spark.position.set(Math.cos(i*Math.PI/4)*.32,Math.sin(i*Math.PI/4)*.32,0);group.add(spark);}
  group.position.set(x*2,1,z*2);this.world.add(group);this.keyEffects??=[];this.keyEffects.push({group,age:0});
 }
 surprise(x,z,intensity=1){
  if(this.bats){this.bats.group.removeFromParent();this.bats.group.traverse(o=>{o.geometry?.dispose();o.material?.dispose();});}
  this.bats=createFriendlyBats();this.bats.group.scale.setScalar(intensity);this.bats.group.position.set(x*2,.55,z*2);this.world.add(this.bats.group);
 }
 draw(s,side,dt,flashlight=true){
  this.time+=dt;this.lamp.intensity=flashlight?24:3;this.build(s,side);const p=this.preview??s.players[side];this.target.set(p.x*2,1.25,p.z*2);const moving=this.camera.position.distanceToSquared(this.target)>.002;this.target.y+=moving?Math.sin(this.time*9)*.012:0;this.camera.position.lerp(this.target,1-Math.exp(-dt*14));this.viewYaw+=Math.atan2(Math.sin(this.yaw-this.viewYaw),Math.cos(this.yaw-this.viewYaw))*(1-Math.exp(-dt*18));this.viewPitch+=(this.pitch-this.viewPitch)*(1-Math.exp(-dt*18));this.camera.rotation.order='YXZ';this.camera.rotation.set(this.viewPitch,this.viewYaw,0);
  this.garden?.update(this.time);this.ambient.intensity=2.2+s.keys*.15;if(this.beacon)this.beacon.intensity=3+s.keys*1.5;
  for(const c of s.chests){const station=this.stations.get(c.id);if(station)updateLanternStation(station,c,this.viewYaw,this.time);const item=this.chests.get(c.id);if(item){item.lid.rotation.x+=((c.opened?-1.1:0)-item.lid.rotation.x)*(1-Math.exp(-dt*8));item.clue.visible=!c.opened;item.clue.rotation.y=this.viewYaw;item.clue.position.y=.8+Math.sin(this.time*2+c.id)*.035;}}
  for(const b of s.bridges??[]){const item=this.bridges.get(b.id);if(item){const open=bridgeIsOpen(s,b);item.deck.position.y+=((open?0:-.45)-item.deck.position.y)*(1-Math.exp(-dt*7));item.deck.visible=open;item.plate.material.emissiveIntensity=open?.5:0;}}
  if(this.bats){const fx=this.bats;fx.age+=dt;fx.group.children.forEach((bat,i)=>{bat.position.set(Math.sin(i*2+fx.age*3)*(.2+fx.age*.3),fx.age*.6+i*.07,Math.cos(i+fx.age*2)*.4);bat.rotation.z=Math.sin(fx.age*13+i)*.22;});if(fx.age>2.8){fx.group.removeFromParent();fx.group.traverse(o=>{o.geometry?.dispose();o.material?.dispose();});this.bats=null;}}
  for(const trap of s.traps){const mark=this.traps.get(trap.id);if(mark)mark.visible=!trap.used;}
  if(this.doorHinge){const opening=s.keys>=3&&Math.abs(p.x-s.exit.x)+Math.abs(p.z-s.exit.z)<3;this.doorHinge.rotation.y+=((opening?-1.35:0)-this.doorHinge.rotation.y)*(1-Math.exp(-dt*5));this.gateLanterns.forEach((item,i)=>{item.glass.material.emissiveIntensity=i<s.keys?1.3:0;item.flame.visible=i<s.keys;item.tablet.visible=false;});this.doorSeals.forEach((seal,i)=>seal.material.color.set(i<s.keys?'#ffe5a3':'#685568'));}
  for(const fx of this.keyEffects??[]){fx.age+=dt;fx.group.position.y+=dt*.55;fx.group.rotation.y=this.viewYaw+Math.sin(fx.age*5)*.25;fx.group.scale.setScalar(Math.max(0,Math.min(1,fx.age*8,(1.6-fx.age)*4)));}
  this.keyEffects=(this.keyEffects??[]).filter(fx=>{if(fx.age<1.6)return true;fx.group.removeFromParent();fx.group.traverse(o=>{o.geometry?.dispose();o.material?.dispose();});return false;});
  const other=s.players.find(q=>q.id!==side);this.partner.visible=!!other;if(other){this.partnerTarget.set(other.x*2,0,other.z*2);if(!this.partnerInitialized){this.partner.position.copy(this.partnerTarget);this.partner.rotation.y=other.facing+Math.PI;this.partnerInitialized=true;}const distance=this.partner.position.distanceTo(this.partnerTarget);const speed=dt>0?distance*(1-Math.exp(-dt*11))/dt:0;this.partner.position.lerp(this.partnerTarget,1-Math.exp(-dt*11));const heading=other.facing+Math.PI;this.partner.rotation.y+=Math.atan2(Math.sin(heading-this.partner.rotation.y),Math.cos(heading-this.partner.rotation.y))*(1-Math.exp(-dt*12));this.partnerMotion?.update(dt,speed,other.hp<=0);}
  this.renderer.render(this.scene,this.camera);
 }
 dispose(){this.partnerMotion?.dispose();this.partner.traverse(o=>{o.geometry?.dispose();for(const m of Array.isArray(o.material)?o.material:o.material?[o.material]:[]){for(const key of ['map','normalMap','roughnessMap','metalnessMap'])m[key]?.dispose();m.dispose();}});removeEventListener('resize',this.resize);this.clearWorld();this.renderer.dispose();}
}
