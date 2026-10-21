import * as T from 'three';

export const CONTACT_TIME=.34, FLIGHT_TIME=.9, IMPACT_TIME=CONTACT_TIME+FLIGHT_TIME;
const clamp=T.MathUtils.clamp;
const ease=x=>{x=clamp(x,0,1);return x*x*(3-2*x);};
const bell=(t,a,b)=>t<a||t>b?0:Math.sin((t-a)/(b-a)*Math.PI);

// Presentation only. The server owns the shot, save and score.
export function shotPresentation(seconds,result){
 const t=Math.max(0,seconds),flight=clamp((t-CONTACT_TIME)/FLIGHT_TIME,0,1);
 const dive=ease((t-.46)/.58),recover=ease((t-1.65)/.8);
 return {flight,approach:ease(t/.28),kickBack:bell(t,0,.34),kickForward:bell(t,.22,.9),
  dive:dive*(1-recover),air:Math.sin(clamp((t-.46)/1.02,0,1)*Math.PI)*.52*(1-recover),
  celebrate:result.kind==='goal'?bell(t,1.45,2.7):0,recover};
}

export function keeperPresentation(seconds,result){
 const m=shotPresentation(seconds,result),reach=result.kind==='save'?result.shot:result.keeper;
 const direction=(reach.x-.5)*7.3;
 const height=.2+reach.y*2.4;
 return {...m,x:direction*m.dive,y:m.air*(.45+.8*reach.y),roll:-Math.sign(direction)*Math.min(.95,Math.abs(direction)*.28)*m.dive,height};
}

// Articulate the original skin, so the same rig also deforms its fitted shirt.
// Reset every controlled joint before applying offsets; no rotation accumulates.
export function createFootballPose(model){
 const bones=new Map(),base=new Map(),axis=new T.Vector3(),parentQ=new T.Quaternion(),worldQ=new T.Quaternion(),delta=new T.Quaternion();
 model.traverse(o=>{if(o.isSkinnedMesh&&!o.userData.cosmetic)for(const b of o.skeleton.bones)bones.set(b.name.replace(/^mixamorig:?/,''),b);});
 for(const [name,b]of bones)base.set(name,b.quaternion.clone());
 const root=model.position.clone(),samples=[];
 model.traverse(mesh=>{
  if(!mesh.isSkinnedMesh||mesh.userData.cosmetic)return;
  const {skinIndex,skinWeight,position}=mesh.geometry.attributes,indices=[];
  for(let i=0;i<position.count;i++){
   let weight=0;for(let j=0;j<4;j++)if(/Left(Foot|ToeBase|Toe_End)$/.test(mesh.skeleton.bones[skinIndex.getComponent(i,j)]?.name??''))weight+=skinWeight.getComponent(i,j);
   if(weight>.55)indices.push(i);
  }
  if(indices.length)samples.push({mesh,indices:Array.from({length:Math.min(64,indices.length)},(_,i)=>indices[Math.floor(i*indices.length/Math.min(64,indices.length))])});
 });
 const vertex=new T.Vector3(),actorPosition=new T.Vector3();
 function sole(){model.updateMatrixWorld(true);let y=Infinity;for(const {mesh,indices}of samples){mesh.skeleton.update();for(const i of indices){vertex.fromBufferAttribute(mesh.geometry.attributes.position,i);mesh.applyBoneTransform(i,vertex);mesh.localToWorld(vertex);y=Math.min(y,vertex.y);}}model.parent.getWorldPosition(actorPosition);return y-actorPosition.y;}
 const ground=sole();
 function turn(name,x,y,z,angle){const b=bones.get(name);if(!b||Math.abs(angle)<1e-8)return;model.updateWorldMatrix(true,false);model.getWorldQuaternion(worldQ);b.parent.getWorldQuaternion(parentQ);axis.set(x,y,z).applyQuaternion(worldQ).applyQuaternion(parentQ.invert()).normalize();delta.setFromAxisAngle(axis,angle);b.quaternion.premultiply(delta);b.updateMatrixWorld(true);}
 return {bones,withRest(action){
  // Clothes are authored in natural rest, not in the middle of a kick/dive.
  // Binding is synchronous: restore the exact visible pose before drawing.
  const saved=new Map([...bones].map(([name,b])=>[name,b.quaternion.clone()])),position=model.position.clone();
  try{for(const [name,b]of bones)b.quaternion.copy(base.get(name));model.position.copy(root);model.updateMatrixWorld(true);return action();}
  finally{for(const [name,b]of bones)b.quaternion.copy(saved.get(name));model.position.copy(position);model.updateMatrixWorld(true);model.userData.cosmetics?.userData.updateSleeves?.();}
 },update(time,{role='striker',seconds=null,result=null}={}){
  for(const [name,b]of bones)b.quaternion.copy(base.get(name));model.position.copy(root);
  const ready=seconds===null,m=ready?null:shotPresentation(seconds,result);
  turn('Spine2',1,0,0,.009*Math.sin(time*2.1));
  if(role==='keeper'){
   const guard=ready?.35:.35+.38*(m.dive);
   turn('LeftArm',0,0,1,guard);turn('RightArm',0,0,1,-guard);
   turn('LeftForeArm',1,0,0,-.24);turn('RightForeArm',1,0,0,-.24);
   turn('LeftUpLeg',1,0,0,.07);turn('RightUpLeg',1,0,0,.07);
   turn('LeftLeg',1,0,0,-.1);turn('RightLeg',1,0,0,-.1);
   if(m){turn('Spine2',0,0,1,-(result.keeper.x-.5)*.16*m.dive);turn('LeftArm',1,0,0,-.25*m.dive);turn('RightArm',1,0,0,-.25*m.dive);}
  }else if(m){
   turn('RightUpLeg',1,0,0,.48*m.kickBack-.75*m.kickForward);
   turn('RightLeg',1,0,0,-.45*m.kickBack-.12*m.kickForward);
   turn('RightFoot',1,0,0,.2*m.kickForward);
   turn('Spine2',1,0,0,.06*m.kickBack+.1*m.kickForward);
   turn('LeftArm',0,0,1,.14*m.kickForward+.62*m.celebrate);
   turn('RightArm',0,0,1,-.14*m.kickForward-.62*m.celebrate);
   turn('Head',0,1,0,.055*m.celebrate*Math.sin(time*7));
  }
  const lowest=sole();if(Number.isFinite(lowest)&&Number.isFinite(ground)&&!(role==='keeper'&&m?.dive>.05)){
   model.parent.getWorldScale(vertex);model.position.y+=(ground-lowest)/Math.max(.0001,vertex.y);
  }
  model.updateMatrixWorld(true);model.userData.cosmetics?.userData.updateSleeves?.();
 },dispose(){for(const [name,b]of bones)b.quaternion.copy(base.get(name));model.position.copy(root);}};
}
