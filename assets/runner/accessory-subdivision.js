import * as THREE from 'three';

// One Loop subdivision pass. Weld only the geometric topology, retaining
// separate UV/normal vertices at texture seams and all original materials.
export function softenAccessoryGeometry(source){
 const position=source.attributes.position,index=source.index;
 if(!index)return source.clone();
 const vertices=[],ids=[],weld=new Map(),adj=[],edges=new Map();
 const edgeKey=(a,b)=>a<b?`${a}:${b}`:`${b}:${a}`;
 for(let i=0;i<position.count;i++){
  const point=new THREE.Vector3().fromBufferAttribute(position,i),key=point.toArray().map(x=>Math.round(x*100000)).join(',');
  if(!weld.has(key)){weld.set(key,vertices.length);vertices.push(point);adj.push(new Set());}
  ids.push(weld.get(key));
 }
 for(let i=0;i<index.count;i+=3){
  const triangle=[0,1,2].map(k=>ids[index.getX(i+k)]);
  for(let k=0;k<3;k++){const a=triangle[k],b=triangle[(k+1)%3],opposite=triangle[(k+2)%3];if(a===b)continue;adj[a].add(b);adj[b].add(a);const key=edgeKey(a,b);if(!edges.has(key))edges.set(key,{a,b,opposite:[]});edges.get(key).opposite.push(opposite);}
 }
 const boundary=vertices.map(()=>new Set());
 for(const e of edges.values())if(e.opposite.length===1){boundary[e.a].add(e.b);boundary[e.b].add(e.a);}
 const smooth=vertices.map((point,i)=>{
  const rim=[...boundary[i]],neighbors=[...adj[i]];
  if(rim.length===2)return point.clone().multiplyScalar(.75).addScaledVector(vertices[rim[0]],.125).addScaledVector(vertices[rim[1]],.125);
  if(rim.length||neighbors.length<3)return point.clone();
  const beta=neighbors.length===3?3/16:3/(8*neighbors.length),result=point.clone().multiplyScalar(1-neighbors.length*beta);
  for(const n of neighbors)result.addScaledVector(vertices[n],beta);return result;
 });
 const output={},midpoints=new Map(),triangles=[];
 for(const [name,attribute] of Object.entries(source.attributes))output[name]=Array.from(attribute.array);
 for(let i=0;i<position.count;i++)smooth[ids[i]].toArray(output.position,i*3);
 function midpoint(a,b){
  const key=edgeKey(a,b);if(midpoints.has(key))return midpoints.get(key);
  const target=output.position.length/3,edge=edges.get(edgeKey(ids[a],ids[b]));
  let point=vertices[ids[a]].clone().add(vertices[ids[b]]).multiplyScalar(.5);
  if(edge?.opposite.length===2)point=vertices[edge.a].clone().add(vertices[edge.b]).multiplyScalar(.375).addScaledVector(vertices[edge.opposite[0]],.125).addScaledVector(vertices[edge.opposite[1]],.125);
  for(const [name,attribute] of Object.entries(source.attributes))for(let k=0;k<attribute.itemSize;k++)output[name].push(name==='position'?point.getComponent(k):(attribute.getComponent(a,k)+attribute.getComponent(b,k))*.5);
  midpoints.set(key,target);return target;
 }
 for(let i=0;i<index.count;i+=3){const a=index.getX(i),b=index.getX(i+1),c=index.getX(i+2),ab=midpoint(a,b),bc=midpoint(b,c),ca=midpoint(c,a);triangles.push(a,ab,ca,ab,b,bc,ca,bc,c,ab,bc,ca);}
 const geometry=new THREE.BufferGeometry();
 for(const [name,attribute] of Object.entries(source.attributes))geometry.setAttribute(name,new THREE.Float32BufferAttribute(output[name],attribute.itemSize,attribute.normalized));
 geometry.setIndex(triangles);geometry.normalizeNormals();geometry.computeBoundingBox();geometry.computeBoundingSphere();return geometry;
}
