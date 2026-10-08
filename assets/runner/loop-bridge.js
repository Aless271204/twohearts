import * as THREE from 'three';
import { createWoodTexture } from './tropical.js';

const woodMap=createWoodTexture();
const deckMaterial=new THREE.MeshLambertMaterial({color:0xffffff,map:woodMap});
const wood=new THREE.MeshLambertMaterial({color:'#79502e',map:woodMap});
const rope=new THREE.MeshLambertMaterial({color:'#dfbd86'});
const iron=new THREE.MeshLambertMaterial({color:'#4d4034'});
const boardGeometry=new THREE.BoxGeometry(5,.17,.54);
const postGeometry=new THREE.BoxGeometry(.24,.96,.24);
const beamGeometry=new THREE.BoxGeometry(.22,.24,12);
const supportGeometry=new THREE.BoxGeometry(.32,3,.32);
const nailGeometry=new THREE.CircleGeometry(.025,6);nailGeometry.rotateX(-Math.PI/2);
const points=[];for(let i=0;i<=8;i++){const t=i/8;points.push(new THREE.Vector3(0,-Math.sin(t*Math.PI)*.12,t*4));}
const ropeGeometry=new THREE.TubeGeometry(new THREE.CatmullRomCurve3(points),8,.045,5,false);
const palette=['#b66f36','#d99c56','#bd8245','#e0ac70','#cf914b','#dda96c'];
const canopyCanvas=document.createElement('canvas');canopyCanvas.width=128;canopyCanvas.height=256;
const ctx=canopyCanvas.getContext('2d');ctx.fillStyle='rgba(19,40,27,.25)';ctx.filter='blur(3px)';
for(let i=0;i<24;i++){ctx.beginPath();ctx.ellipse(64+Math.sin(i*3.7)*75,i*11,10+i%4*4,20+i%3*5,i*.8,0,Math.PI*2);ctx.fill();}
const canopyMap=new THREE.CanvasTexture(canopyCanvas);
const canopyMaterial=new THREE.MeshBasicMaterial({map:canopyMap,transparent:true,depthWrite:false,opacity:.65,polygonOffset:true,polygonOffsetFactor:-1});
const canopyGeometry=new THREE.PlaneGeometry(5,12);

// About 1,600 triangles and six draw calls per segment, with shared resources.
export function createLoopBridge(z){
  const deck=new THREE.Group();deck.position.z=z;
  const transform=new THREE.Object3D();
  const boards=new THREE.InstancedMesh(boardGeometry,deckMaterial,20);
  for(let i=0;i<20;i++){
    transform.position.set(Math.sin(i*7+z)*.06,.095,-5.7+i*.6);transform.rotation.set(0,Math.sin(i*3+z)*.008,0);
    transform.scale.set(.97+Math.sin(i*4+z)*.03,1,.92+i%3*.04);transform.updateMatrix();boards.setMatrixAt(i,transform.matrix);
    boards.setColorAt(i,new THREE.Color(palette[(i+Math.abs(Math.floor(z)))%palette.length]));
  }
  boards.receiveShadow=true;deck.add(boards);
  const posts=new THREE.InstancedMesh(postGeometry,wood,8),beams=new THREE.InstancedMesh(beamGeometry,wood,2),ropes=new THREE.InstancedMesh(ropeGeometry,rope,12);
  let postIndex=0,ropeIndex=0;
  for(const side of [-1,1]){
    transform.rotation.set(0,0,0);transform.scale.setScalar(1);
    for(let i=0;i<4;i++){transform.position.set(side*2.65,.45,-6+i*4);transform.updateMatrix();posts.setMatrixAt(postIndex++,transform.matrix);}
    transform.position.set(side*2.25,-.1,0);transform.updateMatrix();beams.setMatrixAt(side===-1?0:1,transform.matrix);
    for(let span=0;span<3;span++)for(const height of [.43,.83]){transform.position.set(side*2.65,height,-6+span*4);transform.updateMatrix();ropes.setMatrixAt(ropeIndex++,transform.matrix);}
  }
  deck.add(posts,beams,ropes);
  const supports=new THREE.InstancedMesh(supportGeometry,wood,6);
  let supportIndex=0;
  for(const side of [-1,1])for(const depth of [-4,0,4]){
    transform.position.set(side*2.25,-1.5,depth);transform.updateMatrix();supports.setMatrixAt(supportIndex++,transform.matrix);
  }
  deck.add(supports);
  const nails=new THREE.InstancedMesh(nailGeometry,iron,40);
  for(let i=0;i<40;i++){transform.position.set((i%2?1:-1)*2.15,.185,-5.7+Math.floor(i/2)*.6);transform.updateMatrix();nails.setMatrixAt(i,transform.matrix);}deck.add(nails);
  const canopy=new THREE.Mesh(canopyGeometry,canopyMaterial);canopy.rotation.x=-Math.PI/2;canopy.position.y=.181;deck.add(canopy);
  return deck;
}

// All repeated sections share seven draws instead of seven per section.
export function createBridgeBelt(){
  const sections=Array.from({length:9},(_,i)=>createLoopBridge(8-i*12));
  const belt=new THREE.Group(), matrix=new THREE.Matrix4(), color=new THREE.Color();
  for(let type=0;type<sections[0].children.length;type++){
    const source=sections[0].children[type];
    const perSection=source.isInstancedMesh?source.count:1;
    const mesh=new THREE.InstancedMesh(source.geometry,source.material,perSection*sections.length);
    mesh.receiveShadow=source.receiveShadow;
    let index=0;
    for(const section of sections){
      const child=section.children[type];child.updateMatrix();
      for(let i=0;i<perSection;i++){
        if(child.isInstancedMesh)child.getMatrixAt(i,matrix);else matrix.copy(child.matrix);
        matrix.elements[14]+=section.position.z;mesh.setMatrixAt(index,matrix);
        if(child.instanceColor){child.getColorAt(i,color);mesh.setColorAt(index,color);}
        index++;
      }
    }
    mesh.computeBoundingSphere();belt.add(mesh);
  }
  for(const section of sections)for(const child of section.children)if(child.isInstancedMesh)child.dispose();
  return belt;
}
