import * as THREE from 'three';

// Fit the inner crown to the posed character mesh, not a screen-space overlay.
// The caller supplies an independent clone of the original accessory.
export function conformHeadAccessory(part,model,head,settings={}){
  model.updateMatrixWorld(true);
  const surfaces=[];
  model.traverse(mesh=>{
    if(!mesh.isSkinnedMesh||mesh.userData.cosmetic)return;
    mesh.skeleton.update();
    const positions=mesh.geometry.attributes.position,posed=[];
    for(let i=0;i<positions.count;i++){
      const point=new THREE.Vector3().fromBufferAttribute(positions,i);mesh.applyBoneTransform(i,point);mesh.localToWorld(point);model.worldToLocal(point);posed.push(...point.toArray());
    }
    const geometry=new THREE.BufferGeometry();geometry.setAttribute('position',new THREE.Float32BufferAttribute(posed,3));if(mesh.geometry.index)geometry.setIndex(mesh.geometry.index.clone());geometry.computeBoundingBox();geometry.computeBoundingSphere();
    const surface=new THREE.Mesh(geometry,new THREE.MeshBasicMaterial({side:THREE.DoubleSide}));surface.updateMatrixWorld(true);surfaces.push(surface);
  });
  const center=head.getCenter(new THREE.Vector3()),size=head.getSize(new THREE.Vector3());
  const ray=new THREE.Raycaster(),origin=new THREE.Vector3(),direction=new THREE.Vector3(0,-1,0);
  const band=settings.band??.065,clearance=settings.clearance??.012;
  // Sample a shared smooth contact field instead of raycasting thousands of
  // individual UV vertices. The field is based on this exact posed head mesh.
  const resolution=16,heights=new Map();
  function sample(ix,iz){
    const key=ix+':'+iz;if(heights.has(key))return heights.get(key);
    origin.set(head.min.x+size.x*ix/resolution,head.max.y+.2,head.min.z+size.z*iz/resolution);ray.set(origin,direction);
    const hit=ray.intersectObjects(surfaces,false).find(h=>h.point.y>head.min.y+size.y*.38),height=hit?.point.y??null;heights.set(key,height);return height;
  }
  function contactHeight(x,z){
    const gx=THREE.MathUtils.clamp((x-head.min.x)/size.x*resolution,0,resolution-.001),gz=THREE.MathUtils.clamp((z-head.min.z)/size.z*resolution,0,resolution-.001),ix=Math.floor(gx),iz=Math.floor(gz),fx=gx-ix,fz=gz-iz;
    let value=0,weight=0;
    for(const [dx,dz,w] of [[0,0,(1-fx)*(1-fz)],[1,0,fx*(1-fz)],[0,1,(1-fx)*fz],[1,1,fx*fz]]){const y=sample(ix+dx,iz+dz);if(y!==null){value+=y*w;weight+=w;}}
    return weight>.05?value/weight:null;
  }
  let moved=0,maxMovement=0;
  part.traverse(mesh=>{
    if(!mesh.isMesh)return;
    const positions=mesh.geometry.attributes.position;
    let meshMoved=0;
    for(let i=0;i<positions.count;i++){
      const local=new THREE.Vector3().fromBufferAttribute(positions,i);
      let world=mesh.localToWorld(local.clone());
      if(settings.crown_height||settings.visor_length||settings.depth_scale){
        const authored=part.worldToLocal(world.clone());
        if(settings.crown_height)authored.y=-.035+(authored.y+.035)*settings.crown_height;
        if(settings.visor_length&&authored.z>.30){
          const visorWeight=1-THREE.MathUtils.smoothstep(authored.y,.025,.10);
          if(settings.visor_flatten)authored.y=-.035+(authored.y+.035)*THREE.MathUtils.lerp(1,settings.visor_flatten,visorWeight);
          authored.z=.30+(authored.z-.30)*THREE.MathUtils.lerp(1,settings.visor_length,visorWeight);
        }
        if(settings.depth_scale)authored.z*=settings.depth_scale;
        world=part.localToWorld(authored);
        const shaped=mesh.worldToLocal(world.clone());positions.setXYZ(i,shaped.x,shaped.y,shaped.z);meshMoved++;
      }
      const point=model.worldToLocal(world.clone());
      // Preserve the brim, visor, badges, pom-pom and loose hair tips.
      const inPart=part.worldToLocal(world.clone());
      if(settings.contact===false)continue;
      if(inPart.y>band||inPart.y<-.16)continue;
      if(settings.visor&&inPart.z>.30)continue;
      const dx=point.x-center.x,dz=point.z-center.z;
      if(Math.abs(dx)>size.x*.54||Math.abs(dz)>size.z*.54)continue;
      let height=contactHeight(point.x,point.z);
      // Sample just inside the silhouette where the cloth rim wraps the skull.
      if(height===null)height=contactHeight(center.x+dx*.90,center.z+dz*.90);
      if(height===null)continue;
      const difference=height+clearance-point.y;
      const influence=1-THREE.MathUtils.smoothstep(inPart.y,.005,band);
      // A bounded continuous displacement prevents seams between adjacent
      // vertices when the sampled head surface crosses the contact band.
      const edgeFade=1-THREE.MathUtils.smoothstep(Math.max(Math.abs(dx)/(size.x*.54),Math.abs(dz)/(size.z*.54)),.80,1);
      const adjustment=THREE.MathUtils.clamp(difference,-.045,.045)*influence*edgeFade;
      if(Math.abs(adjustment)<.0005)continue;
      point.y+=adjustment;
      const fitted=mesh.worldToLocal(model.localToWorld(point));positions.setXYZ(i,fitted.x,fitted.y,fitted.z);moved++;meshMoved++;maxMovement=Math.max(maxMovement,Math.abs(adjustment));
    }
    // Meshy splits vertices at UV seams. Recomputing normals independently at
    // those seams makes soft cloth and hair look like disconnected triangles.
    if(meshMoved){positions.needsUpdate=true;mesh.geometry.computeBoundingBox();mesh.geometry.computeBoundingSphere();}
  });
  if(settings.hair_lining){
    // The supplied hair has separate open locks. A real inner scalp closes
    // gaps between those locks, so the pet's dark crown cannot poke through.
    const geometry=new THREE.SphereGeometry(1,32,12,0,Math.PI*2,0,1.45);
    const positions=geometry.attributes.position,uv=geometry.attributes.uv,locks=[];
    let hairMaterial=null;
    part.traverse(mesh=>{if(!mesh.isMesh)return;hairMaterial??=Array.isArray(mesh.material)?mesh.material[0]:mesh.material;const vertices=mesh.geometry.attributes.position,texture=mesh.geometry.attributes.uv;if(!texture)return;for(let i=0;i<vertices.count;i++){const point=new THREE.Vector3().fromBufferAttribute(vertices,i);part.worldToLocal(mesh.localToWorld(point));locks.push({point,uv:new THREE.Vector2().fromBufferAttribute(texture,i)});}});
    for(let i=0;i<positions.count;i++){
      const point=new THREE.Vector3().fromBufferAttribute(positions,i);
      point.multiply(new THREE.Vector3(size.x*.52,.205,size.z*.54));
      point.add(new THREE.Vector3(center.x,head.max.y-.255,center.z));
      part.worldToLocal(model.localToWorld(point));positions.setXYZ(i,point.x,point.y,point.z);
      let nearest=null,distance=Infinity;for(const lock of locks){const squared=point.distanceToSquared(lock.point);if(squared<distance){distance=squared;nearest=lock;}}
      if(nearest)uv.setXY(i,nearest.uv.x,nearest.uv.y);
    }
    geometry.computeVertexNormals();
    const material=hairMaterial?hairMaterial.clone():new THREE.MeshStandardMaterial({color:settings.hair_lining});material.normalMap=null;material.metalness=0;material.roughness=.9;material.side=THREE.DoubleSide;
    const lining=new THREE.Mesh(geometry,material);
    lining.name='fitted-hair-inner-lining';lining.userData.cosmetic=true;part.add(lining);
  }
  for(const surface of surfaces){surface.geometry.dispose();surface.material.dispose();}
  part.userData.headConformance={moved,maxMovement};
  return part.userData.headConformance;
}
