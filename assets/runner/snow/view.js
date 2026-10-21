import {platformsFor} from './engine.js';
export const LABELS={copito:'Copitos',rafaga:'Ráfaga',rebote:'Rebotadora',bola_grande:'Bola gigante',triple:'Triple salto',speed:'Velocidad',mini:'Miniatura',shield:'Escudo'};
const colors=['#cf7196','#7aaed0','#a7bb91','#d8b36f'];
export const MAP_BACKGROUNDS=['village.webp','aurora-v1.webp','crystal-v1.webp'];
export class SnowView{
 constructor(back,front){this.back=back.getContext('2d',{alpha:false});this.front=front.getContext('2d');this.background=new Image();this.background.src=new URL('./village.webp',import.meta.url);this.backgrounds=new Map([[0,this.background]]);this.effects=[];this.lastEvent=0;this.scenery=document.createElement('canvas');this.scenery.width=1280;this.scenery.height=720;this.sceneryContext=this.scenery.getContext('2d',{alpha:false});this.sceneryKey='';this.background.onload=()=>{this.sceneryKey='';};}
 events(s,audio,me){for(const e of s.events){if(e.id<=this.lastEvent)continue;this.lastEvent=e.id;audio.fx(e.type,e.player===me?1:.35);this.effects.push({...e,start:performance.now()/1000});}this.effects=this.effects.slice(-40);}
 sceneryDraw(s){const c=this.sceneryContext;c.clearRect(0,0,1280,720);let g=c.createLinearGradient(0,0,0,720);g.addColorStop(0,'#e9bbd1');g.addColorStop(1,'#e8e5f4');c.fillStyle=g;c.fillRect(0,0,1280,720);if(this.background.complete&&this.background.naturalWidth)c.drawImage(this.background,0,0,1280,720);
  for(const p of platformsFor(s)){c.shadowColor='#7c70933a';c.shadowBlur=16;c.shadowOffsetY=12;g=c.createLinearGradient(0,p.y,0,p.y+55);g.addColorStop(0,'#c0a6bd');g.addColorStop(1,'#8c789f');c.fillStyle=g;c.beginPath();c.roundRect(p.x,p.y,p.w,48,18);c.fill();c.shadowBlur=c.shadowOffsetY=0;
   for(let i=0;i<Math.floor(p.w/60);i++){c.fillStyle=i%2?'#c6b0c8':'#b6a0bc';c.beginPath();c.ellipse(p.x+25+i*60,p.y+27,21,11,i*.4,0,Math.PI*2);c.fill();}
   c.fillStyle='#fff8f1';c.beginPath();c.roundRect(p.x-5,p.y-10,p.w+10,24,13);c.fill();for(let i=0;i<p.w/48;i++){c.beginPath();c.ellipse(p.x+15+i*48,p.y+8,12,6+i%3,0,0,Math.PI*2);c.fill();}c.fillStyle='#e3eaf5';c.fillRect(p.x+17,p.y+3,p.w-34,2);
  }
 }
 draw(s,time){const map=s.map??0;if(!this.backgrounds.has(map)){const img=new Image();img.onload=()=>{this.sceneryKey='';};img.src=new URL('./'+MAP_BACKGROUNDS[map%MAP_BACKGROUNDS.length],import.meta.url);this.backgrounds.set(map,img);}this.background=this.backgrounds.get(map);const c=this.back,f=this.front,key=JSON.stringify(platformsFor(s));if(key!==this.sceneryKey){this.sceneryDraw(s);this.sceneryKey=key;}c.drawImage(this.scenery,0,0);
  for(let i=0;i<55;i++){const x=(i*173+time*(8+i%4))%1320-20,y=(i*79+time*(12+i%7))%760-30;c.fillStyle='#ffffffe0';c.beginPath();c.arc(x,y,1+i%3,0,Math.PI*2);c.fill();}
  for(const p of s.players){if(p.rescue)continue;c.fillStyle='#65557735';c.beginPath();c.ellipse(p.x,p.y+3,26*((p.buffs.mini??0)>0?.5:1),6,0,0,Math.PI*2);c.fill();}
  f.clearRect(0,0,1280,720);
  for(const d of s.drops){f.save();f.translate(d.x,d.y+Math.sin(time*5+d.id)*3);f.shadowColor='#91709c60';f.shadowBlur=12;f.fillStyle=d.type==='weapon'?'#cf7196':'#7aaed0';f.beginPath();f.roundRect(-16,-16,32,30,6);f.fill();f.shadowBlur=0;f.fillStyle='#fff0d1';f.fillRect(-3,-16,6,30);f.fillRect(-16,-5,32,5);f.strokeStyle='#fff0d1';f.lineWidth=3;for(const sign of [-1,1]){f.beginPath();f.ellipse(sign*6,-20,8,4,sign*.6,0,Math.PI*2);f.stroke();}f.font='bold 11px system-ui';f.textAlign='center';f.fillStyle='#493c58';f.fillText(LABELS[d.kind],0,-32);f.restore();}
  for(const b of s.shots){f.shadowColor=b.type==='super'?'#b2f4ff':'transparent';f.shadowBlur=b.type==='super'?18:0;f.fillStyle='#d2e7f166';for(let i=1;i<4;i++){f.beginPath();f.arc(b.x-b.vx*.014*i,b.y-b.vy*.014*i,b.r*(1-i*.2),0,Math.PI*2);f.fill();}g=f.createRadialGradient(b.x-3,b.y-4,1,b.x,b.y,b.r);g.addColorStop(0,'#fffefa');g.addColorStop(.7,'#e7f6fb');g.addColorStop(1,'#abcbdc');f.fillStyle=g;f.beginPath();f.arc(b.x,b.y,b.r,0,Math.PI*2);f.fill();}
  f.shadowBlur=0;for(const [i,p]of s.players.entries()){const scale=(p.buffs.mini??0)>0?.5:1,x=p.x,y=p.y-43*scale;
   if(p.rescue||(p.buffs.shield??0)>0){const r=53*scale;g=f.createRadialGradient(x-r*.3,y-r*.4,0,x,y,r);g.addColorStop(0,'#ffffff30');g.addColorStop(.8,'#d5f2ff18');g.addColorStop(1,'#c3ecff99');f.fillStyle=g;f.strokeStyle='#fff6e9';f.lineWidth=3;f.beginPath();f.arc(x,y,r,0,Math.PI*2);f.fill();f.stroke();f.strokeStyle='#ffffffbb';f.beginPath();f.arc(x,y,r*.83,3.6,4.6);f.stroke();}
   if((p.buffs.speed??0)>0){f.strokeStyle='#f8ead3bb';f.lineWidth=3;for(let j=0;j<3;j++){f.beginPath();f.moveTo(x-p.face*25,y+j*7);f.lineTo(x-p.face*46,y+j*7);f.stroke();}}
   if((p.buffs.triple??0)>0){f.fillStyle='#e3b35f';for(let j=0;j<3;j++){f.beginPath();f.arc(x+(j-1)*9,y-51*scale,3,0,Math.PI*2);f.fill();}}
   f.fillStyle=colors[i];f.beginPath();f.roundRect(x-29,y+48*scale,58,15,7);f.fill();f.fillStyle='#fffaf2';f.font='bold 10px system-ui';f.textAlign='center';f.fillText(p.name.slice(0,10),x,y+59*scale);
  }
  this.effects=this.effects.filter(e=>time-e.start<.75);
  for(const e of this.effects){const age=time-e.start,t=Math.max(0,age/.75);f.save();f.globalAlpha=1-t;f.strokeStyle=e.type==='super'?'#d29bbf':'#fff9ed';f.lineWidth=e.type==='super'?8:3;f.beginPath();f.arc(e.x,e.y,e.type==='super'?25+t*260:5+t*28,0,Math.PI*2);f.stroke();if(['hit','rescue','pickup','super'].includes(e.type))for(let j=0;j<10;j++){const a=j*Math.PI/5,r=14+t*65;f.fillStyle=j%2?'#fff8e9':'#d4e7f8';f.beginPath();f.arc(e.x+Math.cos(a)*r,e.y+Math.sin(a)*r-t*12,3*(1-t)+1,0,Math.PI*2);f.fill();}f.restore();}
 }
}
