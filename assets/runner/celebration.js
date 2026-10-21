// Small canvas celebration; bounded particles, no extra 3D models or downloads.
export function celebrateVictory({sound=()=>{},reduced=globalThis.matchMedia?.('(prefers-reduced-motion: reduce)').matches}={}){
 if(reduced)return ()=>{};
 const canvas=document.createElement('canvas');canvas.setAttribute('aria-hidden','true');
 Object.assign(canvas.style,{position:'fixed',inset:'0',width:'100%',height:'100%',zIndex:'20',pointerEvents:'none'});
 canvas.width=960;canvas.height=540;document.body.append(canvas);
 const c=canvas.getContext('2d'),start=performance.now(),particles=[],colors=['#ffe8a3','#ffa3b9','#a0e7de','#d0b7ff'];let frame,burst=0,closed=false;
 function close(){if(closed)return;closed=true;cancelAnimationFrame(frame);canvas.remove();}
 function draw(now){if(closed)return;const time=(now-start)/1000;if(time>3.2||document.hidden){close();return;}
  c.clearRect(0,0,960,540);
  if(time>=burst*.55&&burst<5){const x=150+(burst*173)%660,y=90+(burst%2)*85;burst++;sound();
   for(let i=0;i<18;i++){const a=i*Math.PI/9;particles.push({x,y,vx:Math.cos(a)*(80+i%4*22),vy:Math.sin(a)*(80+i%4*22),born:time,color:colors[i%4]});}}
  for(const p of particles){const age=time-p.born;if(age>1.3)continue;c.globalAlpha=1-age/1.3;c.fillStyle=p.color;c.beginPath();c.arc(p.x+p.vx*age,p.y+p.vy*age+90*age*age,3.5,0,Math.PI*2);c.fill();}
  c.globalAlpha=1;frame=requestAnimationFrame(draw);
 }
 frame=requestAnimationFrame(draw);return close;
}
