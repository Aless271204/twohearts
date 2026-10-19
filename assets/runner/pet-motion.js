import * as THREE from 'three';

// Gentle room gestures on the original rig. Never stretch the body or move feet.
export function createPetMotion(model) {
  let head,spine,time=0,affection=0;
  const wings=[],arms=[];
  model.traverse(o=>{
    if(o.isBone&&/Head$/.test(o.name))head=o;
    if(o.isBone&&/Spine2$/.test(o.name))spine=o;
    if(/RoundedWing$/.test(o.name))wings.push({mesh:o,base:o.quaternion.clone(),sign:o.name.startsWith('Left')?1:-1});
    if(o.isBone&&/(RightArm|RightForeArm|RightHand)$/.test(o.name))arms.push({bone:o,base:o.quaternion.clone()});
  });
  const heart=new THREE.Shape();heart.moveTo(0,-.35);heart.bezierCurveTo(-.65,.05,-.6,.65,0,.34);heart.bezierCurveTo(.6,.65,.65,.05,0,-.35);
  const hearts=new THREE.Group();hearts.name='room-kiss-hearts';model.add(hearts);
  for(let i=0;i<3;i++){const mesh=new THREE.Mesh(new THREE.ShapeGeometry(heart,12),new THREE.MeshBasicMaterial({color:['#ed7c8b','#f3ad9e','#eeba75'][i],transparent:true,depthWrite:false,side:THREE.DoubleSide}));mesh.scale.setScalar(.07-i*.009);hearts.add(mesh);}
  hearts.visible=false;
  const smooth=t=>{t=THREE.MathUtils.clamp(t,0,1);return t*t*(3-2*t);};
  const envelope=(t,start,length)=>t<start||t>start+length?0:Math.sin(Math.PI*(t-start)/length);
  return {
    stroke(){affection=2.4;},
    update(dt){
      time+=Math.min(dt,.12);affection=Math.max(0,affection-dt);
      const response=affection>0?Math.sin(Math.PI*Math.min(1,affection/2.4)):0;
      const cycle=time%28,wave=envelope(cycle,1,3.6),kiss=Math.max(envelope(cycle,14,3),response);
      if(spine)spine.quaternion.multiply(new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(1,0,0),Math.sin(time*1.65)*.006));
      if(head){head.quaternion.multiply(new THREE.Quaternion().setFromEuler(new THREE.Euler(Math.sin(time*.7)*.009-response*.025,Math.sin(time*.45)*.018,(.028+Math.sin(time*.55)*.015+response*.07))));}
      for(const {bone,base}of arms){
        bone.quaternion.copy(base);
        const motion=/ForeArm$/.test(bone.name)?new THREE.Euler(-kiss*.32,0,wave*.32):/Hand$/.test(bone.name)?new THREE.Euler(0,wave*Math.sin(time*9)*.15,kiss*.08):new THREE.Euler(-kiss*.24,wave*.06,-wave*.25);
        bone.quaternion.multiply(new THREE.Quaternion().setFromEuler(motion));
      }
      for(const {mesh,base,sign} of wings)mesh.quaternion.copy(base).multiply(new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(0,0,1),sign*(Math.sin(time*1.65)*.012+response*.10)));
      hearts.visible=kiss>.1;
      if(hearts.visible){
        if(head){model.updateMatrixWorld(true);hearts.position.copy(model.worldToLocal(head.getWorldPosition(new THREE.Vector3())));}
        hearts.children.forEach((mesh,i)=>{const p=(cycle>14&&cycle<17?(cycle-14)/3:1-affection/2.4)+i*.16;mesh.position.set(.10+i*.07,.08+smooth(p)*.27,.32);mesh.rotation.z=Math.sin(time*2+i)*.1;mesh.material.opacity=kiss*.8;});
      }
      model.userData.affection=response;
      model.userData.breathing=Math.sin(time*1.65)*.007;
      model.userData.roomGesture=wave>.1?'wave':kiss>.1?'kiss':'breathing';
    },
    dispose(){hearts.traverse(o=>{o.geometry?.dispose();o.material?.dispose();});hearts.removeFromParent();},
  };
}
