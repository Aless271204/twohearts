(async()=>{try{
 const sleep=ms=>new Promise(r=>setTimeout(r,ms)),snap=()=>qaApp.adventureSnapshot();
 async function until(fn){for(let i=0;i<80;i++){if(fn())return;await sleep(35);}throw Error('Input timed out: '+JSON.stringify({p:snap().state.players[0],paused:snap().paused,context:document.getElementById('open').textContent}));}
 function face(dx,dz){const desired=Math.atan2(-dx,-dz),delta=Math.atan2(Math.sin(desired-snap().yaw),Math.cos(desired-snap().yaw)),view=document.getElementById('look');view.dispatchEvent(new PointerEvent('pointerdown',{pointerId:1,clientX:400,clientY:180}));view.dispatchEvent(new PointerEvent('pointermove',{pointerId:1,clientX:400-delta/.006,clientY:180}));view.dispatchEvent(new PointerEvent('pointerup',{pointerId:1}));}
 async function choose(action,id){const buttons=[...document.querySelectorAll('#interactions button')],button=buttons.find(b=>b.dataset.action===action&&b.dataset.chest===String(id)),seq=snap().state.players[0].sequence??0;if(!button)throw Error('Missing interaction '+action+' '+id);if(buttons.length===1)document.getElementById('open').click();else button.click();await until(()=>(snap().state.players[0].sequence??0)>seq||!document.getElementById('puzzle').hidden);await sleep(250);}
 function path(s,target){const p=s.players[0],q=[[p.x,p.z,[]]],seen=new Set([p.z*s.size+p.x]);for(let i=0;i<q.length;i++){const[x,z,steps]=q[i];if(x===target.x&&z===target.z)return steps;for(const[dx,dz]of[[1,0],[-1,0],[0,1],[0,-1]]){const nx=x+dx,nz=z+dz,id=nz*s.size+nx;if(nx<0||nz<0||nx>=s.size||nz>=s.size||s.grid[id]||seen.has(id))continue;seen.add(id);q.push([nx,nz,[...steps,[dx,dz]]]);}}throw Error('No route');}
 async function go(target,before=false){const steps=path(snap().state,target);for(const[dx,dz]of(before?steps.slice(0,-1):steps)){
  let s=snap().state,p=s.players[0];const nx=p.x+dx,nz=p.z+dz,trap=s.traps.find(t=>!t.used&&t.x===nx&&t.z===nz);if(trap)await choose('disarm',trap.id);
  s=snap().state;p=s.players[0];const b=s.bridges?.find(b=>!b.secured&&b.x===nx&&b.z===nz);if(b)await choose('activate',b.id);
  face(dx,dz);window.dispatchEvent(new KeyboardEvent('keydown',{code:'KeyW'}));try{await until(()=>{const q=snap().state.players[0];return q.x!==p.x||q.z!==p.z;});}finally{window.dispatchEvent(new KeyboardEvent('keyup',{code:'KeyW'}));}
  const q=snap().state.players[0];if(q.x!==nx||q.z!==nz)throw Error('Unexpected movement');await sleep(300);
 }const p=snap().state.players[0];face(target.x-p.x,target.z-p.z);await sleep(200);}
 window.qaGo=go;window.qaChoose=choose;
 const target=snap().state.chests[0];await go(target,true);await choose('open',target.id);await until(()=>!document.getElementById('puzzle').hidden);window.qaDone=true;
}catch(e){window.qaFailure=String(e);window.qaDone=true;}})();
