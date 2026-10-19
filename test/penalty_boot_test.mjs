import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import * as rules from '../assets/runner/penalties/rules.js';
const AsyncFunction=Object.getPrototypeOf(async function(){}).constructor;
const source=fs.readFileSync(new URL('../assets/runner/penalties/main.js',import.meta.url),'utf8').replace(/^import .+;\r?\n/gm,'');
async function boot({storageBlocked=false,assetFailure=false}={}){
 const elements=new Map();const element=id=>{
  if(!elements.has(id))elements.set(id,{hidden:false,disabled:false,value:'70',style:{},textContent:'',classList:{toggle(){}},getBoundingClientRect:()=>({left:0,top:0,width:116,height:116})});
  return elements.get(id);
 };
 const storage={getItem(){if(storageBlocked)throw new Error('Access to sessionStorage denied');return null;},setItem(){if(storageBlocked)throw new Error('Storage disabled');},removeItem(){if(storageBlocked)throw new Error('Storage disabled');}};
 class Stage {async load(){if(assetFailure)throw Error('Camiseta: HTTP 404');}setTurn(){}draw(){}dispose(){}}
 let audioStarts=0;
 class Audio {enabled=false;active=false;async unlock(){this.enabled=true;}start(){this.active=true;audioStarts++;}pause(){this.active=false;}play(){}volumes(){}close(){}}
 const params={PenaltyScene:Stage,StadiumAudio:Audio,...rules,sessionStorage:storage,localStorage:storage,document:{getElementById:element,addEventListener(){},hidden:false},location:{search:'',origin:'http://localhost',reload(){}},parent:globalThis,addEventListener(){},requestAnimationFrame(){return 1;},cancelAnimationFrame(){},setTimeout(){return 1;},clearTimeout(){},console:{error(){}}};
 await new AsyncFunction(...Object.keys(params),source)(...Object.values(params));
 element.musicStarts=()=>audioStarts;return element;
}
test('blocked optional storage never prevents the stadium or training from opening',async()=>{
 const element=await boot({storageBlocked:true});
 assert.equal(element('load').textContent,'Camisetas azul y roja incluidas.');
 assert.equal(element.musicStarts(),0,'Menu stays silent');
 await element('practice').onclick();
 assert.equal(element('menu').hidden,true);
 assert.equal(element('controls').hidden,false);
 assert.equal(element('action').textContent,'PATEAR');
 assert.equal(element.musicStarts(),1,'Music starts upon entering the match');
 await element('exit').onclick();
 assert.equal(element('menu').hidden,false);
 await element('practice').onclick();
 assert.equal(element('controls').hidden,false);
});
test('a real asset failure is reported distinctly with a working retry control',async()=>{
 const element=await boot({assetFailure:true});
 assert.match(element('load').textContent,/Camiseta: HTTP 404/);
 assert.equal(element('retryLoad').hidden,false);
});
