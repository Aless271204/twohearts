// Records the deterministic 8-second art animation, then encodes a local H.264 loop.
const fs=require('node:fs'),path=require('node:path'),http=require('node:http'),{spawnSync}=require('node:child_process');
const runtime='C:/Users/Lenovo/.cache/codex-runtimes/codex-primary-runtime/dependencies';
const {chromium}=require(runtime+'/node/node_modules/playwright');
const root=path.resolve(__dirname,'../assets/runner');
const server=http.createServer((req,res)=>{
  if(req.url==='/record'){
    res.setHeader('Content-Type','text/html');res.end(`<style>body{margin:0}canvas{display:block}</style><script type="importmap">{"imports":{"three":"/vendor/three.module.js"}}</script><script type="module">
    import * as THREE from 'three';import {createForestBackdrop} from '/forest-backdrop.js';
    const scene=new THREE.Scene(),backdrop=createForestBackdrop(scene,{video:false}),renderer=new THREE.WebGLRenderer({preserveDrawingBuffer:true});
    renderer.setSize(540,1140);renderer.outputColorSpace=THREE.SRGBColorSpace;document.body.append(renderer.domElement);
    await backdrop.load();const camera=new THREE.Camera();window.frames=[];
    // Exact frame stepping makes the first and last frame meet without a jump.
    window.drawFrame=(i)=>{scene.children[0].material.uniforms.time.value=i/24;backdrop.update(0,540/1140,0);renderer.render(scene,camera);return renderer.domElement.toDataURL('image/png').split(',')[1];};
    window.ready=true;
    </script>`);return;
  }
  const file=path.resolve(root,'.'+decodeURIComponent(req.url.split('?')[0]));
  if(!file.startsWith(root+path.sep)){res.writeHead(403);res.end();return;}
  fs.readFile(file,(e,b)=>{if(e){res.writeHead(404);res.end();return;}res.setHeader('Content-Type',file.endsWith('.js')?'text/javascript':'image/jpeg');res.end(b);});
});
(async()=>{
  await new Promise(r=>server.listen(0,'127.0.0.1',r));let browser;
  const frames=path.resolve(__dirname,'../.tools/forest-frames');fs.mkdirSync(frames,{recursive:true});
  try{
    browser=await chromium.launch({channel:'chrome',headless:true,args:['--enable-webgl']});const page=await browser.newPage();
    await page.goto(`http://127.0.0.1:${server.address().port}/record`);await page.waitForFunction(()=>window.ready);
    for(let i=0;i<192;i++){const png=await page.evaluate(i=>window.drawFrame(i),i);fs.writeFileSync(path.join(frames,String(i).padStart(4,'0')+'.png'),Buffer.from(png,'base64'));}
    const python=runtime+'/python/python.exe';const lookup=spawnSync(python,['-c',"import sys;sys.path.insert(0,'.tools');import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())"],{encoding:'utf8',cwd:path.resolve(__dirname,'..')});
    if(lookup.status!==0)throw Error(lookup.stderr);
    const result=spawnSync(lookup.stdout.trim(),['-y','-framerate','24','-i',path.join(frames,'%04d.png'),'-c:v','libx264','-profile:v','baseline','-level','3.1','-pix_fmt','yuv420p','-crf','24','-preset','slow','-movflags','+faststart','-an',path.join(root,'forest-kingdom-loop.mp4')],{encoding:'utf8'});
    if(result.status!==0)throw Error(result.stderr);
    console.log(JSON.stringify({frames:192,duration:8,width:540,height:1140,bytes:fs.statSync(path.join(root,'forest-kingdom-loop.mp4')).size}));
  }finally{await browser?.close();server.close();}
})().catch(e=>{console.error(e);process.exitCode=1;server.close();});
