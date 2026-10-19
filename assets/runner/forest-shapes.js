import * as THREE from 'three';
import {mergeGeometries} from 'three/addons/utils/BufferGeometryUtils.js';

// Reusable silhouettes with soft edges, rather than flat triangular boulders
// and straight poles. No extra image downloads or per-tree materials.
export function createForestRockGeometry() {
  const geometry=new THREE.SphereGeometry(1,12,8),p=geometry.attributes.position;
  const colors=new Float32Array(p.count*3),color=new THREE.Color();
  for(let i=0;i<p.count;i++) {
    const x=p.getX(i),y=p.getY(i),z=p.getZ(i);
    const radius=1+.09*Math.sin(x*4+z*3)*Math.cos(y*5)+.035*Math.sin(z*8-y*2);
    p.setXYZ(i,x*radius,y*radius,z*radius);
    const light=.79+.21*(y+1)/2;
    color.setRGB(light*.98,light,light*.97).toArray(colors,i*3);
  }
  geometry.setAttribute('color',new THREE.BufferAttribute(colors,3));
  geometry.computeVertexNormals();
  return geometry;
}

export function createForestTrunkGeometry() {
  const trunk=new THREE.CylinderGeometry(.28,.45,1,10,5),p=trunk.attributes.position;
  for(let i=0;i<p.count;i++) {
    const y=p.getY(i);
    p.setX(i,p.getX(i)+.06*Math.sin((y+.5)*2.8));
    p.setZ(i,p.getZ(i)+.035*Math.sin((y+.5)*4));
  }
  const parts=[trunk],up=new THREE.Vector3(0,1,0);
  for(const [x,y,z] of [[.9,.37,.12],[-.75,.3,-.26],[.28,.43,-.83]]) {
    const start=new THREE.Vector3(.04,.02,0),end=new THREE.Vector3(x,y,z),direction=end.clone().sub(start);
    const branch=new THREE.CylinderGeometry(.06,.15,direction.length(),7,2);
    branch.applyQuaternion(new THREE.Quaternion().setFromUnitVectors(up,direction.clone().normalize()));
    branch.translate(...start.add(end).multiplyScalar(.5).toArray());
    parts.push(branch);
  }
  const geometry=mergeGeometries(parts);
  parts.forEach(g=>g.dispose());
  const colors=new Float32Array(geometry.attributes.position.count*3),color=new THREE.Color();
  const position=geometry.attributes.position;
  for(let i=0;i<position.count;i++) {
    const shade=.84+.16*(position.getY(i)+.5);
    color.setRGB(shade,shade*.96,shade*.87).toArray(colors,i*3);
  }
  geometry.setAttribute('color',new THREE.BufferAttribute(colors,3));
  geometry.computeVertexNormals();
  return geometry;
}
