import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const pieces=[];
function piece(source,position,rotation,color){
  const geometry=source.index?source.toNonIndexed():source.clone(),transform=new THREE.Object3D();
  transform.position.copy(position);transform.rotation.copy(rotation);transform.updateMatrix();geometry.applyMatrix4(transform.matrix);
  const rgb=new THREE.Color(color),colors=[];for(let i=0;i<geometry.attributes.position.count;i++)colors.push(rgb.r,rgb.g,rgb.b);
  geometry.setAttribute('color',new THREE.Float32BufferAttribute(colors,3));pieces.push(geometry);
}
piece(new THREE.CylinderGeometry(.26,.26,.09,20),new THREE.Vector3(),new THREE.Euler(Math.PI/2,0,0),'#ffd34f');
const ring=new THREE.TorusGeometry(.225,.021,4,20),heart=new THREE.Shape();
heart.moveTo(0,-.12);heart.bezierCurveTo(-.22,.02,-.16,.19,0,.08);heart.bezierCurveTo(.16,.19,.22,.02,0,-.12);
const stamp=new THREE.ExtrudeGeometry(heart,{depth:.018,curveSegments:5,bevelEnabled:true,bevelSegments:1,steps:1,bevelSize:.008,bevelThickness:.008});
for(const side of [-1,1]){
  piece(ring,new THREE.Vector3(0,0,side*.05),new THREE.Euler(),'#fff0a0');
  piece(stamp,new THREE.Vector3(0,0,side*.05),new THREE.Euler(0,side<0?Math.PI:0,0),'#ffec8b');
}
const geometry=mergeGeometries(pieces,false);for(const part of pieces)part.dispose();
const material=new THREE.MeshStandardMaterial({vertexColors:true,metalness:.2,roughness:.35,emissive:'#b76d08',emissiveIntensity:.25});
export function createRunnerCoin(){return new THREE.Mesh(geometry,material);}
