import * as THREE from 'three';
import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';
import {createNaturalRest} from './pet-rest-pose.js';
import {refinePip} from './pip-delicate.js';
import {equipRunnerCosmetics,prepareAccessoryAssets,releaseAccessoryAssets,disposeAccessory} from './cosmetics.js';

const blender=new URLSearchParams(location.search).has('blender');
const catalog=await fetch(blender?'blender-head-models.json':'head-models.json',{cache:'no-store'}).then(r=>r.json()).then(items=>items.filter(item=>item.visible!==false));
const pets={penguin:['Pingüino','Meshy_AI_Pip_the_Penguin_All_Animations.glb'],bear:['Oso','bear.glb'],pig:['Cerdito','pig.glb'],chick:['Pollito','chick.glb']};
const scene=new THREE.Scene();scene.background=new THREE.Color('#fff5f6');
scene.add(new THREE.HemisphereLight('#fff6ee','#b8aab5',2));
const sun=new THREE.DirectionalLight('#ffffff',2);sun.position.set(-3,6,5);sun.castShadow=true;sun.shadow.mapSize.set(1024,1024);sun.shadow.camera.left=-2;sun.shadow.camera.right=2;sun.shadow.camera.top=2;sun.shadow.camera.bottom=-2;sun.shadow.normalBias=.015;scene.add(sun);
const fill=new THREE.DirectionalLight('#e8efff',.6);fill.position.set(4,3,4);scene.add(fill);
const floor=new THREE.Mesh(new THREE.PlaneGeometry(20,20),new THREE.ShadowMaterial({color:'#78656b',opacity:.18}));floor.rotation.x=-Math.PI/2;floor.receiveShadow=true;floor.position.y=-.007;scene.add(floor);
const renderer=new THREE.WebGLRenderer({antialias:true,preserveDrawingBuffer:true});renderer.setSize(420,540);renderer.outputColorSpace=THREE.SRGBColorSpace;renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFSoftShadowMap;
const camera=new THREE.PerspectiveCamera(28,420/540,.01,30),loader=new GLTFLoader();
const gallery=document.querySelector('#gallery'),status=document.querySelector('#status');
gallery.style.setProperty('--head-count',catalog.length);
const photographs=[],view=document.querySelector('select');
view.onchange=()=>{for(const photo of photographs)photo.image.src=photo.angles[view.value];};
let completed=0;
try{
 for(const [species,[label,file]] of Object.entries(pets)){
  const heading=document.createElement('h2');heading.textContent=label;gallery.append(heading);
  const grid=document.createElement('div');grid.className='grid';gallery.append(grid);
  const {scene:character}=await loader.loadAsync('./play-models/'+file);
  character.scale.multiplyScalar(1.15/new THREE.Box3().setFromObject(character).getSize(new THREE.Vector3()).y);
  const bounds=new THREE.Box3().setFromObject(character),center=bounds.getCenter(new THREE.Vector3());character.position.sub(new THREE.Vector3(center.x,bounds.min.y,center.z));
  const model=new THREE.Group();model.add(character);model.userData.species=species;scene.add(model);
  const mixer=new THREE.AnimationMixer(model);mixer.clipAction(createNaturalRest(model)).play();mixer.update(0);
  if(species==='penguin')refinePip(model);
  model.traverse(mesh=>{if(mesh.isMesh)mesh.castShadow=true;});
  for(const item of catalog){
   status.textContent=`Preparando ${item.name} · ${label} (${completed+1}/${catalog.length*4})`;
   // Fit in the neutral coordinate frame; rotation is only for photography.
   model.rotation.y=0;model.updateMatrixWorld(true);
   await prepareAccessoryAssets({pet_head:item.appearance},species);
   const equipped=equipRunnerCosmetics(model,{pet_head:item.appearance});
   equipped.userData.slots.forEach(part=>part.traverse(mesh=>{if(mesh.isMesh)mesh.castShadow=true;}));
   // The body keeps the same size in every card; taller hats do not shrink it.
   camera.position.set(0,.85,3.10);camera.lookAt(0,.72,0);
   const angles={};for(const [key,angle] of Object.entries({front:.10,three:Math.PI/4,profile:Math.PI/2,back:Math.PI})){model.rotation.y=angle;model.updateMatrixWorld(true);renderer.render(scene,camera);angles[key]=renderer.domElement.toDataURL('image/png');}
   const card=document.createElement('article'),image=new Image(),title=document.createElement('h3'),link=document.createElement('a');
   image.src=angles[view.value];image.alt=`${label} con ${item.name}`;image.dataset.file=`${species}-${item.item_key}.png`;photographs.push({image,angles});
   title.textContent=item.name;link.textContent='Ver en 3D';link.href=`accessory-review.html?${blender?'blender=1':'meshy=1'}&item=${item.item_key}&species=${species}`;
   card.append(image,title,link);grid.append(card);completed++;
   for(const part of equipped.userData.slots)disposeAccessory(part);disposeAccessory(equipped);delete model.userData.cosmetics;releaseAccessoryAssets();
   await new Promise(resolve=>requestAnimationFrame(resolve));
  }
  mixer.stopAllAction();mixer.uncacheRoot(model);
  model.traverse(mesh=>{if(!mesh.isMesh)return;for(const material of Array.isArray(mesh.material)?mesh.material:[mesh.material])for(const value of Object.values(material))if(value?.isTexture)value.dispose();});disposeAccessory(model);
 }
 status.textContent=`${completed} combinaciones ${blender?'modeladas en Blender':'adaptadas'} listas para revisar.`;document.body.dataset.ready='true';
}catch(error){status.textContent='No se pudo completar la revisión: '+error.message;console.error(error);}
finally{renderer.dispose();renderer.forceContextLoss();floor.geometry.dispose();floor.material.dispose();}
