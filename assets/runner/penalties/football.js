import * as T from 'three';
export function createFootball(radius=.23){
 const ico=new T.IcosahedronGeometry(1,0),raw=ico.attributes.position,vertices=[],faces=[];
 for(let i=0;i<raw.count;i+=3){const face=[];for(let j=0;j<3;j++){const v=new T.Vector3().fromBufferAttribute(raw,i+j);let id=vertices.findIndex(p=>p.distanceTo(v)<1e-5);if(id<0){id=vertices.length;vertices.push(v);}face.push(id);}faces.push(face);}ico.dispose();
 const polygons=[],around=vertices.map(()=>[]);
 for(const [a,b,c]of faces){const hex=[];for(const [u,v]of [[a,b],[b,a],[b,c],[c,b],[c,a],[a,c]]){const p=vertices[u].clone().lerp(vertices[v],1/3).normalize();hex.push(p);if(!around[u].some(q=>q.distanceTo(p)<1e-5))around[u].push(p);}polygons.push({points:hex,black:false});}
 around.forEach((points,i)=>{const n=vertices[i].clone().normalize(),u=new T.Vector3(0,1,0).cross(n).normalize();if(u.length()<.1)u.set(1,0,0);const v=n.clone().cross(u);points.sort((a,b)=>Math.atan2(a.dot(v),a.dot(u))-Math.atan2(b.dot(v),b.dot(u)));polygons.push({points,black:true});});
 const positions=[],normals=[],colors=[];
 for(const {points,black}of polygons){const center=points.reduce((a,p)=>a.add(p),new T.Vector3()).normalize(),color=new T.Color(black?'#26303b':'#f6edda');for(let i=0;i<points.length;i++){const tri=[center,points[i].clone().lerp(center,.025).normalize(),points[(i+1)%points.length].clone().lerp(center,.025).normalize()];if(new T.Vector3().crossVectors(tri[1].clone().sub(tri[0]),tri[2].clone().sub(tri[0])).dot(center)<0)tri.reverse();for(const p of tri){positions.push(...p.clone().multiplyScalar(radius).toArray());normals.push(...p.toArray());colors.push(...color.toArray());}}}
 const geometry=new T.BufferGeometry();geometry.setAttribute('position',new T.Float32BufferAttribute(positions,3));geometry.setAttribute('normal',new T.Float32BufferAttribute(normals,3));geometry.setAttribute('color',new T.Float32BufferAttribute(colors,3));
 const group=new T.Group();group.add(new T.Mesh(new T.SphereGeometry(radius*.997,16,12),new T.MeshStandardMaterial({color:'#84796c',roughness:.9})),new T.Mesh(geometry,new T.MeshStandardMaterial({vertexColors:true,roughness:.78})));return group;
}
