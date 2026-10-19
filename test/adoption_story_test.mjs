import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
const moduleUrl=new URL('../assets/runner/adoption-story.js',import.meta.url).href;
const source=fs.readFileSync(new URL(moduleUrl),'utf8').replace('export const storyFrames','const storyFrames').replaceAll('import.meta.url','moduleUrl');
const AsyncFunction=Object.getPrototypeOf(async function(){}).constructor;
test('adoption shows only its species sequence and exits once, independently of login welcome',async()=>{
 for(const species of ['penguin','bear','pig','chick']){
  const elements=new Map(),events=new Map(),messages=[],progress={children:[],append(x){this.children.push(x);}};
  const element=()=>({style:{},className:'',disabled:false,hidden:false,setAttribute(){},remove(){},classList:{add(){},toggle(){}},append(){},querySelector:()=>progress});
  const document={hidden:false,head:{append(){}},body:{append(){}},createElement:element,getElementById(id){if(!elements.has(id))elements.set(id,element());return elements.get(id);},addEventListener(name,fn){events.set(name,fn);}};
  const globals={RunnerBridge:{postMessage(m){messages.push(JSON.parse(m));}}};
  class Audio{constructor(url){assert.ok(fs.existsSync(new URL(url)));}async play(){}pause(){}load(){}removeAttribute(){}}
  const args={moduleUrl,document,location:{search:'?species='+species+'&arrival=1',origin:'http://localhost'},matchMedia:()=>({matches:true}),Image:class{async decode(){}},Audio,globalThis:globals,parent:{},window:{},addEventListener(name,fn){events.set(name,fn);},requestAnimationFrame:()=>1,cancelAnimationFrame(){},setTimeout(fn){fn();return 1;}};
  const frames=await new AsyncFunction(...Object.keys(args),source+';return storyFrames;')(...Object.values(args));
  assert.equal(frames.length,4);
  for(const f of frames){assert.match(f.src,new RegExp('adoption-'+species));assert.ok(fs.existsSync(new URL(f.src)));}
  for(let i=0;i<4;i++)elements.get('story-next').onclick();
  assert.deepEqual(messages,[{type:'runner-exit'}]);elements.get('story-next').onclick();assert.equal(messages.length,1);
  events.get('pagehide')();
 }
});
