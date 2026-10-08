const http=require('node:http');
const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');
const {chromium}=require('C:/Users/Lenovo/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const root=path.resolve(__dirname,'../assets/runner');
const server=http.createServer((req,res)=>{
  const file=path.resolve(root,'.'+decodeURIComponent(req.url.split('?')[0]));
  if(!file.startsWith(root+path.sep)){res.writeHead(403);res.end();return;}
  fs.readFile(file,(error,bytes)=>{if(error){res.writeHead(404);res.end();return;}
    res.setHeader('Content-Type',file.endsWith('.js')?'text/javascript':file.endsWith('.html')?'text/html':file.endsWith('.json')?'application/json':file.endsWith('.jpg')?'image/jpeg':file.endsWith('.mp4')?'video/mp4':'application/octet-stream');res.end(bytes);});
});
(async()=>{
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));let browser;
  try{
    browser=await chromium.launch({channel:'chrome',headless:true,args:['--enable-webgl','--disable-background-timer-throttling','--disable-renderer-backgrounding','--disable-backgrounding-occluded-windows']});
    const page=await browser.newPage({viewport:{width:390,height:844}});const errors=[],models=[];page.on('pageerror',e=>errors.push(e.message));
    page.on('request',request=>{if(request.url().endsWith('.glb'))models.push(request.url());});
    await page.goto(`http://127.0.0.1:${server.address().port}/index.html`);
    await page.waitForFunction(()=>!document.getElementById('start').disabled,{},{timeout:60000});
    await page.waitForFunction(()=>window.runnerPreview.stats().videoTime>0,{},{timeout:30000});
    await page.evaluate(()=>document.getElementById('start').click());
    await page.waitForTimeout(600);
    console.log('Started',JSON.stringify(await page.evaluate(()=>({state:window.runnerPreview.stats(),hidden:document.hidden,title:document.getElementById('title').textContent}))));
    await page.waitForFunction(()=>window.runnerPreview.stats().distance>50,{},{timeout:60000});
    await page.screenshot({path:path.resolve(__dirname,'../tropical-preview.png')});
    const stats=await page.evaluate(()=>window.runnerPreview.stats());assert.ok(stats.triangles<80000);assert.equal(models.length,4);
    await page.evaluate(()=>document.getElementById('left').click());await page.waitForFunction(()=>window.runnerPreview.stats().lane===0);
    await page.evaluate(()=>document.getElementById('right').click());await page.waitForFunction(()=>window.runnerPreview.stats().lane===1);
    await page.evaluate(()=>document.getElementById('jump').click());await page.waitForFunction(()=>window.runnerPreview.stats().height>0);
    await page.evaluate(()=>document.getElementById('pause').click());await page.waitForFunction(()=>window.runnerPreview.stats().paused);
    const paused=await page.evaluate(()=>window.runnerPreview.stats());await page.waitForTimeout(300);
    const frozen=await page.evaluate(()=>window.runnerPreview.stats());assert.equal(frozen.distance,paused.distance);assert.equal(frozen.sceneryTime,paused.sceneryTime);
    assert.ok(frozen.videoPaused);assert.ok(Math.abs(frozen.videoTime-paused.videoTime)<.12);
    await page.evaluate(()=>document.getElementById('start').click());await page.waitForFunction(()=>!window.runnerPreview.stats().paused);
    await page.waitForFunction(()=>!window.runnerPreview.stats().running,{},{timeout:60000});
    const finish=await page.evaluate(()=>window.runnerPreview.stats());assert.ok(finish.coins>0);assert.ok(finish.distance>90&&finish.distance<100);
    console.log(JSON.stringify({errors,models:models.length,stats,finish,checks:'lane changes, jump, pause, collision and coin collection passed'}));
    if(errors.length)process.exitCode=1;
  }finally{await browser?.close();server.close();}
})().catch(error=>{console.error(error);process.exitCode=1;server.close();});
