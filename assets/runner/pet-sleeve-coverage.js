import * as THREE from 'three';

// Garments render their own volume over the upper arm. Cull only the skin
// that is physically inside a sleeve; preserve the exposed forearm/hand and
// every original attribute. Restore before applying any other coverage mask.
export function restoreSleeveCoverage(model){
 model.traverse(mesh=>{
  if(mesh.userData.sleeveSourceGeometry){
   mesh.geometry.dispose();mesh.geometry=mesh.userData.sleeveSourceGeometry;
   delete mesh.userData.sleeveSourceGeometry;delete mesh.userData.sleeveSourceIndices;return;
  }
  const index=mesh.userData.sleeveSourceIndices;
  if(index){mesh.geometry.setIndex(index.clone());delete mesh.userData.sleeveSourceIndices;}
 });
}
export function coverSleeveSkin(model,item){
 const measured=item?.covered_skin_triangles;
 if(measured){
  model.traverse(mesh=>{
   if(!mesh.isSkinnedMesh||mesh.userData.cosmetic||!mesh.geometry.index)return;
   const triangles=measured[mesh.name];if(!Array.isArray(triangles))return;
   const covered=new Set();for(let i=0;i<triangles.length;i+=3)covered.add(triangles.slice(i,i+3).join(','));
   const source=mesh.geometry.index,kept=[];
   const clips=new Map((measured.__clips?.[mesh.name]??[]).map(entry=>[entry.triangle.join(','),entry.polygon]));
   const original=mesh.geometry,attributes=Object.fromEntries(Object.entries(original.attributes).map(([name,a])=>[name,Array.from(a.array)]));
   let vertexCount=original.attributes.position.count;
   function clippedVertex(ref){
    if(Number.isInteger(ref))return ref;
    const [a,b,t]=ref,index=vertexCount++;
    for(const [name,values] of Object.entries(attributes)){
     const attribute=original.attributes[name];
     if(name==='skinIndex'||name==='skinWeight')continue;
     const value=[];for(let k=0;k<attribute.itemSize;k++)value.push(attribute.getComponent(a,k)*(1-t)+attribute.getComponent(b,k)*t);
     if(name==='normal'){const n=new THREE.Vector3(...value).normalize();value.splice(0,3,n.x,n.y,n.z);}
     values.push(...value);
    }
    const weights=new Map(),j=original.attributes.skinIndex,w=original.attributes.skinWeight;
    for(const [v,part] of [[a,1-t],[b,t]])for(let k=0;k<4;k++){const bone=j.getComponent(v,k);weights.set(bone,(weights.get(bone)??0)+w.getComponent(v,k)*part);}
    const sorted=[...weights].filter(([,weight])=>weight>0).sort((a,b)=>b[1]-a[1]).slice(0,4),sum=sorted.reduce((s,[,weight])=>s+weight,0);
    for(let k=0;k<4;k++){attributes.skinIndex.push(sorted[k]?.[0]??0);attributes.skinWeight.push((sorted[k]?.[1]??0)/sum);}
    return index;
   }
   for(let i=0;i<source.count;i+=3){
    const tri=[source.getX(i),source.getX(i+1),source.getX(i+2)],key=tri.join(',');if(covered.has(key))continue;
    const polygon=clips.get(key);
    if(polygon){const vertices=polygon.map(clippedVertex);for(let k=1;k<vertices.length-1;k++)kept.push(vertices[0],vertices[k],vertices[k+1]);}
    else kept.push(...tri);
   }
   if(clips.size){
    const geometry=original.clone();
    for(const [name,values] of Object.entries(attributes)){const a=original.attributes[name];geometry.setAttribute(name,new THREE.BufferAttribute(new a.array.constructor(values),a.itemSize,a.normalized));}
    geometry.setIndex(kept);geometry.computeBoundingBox();geometry.computeBoundingSphere();mesh.userData.sleeveSourceGeometry=original;mesh.geometry=geometry;
   }else{mesh.userData.sleeveSourceIndices=source.clone();mesh.geometry.setIndex(kept);}
  });
  return;
 }
 const coverage=item?.sleeve_coverage?.[model.userData.species];
 const body=model.userData.accessoryFit?.body;
 const bodyTop=body?.max.y??0,shoulderX=body?Math.max(Math.abs(body.min.x),Math.abs(body.max.x))*.70:Infinity;
 model.updateMatrixWorld(true);
 model.traverse(mesh=>{
  if(!mesh.isSkinnedMesh||mesh.userData.cosmetic||!mesh.geometry.index)return;
  let samples=mesh.userData.sleeveRestSamples;
  if(!samples){
   mesh.skeleton.update();samples=[];
   const p=mesh.geometry.attributes.position,j=mesh.geometry.attributes.skinIndex,w=mesh.geometry.attributes.skinWeight;
   for(let i=0;i<p.count;i++){
    let arm=0;for(let k=0;k<4;k++)if(/(Arm|ForeArm)$/.test(mesh.skeleton.bones[j.getComponent(i,k)].name))arm+=w.getComponent(i,k);
    const point=new THREE.Vector3().fromBufferAttribute(p,i);mesh.applyBoneTransform(i,point);mesh.localToWorld(point);model.worldToLocal(point);
    // Source shoulder skin sometimes carries spine/neck weights rather than
    // arm weights. The tailored sleeve still covers that entire shoulder.
    if(Math.abs(point.x)>.10&&(arm>.30||point.y<=bodyTop&&Math.abs(point.x)>=shoulderX))samples.push({i,y:point.y,arm});
   }
   mesh.userData.sleeveRestSamples=samples;
  }
  if(!coverage)return;
  const hidden=new Set(samples.filter(p=>p.y>=coverage.min_y&&p.y<=coverage.max_y).map(p=>p.i));
  if(!hidden.size)return;
  const source=mesh.geometry.index,kept=[];
  // Keep triangles crossing the cuff boundary. Removing a face merely because
  // one vertex lies under the sleeve opens a visible tear in the exposed arm.
  for(let i=0;i<source.count;i+=3){const a=source.getX(i),b=source.getX(i+1),c=source.getX(i+2);if(!(hidden.has(a)&&hidden.has(b)&&hidden.has(c)))kept.push(a,b,c);}
  mesh.userData.sleeveSourceIndices=source.clone();mesh.geometry.setIndex(kept);
 });
}
