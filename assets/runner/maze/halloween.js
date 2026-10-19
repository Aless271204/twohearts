import * as T from 'three';
export function addHalloweenDecor(parent,points){
 const body=new T.InstancedMesh(new T.SphereGeometry(1,10,7),new T.MeshStandardMaterial({color:'#d9873b',roughness:.9}),points.length*7);
 const stems=new T.InstancedMesh(new T.CylinderGeometry(.025,.04,.12,6),new T.MeshStandardMaterial({color:'#6c783e',roughness:1}),points.length);
 const shape=new T.Shape();shape.moveTo(0,.065);shape.lineTo(-.045,-.025);shape.lineTo(.045,-.025);shape.closePath();
 const eyes=new T.InstancedMesh(new T.ShapeGeometry(shape),new T.MeshBasicMaterial({color:'#ffce78',side:T.DoubleSide}),points.length*2);
 const mouths=new T.InstancedMesh(new T.TorusGeometry(.08,.016,4,10,Math.PI),new T.MeshBasicMaterial({color:'#ffce78',side:T.DoubleSide}),points.length);
 const o=new T.Object3D();points.forEach(([x,z],i)=>{
  for(let lobe=0;lobe<7;lobe++){const a=lobe*Math.PI*2/7;o.position.set(x+Math.cos(a)*.11,.24,z+Math.sin(a)*.11);o.scale.set(.17,.22,.17);o.rotation.set(0,a,0);o.updateMatrix();body.setMatrixAt(i*7+lobe,o.matrix);}
  o.position.set(x,.48,z);o.rotation.set(0,0,-.18);o.scale.setScalar(1);o.updateMatrix();stems.setMatrixAt(i,o.matrix);
  for(let e=0;e<2;e++){o.position.set(x+(e?1:-1)*.085,.3,z+.263);o.rotation.set(0,0,0);o.updateMatrix();eyes.setMatrixAt(i*2+e,o.matrix);}
  o.position.set(x,.2,z+.273);o.rotation.z=Math.PI;o.updateMatrix();mouths.setMatrixAt(i,o.matrix);
 });parent.add(body,stems,eyes,mouths);
}
