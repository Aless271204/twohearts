import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

// Editable room variant. The supplied GLB, face, torso and accessory rig remain.
export function refinePip(model) {
  const bones={};model.traverse(node=>{if(node.isBone)bones[node.name.replace(/^mixamorig:?/,'')]=node;});
  model.updateMatrixWorld(true);
  const hidden=/(Arm|ForeArm|Hand|Hand.*|Foot|ToeBase|Toe_End)$/;
  model.traverse(mesh=>{
    if(!mesh.isSkinnedMesh)return;
    const geometry=mesh.geometry.clone(),joints=geometry.attributes.skinIndex,weights=geometry.attributes.skinWeight;
    const coverage=index=>{let value=0;for(let k=0;k<4;k++)if(hidden.test(mesh.skeleton.bones[joints.getComponent(index,k)]?.name??''))value+=weights.getComponent(index,k);return value;};
    const index=geometry.index,kept=[];
    mesh.skeleton.update();
    const points=[];
    for(let i=0;i<geometry.attributes.position.count;i++){
      const point=new THREE.Vector3().fromBufferAttribute(geometry.attributes.position,i);
      mesh.applyBoneTransform(i,point);mesh.localToWorld(point);model.worldToLocal(point);points.push(point);
    }
    for(let i=0;i<(index?.count??geometry.attributes.position.count);i+=3){
      const triangle=[0,1,2].map(k=>index?index.getX(i+k):i+k);
      const center=triangle.reduce((sum,v)=>sum.add(points[v]),new THREE.Vector3()).multiplyScalar(1/3);
      const oldLimb=center.y<.105||(center.y<.525&&center.y>.08&&Math.abs(center.x)>.215+.018*Math.sin((center.y-.08)/.445*Math.PI));
      if(!oldLimb&&triangle.reduce((sum,v)=>sum+coverage(v),0)/3<.35)kept.push(...triangle);
    }
    geometry.setIndex(kept);mesh.geometry=geometry;
    const soften=source=>{const material=source.clone();material.metalness=0;material.roughness=.85;material.normalMap=null;material.roughnessMap=null;return material;};
    mesh.material=Array.isArray(mesh.material)?mesh.material.map(soften):soften(mesh.material);
  });
  const dark=new THREE.MeshStandardMaterial({color:'#30303d',roughness:.78});
  const orange=new THREE.MeshStandardMaterial({color:'#ffa61f',roughness:.48});
  function attach(mesh,bone,position){
    if(!bone)return;
    const worldPosition=model.localToWorld(new THREE.Vector3(...position));
    const worldRotation=model.getWorldQuaternion(new THREE.Quaternion());
    const worldScale=model.getWorldScale(new THREE.Vector3());
    const matrix=new THREE.Matrix4().compose(worldPosition,worldRotation,worldScale);
    bone.add(mesh);bone.updateWorldMatrix(true,false);
    matrix.premultiply(bone.matrixWorld.clone().invert());matrix.decompose(mesh.position,mesh.quaternion,mesh.scale);
  }
  // Close the original limb sockets from inside, keeping the painted belly visible.
  const liningGeometry=new THREE.SphereGeometry(1,24,16);liningGeometry.scale(.22,.245,.17);
  const lining=new THREE.Mesh(liningGeometry,dark);lining.name='RoundedTorsoLining';
  attach(lining,bones.Spine2,[0,.29,-.025]);
  for(const [side,sign] of [['Left',1],['Right',-1]]){
    const wingGeometry=new THREE.SphereGeometry(1,20,14);
    wingGeometry.scale(.08,.158,.068);wingGeometry.rotateZ(sign*.32);
    const wing=new THREE.Mesh(wingGeometry,dark);wing.name=side+'RoundedWing';
    attach(wing,bones.Spine2,[sign*.257,.387,.025]);
    const parts=[];
    const heel=new THREE.SphereGeometry(1,16,10);heel.scale(.073,.06,.065);heel.translate(0,.06,.02);parts.push(heel);
    for(let toe=-1;toe<=1;toe++){
      const shape=new THREE.SphereGeometry(1,16,10);shape.scale(.034,.034,toe===0?.06:.052);
      shape.translate(toe*.048,.034,.065+(toe===0?.008:0));parts.push(shape);
    }
    const foot=new THREE.Mesh(mergeGeometries(parts),orange);foot.name=side+'RoundedFoot';
    for(const part of parts)part.dispose();
    attach(foot,bones[side+'Foot'],[sign*.11,0,-.015]);
    // A short feathered ankle overlaps the heel and the body, closing the join.
    const ankleGeometry=new THREE.SphereGeometry(1,16,12);ankleGeometry.scale(.059,.064,.065);
    const ankle=new THREE.Mesh(ankleGeometry,dark);ankle.name=side+'FeatheredAnkle';
    attach(ankle,bones[side+'Foot'],[sign*.11,.125,.005]);
  }
  model.userData.delicatePip=true;model.updateMatrixWorld(true);
}
