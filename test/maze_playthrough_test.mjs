import test from 'node:test';import assert from 'node:assert/strict';import fs from 'node:fs';
import * as engine from '../assets/runner/maze/engine.js';import * as nav from '../assets/runner/maze/navigation.js';
const ids=new Set([...fs.readFileSync('assets/runner/maze/index.html','utf8').matchAll(/id="([^"]+)"/g)].map(m=>m[1]));
const source=fs.readFileSync('assets/runner/maze/main.js','utf8').replace(/^import .+;\r?\n/gm,'').replace(/^export /gm,'');
test('real input handlers reveal, rotate and solve all three lanterns, cross the bridge and finish solo',async()=>{
 const elements=new Map(),events=new Map(),context={clearRect(){},fillRect(){},beginPath(){},arc(){},fill(){}};
 class Element{constructor(id){this.hidden=true;this.value=id==='difficulty'?'easy':id==='theme'?'halloween':'45';this.style={setProperty(){}};this.children=[];}set textContent(v){this.text=v;this.children=[];}get textContent(){return this.text??'';}setAttribute(){}getContext(){return context;}appendChild(c){this.children.push(c);}setPointerCapture(){}hasPointerCapture(){return false;}}
 const element=id=>{assert.ok(ids.has(id),id);if(!elements.has(id))elements.set(id,new Element(id));return elements.get(id);};
 let frame,now=10000;
 class Stage{constructor(){this.yaw=0;this.pitch=0;this.renderer={info:{render:{calls:1},memory:{geometries:0}}};}draw(){}dispose(){}}
 class SceneSound{constructor(){this.buffers=new Map();}async unlock(){return false;}start(){}effect(){return false;}pause(){}close(){}volumes(){}}
 const args={...engine,...nav,MazeScene:Stage,SceneSound,document:{getElementById:element,createElement:()=>new Element(),addEventListener(){},hidden:false},sessionStorage:{getItem(){return null;},setItem(){},removeItem(){}},window:globalThis,parent:globalThis,location:{origin:'http://localhost',search:''},crypto:{getRandomValues(a){a[0]=17;return a;}},addEventListener(k,v){events.set(k,v);},requestAnimationFrame(f){frame=f;return 1;},cancelAnimationFrame(){},setInterval(){return 1;},clearInterval(){},setTimeout(){return 1;},clearTimeout(){}};
 const AsyncFunction=Object.getPrototypeOf(async function(){}).constructor;await new AsyncFunction(...Object.keys(args),source)(...Object.values(args));
 await element('solo').onclick();await element('begin').onclick();const snap=()=>globalThis.nidoAdventureSnapshot(),flush=()=>new Promise(setImmediate);
 function route(s,target){const p=s.players[0],q=[[p.x,p.z,[]]],seen=new Set([p.z*s.size+p.x]);for(let i=0;i<q.length;i++){const[x,z,steps]=q[i];if(x===target.x&&z===target.z)return steps;for(const[dx,dz]of[[1,0],[-1,0],[0,1],[0,-1]]){const a=x+dx,b=z+dz,n=b*s.size+a;if(a<0||b<0||a>=s.size||b>=s.size||s.grid[n]||seen.has(n))continue;seen.add(n);q.push([a,b,[...steps,[dx,dz]]]);}}throw Error('No route');}
 async function go(target){for(const [dx,dz]of route(snap().state,target)){
  let i=nav.nearbyInteraction(snap().state,0);while(i?.action==='disarm'){await element('open').onclick();i=nav.nearbyInteraction(snap().state,0);}
  if(i?.action==='activate')await element('open').onclick();
  const yaw=Math.atan2(-dx,-dz),turn=Math.atan2(Math.sin(yaw-snap().yaw),Math.cos(yaw-snap().yaw)),e={clientX:0,clientY:0,pointerId:1,currentTarget:element('look')};element('look').onpointerdown(e);element('look').onpointermove({...e,clientX:-turn/.006});element('look').onpointerup();
  events.get('keydown')({code:'KeyW',preventDefault(){}});frame(now+=400);events.get('keyup')({code:'KeyW'});await flush();
 }}
 for(let id=0;id<3;id++){await go(snap().state.chests[id]);await element('open').onclick();assert.equal(element('puzzle').hidden,false);const c=snap().state.chests[id];assert.equal(c.revealed,true);for(let n=0;n<c.pattern.length;n++)for(let j=0;j<c.pattern[n];j++)element('dials').children[n].onclick();await element('solve').onclick();assert.equal(snap().state.keys,id+1);assert.equal(element('puzzle').hidden,true);}
 await go(snap().state.exit);assert.equal(snap().state.status,'victory');assert.equal(element('result').hidden,false);assert.equal(element('district').hidden,true);assert.ok(snap().state.bridges[0].secured);
});
