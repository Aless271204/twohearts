import * as THREE from 'three';

// Only upper-body motion. Root, legs and soles are never animated here.
export function createPetMotion(model) {
  let head,spine,time=0,affection=0;
  const wings=[];
  model.traverse(o=>{
    if(o.isBone&&/Head$/.test(o.name))head=o;
    if(o.isBone&&/Spine2$/.test(o.name))spine=o;
    if(/RoundedWing$/.test(o.name))wings.push({mesh:o,base:o.quaternion.clone(),sign:o.name.startsWith('Left')?1:-1});
  });
  const scale=spine?.scale.clone();
  return {
    stroke(){affection=2.4;},
    update(dt){
      time+=Math.min(dt,.12);affection=Math.max(0,affection-dt);
      const response=affection>0?Math.sin(Math.PI*Math.min(1,affection/2.4)):0;
      if(spine&&scale)spine.scale.set(scale.x*(1+Math.sin(time*1.65)*.007),scale.y*(1+Math.sin(time*1.65)*.003),scale.z*(1+Math.sin(time*1.65)*.01));
      if(head){head.quaternion.multiply(new THREE.Quaternion().setFromEuler(new THREE.Euler(Math.sin(time*.7)*.009-response*.025,Math.sin(time*.45)*.018,response*.11)));}
      for(const {mesh,base,sign} of wings)mesh.quaternion.copy(base).multiply(new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(0,0,1),sign*(Math.sin(time*1.65)*.012+response*.10)));
      model.userData.affection=response;
      model.userData.breathing=Math.sin(time*1.65)*.007;
    },
  };
}
