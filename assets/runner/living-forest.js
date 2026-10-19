import * as THREE from 'three';
import {mergeGeometries} from 'three/addons/utils/BufferGeometryUtils.js';
import {seasonAt} from './seasons.js';
import {createSeasonalBotany,createRoundedCanopyGeometry} from './seasonal-botany.js';
import {createForestRockGeometry,createForestTrunkGeometry} from './forest-shapes.js';

// One world-space scene: scenery and bridge use the same perspective and light.
export function createLivingForest(scene) {
  scene.background=new THREE.Color('#7bceef');
  scene.fog=new THREE.Fog('#b8e3d9',40,145);
  const moving=new THREE.Group(),horizon=new THREE.Group();scene.add(moving,horizon);
  const sky=new THREE.Mesh(new THREE.SphereGeometry(240,16,8),new THREE.ShaderMaterial({side:THREE.BackSide,depthWrite:false,
    uniforms:{top:{value:new THREE.Color('#56b9ed')},bottom:{value:new THREE.Color('#d7e8d0')}},
    vertexShader:'varying vec3 v;void main(){v=position;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.);}',
    fragmentShader:'varying vec3 v;uniform vec3 top,bottom;void main(){vec3 d=normalize(v);vec3 c=mix(bottom,top,smoothstep(0.,.7,d.y));float sun=pow(max(0.,dot(d,normalize(vec3(-.4,.6,-1.)))),90.);gl_FragColor=vec4(c+sun*vec3(.7,.5,.2),1.);\n#include <colorspace_fragment>\n}'}));scene.add(sky);
  const dummy=new THREE.Object3D(),palette=['#3f8545','#59983b','#75af45','#286749'];
  const material=color=>new THREE.MeshLambertMaterial({color,flatShading:true});
  const batches=[],trees=[];
  function batch(geometry,mat,count){const mesh=new THREE.InstancedMesh(geometry,mat,count);mesh.frustumCulled=false;moving.add(mesh);batches.push({mesh,items:[]});return batches.at(-1);}
  function put(batch,x,y,z,sx,sy,sz,color){batch.items.push({x,y,z,sx,sy,sz,phase:z*.41+x});if(color)batch.mesh.setColorAt(batch.items.length-1,new THREE.Color(color));}
  const trunks=batch(createForestTrunkGeometry(),new THREE.MeshLambertMaterial({color:'#966b46',vertexColors:true}),48);
  const leafMaterial=new THREE.MeshLambertMaterial({color:'#ffffff',vertexColors:true});
  const leaves=batch(createRoundedCanopyGeometry(),leafMaterial,144);
  const rocks=batch(createForestRockGeometry(),new THREE.MeshLambertMaterial({color:'#9caeaa',vertexColors:true}),96);
  const fernVertices=[];for(let leaf=0;leaf<7;leaf++){const a=leaf*Math.PI*2/7,dx=Math.cos(a),dz=Math.sin(a);fernVertices.push(0,0,0,dx*.25-dz*.13,.22,dz*.25+dx*.13,dx*.7,.65,dz*.7,0,0,0,dx*.7,.65,dz*.7,dx*.25+dz*.13,.22,dz*.25-dx*.13);}
  const fernGeometry=new THREE.BufferGeometry();fernGeometry.setAttribute('position',new THREE.Float32BufferAttribute(fernVertices,3));fernGeometry.computeVertexNormals();
  const grass=batch(fernGeometry,new THREE.MeshLambertMaterial({color:'#7ca845',side:THREE.DoubleSide}),96);
  for(let row=0;row<24;row++)for(const side of [-1,1]){
    const z=10-row*6+Math.sin(row*1.7+side)*.9,x=side*(5.4+(row%4)*1.1+Math.sin(row*2+side)*.65),height=5.8+(row%5)*.9;
    trees.push({x,z,height,side,row});
    put(trunks,x,height/2-.8,z,1,height,1);
    for(let crown=0;crown<3;crown++)put(leaves,x+side*crown*.55,height*.6+crown*.8,z,2.7-crown*.35,2.1,2.4,palette[(row+crown)%4]);
    put(rocks,side*(4.3+row%3),-.5,z-1,1.1+row%2*.6,.8,1.6);
    put(rocks,side*(11+row%4),1,z,3,3+row%3,3);
    for(let j=0;j<2;j++)put(grass,side*(3.2+j*.9),-.2,z-j*1.3,.8,1.1+j*.3,.8);
  }
  const botany=createSeasonalBotany(scene,trees);
  // Both banks continue beneath the bridge; the river is recessed, not a void.
  const bankMaterial=material('#78914e');
  for(const side of [-1,1]){
    const bank=new THREE.Mesh(new THREE.BoxGeometry(28,2,180),bankMaterial);bank.position.set(side*21,-1.8,-65);scene.add(bank);
    const nearBank=new THREE.Mesh(new THREE.BoxGeometry(8.2,2,180),bankMaterial);nearBank.position.set(side*7,-1.3,-65);scene.add(nearBank);
  }
  const waterMaterial=new THREE.ShaderMaterial({transparent:true,uniforms:{time:{value:0},ice:{value:0}},
    vertexShader:'varying vec2 v; uniform float time; void main(){v=uv; vec3 p=position; p.z+=sin(p.x*1.5+time*2.0)*.04; gl_Position=projectionMatrix*modelViewMatrix*vec4(p,1.);}',
    fragmentShader:'varying vec2 v;uniform float time,ice;void main(){float ripple=pow(.5+.5*sin(v.y*180.+time*4.+sin(v.x*32.)*2.),15.); vec3 c=mix(vec3(.06,.48,.49),vec3(.21,.76,.72),v.x);c=mix(c,vec3(.63,.83,.9),ice*.9);gl_FragColor=vec4(c+ripple*.17,.96); #include <colorspace_fragment> }'.replace(' #include','\n#include')});
  const river=new THREE.Mesh(new THREE.PlaneGeometry(19,220,12,32),waterMaterial);river.rotation.x=-Math.PI/2;river.position.set(0,-1.15,-82);scene.add(river);
  const foamMaterial=new THREE.MeshBasicMaterial({color:'#d9fff0',transparent:true,opacity:.65,depthWrite:false});
  const foam=new THREE.InstancedMesh(new THREE.PlaneGeometry(.65,.09),foamMaterial,60);foam.frustumCulled=false;scene.add(foam);
  // The waterfall starts at a physical ledge beneath the distant kingdom.
  for(const side of [-1,1]){const cliff=new THREE.Mesh(new THREE.IcosahedronGeometry(1,1),material('#87948a'));cliff.scale.set(15,22,19);cliff.position.set(side*17,12,-125);horizon.add(cliff);}
  const ledge=new THREE.Mesh(new THREE.CylinderGeometry(19,18,2,12),material('#6b9f54'));ledge.position.set(0,32,-125);horizon.add(ledge);
  const fallMaterial=new THREE.ShaderMaterial({side:THREE.DoubleSide,uniforms:{time:{value:0}},
    vertexShader:'varying vec2 v;void main(){v=uv;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.);}',
    fragmentShader:'varying vec2 v;uniform float time;void main(){float strands=pow(.5+.5*sin(v.x*52.+sin(v.y*8.-time*2.)*.5),5.);float drift=.5+.5*sin(v.y*45.+time*7.);gl_FragColor=vec4(mix(vec3(.12,.61,.75),vec3(.83,1.,1.),strands*.42+drift*.1+pow(abs(v.x-.5)*2.,3.)*.2),1.);\n#include <colorspace_fragment>\n}'});
  const fall=new THREE.Mesh(new THREE.PlaneGeometry(7,33),fallMaterial);fall.position.set(0,15.5,-104.2);horizon.add(fall);
  const mist=new THREE.Mesh(new THREE.SphereGeometry(1,10,6),new THREE.MeshBasicMaterial({color:'#d8f7f1',transparent:true,opacity:.38,depthWrite:false}));mist.scale.set(8,2,3);mist.position.set(0,-.2,-104);horizon.add(mist);
  const walls=material('#ece1bc'),roof=material('#797ab8');
  for(let i=0;i<7;i++){
    const x=(i-3)*4,y=35+(i%3)*2,z=-125-(i%2)*3;
    const tower=new THREE.Mesh(new THREE.CylinderGeometry(1.5,1.8,8+i%3,8),walls);tower.position.set(x,y,z);horizon.add(tower);
    const cap=new THREE.Mesh(new THREE.ConeGeometry(2,4,8),roof);cap.position.set(x,y+6,z);horizon.add(cap);
    for(let opening=0;opening<3;opening++){const window=new THREE.Mesh(new THREE.PlaneGeometry(.42,.75),material('#b78842'));window.position.set(x,y-2+opening*1.8,z+1.57);horizon.add(window);}
    const flag=new THREE.Mesh(new THREE.PlaneGeometry(1.2,.6),material('#e996b8'));flag.position.set(x+.6,y+8,z);horizon.add(flag);
  }
  const keep=new THREE.Mesh(new THREE.BoxGeometry(17,6,9),walls);keep.position.set(0,34,-127);horizon.add(keep);
  const cloudMaterial=new THREE.MeshLambertMaterial({color:'#fff4e5'});for(let cloud=0;cloud<5;cloud++)for(let puff=0;puff<3;puff++){const mesh=new THREE.Mesh(new THREE.SphereGeometry(1,10,6),cloudMaterial);mesh.scale.set(6+puff,2.3,3);mesh.position.set(-75+cloud*35+puff*4,38+(cloud%3)*10,-170);horizon.add(mesh);}
  // Distant banks frame the waterfall, without closing the endless track.
  for(const side of [-1,1])for(let i=0;i<4;i++){const ridge=new THREE.Mesh(new THREE.IcosahedronGeometry(1,0),material(i%2?'#79ab89':'#72a594'));ridge.scale.set(15,18+i*4,19);ridge.position.set(side*(23+i*11),8+i*3,-101-i*14);horizon.add(ridge);}
  const staticGeometry=[];
  for(const mesh of [...horizon.children]){
    if(!mesh.material.isMeshLambertMaterial)continue;
    mesh.updateMatrix();const geometry=mesh.geometry.index?mesh.geometry.toNonIndexed():mesh.geometry.clone();geometry.applyMatrix4(mesh.matrix);geometry.deleteAttribute('uv');
    const colors=new Float32Array(geometry.attributes.position.count*3);for(let i=0;i<colors.length;i+=3){const shade=mesh.geometry.type==='IcosahedronGeometry'?.86+.18*Math.sin(Math.floor(i/9)*7):1;mesh.material.color.clone().multiplyScalar(shade).toArray(colors,i);}
    geometry.setAttribute('color',new THREE.BufferAttribute(colors,3));staticGeometry.push(geometry);horizon.remove(mesh);mesh.geometry.dispose();mesh.material.dispose();
  }
  const merged=mergeGeometries(staticGeometry);if(merged)horizon.add(new THREE.Mesh(merged,new THREE.MeshLambertMaterial({vertexColors:true,side:THREE.DoubleSide,fog:false})));
  for(const geometry of staticGeometry)geometry.dispose();
  const driftGeometry=new THREE.BufferGeometry(),driftPositions=new Float32Array(120*3);driftGeometry.setAttribute('position',new THREE.BufferAttribute(driftPositions,3));
  const driftMaterial=new THREE.PointsMaterial({color:'#f6bad0',size:.075,transparent:true,opacity:.75,depthWrite:false});const drift=new THREE.Points(driftGeometry,driftMaterial);drift.frustumCulled=false;scene.add(drift);
  const snow=new THREE.InstancedMesh(new THREE.SphereGeometry(1,8,5),new THREE.MeshLambertMaterial({color:'#edf5f4'}),48);scene.add(snow);snow.frustumCulled=false;
  const from=new THREE.Color(),to=new THREE.Color(),mixed=new THREE.Color();
  const blend=(a,b,t)=>mixed.copy(from.set(a)).lerp(to.set(b),t);
  let time=0;
  return {load:async()=>{},setPaused(){},update(dt,_aspect,_lean,distance=0,seasonDistance=distance){
    time+=dt;waterMaterial.uniforms.time.value=fallMaterial.uniforms.time.value=time;
    const season=seasonAt(seasonDistance),t=season.blend,prev=season.previous;
    sky.material.uniforms.top.value.copy(blend(prev.sky,season.sky,t));sky.material.uniforms.bottom.value.copy(blend(prev.horizon,season.horizon,t));scene.fog.color.copy(blend(prev.fog,season.fog,t));
    grass.mesh.material.color.copy(blend(prev.grass,season.grass,t));
    bankMaterial.color.copy(blend(prev.grass,season.grass,t));
    for(let i=0;i<leaves.items.length;i++)leaves.mesh.setColorAt(i,blend(prev.leaves[i%4],season.leaves[i%4],t));leaves.mesh.instanceColor.needsUpdate=true;
    botany.update(season,distance,time);
    const snowy=prev.snow+(season.snow-prev.snow)*t;waterMaterial.uniforms.ice.value=snowy;snow.visible=snowy>.02;
    if(snow.visible)for(let i=0;i<48;i++){dummy.position.set((i%2?1:-1)*(2.7+i%3*.7),.04,((i*3.17+distance+140)%144)-140);dummy.scale.set(.4,.12*snowy,.65);dummy.rotation.set(0,i,0);dummy.updateMatrix();snow.setMatrixAt(i,dummy.matrix);}snow.instanceMatrix.needsUpdate=true;
    drift.visible=season.index!==1&&season.index!==4;driftMaterial.color.set(season.index===3?'#fff4ff':season.index===2?'#efb463':'#f9bdd3');
    if(drift.visible){for(let i=0;i<120;i++){driftPositions[i*3]=Math.sin(i*1.9+time*.4)*6;driftPositions[i*3+1]=5-((time*(season.index===3?.5:.24)+i*.317)%5);driftPositions[i*3+2]=-((i*1.9+distance*.2)%45);}driftGeometry.attributes.position.needsUpdate=true;}
    for(const batch of batches){for(let i=0;i<batch.items.length;i++){const p=batch.items[i];const z=((p.z+distance+140)%144+144)%144-140;
      dummy.position.set(p.x,p.y,z);dummy.scale.set(p.sx,p.sy,p.sz);dummy.rotation.set(0,p.phase, batch===leaves?Math.sin(time*.8+p.phase)*.025:0);dummy.updateMatrix();batch.mesh.setMatrixAt(i,dummy.matrix);}batch.mesh.instanceMatrix.needsUpdate=true;}
    for(let i=0;i<60;i++){dummy.position.set((i%2?1:-1)*(3.5+i%7*.7),-1.1,((i*3+time*2)%160)-150);dummy.rotation.set(-Math.PI/2,0,0);dummy.scale.set(1+i%3*.2,1,1);dummy.updateMatrix();foam.setMatrixAt(i,dummy.matrix);}foam.instanceMatrix.needsUpdate=true;
  },dispose(){botany.dispose();}};
}
