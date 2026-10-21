import test from 'node:test';import assert from 'node:assert/strict';import fs from 'node:fs';
import * as engine from '../assets/runner/maze/engine.js';import * as navigation from '../assets/runner/maze/navigation.js';
const html=fs.readFileSync(new URL('../assets/runner/maze/index.html',import.meta.url),'utf8'),ids=new Set([...html.matchAll(/id="([^"]+)"/g)].map(m=>m[1]));
const source=fs.readFileSync(new URL('../assets/runner/maze/main.js',import.meta.url),'utf8').replace(/^import .+;\r?\n/gm,'').replace(/^export /gm,'');
const AsyncFunction=Object.getPrototypeOf(async function(){}).constructor;
test('maze opens despite blocked storage, explains its goal before movement and renders on successive display frames',async()=>{
 const elements=new Map(),context={clearRect(){},fillRect(){},beginPath(){},arc(){},fill(){}};
 const element=id=>{assert.ok(ids.has(id),'Missing real UI element: '+id);if(!elements.has(id))elements.set(id,{hidden:true,value:id==='difficulty'?'easy':id==='theme'?'halloween':'45',textContent:'',style:{},setAttribute(){},getContext:()=>context});return elements.get(id);};
 let frame;const scenes=[];
 class Stage{constructor(){this.yaw=0;this.pitch=0;this.draws=0;scenes.push(this);}draw(){this.draws++;}dispose(){}}
 class SceneSound{async unlock(){return false;}start(){}effect(){return false;}pause(){}close(){}volumes(){}}
 const storage={getItem(){throw Error('Storage unavailable');},setItem(){throw Error('Storage unavailable');},removeItem(){throw Error('Storage unavailable');}};
 const document={getElementById:element,addEventListener(){},hidden:false};
 const params={...engine,...navigation,MazeScene:Stage,SceneSound,Image:class{},AudioContext:class{constructor(){throw Error('Audio unavailable');}},document,sessionStorage:storage,window:globalThis,parent:globalThis,location:{origin:'http://localhost',search:''},crypto:{getRandomValues(a){a[0]=17;return a;}},addEventListener(){},requestAnimationFrame(f){frame=f;return 1;},cancelAnimationFrame(){},setInterval(){return 1;},clearInterval(){},setTimeout(){return 1;},clearTimeout(){}};
 await new AsyncFunction(...Object.keys(params),source)(...Object.values(params));
 assert.match(element('load').textContent,/linterna/);
 await element('solo').onclick();assert.equal(element('helpPanel').hidden,false);assert.match(element('objective').textContent,/0\/3/);
 await element('begin').onclick();assert.equal(element('helpPanel').hidden,true);assert.equal(element('progress').hidden,false);assert.equal(element('district').hidden,false);
 frame(1000);frame(1016.7);assert.equal(scenes[0].draws,2,'No hard-coded 30fps skip');
 element('help').onclick();assert.equal(element('helpPanel').hidden,false);
 await element('exit').onclick();assert.equal(element('menu').hidden,false);
});
