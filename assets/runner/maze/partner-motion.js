import * as T from 'three';
import {createNaturalRest} from '../pet-rest-pose.js';
import {keepJumpFacingForward} from '../pet-jump-heading.js';

export function createMazePartnerMotion(model,animations){
 const restClip=createNaturalRest(model),walkClip=keepJumpFacingForward(model,animations.find(c=>c.name==='Walking'));
 if(!walkClip)throw Error('No se encontró el paso de la mascota');
 const mixer=new T.AnimationMixer(model),rest=mixer.clipAction(restClip),walk=mixer.clipAction(walkClip);rest.play();walk.play().setEffectiveWeight(0);
 let weight=0;
 return {update(dt,speed=0,fallen=false){
  weight+=((fallen?0:Math.min(1,speed/1.3))-weight)*(1-Math.exp(-dt*12));
  // Distance, rather than frame rate, drives the pace of the imported walk.
  walk.timeScale=Math.max(.18,Math.min(2,speed/2.3));
  rest.setEffectiveWeight(1-weight);walk.setEffectiveWeight(weight);mixer.update(dt);
  model.rotation.z+=( (fallen?-.9:0)-model.rotation.z)*(1-Math.exp(-dt*7));
 },get walkingWeight(){return weight;},dispose(){mixer.stopAllAction();mixer.uncacheRoot(model);}};
}
