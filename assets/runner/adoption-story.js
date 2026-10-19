const params=new URLSearchParams(location.search),species=['penguin','bear','pig','chick'].includes(params.get('species'))?params.get('species'):'penguin';
const preview=params.get('preview')==='1',reduced=matchMedia('(prefers-reduced-motion: reduce)').matches;
const asset=name=>new URL('../images/ui/'+name,import.meta.url).href;
export const storyFrames=[
 {src:asset(`adoption-${species}-0-v3.webp`),title:'Una pequeña compañía viene en camino…',detail:'La cigüeña ya encontró su Nido.',seconds:4},
 {src:asset(`adoption-${species}-1-v3.webp`),title:'Aquí empieza su hogar',detail:'Un lugar calentito y mucho cariño.',seconds:4},
 {src:asset(`adoption-${species}-2-v3.webp`),title:'Crecer con ustedes',detail:'Cada momento juntos deja una huellita.',seconds:3.5},
 {src:asset(`adoption-${species}-3-v3.webp`),title:'¡Bienvenida a la familia!',detail:'Su mascota los espera en la habitación.',seconds:4},
];
const style=document.createElement('style');style.textContent=`
.story{height:100dvh;display:flex;flex-direction:column;box-sizing:border-box;padding:12px max(12px,env(safe-area-inset-right)) max(12px,env(safe-area-inset-bottom));background:radial-gradient(ellipse at top,#fffdf3,#fbe9df);color:#593f3d}
.story button{font:600 14px system-ui;border:1px solid #dbc7bd;background:#fff9f1;color:#644841;border-radius:22px;min-height:44px;padding:10px 16px;cursor:pointer}.story button:disabled{opacity:.5;cursor:default}.story button:focus-visible{outline:3px solid #bb5770;outline-offset:3px}
.story-top{display:flex;justify-content:space-between;align-items:center;gap:12px;flex-shrink:0;font:600 13px system-ui}.story-top button{padding:8px 12px}.story-stage{flex:1;min-height:0;display:grid;place-items:center;position:relative;margin:10px 0;overflow:hidden;border-radius:24px}.story-stage img{grid-area:1/1;max-width:100%;max-height:100%;width:100%;height:100%;object-fit:contain;opacity:0;transition:opacity .65s ease;pointer-events:none}.story-stage img.shown{opacity:1}.story-stage img.zoom{animation:story-zoom 4.5s ease-out both}@keyframes story-zoom{from{transform:scale(.985)}to{transform:scale(1.015)}}
.story-copy{text-align:center;flex-shrink:0}.story-copy h1{font:600 clamp(18px,4.5vw,25px) Georgia,serif;margin:2px 0 6px;line-height:1.18}.story-copy p{font:400 13px system-ui;margin:0 0 10px;line-height:1.4;color:#775b54}.story-controls{display:flex;align-items:center;justify-content:center;gap:8px;flex-wrap:wrap}.story-controls .main{background:#e85677;color:white;border-color:#e85677;box-shadow:0 3px 8px #9f52602b}.story-progress{display:flex;gap:5px;justify-content:center;margin:10px 0 4px}.story-progress span{height:4px;width:25px;border-radius:6px;background:#d8c7b9}.story-progress span.active{background:#d95775}.story-error{font:400 13px system-ui;text-align:center;color:#85443f;margin:5px}.story-leaving{opacity:0;transition:opacity .45s ease}
@media(orientation:landscape) and (max-height:600px){.story{display:grid;grid-template-columns:1.25fr 1fr;grid-template-rows:auto 1fr;column-gap:16px}.story-top{grid-column:1/3}.story-stage{grid-column:1;grid-row:2;margin:8px 0 0}.story-copy{grid-column:2;grid-row:2;align-self:center}.story-copy h1{font-size:24px}.story-controls{gap:6px}.story-controls button{padding:10px 13px}.story-progress{margin-top:18px}}
@media(prefers-reduced-motion:reduce){.story-stage img{transition:opacity .12s}.story-stage img.zoom{animation:none}.story-leaving{transition:none}}
`;
document.head.append(style);
const root=document.createElement('main');root.className='story';
root.innerHTML='<header class="story-top"><span>Un nuevo Nido ♡</span><button id="story-sound" aria-pressed="false">Activar sonido</button></header><section class="story-stage" aria-label="Llegada de su mascota"><img id="story-a" alt=""><img id="story-b" alt=""></section><section class="story-copy"><h1 id="story-title" aria-live="polite"></h1><p id="story-detail"></p><div class="story-controls"><button id="story-back" aria-label="Imagen anterior">‹</button><button id="story-pause">Pausar</button><button id="story-next" class="main">Siguiente ›</button></div><div class="story-progress" aria-label="Progreso de la bienvenida"></div><p class="story-error" id="story-error" hidden></p></section>';
document.getElementById('loading')?.remove();document.getElementById('caption')?.remove();document.body.append(root);
const $=id=>document.getElementById(id),images=[$('story-a'),$('story-b')],dots=root.querySelector('.story-progress');
storyFrames.forEach(()=>dots.append(document.createElement('span')));
const voice=new Audio(new URL(`../sounds/adoption_baby_${species}_v3.mp3`,import.meta.url).href);voice.preload='auto';voice.volume=.43;
let index=-1,visible=1,elapsed=0,last=performance.now(),paused=false,muted=false,audible=false,finished=false,raf=0;
function labelSound(){const b=$('story-sound');b.textContent=muted?'Activar sonido':audible?'Silenciar':'Activar sonido';b.setAttribute('aria-pressed',String(!muted&&audible));}
async function baby(){if(muted||document.hidden||finished)return;try{voice.currentTime=0;await voice.play();audible=true;}catch{audible=false;}labelSound();}
function show(next){
 index=Math.max(0,Math.min(storyFrames.length-1,next));elapsed=0;const frame=storyFrames[index];visible=1-visible;
 images[visible].src=frame.src;images[visible].alt=frame.title;images[visible].className='shown'+(!reduced?' zoom':'');images[1-visible].className='';
 $('story-title').textContent=frame.title;$('story-detail').textContent=frame.detail;$('story-back').disabled=index===0;
 $('story-next').textContent=index===storyFrames.length-1?(preview?'Ver de nuevo':'Entrar al Nido'):'Siguiente ›';
 [...dots.children].forEach((dot,i)=>dot.classList.toggle('active',i<=index));
 if(index===0||index===2)baby();
}
function finish(){if(finished)return;if(preview){show(0);return;}finished=true;voice.pause();cancelAnimationFrame(raf);root.classList.add('story-leaving');setTimeout(()=>{const message=JSON.stringify({type:'runner-exit'});if(globalThis.RunnerBridge)globalThis.RunnerBridge.postMessage(message);else if(parent!==window)parent.postMessage(message,location.origin);},reduced?0:460);}
function advance(){if(index<storyFrames.length-1)show(index+1);else finish();}
$('story-back').onclick=()=>show(index-1);$('story-next').onclick=advance;
$('story-pause').onclick=()=>{paused=!paused;$('story-pause').textContent=paused?'Continuar':'Pausar';if(paused)voice.pause();};
$('story-sound').onclick=()=>{if(audible&&!muted){muted=true;voice.pause();labelSound();}else{muted=false;baby();}};
function frame(now){raf=requestAnimationFrame(frame);const dt=Math.min(.1,(now-last)/1000);last=now;if(paused||document.hidden||finished)return;elapsed+=dt;if(elapsed>=storyFrames[index].seconds)advance();}
globalThis.runnerSuspend=()=>{paused=true;voice.pause();$('story-pause').textContent='Continuar';};
document.addEventListener('visibilitychange',()=>{last=performance.now();if(document.hidden)voice.pause();});
addEventListener('pagehide',()=>{finished=true;cancelAnimationFrame(raf);voice.pause();voice.removeAttribute('src');voice.load();},{once:true});
const decoded=await Promise.allSettled(storyFrames.map(frame=>{const img=new Image();img.src=frame.src;return img.decode();}));
if(decoded.some(r=>r.status==='rejected')){$('story-error').hidden=false;$('story-error').textContent='Una imagen no pudo cargarse. Puedes continuar a la habitación.';}
show(0);raf=requestAnimationFrame(frame);
