import {chromium} from 'file:///C:/Users/Lenovo/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright/index.mjs';
import {mkdir,writeFile} from 'node:fs/promises';
const output=new URL('../outputs/wardrobe-qa-20261014/',import.meta.url);await mkdir(output,{recursive:true});
const browser=await chromium.launch({headless:true,executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',args:[]});
const context=await browser.newContext({viewport:{width:1100,height:1500}});const page=await context.newPage();const results=[];let errors=[];
page.on('pageerror',e=>errors.push(e.message));
page.on('response',r=>{if(r.status()>=400&&!r.url().endsWith('/favicon.ico'))errors.push(r.status()+' '+r.url());});
try{
 for(const outfit of ['dulce','cozy','jardin','chic','pastel']){
  for(const species of ['penguin','bear','pig','chick'])for(const [angle,motion] of [[0,''],[90,''],[180,''],[40,'Wardrobe_Run'],[40,'Natural_Jump']]){
   errors=[];const name=outfit+'-'+species+'-'+angle+'-'+(motion||'rest');
   await page.goto('http://127.0.0.1:58104/assets/runner/wardrobe-outfit-review.html?'+new URLSearchParams({outfit,angle:String(angle),motion,live:'0',phase:'.5',species}),{waitUntil:'domcontentloaded'});
   try{await page.waitForFunction(()=>[...document.querySelectorAll('.readiness')].length===1&&[...document.querySelectorAll('.readiness')].every(e=>e.textContent.includes('Vista lista')),{},{timeout:90000});}catch(error){await page.screenshot({path:new URL('failed.png',output).pathname.replace(/^\//,''),fullPage:true});await writeFile(new URL('failure.json',output),JSON.stringify({error:String(error),errors,frames:await Promise.all(page.frames().map(async f=>({url:f.url(),body:await f.locator('body').innerText().catch(()=>'' )})))},null,2));throw error;}
   for(const frame of page.frames().slice(1))await frame.waitForFunction(()=>getComputedStyle(document.querySelector('canvas')).opacity==='1',{},{timeout:5000});
   await page.screenshot({path:new URL(name+'.png',output).pathname.replace(/^\//,''),fullPage:true});
   results.push({outfit,angle,motion:motion||'rest',species,ready:1,errors:[...errors]});console.log(name, errors.length?'FAIL':'READY');
   await writeFile(new URL('results.json',output),JSON.stringify(results,null,2));
  }
 }
}finally{await browser.close();}
if(results.some(r=>r.errors.length))process.exitCode=1;
