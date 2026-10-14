import * as THREE from 'three';

// Reversible boundary clipping: interpolate original UVs, normals and bone
// weights instead of deleting a whole face that crosses a clothing edge.
export function clipSkinGeometry(original,covered,clips){
 const source=original.index,kept=[],attributes=Object.fromEntries(Object.entries(original.attributes).map(([name,a])=>[name,Array.from(a.array)]));
 let count=original.attributes.position.count;
 function vertex(ref){
  if(Number.isInteger(ref))return ref;
  const [a,b,t]=ref,index=count++;
  for(const [name,values]of Object.entries(attributes)){
   if(name==='skinIndex'||name==='skinWeight')continue;
   const attr=original.attributes[name],value=[];
   for(let k=0;k<attr.itemSize;k++)value.push(attr.getComponent(a,k)*(1-t)+attr.getComponent(b,k)*t);
   if(name==='normal'){const n=new THREE.Vector3(...value).normalize();value.splice(0,3,n.x,n.y,n.z);}
   values.push(...value);
  }
  const j=original.attributes.skinIndex,w=original.attributes.skinWeight;
  if(j&&w){
   const weights=new Map();for(const [v,part]of [[a,1-t],[b,t]])for(let k=0;k<4;k++){const bone=j.getComponent(v,k);weights.set(bone,(weights.get(bone)??0)+w.getComponent(v,k)*part);}
   const selected=[...weights].filter(([,w])=>w>0).sort((a,b)=>b[1]-a[1]).slice(0,4),sum=selected.reduce((s,[,w])=>s+w,0);
   for(let k=0;k<4;k++){attributes.skinIndex.push(selected[k]?.[0]??0);attributes.skinWeight.push((selected[k]?.[1]??0)/sum);}
  }
  return index;
 }
 for(let i=0;i<source.count;i+=3){
  const tri=[source.getX(i),source.getX(i+1),source.getX(i+2)],key=tri.join(',');if(covered.has(key))continue;
  const polygon=clips.get(key);
  if(polygon){const ids=polygon.map(vertex);for(let k=1;k<ids.length-1;k++)kept.push(ids[0],ids[k],ids[k+1]);}
  else kept.push(...tri);
 }
 const geometry=original.clone();
 if(clips.size)for(const [name,values]of Object.entries(attributes)){const a=original.attributes[name];geometry.setAttribute(name,new THREE.BufferAttribute(new a.array.constructor(values),a.itemSize,a.normalized));}
 geometry.setIndex(kept);geometry.computeBoundingBox();geometry.computeBoundingSphere();return geometry;
}
