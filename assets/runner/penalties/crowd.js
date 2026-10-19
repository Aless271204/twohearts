import * as T from 'three';
// Two atlases, two instanced draws: recognizable pets replace anonymous crowd dots.
export async function createPetCrowd(scene){
 const loader=new T.TextureLoader(),textures=await Promise.all(['crowd-base','crowd-diverse'].map(n=>loader.loadAsync(`art/${n}.webp`)));
 const meshes=[];
 for(let atlas=0;atlas<2;atlas++){
  const texture=textures[atlas];texture.colorSpace=T.SRGBColorSpace;
  const geometry=new T.PlaneGeometry(.84,.86),cells=new Float32Array(360),phase=new Float32Array(360);
  for(let i=0;i<360;i++){cells[i]=atlas?i%12:i%4;phase[i]=i*2.37;}
  geometry.setAttribute('cell',new T.InstancedBufferAttribute(cells,1));geometry.setAttribute('phase',new T.InstancedBufferAttribute(phase,1));
  const mat=new T.ShaderMaterial({transparent:false,side:T.DoubleSide,uniforms:{map:{value:texture},time:{value:0},reaction:{value:0},base:{value:atlas===0?1:0}},
   vertexShader:'attribute float cell,phase;uniform float time,reaction,base;varying vec2 vUv;void main(){float index=cell+(base>0.5?floor(reaction)*4.:0.);vUv=vec2((uv.x+mod(index,4.))/4.,(uv.y+2.-floor(index/4.))/3.);vec3 p=position;p.y+=sin(time*(reaction>0.5?7.:2.)+phase)*(reaction>0.5?.09:.018);vec4 world=instanceMatrix*vec4(p,1.);gl_Position=projectionMatrix*modelViewMatrix*world;}',
   fragmentShader:'uniform sampler2D map;varying vec2 vUv;void main(){vec4 c=texture2D(map,vUv);if(c.a<.65)discard;gl_FragColor=vec4(c.rgb,1.);\n#include <colorspace_fragment>\n}'});
  const mesh=new T.InstancedMesh(geometry,mat,360),m=new T.Matrix4();let index=0;
  for(const end of [-1,1])for(let row=0;row<5;row++)for(let i=0;i<36;i++){m.makeRotationY(end===1?Math.PI:0);m.setPosition(-25+(i*2+atlas)*.7,.95+row*.9,end===-1?-9-row*2:34+row*2);mesh.setMatrixAt(index++,m);}mesh.frustumCulled=false;scene.add(mesh);meshes.push(mesh);
 }
 let until=0,starts=0,reaction=0;
 return {react(kind,time){reaction=kind==='goal'?1:2;starts=time;until=time+2.8;},update(time){for(const mesh of meshes){mesh.material.uniforms.time.value=time;mesh.material.uniforms.reaction.value=time>=starts&&time<until?reaction:0;}},dispose(){for(const mesh of meshes){scene.remove(mesh);mesh.geometry.dispose();mesh.material.dispose();}textures.forEach(t=>t.dispose());}};
}
