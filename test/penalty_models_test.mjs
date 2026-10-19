import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import * as T from '../assets/runner/vendor/three.module.js';
import {loadPet,runtimeUrl} from './three-runtime.mjs';
const {GLTFLoader}=await import(runtimeUrl('../assets/runner/vendor/loaders/GLTFLoader.js',{preserveModuleIdentity:true}));
const {PenaltyScene}=await import(runtimeUrl('../assets/runner/penalties/scene.js',{preserveModuleIdentity:true}));
test('all four original mascots can load their real football shirts',async()=>{
 const load=GLTFLoader.prototype.loadAsync,fetch=globalThis.fetch;
 GLTFLoader.prototype.loadAsync=async path=>loadPet(path.includes('/play-models/')?path.split('/play-models/')[1]:'../accessories/'+path.split('/accessories/')[1]);
 globalThis.fetch=async path=>({ok:true,json:async()=>JSON.parse(readFileSync(new URL(path),'utf8'))});
 try{
  for(const species of ['penguin','bear','pig','chick']){
   const stage={actors:[new T.Group(),new T.Group()],mixers:[]};
   try{await PenaltyScene.prototype.load.call(stage,[species,species]);}
   catch(cause){const error=new Error(cause.message);error.stack='Penalty scene load: '+cause.message;throw error;}
   for(const actor of stage.actors){
    const model=actor.children[0];assert.equal(model.userData.species,species);
    assert.ok(model.userData.cosmetics.children.length>0);
    const motion=model.userData.footballPose;assert.ok(motion);
    const result={kind:'goal',shot:{x:.8,y:.7},keeper:{x:.2,y:.5},side:0};
    motion.update(0,{role:'striker',seconds:null});
    const leg=motion.bones.get('RightUpLeg'),base=leg.quaternion.clone();
    const scales=new Map();model.traverse(o=>scales.set(o.uuid,o.scale.clone()));
    motion.update(.45,{role:'striker',seconds:.45,result});assert.ok(leg.quaternion.angleTo(base)>.2,'Articulated kick');
    const pose=leg.quaternion.clone();for(let i=0;i<100;i++)motion.update(.45,{role:'striker',seconds:.45,result});
    assert.ok(leg.quaternion.toArray().every((v,i)=>Math.abs(v-pose.toArray()[i])<1e-7),'No accumulated rotation');
    let sharesSkin=false;model.userData.cosmetics.traverse(o=>{if(o.isSkinnedMesh&&o.skeleton.bones.includes(leg))sharesSkin=true;});
    assert.ok(sharesSkin,'Shirt uses the same moving original joints');
    model.traverse(o=>assert.ok(o.scale.distanceTo(scales.get(o.uuid))<1e-8,'No body scaling'));
    motion.update(1,{role:'keeper',seconds:1,result});
    assert.ok(motion.bones.get('LeftArm').quaternion.toArray().every(Number.isFinite));
    motion.dispose();
   }
   Object.assign(stage,{role:0,side:0,progress:null,target:new T.Vector3(),camera:new T.PerspectiveCamera(56,1.8,.1,120),gloves:new T.Group(),ball:new T.Object3D(),aim:new T.Object3D(),renderer:{render(){}},scene:new T.Scene(),contactShadows:[]});
   stage.gloves.add(new T.Object3D(),new T.Object3D());stage.camera.add(stage.gloves);
   for(const side of [0,1]){
    PenaltyScene.prototype.setTurn.call(stage,0,side);
    if(side===0){stage.camera.updateMatrixWorld(true);const center=new T.Vector3(0,1.2,0).project(stage.camera);assert.ok(Math.abs(center.x)<1e-8,'Goal is centered from the striker viewpoint');assert.equal(stage.camera.position.x,0);}
    const result={kind:'save',side:0,shot:{x:.8,y:.9,power:.7},keeper:{x:.8,y:.9}};
    PenaltyScene.prototype.animate.call(stage,result,0);
    PenaltyScene.prototype.draw.call(stage,.9,1/60,{x:.5,y:.5});
    if(side===1){assert.ok(stage.camera.position.y>1.7,'Keeper camera jumps');assert.ok(stage.camera.position.x>0,'Keeper camera follows the dive');}
    PenaltyScene.prototype.draw.call(stage,1.24,1/60,{x:.5,y:.5});
    const hands=['LeftHand','RightHand'].map(n=>stage.actors[1].children[0].userData.footballPose.bones.get(n).getWorldPosition(new T.Vector3()));
    assert.ok(hands.some(p=>p.distanceTo(stage.ball.position)<1e-4),'Saved ball stops at an articulated glove in either view');
    if(side===1)stage.gloves.children.forEach((g,i)=>assert.ok(g.getWorldPosition(new T.Vector3()).distanceTo(hands[i])<1e-5,'First-person gloves share the visible keeper hand position'));
   }
  }
 }finally{GLTFLoader.prototype.loadAsync=load;globalThis.fetch=fetch;}
});
