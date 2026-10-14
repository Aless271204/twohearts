import * as THREE from 'three';

/** Reversible headwear occlusion. Skinning, UVs and original assets stay intact.
 * The fitted cap's closed crown covers the temporary mesh boundary.
 * All calculations use the pet's unanimated, normalized model coordinates.
 */
export function prepareHeadwearOcclusion(pet, modelRoot, profile) {
  if (!profile) return {setEquipped(){}, dispose(){}, hiddenTriangles:0};
  modelRoot.updateMatrixWorld(true);
  const inverseRoot=modelRoot.matrixWorld.clone().invert();
  const [cx,cy,cz]=profile.center,[rx,ry,rz]=profile.radius;
  const changes=[];let hiddenTriangles=0;
  pet.traverse(mesh=>{
    if(!mesh.isMesh || !mesh.geometry.attributes.position) return;
    const original=mesh.geometry,positions=original.attributes.position;
    const transform=new THREE.Matrix4().multiplyMatrices(inverseRoot,mesh.matrixWorld);
    const hidden=new Uint8Array(positions.count),p=new THREE.Vector3();
    if(mesh.isSkinnedMesh)mesh.skeleton.update();
    for(let i=0;i<positions.count;i++){
      p.fromBufferAttribute(positions,i);if(mesh.isSkinnedMesh)mesh.applyBoneTransform(i,p);p.applyMatrix4(transform);
      const a=Math.atan2((p.x-cx)/rx,(p.z-cz)/rz);
      const hem=cy+.045-.034*(1-Math.cos(a))/2-.012*Math.sin(a)**2;
      const radiusSquared=((p.x-cx)/rx)**2+((p.y-cy)/ry)**2+((p.z-cz)/rz)**2;
      const rearWindow=Math.abs(p.x-cx)<.080&&Math.abs(p.y-(cy+.055))<.061&&p.z<cz-rz*.75;
      const margin=radiusSquared>1.02&&Math.abs(Math.sin(a))>.75?(profile.lateral_hem_margin??profile.hem_margin):profile.hem_margin;
      hidden[i]=p.y>hem-margin && (radiusSquared>.965||profile.hide_inside_crown&&!rearWindow) ? 1 : 0;
    }
    const index=original.index,kept=[],groups=[];let removed=0;
    const sourceGroups=original.groups.length?original.groups:[{start:0,count:index?index.count:positions.count,materialIndex:0}];
    for(const group of sourceGroups){
      const start=kept.length;
      for(let i=group.start;i<group.start+group.count;i+=3){
        const a=index?index.getX(i):i,b=index?index.getX(i+1):i+1,c=index?index.getX(i+2):i+2;
        const remove=profile.hide_inside_crown?hidden[a]&&hidden[b]&&hidden[c]:hidden[a]||hidden[b]||hidden[c];
        if(remove){removed++;continue;}
        kept.push(a,b,c);
      }
      groups.push({start,count:kept.length-start,materialIndex:group.materialIndex});
    }
    if(!removed)return;
    const covered=original.clone();covered.setIndex(kept);covered.clearGroups();
    groups.forEach(g=>covered.addGroup(g.start,g.count,g.materialIndex));
    covered.computeBoundingBox();covered.computeBoundingSphere();
    changes.push({mesh,original,covered});hiddenTriangles+=removed;
  });
  return {
    hiddenTriangles,
    setEquipped(equipped){changes.forEach(c=>c.mesh.geometry=equipped?c.covered:c.original);},
    dispose(){changes.forEach(c=>{c.mesh.geometry=c.original;c.covered.dispose();});}
  };
}
