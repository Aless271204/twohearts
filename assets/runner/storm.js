import * as THREE from 'three';
export function stormIntensity(distance){return Math.max(0,Math.min(1,(distance-1500)/500));}
// One draw call, fixed buffers, no per-frame allocations or post-processing.
export function createStorm(scene){
 const count=160,positions=new Float32Array(count*6),geometry=new THREE.BufferGeometry();geometry.setAttribute('position',new THREE.BufferAttribute(positions,3));
 const material=new THREE.LineBasicMaterial({color:'#c3d7e9',transparent:true,opacity:0,depthWrite:false});
 const rain=new THREE.LineSegments(geometry,material);rain.frustumCulled=false;rain.visible=false;scene.add(rain);
 const boltGeometry=new THREE.BufferGeometry().setFromPoints([
  new THREE.Vector3(-3,7,-24),new THREE.Vector3(-3.7,5.6,-24),
  new THREE.Vector3(-3.1,5.7,-24),new THREE.Vector3(-4,3.8,-24),
 ]);
 const boltMaterial=new THREE.LineBasicMaterial({color:'#e6eaff',transparent:true,opacity:0,depthWrite:false});
 const bolt=new THREE.Line(boltGeometry,boltMaterial);bolt.visible=false;scene.add(bolt);
 const reduced=matchMedia('(prefers-reduced-motion: reduce)').matches;let time=0;
 const overlay=document.createElement('div');overlay.style.cssText='position:fixed;inset:0;pointer-events:none;background:#102030;opacity:0;z-index:0';document.body.insertBefore(overlay,document.getElementById('hud'));
 return {update(dt,distance,x){
  const intensity=stormIntensity(distance);rain.visible=intensity>0;material.opacity=intensity*.52;time+=dt;
  overlay.style.opacity=String(intensity*.42);
  if(!intensity)return;
  for(let i=0;i<count;i++){const n=i*6,xx=((i*7.317)%13)-6.5+x,zz=-((i*4.719)%32),y=5-((time*(reduced?1.4:8)+i*.391)%6);
   positions[n]=xx;positions[n+1]=y;positions[n+2]=zz;positions[n+3]=xx-.07;positions[n+4]=y+.32;positions[n+5]=zz-.04;
  }
  geometry.attributes.position.needsUpdate=true;
  // A single soft lightning glow, never rapid strobing.
  const pulse=distance>=2000&&!reduced?Math.max(0,1-Math.abs(time%8-.3)/.3):0;
  bolt.visible=pulse>0;boltMaterial.opacity=pulse*.65;bolt.position.x=x;
  material.color.set(pulse>.1?'#eef4ff':'#c3d7e9');
  overlay.style.background=pulse>.1?'#6b7f9b':'#102030';
 },dispose(){scene.remove(rain,bolt);geometry.dispose();material.dispose();boltGeometry.dispose();boltMaterial.dispose();overlay.remove();}};
}
