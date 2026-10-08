import * as THREE from 'three';
import { createFlowMaterial, createKingdom } from './fantasy-water.js';

// Shared geometry keeps the repeated scenery inexpensive on mobile.
const gold=new THREE.MeshStandardMaterial({color:'#ffd34f',metalness:.72,roughness:.26,emissive:'#8a4600',emissiveIntensity:.18});
const rim=new THREE.MeshStandardMaterial({color:'#fff0a0',metalness:.65,roughness:.24});
const coinBody=new THREE.CylinderGeometry(.26,.26,.09,24);
const coinRim=new THREE.TorusGeometry(.225,.021,6,24);
const heart=new THREE.Shape();
heart.moveTo(0,-.12);heart.bezierCurveTo(-.22,.02,-.16,.19,0,.08);heart.bezierCurveTo(.16,.19,.22,.02,0,-.12);
const emblem=new THREE.ExtrudeGeometry(heart,{depth:.018,bevelEnabled:true,bevelSegments:1,steps:1,bevelSize:.008,bevelThickness:.008});
export function createTropicalCoin(){
  const group=new THREE.Group(),body=new THREE.Mesh(coinBody,gold);body.rotation.x=Math.PI/2;group.add(body);
  for(const side of [-1,1]){
    const edge=new THREE.Mesh(coinRim,rim);edge.position.z=side*.05;group.add(edge);
    const stamp=new THREE.Mesh(emblem,rim);stamp.position.z=side*.05;stamp.rotation.y=side<0?Math.PI:0;group.add(stamp);
  }
  return group;
}
const trunkGeometry=new THREE.CylinderGeometry(.13,.24,3.8,7);
const trunkMaterial=new THREE.MeshStandardMaterial({color:'#b77c48',roughness:1});
const leaves=['#36a76a','#63c75a','#20936a'].map(color=>new THREE.MeshStandardMaterial({color,roughness:.85,side:THREE.DoubleSide}));
const leafVertices=[],leafIndices=[];
for(let i=0;i<=10;i++){
  const t=i/10,width=.36*Math.sin(Math.PI*t),y=Math.sin(t*Math.PI)*.4-t*t*.45;
  leafVertices.push(-width,y,t*2.4,0,y+.07*Math.sin(Math.PI*t),t*2.4,width,y,t*2.4);
  if(i<10){const a=i*3;leafIndices.push(a,a+3,a+1,a+1,a+3,a+4,a+1,a+4,a+2,a+2,a+4,a+5);}
}
const leafGeometry=new THREE.BufferGeometry();leafGeometry.setAttribute('position',new THREE.Float32BufferAttribute(leafVertices,3));leafGeometry.setIndex(leafIndices);leafGeometry.computeVertexNormals();
const petalGeometry=new THREE.SphereGeometry(.13,7,5);
const bloomMaterials=['#ff678c','#ffb83e','#bd83ff'].map(color=>new THREE.MeshStandardMaterial({color,roughness:.65}));
export function createPalm(index=0){
  const group=new THREE.Group();group.userData.fronds=[];const trunk=new THREE.Mesh(trunkGeometry,trunkMaterial);trunk.position.y=1.9;trunk.rotation.z=.09;group.add(trunk);
  for(let i=0;i<7;i++){
    const pivot=new THREE.Group();pivot.position.set(-.17,3.65,0);pivot.rotation.y=i*Math.PI*2/7;
    const leaf=new THREE.Mesh(leafGeometry,leaves[i%3]);leaf.rotation.x=-.12; pivot.add(leaf);group.add(pivot);group.userData.fronds.push(leaf);
  }
  for(let i=0;i<4;i++){
    const flower=new THREE.Group();flower.position.set(Math.sin(i*2)*.7,.35,Math.cos(i*2)*.7);
    for(let p=0;p<5;p++){const petal=new THREE.Mesh(petalGeometry,bloomMaterials[index%3]);petal.position.set(Math.cos(p*1.256)*.14,0,Math.sin(p*1.256)*.14);petal.scale.y=.45;flower.add(petal);}
    const center=new THREE.Mesh(petalGeometry,gold);center.scale.set(.55,.4,.55);flower.add(center);group.add(flower);
  }
  return group;
}
export function createWoodTexture(){
  const canvas=document.createElement('canvas');canvas.width=256;canvas.height=64;const ctx=canvas.getContext('2d');
  ctx.fillStyle='#ffffff';ctx.fillRect(0,0,256,64);
  for(let i=0;i<16;i++){ctx.strokeStyle=i%3?'rgba(98,47,17,.12)':'rgba(255,255,255,.25)';ctx.lineWidth=1+i%2;ctx.beginPath();ctx.moveTo(0,i*4);ctx.bezierCurveTo(80,i*4+5,160,i*4-4,256,i*4+2);ctx.stroke();}
  const texture=new THREE.CanvasTexture(canvas);texture.colorSpace=THREE.SRGBColorSpace;return texture;
}
export function createWaterfall(scene){
  const group=new THREE.Group();group.position.set(0,0,-90);group.scale.setScalar(1.05);scene.add(group);
  const rockMaterial=new THREE.MeshStandardMaterial({color:'#668977',roughness:1});
  const rockGeometry=new THREE.IcosahedronGeometry(1,1);
  for(let i=0;i<12;i++){const rock=new THREE.Mesh(rockGeometry,rockMaterial);rock.position.set((i%2?1:-1)*(3+i%3),i%4*2.1,0);rock.scale.set(2.4,2.5,2);group.add(rock);}
  // A continuous cliff, a visible river on its shelf, then the drop and pool.
  const cliff=new THREE.Mesh(rockGeometry,rockMaterial);cliff.scale.set(5.5,6,1.8);cliff.position.set(0,4.5,-1.1);group.add(cliff);
  const shelf=new THREE.Mesh(rockGeometry,rockMaterial);shelf.scale.set(5,.4,2.5);shelf.position.set(0,9.6,-1.4);group.add(shelf);
  for(let i=0;i<10;i++){
    const bank=new THREE.Mesh(rockGeometry,leaves[i%3]);bank.scale.set(.9,.45,.7);bank.position.set((i%2?1:-1)*(1.8+Math.floor(i/2)*.65),10,-.5-(i%3)*.6);group.add(bank);
  }
  const waterMaterial=createFlowMaterial(true),surfaceMaterial=createFlowMaterial();
  const water=new THREE.Mesh(new THREE.PlaneGeometry(3,10),waterMaterial);water.position.set(0,5,1.15);group.add(water);
  const river=new THREE.Mesh(new THREE.PlaneGeometry(3,5),surfaceMaterial);river.rotation.x=-Math.PI/2;river.position.set(0,10.1,-1.3);group.add(river);
  const pool=new THREE.Mesh(new THREE.CircleGeometry(5,24),surfaceMaterial);pool.rotation.x=-Math.PI/2;pool.position.set(0,-.06,3);group.add(pool);
  const kingdom=createKingdom(group);kingdom.position.set(8,23,-17);kingdom.scale.setScalar(1.2);
  const kingdomPeak=new THREE.Mesh(rockGeometry,rockMaterial);kingdomPeak.position.set(8,11,-19);kingdomPeak.scale.set(6,12,6);group.add(kingdomPeak);
  const kingdomGarden=new THREE.Mesh(rockGeometry,leaves[1]);kingdomGarden.position.set(8,22.8,-17);kingdomGarden.scale.set(6,.35,4);group.add(kingdomGarden);
  // Water descends through two higher terraces before the foreground fall.
  for(let level=1;level<=2;level++){
    const z=-level*12,y=level*10;
    const terrace=new THREE.Mesh(rockGeometry,rockMaterial);terrace.position.set(0,y+4.5,z-2);terrace.scale.set(7,6,4);group.add(terrace);
    const fall=new THREE.Mesh(new THREE.PlaneGeometry(3.7,10),waterMaterial);fall.position.set(0,y+5,z+2.1);group.add(fall);
    const stream=new THREE.Mesh(new THREE.PlaneGeometry(3.7,12),surfaceMaterial);stream.rotation.x=-Math.PI/2;stream.position.set(0,y+.02,z+8);group.add(stream);
    const top=new THREE.Mesh(rockGeometry,leaves[level]);top.position.set(0,y+10,z-1);top.scale.set(6,.4,3.5);group.add(top);
    // A small distant crossing gives the canyon a readable sense of scale.
    const crossing=new THREE.Mesh(new THREE.BoxGeometry(10,.18,.65),trunkMaterial);crossing.position.set(0,y+.3,z+5);group.add(crossing);
    for(let i=0;i<7;i++){const post=new THREE.Mesh(new THREE.CylinderGeometry(.055,.065,.65,5),trunkMaterial);post.position.set(-4.5+i*1.5,y+.6,z+5);group.add(post);}
  }
  const foamMaterial=new THREE.MeshBasicMaterial({color:'#e9ffef',transparent:true,opacity:.75,depthWrite:false});
  const foamGeometry=new THREE.TorusGeometry(1,.06,5,24),ripples=[];
  for(let i=0;i<3;i++){const ring=new THREE.Mesh(foamGeometry,foamMaterial);ring.rotation.x=-Math.PI/2;ring.position.set(0,.06,2);group.add(ring);ripples.push(ring);}
  let elapsed=0;
  return {update(dt){elapsed+=dt;waterMaterial.uniforms.time.value+=dt;surfaceMaterial.uniforms.time.value+=dt;ripples.forEach((ring,i)=>ring.scale.setScalar(.5+((elapsed*.45+i/3)%1)*2));}};
}

// A bounded reusable pool: no new geometries/materials on each pickup.
export function createRunnerEffects(scene){
  const material=new THREE.MeshBasicMaterial({color:'#ffe578',transparent:true,depthWrite:false});
  const geometry=new THREE.SphereGeometry(.055,6,4),pool=[];
  for(let i=0;i<32;i++){const mesh=new THREE.Mesh(geometry,material);mesh.visible=false;scene.add(mesh);pool.push({mesh,life:0,v:new THREE.Vector3()});}
  let cursor=0;
  return {burst(x,y,z,landing=false){
    for(let i=0;i<8;i++){const p=pool[cursor++%pool.length],angle=i*Math.PI/4;p.life=.55;p.mesh.visible=true;p.mesh.position.set(x,y,z);p.v.set(Math.cos(angle)*(landing?.7:.4),landing?.35:.8+Math.sin(i)*.25,Math.sin(angle)*.5);}
  },update(dt){for(const p of pool){if(p.life<=0)continue;p.life-=dt;p.mesh.visible=p.life>0;p.mesh.position.addScaledVector(p.v,dt);p.v.y-=dt*.7;p.mesh.scale.setScalar(Math.max(.1,p.life/.55));}},reset(){for(const p of pool){p.life=0;p.mesh.visible=false;}}};
}

export function createButterflies(scene){
  const flock=new THREE.Group();scene.add(flock);const geometry=new THREE.SphereGeometry(.11,6,4),butterflies=[];
  for(let i=0;i<8;i++){
    const body=new THREE.Group();const wings=[];
    for(const side of [-1,1]){const wing=new THREE.Mesh(geometry,bloomMaterials[i%3]);wing.position.x=side*.09;wing.scale.set(1,.12,1.5);body.add(wing);wings.push(wing);}
    flock.add(body);butterflies.push({body,wings});
  }
  let time=0;return {update(dt){time+=dt;butterflies.forEach(({body,wings},i)=>{body.position.set((i%2?1:-1)*(3.4+Math.sin(time*.7+i)*.4),.9+Math.sin(time+i)*.25,3-i*7+Math.cos(time*.6+i));wings.forEach((wing,j)=>wing.rotation.z=Math.sin(time*16+i)*(j?1:-1)*.7);});}};
}
