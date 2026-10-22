import test from 'node:test';
import assert from 'node:assert/strict';
import {SnowView} from '../assets/runner/snow/view.js';
import {newArena} from '../assets/runner/snow/engine.js';

test('snow scenery is drawn once, refreshed for maps and late image loading',()=>{
 const previousImage=globalThis.Image,previousDocument=globalThis.document;
 const contexts=[];
 function canvas(){
  const calls={gradients:0,images:0};
  const context=new Proxy(calls,{get(target,key){if(key in target)return target[key];if(key==='createLinearGradient'||key==='createRadialGradient')return ()=>{target.gradients++;return {addColorStop(){}};};if(key==='drawImage')return ()=>target.images++;return ()=>{};}});
  contexts.push(context);return {getContext:()=>context};
 }
 try{
  globalThis.Image=class{complete=false;naturalWidth=0;};
  globalThis.document={createElement:()=>canvas()};
  const view=new SnowView(canvas(),canvas()),scenery=contexts[2],back=contexts[0];
  const state=newArena(0,[{id:'a'},{id:'b'}]);state.players[0].buffs.shield=10;state.players[1].rescue=1;state.shots=[{x:250,y:200,vx:150,vy:0,r:12,type:'super'}];
  view.draw(state,1);const initial=scenery.gradients;assert.ok(initial>0);
  for(let i=0;i<90;i++)view.draw(state,2+i/30);
  assert.equal(scenery.gradients,initial,'static shadows/platforms must not redraw each frame');
  assert.equal(back.images,91,'cached scenery still composites each frame');
  state.map=1;view.draw(state,6);assert.ok(scenery.gradients>initial);
  const afterMap=scenery.gradients;
  view.background.complete=true;view.background.naturalWidth=1280;view.background.onload();
  view.draw(state,7);assert.ok(scenery.gradients>afterMap);assert.equal(scenery.images,1);
 }finally{globalThis.Image=previousImage;globalThis.document=previousDocument;}
});
