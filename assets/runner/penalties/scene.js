import * as T from 'three';
import {GLTFLoader} from '../vendor/loaders/GLTFLoader.js';
import {createPetCrowd} from './crowd.js';
import {createFootball} from './football.js';
import {createNaturalRest} from '../pet-rest-pose.js';
import {createFootballPose,shotPresentation,keeperPresentation,CONTACT_TIME,IMPACT_TIME} from './motion.js';
import {limitTextureMemory} from '../texture_budget.js';
import {registerAccessoryAsset,releaseAccessoryAssets,equipRunnerCosmetics,prepareAccessoryAssets} from '../cosmetics.js?revision=registry-api-6';
export class PenaltyScene{
 constructor(canvas){
  this.renderer=new T.WebGLRenderer({canvas,antialias:true,powerPreference:'low-power'});this.renderer.setPixelRatio(Math.min(devicePixelRatio,1.5));this.renderer.outputColorSpace=T.SRGBColorSpace;this.renderer.toneMapping=T.ACESFilmicToneMapping;
  this.scene=new T.Scene();this.scene.background=new T.Color('#eeb5af');this.scene.fog=new T.Fog('#d1afb3',38,90);this.camera=new T.PerspectiveCamera(56,1,.1,120);this.target=new T.Vector3();
  this.scene.add(new T.HemisphereLight('#ffe9cd','#718368',2.7));const sun=new T.DirectionalLight('#ffdfb8',3.1);sun.position.set(-8,15,10);this.scene.add(sun);
  const mat=(color,roughness=.85)=>new T.MeshStandardMaterial({color,roughness});this.material=mat;
  const box=(w,h,d,x,y,z,color)=>{const m=new T.Mesh(new T.BoxGeometry(w,h,d),mat(color));m.position.set(x,y,z);this.scene.add(m);return m;};
  const turf=box(70,.2,85,0,-.16,10,'#479767');
  const patch=document.createElement('canvas');patch.width=128;patch.height=128;const ink=patch.getContext('2d');ink.fillStyle='#72a874';ink.fillRect(0,0,128,128);
  let seed=731;for(let i=0;i<8000;i++){seed=(Math.imul(seed,1664525)+1013904223)>>>0;const x=seed%128;seed=(Math.imul(seed,1664525)+1013904223)>>>0;const y=seed%128;ink.fillStyle=i%2?'#52885a':'#92bc82';ink.fillRect(x,y,1,2);}
  const grass=new T.CanvasTexture(patch);grass.wrapS=grass.wrapT=T.RepeatWrapping;grass.repeat.set(35,40);turf.material.map=grass;
  for(let i=0;i<13;i++){const stripe=box(45,.012,4,0,-.047,-19+i*4,i%2?'#80b48b':'#346348');stripe.material.transparent=true;stripe.material.opacity=.22;}
  const linePoints=[],lineColors=[];const line=(a,b,color='#fff2d7')=>{linePoints.push(...a,...b);const c=new T.Color(color);lineColors.push(...c.toArray(),...c.toArray());};
  for(const x of [-12,12])line([x,.015,-1],[x,.015,18]);line([-12,.015,18],[12,.015,18]);line([-18,.015,-1],[18,.015,-1]);
  const goal=new T.Group();this.scene.add(goal);this.goal=goal;
  const bar=(a,b)=>{const p=new T.Vector3(...a),q=new T.Vector3(...b),m=new T.Mesh(new T.CylinderGeometry(.075,.075,p.distanceTo(q),10),mat('#fff5e9'));m.position.copy(p.clone().add(q).multiplyScalar(.5));m.quaternion.setFromUnitVectors(new T.Vector3(0,1,0),q.sub(p).normalize());goal.add(m);};
  bar([-3.7,0,0],[-3.7,2.7,0]);bar([3.7,0,0],[3.7,2.7,0]);bar([-3.7,2.7,0],[3.7,2.7,0]);
  for(let x=-3.6;x<=3.7;x+=.25){line([x,0,-1.5],[x,2.7,-1.5],'#dddcd5');line([x,2.7,0],[x,2.7,-1.5],'#dddcd5');}
  for(let y=0;y<=2.7;y+=.25)line([-3.7,y,-1.5],[3.7,y,-1.5],'#dddcd5');
  for(const x of [-3.7,3.7])for(let y=0;y<=2.7;y+=.25)line([x,y,0],[x,y,-1.5],'#dddcd5');
  const netGeometry=new T.BufferGeometry();netGeometry.setAttribute('position',new T.Float32BufferAttribute(linePoints,3));netGeometry.setAttribute('color',new T.Float32BufferAttribute(lineColors,3));this.scene.add(new T.LineSegments(netGeometry,new T.LineBasicMaterial({vertexColors:true})));
  this.crowdReady=createPetCrowd(this.scene).then(c=>this.crowd=c).catch(()=>{});
  for(let row=0;row<5;row++){
   box(55,.9,2,0,.2+row*.9,-9-row*2,'#c5a78e');box(55,.9,2,0,.2+row*.9,34+row*2,'#c5a78e');

  }
  for(const x of [-19,19]){box(.2,12,.2,x,6,-5,'#a6aaa5');box(3,.7,.2,x,12,-5,'#fff5cb');}
  this.ball=createFootball();this.scene.add(this.ball);
  this.actors=[new T.Group(),new T.Group()];this.actors.forEach(g=>this.scene.add(g));this.mixers=[];this.contactShadows=this.actors.map(()=>{const mesh=new T.Mesh(new T.CircleGeometry(.52,24),new T.MeshBasicMaterial({color:'#23382d',transparent:true,opacity:.16,depthWrite:false}));mesh.rotation.x=-Math.PI/2;mesh.position.y=.026;this.scene.add(mesh);return mesh;});this.role=0;this.side=0;this.progress=null;
  this.scene.add(this.camera);this.gloves=new T.Group();this.camera.add(this.gloves);
  for(const x of [-.55,.55]){const glove=new T.Mesh(new T.SphereGeometry(.18,12,8),mat('#fff1d8'));glove.scale.set(1,1.2,.6);glove.position.set(x,-.44,-1.05);this.gloves.add(glove);}
  this.aim=new T.Mesh(new T.RingGeometry(.13,.18,24),new T.MeshBasicMaterial({color:'#fff0af',side:T.DoubleSide,transparent:true,opacity:.85}));this.aim.position.set(0,1.4,.06);this.scene.add(this.aim);
  this.resize=()=>{this.renderer.setSize(innerWidth,innerHeight,false);this.camera.aspect=innerWidth/innerHeight;this.camera.fov=T.MathUtils.radToDeg(2*Math.atan(Math.tan(T.MathUtils.degToRad(56)/2)*Math.max(1,.78/this.camera.aspect)));this.camera.updateProjectionMatrix();};addEventListener('resize',this.resize);this.resize();this.setTurn(0,0);
 }
 async load(species,onProgress=()=>{}){
  const loader=new GLTFLoader(),files={penguin:'Meshy_AI_Pip_the_Penguin_All_Animations.glb',bear:'bear.glb',pig:'pig.glb',chick:'chick.glb'};
  // Decode one original mascot at a time. Parallel large-texture decoding can
  // exhaust mobile WebViews before the runtime texture budget is applied.
  for(const [i,group]of this.actors.entries()){
   group.clear();const name=files[species[i]]?species[i]:i?'bear':'penguin';
   onProgress('Preparando mascota '+(i+1)+' de 2…');
   const load=async(path,label)=>{try{return await loader.loadAsync(path);}catch(error){throw new Error(label+': '+(error?.message||'No se pudo descargar el recurso'),{cause:error});}};
   const gltf=await load(new URL('../play-models/'+files[name],import.meta.url).href,'Mascota '+name);
   limitTextureMemory(gltf.scene,768);
   const model=new T.Group();createNaturalRest(gltf.scene);gltf.scene.updateMatrixWorld(true);const b=new T.Box3().setFromObject(gltf.scene),height=b.max.y-b.min.y;
   gltf.scene.scale.multiplyScalar(1.15/height);const fitted=new T.Box3().setFromObject(gltf.scene),center=fitted.getCenter(new T.Vector3());gltf.scene.position.sub(new T.Vector3(center.x,fitted.min.y,center.z));model.add(gltf.scene);model.userData.species=name;group.add(model);group.scale.setScalar(1.8/1.15);model.updateMatrixWorld(true);
   onProgress('Preparando camiseta '+(i+1)+' de 2…');
   const asset=`assets/runner/accessories/sewn_shirt_love_${name}.glb`,shirt=await load(new URL('../accessories/'+asset.split('/').pop(),import.meta.url).href,'Camiseta '+name);
   limitTextureMemory(shirt.scene,768);
   // Match the approved species-specific shirt and original skin instead of generic cylinders.
   registerAccessoryAsset(asset,shirt.scene);
   const coverage=await fetch(new URL('../restart/'+`shirt-original-coverage-${name}.json`,import.meta.url));
   const item={style:'shirt_love',model_asset:asset,fitted_model_space:true,skinned_model_space:true,garment_color:i?'#df4d59':'#2c70ce',color_base:'#FFF0D9',color_materials:['Algodón crema grueso'],...(coverage.ok?{covered_skin_triangles:await coverage.json()}:{})};
   model.userData.defaultAppearance={pet_body:item};
   const outfit=equipRunnerCosmetics(model,{pet_body:item});outfit.traverse(o=>{if(o.isMesh&&(/coraz|bordado|heart/i.test(o.name)||/Bordado/.test(o.material?.name??'')))o.visible=false;});
   model.userData.cosmetics=outfit;model.userData.footballPose=createFootballPose(model);
   if(this.appearanceBySide?.[i])await this.setAppearance(this.appearanceBySide[i],i);

  }
 }
 async setAppearance(appearance,side=0){
  if(side!==0&&side!==1)return;
  this.appearanceBySide??=[null,null];this.appearanceBySide[side]=structuredClone(appearance??{});
  const model=this.actors[side]?.children[0];if(!model?.userData.defaultAppearance)return;
  const revision=(model.userData.appearanceRevision??0)+1;model.userData.appearanceRevision=revision;
  const selected=Object.fromEntries(Object.entries(appearance??{}).filter(([slot,item])=>/^pet_(head|body|neck|feet|eyes|face|back)$/.test(slot)&&item&&typeof item==='object'&&!Array.isArray(item)));
  const loadout=structuredClone({...model.userData.defaultAppearance,...selected});
  // Prepare the replacement before removing the current outfit. A failed
  // download must not leave an undressed actor or restart the penalty turn.
  await prepareAccessoryAssets(loadout,model.userData.species);
  if(model.userData.appearanceRevision!==revision||this.actors[side]?.children[0]!==model)return;
  const equip=()=>equipRunnerCosmetics(model,loadout);
  const outfit=model.userData.footballPose?.withRest?model.userData.footballPose.withRest(equip):equip();
  if(!selected.pet_body)outfit.traverse(o=>{if(o.isMesh&&(/coraz|bordado|heart/i.test(o.name)||/Bordado/.test(o.material?.name??'')))o.visible=false;});
  model.userData.cosmetics=outfit;
 }
 setTurn(shooting,side){if(this.turnReady&&this.role===shooting&&this.side===side&&!this.progress)return;this.turnReady=true;this.role=shooting;this.side=side;this.progress=null;this.gloves.rotation.set(0,0,0);this.ball.rotation.set(0,0,0);this.ball.position.set(0,.23,10);this.ball.visible=true;this.actors.forEach((g,i)=>{g.position.set(i===shooting?-.32:0,0,i===shooting?11.3:.4);g.rotation.set(0,i===shooting?Math.PI:0,0);});
  const keeper=side!==shooting;this.actors[side].visible=!keeper;this.actors[1-side].visible=true;this.gloves.visible=keeper;this.camera.position.set(0,keeper?1.7:2.7,keeper?-.75:15.8);this.camera.lookAt(0,keeper?.8:1.2,keeper?11:0);this.cameraHome=this.camera.position.clone();this.cameraRest=this.camera.quaternion.clone();this.aim.visible=!keeper;
 }
 animate(result,time){this.progress={result,start:time};this.crowd?.react(result.kind,time+IMPACT_TIME);this.aim.visible=false;}
 draw(time,dt,aim){
  this.aim.position.set((aim.x-.5)*7.3,.2+aim.y*2.4,.08);
  this.camera.position.copy(this.cameraHome);this.camera.quaternion.copy(this.cameraRest);
  if(this.progress){const {result:r,start}=this.progress,seconds=Math.max(0,time-start),motion=shotPresentation(seconds,r),t=(seconds-CONTACT_TIME)/.9,p=motion.flight,keeper=this.actors[1-r.side],striker=this.actors[r.side];
   this.ball.position.set((r.shot.x-.5)*(r.kind==='miss'?9:7.3)*p,.23+(.2+r.shot.y*2.4-.23)*p+Math.sin(p*Math.PI)*.7,10*(1-p));this.ball.rotation.x=-p*14;
   const k=keeperPresentation(seconds,r);keeper.position.x=k.x;keeper.position.y=k.y;keeper.rotation.z=k.roll;striker.position.z=11.3-.48*motion.approach;striker.rotation.x=0;
   if(this.side!==this.role){this.camera.position.x+=k.x;this.camera.position.y+=k.y;this.camera.rotateZ(k.roll*.17);}
   if(t>1&&r.kind==='save'){/* The articulated glove catches it below, after the skin updates. */}
   else if(t>1&&r.kind==='post'){this.ball.position.z=(t-1)*4;this.ball.position.y=Math.max(.23,this.ball.position.y-(t-1)*2);}
   else if(t>1){this.ball.position.z=-Math.min(1.3,(t-1)*3);}
  }
  for(const [i,actor]of this.actors.entries())actor.children[0]?.userData.footballPose?.update(time,{role:i===this.role?'striker':'keeper',seconds:this.progress?time-this.progress.start:null,result:this.progress?.result});
  const goalie=this.actors[1-this.role].children[0],hands=['LeftHand','RightHand'].map(n=>goalie?.userData.footballPose?.bones.get(n)).filter(Boolean);this.camera.updateMatrixWorld(true);
  if(this.gloves.visible)hands.forEach((hand,i)=>{hand.getWorldPosition(this.target);this.camera.worldToLocal(this.target);this.gloves.children[i].position.copy(this.target);});
  if(this.progress?.result.kind==='save'){
   const elapsed=time-this.progress.start,p=shotPresentation(elapsed,this.progress.result).flight;
   if(p>.75&&hands.length){const expected=new T.Vector3((this.progress.result.shot.x-.5)*7.3,.2+this.progress.result.shot.y*2.4,.4),positions=hands.map(h=>h.getWorldPosition(new T.Vector3()));positions.sort((a,b)=>a.distanceToSquared(expected)-b.distanceToSquared(expected));this.ball.position.lerp(positions[0],T.MathUtils.smoothstep(p,.75,1));}
  }
  this.contactShadows.forEach((m,i)=>{m.position.x=this.actors[i].position.x;m.position.z=this.actors[i].position.z;m.material.opacity=.16/(1+this.actors[i].position.y);});this.crowd?.update(time);this.renderer.render(this.scene,this.camera);
 }
 dispose(){for(const actor of this.actors)actor.children[0]?.userData.footballPose?.dispose();this.crowd?.dispose();releaseAccessoryAssets();removeEventListener('resize',this.resize);this.scene.traverse(o=>{o.geometry?.dispose();if(o.material){for(const m of Array.isArray(o.material)?o.material:[o.material]){for(const key of ['map','normalMap','roughnessMap','metalnessMap'])m[key]?.dispose();m.dispose();}}});this.renderer.dispose();}
}
