import * as THREE from 'three';
import { createFlowMaterial } from './fantasy-water.js';

export function createRiver(scene){
  const material=createFlowMaterial();
  // One river beneath the bridge, connected to the waterfall basin at z=-75.
  const water=new THREE.Mesh(new THREE.PlaneGeometry(15,103),material);water.rotation.x=-Math.PI/2;water.position.set(0,-.1,-31.5);scene.add(water);
  return {update(dt){material.uniforms.time.value+=dt;}};
}

const greens=['#279e64','#57b445','#138967'].map(color=>new THREE.MeshStandardMaterial({color,roughness:.9,side:THREE.DoubleSide}));
const berryMaterials=['#ff8539','#ef4668','#ffcb3d'].map(color=>new THREE.MeshStandardMaterial({color,roughness:.5}));
const round=new THREE.SphereGeometry(1,8,6);
const leaf=new THREE.PlaneGeometry(.18,.42);
export function createForestCluster(index){
  const group=new THREE.Group();group.userData.planting=true;
  // Fern fronds with paired leaflets rather than a solid generic bush.
  const fern=new THREE.InstancedMesh(leaf,greens[index%3],50),transform=new THREE.Object3D(),rotation=new THREE.Matrix4();let instance=0;
  for(let f=0;f<5;f++){
    rotation.makeRotationY(f*Math.PI*2/5);
    for(let n=0;n<5;n++)for(const side of [-1,1]){
      transform.position.set(side*(.08+n*.025),.16+Math.sin(n*.35)*.4,n*.14);
      transform.rotation.set(-.8,side*.5,side*.5);transform.scale.setScalar(1-n*.12);transform.updateMatrix();
      fern.setMatrixAt(instance++,new THREE.Matrix4().multiplyMatrices(rotation,transform.matrix));
    }
  }
  group.add(fern);
  for(let i=0;i<3;i++){
    const fruit=new THREE.Mesh(round,berryMaterials[index%3]);fruit.scale.set(.13,.16,.13);fruit.position.set(.5+i*.16,.22+i%2*.14,-.3);group.add(fruit);
    const stem=new THREE.Mesh(new THREE.CylinderGeometry(.012,.015,.12,5),greens[0]);stem.position.copy(fruit.position);stem.position.y+=.17;group.add(stem);
  }
  const centerMat=berryMaterials[2];
  for(let i=0;i<2;i++){
    const flower=new THREE.Group();flower.position.set(-.45+i*.3,.5,-.35);
    for(let p=0;p<5;p++){const petal=new THREE.Mesh(round,berryMaterials[(index+1)%3]);petal.scale.set(.14,.045,.09);petal.position.set(Math.cos(p*1.256)*.13,0,Math.sin(p*1.256)*.13);flower.add(petal);}
    const center=new THREE.Mesh(round,centerMat);center.scale.setScalar(.065);flower.add(center);group.add(flower);
  }
  return group;
}

export function createBirds(scene){
  const birds=[],bodyGeometry=new THREE.SphereGeometry(1,8,6),wingGeometry=new THREE.SphereGeometry(1,6,4);
  const colors=['#30b9d1','#ffc64a','#ee7766'].map(color=>new THREE.MeshStandardMaterial({color,roughness:.8}));
  for(let i=0;i<5;i++){
    const bird=new THREE.Group(),body=new THREE.Mesh(bodyGeometry,colors[i%3]);bird.scale.setScalar(.55);body.scale.set(.13,.13,.32);bird.add(body);
    const wings=[];for(const side of [-1,1]){const pivot=new THREE.Group(),wing=new THREE.Mesh(wingGeometry,colors[i%3]);wing.scale.set(.48,.035,.16);wing.position.x=side*.36;pivot.add(wing);bird.add(pivot);wings.push(pivot);}
    const beak=new THREE.Mesh(new THREE.ConeGeometry(.06,.15,5),colors[1]);beak.rotation.x=-Math.PI/2;beak.position.z=-.37;bird.add(beak);
    scene.add(bird);birds.push({bird,wings});
  }
  let time=0;return {update(dt){time+=dt;birds.forEach(({bird,wings},i)=>{
    const phase=(time*.055+i/5)%1;bird.position.set(-13+phase*26,4+i%3*.65+Math.sin(time*1.4+i)*.25,-8-i*9);
    bird.rotation.y=-Math.PI/2;wings.forEach((wing,j)=>wing.rotation.z=Math.sin(time*9+i)*(j?-1:1)*.65);
  });}};
}
