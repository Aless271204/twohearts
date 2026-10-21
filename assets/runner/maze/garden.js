import * as T from 'three';
import {districtAt} from './navigation.js';
const cream='#ffeac5',gold='#dba467',mint='#9bd6ac';
const material=(color,emissive=0)=>new T.MeshStandardMaterial({color,roughness:.84,emissive:color,emissiveIntensity:emissive});
function mesh(g,m,parent,x=0,y=0,z=0){const o=new T.Mesh(g,m);o.position.set(x,y,z);parent.add(o);return o;}
export function symbolTexture(pattern){
 const canvas=document.createElement('canvas');canvas.width=384;canvas.height=128;
 const c=canvas.getContext('2d');c.fillStyle='#fff0cb';c.font='bold 78px serif';c.textAlign='center';c.textBaseline='middle';
 (pattern??[null,null,null]).forEach((v,i,a)=>c.fillText(v==null?'?':['★','☾','❧'][v],(i+.5)*384/a.length,64));
 const texture=new T.CanvasTexture(canvas);texture.colorSpace=T.SRGBColorSpace;return texture;
}
export function createLanternStation(c){
 const group=new T.Group(),stone=material('#8e758d'),rim=material(gold),glow=material('#ffe6a2',.08);
 mesh(new T.CylinderGeometry(.4,.46,.16,12),stone,group,0,.08);
 mesh(new T.CylinderGeometry(.33,.43,.72,12),stone,group,0,.48);
 mesh(new T.CylinderGeometry(.48,.4,.13,12),rim,group,0,.89);
 const lantern=new T.Group();group.add(lantern);lantern.position.y=.96;
 mesh(new T.CylinderGeometry(.24,.27,.09,8),rim,lantern,0,.02);
 const glass=mesh(new T.CylinderGeometry(.2,.2,.43,8),glow,lantern,0,.27);
 for(let i=0;i<4;i++){const a=i*Math.PI/2;mesh(new T.CylinderGeometry(.018,.018,.45,5),rim,lantern,Math.cos(a)*.21,.27,Math.sin(a)*.21);}
 mesh(new T.ConeGeometry(.32,.22,8),rim,lantern,0,.59);
 const ring=mesh(new T.TorusGeometry(.09,.018,5,12),rim,lantern,0,.79);ring.rotation.y=.15;
 const flame=mesh(new T.SphereGeometry(.075,8,6),material('#fff5cc',1),lantern,0,.29);flame.scale.y=1.8;
 // The engraved clue faces the approaching player, not a fixed world direction.
 const tablet=new T.Group();tablet.position.set(0,1.96,0);group.add(tablet);
 mesh(new T.BoxGeometry(.98,.43,.1),stone,tablet,0,0,-.07);
 const face=mesh(new T.PlaneGeometry(.94,.32),new T.MeshBasicMaterial({map:symbolTexture(null),transparent:true,depthWrite:false,side:T.DoubleSide}),tablet);
 const leaf=mesh(new T.SphereGeometry(.08,8,5),material(mint,.2),group,0,1.68);leaf.scale.set(.6,1.2,.25);leaf.rotation.z=-.4;
 return {group,lantern,glass,flame,tablet,face,leaf,signature:''};
}
export function updateLanternStation(item,c,yaw,time){
 const lit=!!c.opened;item.glass.material.emissiveIntensity=lit?1.2:.04;item.glass.material.color.set(lit?'#ffe3a0':'#766b85');item.flame.visible=lit;
 item.flame.scale.y=1.6+Math.sin(time*5+c.id)*.18;item.tablet.rotation.y=yaw;item.leaf.rotation.y=yaw;
 const signature=JSON.stringify(c.pattern??null);if(item.signature!==signature){item.face.material.map.dispose();item.face.material.map=symbolTexture(c.pattern);item.signature=signature;}
}
export function createBridge(b){
 const group=new T.Group(),water=material('#336b83',.15),wood=material('#b88866'),brass=material(gold),plateMat=material('#8b9e72');
 group.position.set(b.x*2,0,b.z*2);
 const stream=mesh(new T.BoxGeometry(1.95,.12,1.95),water,group,0,-.035);
 const deck=new T.Group();group.add(deck);
 const alongX=b.plate.x!==b.x;deck.rotation.y=alongX?Math.PI/2:0;
 for(let i=0;i<7;i++)mesh(new T.BoxGeometry(1.4,.12,.25),wood,deck,0,.05,(i-3)*.27);
 for(const x of [-.78,.78]){mesh(new T.CylinderGeometry(.04,.04,1.8,6),wood,deck,x,.42).rotation.x=Math.PI/2;for(const z of [-.8,.8]){mesh(new T.CylinderGeometry(.045,.045,.65,6),brass,deck,x,.32,z);}}
 const plate=mesh(new T.CylinderGeometry(.44,.49,.08,16),plateMat,group,(b.plate.x-b.x)*2,.04,(b.plate.z-b.z)*2);
 const leaf=mesh(new T.SphereGeometry(.17,10,6),material('#e6d6a3',.3),plate);leaf.scale.set(.65,.15,1.2);leaf.position.y=.06;
 return {group,deck,plate,stream};
}
export function addGarden(world,s){
 const walls=[];for(let i=0;i<s.grid.length;i++)if(s.grid[i])walls.push(i);
 const hedge=new T.InstancedMesh(new T.SphereGeometry(1,10,7),material('#ffffff'),walls.length*2),o=new T.Object3D();
 const colors=['#618571','#70988e','#9385a4'];walls.forEach((cell,i)=>{const x=cell%s.size,z=Math.floor(cell/s.size),zone=districtAt(s,x,z);for(let k=0;k<2;k++){o.position.set(x*2+(k?-.3:.3),1.3+(cell%3)*.035,z*2);o.scale.set(.98,.78,1);o.rotation.set(0,cell*.43,0);o.updateMatrix();hedge.setMatrixAt(i*2+k,o.matrix);hedge.setColorAt(i*2+k,new T.Color(colors[zone]));}});world.add(hedge);
 // Leaf detail follows only faces exposed to a path; one shared geometry/draw.
 const faces=[];for(const cell of walls){const x=cell%s.size,z=Math.floor(cell/s.size);for(const [dx,dz]of[[1,0],[-1,0],[0,1],[0,-1]]){const nx=x+dx,nz=z+dz;if(nx>=0&&nz>=0&&nx<s.size&&nz<s.size&&!s.grid[nz*s.size+nx])faces.push({x,z,dx,dz});}}
 const leafShape=new T.Shape();leafShape.moveTo(0,-.1);leafShape.quadraticCurveTo(-.09,-.01,0,.11);leafShape.quadraticCurveTo(.09,.01,0,-.1);
 const leafMaterial=material('#ffffff');leafMaterial.side=T.DoubleSide;
 const hedgeLeaves=new T.InstancedMesh(new T.ShapeGeometry(leafShape,3),leafMaterial,faces.length*12);
 const seams=new T.InstancedMesh(new T.BoxGeometry(1.98,.014,.02),material('#93829b'),faces.length*2);
 const joints=new T.InstancedMesh(new T.BoxGeometry(.014,.19,.02),material('#93829b'),faces.length*4);
 const leafColors=['#729774','#a0b67c','#598b72','#90ad95'];
 faces.forEach((f,i)=>{const yaw=Math.atan2(f.dx,f.dz);for(let k=0;k<12;k++){const row=Math.floor(k/4),u=(k%4-1.5)*.44+Math.sin(i*5+k)*.06;
  o.position.set(f.x*2+f.dx*1.015+f.dz*u,.85+row*.36+Math.sin(i+k)*.06,f.z*2+f.dz*1.015-f.dx*u);o.rotation.set(0,yaw,Math.sin(k*3+i)*.65);o.scale.setScalar(.85+(k%3)*.25);o.updateMatrix();hedgeLeaves.setMatrixAt(i*12+k,o.matrix);hedgeLeaves.setColorAt(i*12+k,new T.Color(leafColors[(i+k)%leafColors.length]));}
  for(let k=0;k<2;k++){o.position.set(f.x*2+f.dx*1.015,.19+k*.23,f.z*2+f.dz*1.015);o.rotation.set(0,yaw,0);o.scale.setScalar(1);o.updateMatrix();seams.setMatrixAt(i*2+k,o.matrix);}
  for(let k=0;k<4;k++){const u=(k%2-.5)*.84+(k>1?.21:0);o.position.set(f.x*2+f.dx*1.025+f.dz*u,.09+Math.floor(k/2)*.23,f.z*2+f.dz*1.025-f.dx*u);o.rotation.set(0,yaw,0);o.updateMatrix();joints.setMatrixAt(i*4+k,o.matrix);}
 });world.add(hedgeLeaves,seams,joints);
 // Shared instances keep the garden inexpensive: no light or shadow per firefly.
 const cells=[];for(let i=0;i<s.grid.length;i++)if(!s.grid[i]&&i%3===0)cells.push(i);
 const leaves=new T.InstancedMesh(new T.SphereGeometry(1,5,3),material('#d8aa67'),cells.length*3),flies=new T.InstancedMesh(new T.SphereGeometry(.025,5,4),new T.MeshBasicMaterial({color:'#ffdf8f'}),Math.min(90,cells.length));
 cells.forEach((cell,i)=>{const x=cell%s.size*2,z=Math.floor(cell/s.size)*2;for(let k=0;k<3;k++){o.position.set(x+Math.sin(cell+k)*.8,.012,z+Math.cos(cell*2+k)*.8);o.scale.set(.055,.008,.12);o.rotation.set(0,cell+k,0);o.updateMatrix();leaves.setMatrixAt(i*3+k,o.matrix);}});world.add(leaves,flies);
 // Warm path lamps use shared emissive meshes rather than individual lights.
 const lampCells=cells.filter((cell,i)=>i%4===0).slice(0,20);
 const posts=new T.InstancedMesh(new T.CylinderGeometry(.025,.035,.75,6),material(gold),lampCells.length);
 const lamps=new T.InstancedMesh(new T.CylinderGeometry(.11,.11,.23,6),material('#ffda93',1.1),lampCells.length);
 const roofs=new T.InstancedMesh(new T.ConeGeometry(.17,.14,6),material('#bf975f'),lampCells.length);
 lampCells.forEach((cell,i)=>{const x=cell%s.size,z=Math.floor(cell/s.size);let dx=0,dz=0;for(const [a,b]of [[1,0],[-1,0],[0,1],[0,-1]])if(s.grid[(z+b)*s.size+x+a]){dx=a*.77;dz=b*.77;break;}
  o.scale.setScalar(1);o.rotation.set(0,0,0);o.position.set(x*2+dx,.4,z*2+dz);o.updateMatrix();posts.setMatrixAt(i,o.matrix);
  o.position.y=.89;o.updateMatrix();lamps.setMatrixAt(i,o.matrix);o.position.y=1.065;o.updateMatrix();roofs.setMatrixAt(i,o.matrix);
 });world.add(posts,lamps,roofs);
 // Small flowering plants along path edges; petals are instanced, not textures.
 const plants=lampCells.slice(0,12),stalks=new T.InstancedMesh(new T.CylinderGeometry(.012,.016,.25,5),material('#8a9c64'),plants.length),petals=new T.InstancedMesh(new T.SphereGeometry(1,6,4),material('#e8b8bd'),plants.length*5),centers=new T.InstancedMesh(new T.SphereGeometry(.045,7,5),material('#ffe3a1'),plants.length);
 plants.forEach((cell,i)=>{const x=cell%s.size,z=Math.floor(cell/s.size),edge=[[1,0],[-1,0],[0,1],[0,-1]].find(([dx,dz])=>s.grid[(z+dz)*s.size+x+dx])??[1,0],px=x*2+edge[0]*.7,pz=z*2+edge[1]*.7;
  o.rotation.set(0,0,0);o.scale.setScalar(1);o.position.set(px,.12,pz);o.updateMatrix();stalks.setMatrixAt(i,o.matrix);
  for(let k=0;k<5;k++){const a=k*Math.PI*2/5;o.position.set(px+Math.cos(a)*.07,.27+Math.sin(a)*.07,pz);o.scale.set(.06,.065,.025);o.updateMatrix();petals.setMatrixAt(i*5+k,o.matrix);}o.position.set(px,.27,pz+.025);o.scale.setScalar(1);o.updateMatrix();centers.setMatrixAt(i,o.matrix);
 });world.add(stalks,petals,centers);
 const moon=mesh(new T.SphereGeometry(1.1,20,12),new T.MeshBasicMaterial({color:cream}),world,s.size,16,-24);moon.material.fog=false;
 const stars=new T.InstancedMesh(new T.OctahedronGeometry(.045),new T.MeshBasicMaterial({color:'#f5d8a5',fog:false}),45);
 for(let i=0;i<45;i++){o.position.set(Math.sin(i*7)*s.size+s.size,7+(i%9)*.7,Math.cos(i*5)*s.size+s.size);o.scale.setScalar(.6+(i%3)*.3);o.rotation.set(0,0,0);o.updateMatrix();stars.setMatrixAt(i,o.matrix);}world.add(stars);
 return {update(time){for(let i=0;i<flies.count;i++){const cell=cells[i],x=cell%s.size*2,z=Math.floor(cell/s.size)*2;o.position.set(x+Math.sin(time*.6+i)*.55,.65+(i%4)*.22+Math.sin(time+i)*.12,z+Math.cos(time*.5+i)*.55);o.scale.setScalar(.7+Math.sin(time*2+i)*.3);o.rotation.set(0,0,0);o.updateMatrix();flies.setMatrixAt(i,o.matrix);}flies.instanceMatrix.needsUpdate=true;}};
}
export function createFriendlyBats(){
 const group=new T.Group(),body=material('#9a79b4'),pink=material('#e6a8b7');
 for(let i=0;i<5;i++){const bat=new T.Group();const ball=mesh(new T.SphereGeometry(.12,10,7),body,bat);ball.scale.set(1,.85,.8);for(const side of [-1,1]){const wing=mesh(new T.SphereGeometry(.14,8,5),body,bat,side*.17,.01);wing.scale.set(1.5,.3,.4);mesh(new T.ConeGeometry(.045,.09,5),body,bat,side*.065,.12);mesh(new T.SphereGeometry(.025,5,4),pink,bat,side*.07,-.02,.095);mesh(new T.SphereGeometry(.018,5,4),material('#fff5dd'),bat,side*.04,.025,.1);}group.add(bat);}
 return {group,age:0};
}
