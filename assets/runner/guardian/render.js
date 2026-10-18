import {PixelWardrobe,eyeLandmark} from './wardrobe.js';
import {FLOOR,WORLD_END,ARENA,ITEM_FRAMES,RUNE_X} from './config.js';
export const NAMES={penguin:'Pingüino',bear:'Oso',pig:'Cerdito',chick:'Pollito'};
export class GuardianRenderer{
 constructor(canvas){this.canvas=canvas;this.ctx=canvas.getContext('2d',{alpha:false});this.images={};this.frames={};this.camera=0;this.loadouts=[[],[]];}
 async load(){let feetKeys=[];try{const response=await fetch(new URL('./feet-fit-manifest.json',import.meta.url));if(response.ok)feetKeys=(await response.json()).filter(k=>['shoes_heart','boots_rain','slippers_cloud','shoes_chic','sandals_summer'].includes(k));}catch{}let headKeys=[];try{const response=await fetch(new URL('./head-fit-manifest.json',import.meta.url));if(response.ok)headKeys=(await response.json()).filter(k=>['cap_pink','beanie_cloud','hat_garden','beret_chic'].includes(k));}catch{}await Promise.all(['forest','musgo','enemies','items','tiles','pets-base','wardrobe-atlas','musgo-laugh',...['shirt_love','jacket_denim','coat_cloud','dress_petal','hoodie_nido'].map(key=>'body-'+key),...headKeys.map(key=>'head-'+key),...feetKeys.map(key=>'feet-'+key)].map(async name=>{const image=new Image();image.src=new URL(name+'.webp',import.meta.url);await image.decode();this.images[name]=image;if(!['forest','pets-base','wardrobe-atlas'].includes(name)&&!name.startsWith('body-')&&!name.startsWith('head-')&&!name.startsWith('feet-'))this.frames[name]=this.measure(image,name==='items'?4:3,name==='musgo-laugh'?1:['items','tiles'].includes(name)?3:2);}));this.wardrobe=new PixelWardrobe(this.images['pets-base'],this.images['wardrobe-atlas'],undefined,{bodies:Object.fromEntries(['shirt_love','jacket_denim','coat_cloud','dress_petal','hoodie_nido'].map(key=>[key,this.images['body-'+key]])),heads:Object.fromEntries(['cap_pink','beanie_cloud','hat_garden','beret_chic'].map(key=>[key,this.images['head-'+key]])),feet:Object.fromEntries(feetKeys.map(key=>[key,this.images['feet-'+key]]))});}
 measure(image,cols,rows){
  const c=document.createElement('canvas');c.width=image.width;c.height=image.height;const context=c.getContext('2d',{willReadFrequently:true});context.drawImage(image,0,0);const pixels=context.getImageData(0,0,c.width,c.height).data,frames=[];
  for(let i=0;i<cols*rows;i++){const x0=Math.floor(i%cols*c.width/cols),y0=Math.floor(Math.floor(i/cols)*c.height/rows),x1=Math.floor((i%cols+1)*c.width/cols),y1=Math.floor((Math.floor(i/cols)+1)*c.height/rows);let a=x1,b=y1,d=x0,e=y0;
   for(let y=y0;y<y1;y+=2)for(let x=x0;x<x1;x+=2)if(pixels[(y*c.width+x)*4+3]>210){a=Math.min(a,x);b=Math.min(b,y);d=Math.max(d,x);e=Math.max(e,y);}
   frames.push(d>a?{x:Math.max(x0,a-3),y:Math.max(y0,b-3),w:Math.min(x1-a+3,d-a+7),h:Math.min(y1-b+3,e-b+7)}:{x:x0,y:y0,w:x1-x0,h:y1-y0});
  }return frames;
 }
 sprite(name,index,x,y,height,flip=false,angle=0,centerRotation=false){const r=this.frames[name]?.[index],image=this.images[name];if(!r||!image)return;const c=this.ctx,w=r.w/r.h*height;c.save();c.translate(Math.round(x),Math.round(y)-(centerRotation?height/2:0));c.rotate(angle);if(flip)c.scale(-1,1);c.drawImage(image,r.x,r.y,r.w,r.h,Math.round(-w/2),centerRotation?-height/2:-height,Math.round(w),height);c.restore();}
 portrait(canvas,species){const old=this.ctx;this.ctx=canvas.getContext('2d');this.ctx.clearRect(0,0,canvas.width,canvas.height);this.pet(species,0,canvas.width/2,canvas.height-3,canvas.height-2,false,0,this.loadouts[0]);this.ctx=old;}
 pet(species,pose,x,y,height,flip=false,angle=0,loadout=[],walkPhase=null){if(!this.wardrobe){this.sprite(species,pose,x,y,height,flip,angle);return;}const image=walkPhase===null?this.wardrobe.frame(species,pose,loadout):this.wardrobe.walkFrame(species,pose,loadout,walkPhase),c=this.ctx;c.save();c.translate(Math.round(x),Math.round(y));c.rotate(angle);if(flip)c.scale(-1,1);c.drawImage(image,-height/2,-height,height,height);c.restore();}
 drawDefeat(species,loadout,seconds=0){this.draw(null);const c=this.ctx,zoom=1+Math.min(1,seconds/.7)*.12;c.fillStyle='#142c3666';c.fillRect(0,0,960,540);this.sprite('musgo-laugh',Math.floor(seconds*4)%3,660,365+Math.sin(seconds*12)*3,335);this.shadow(315,443,58);this.pet(species,5,315,448,185*zoom,false,0,loadout);const face=eyeLandmark(species,5),height=185*zoom,scale=height/320;for(let i=0;i<2;i++){const t=(seconds*1.5+i*.35)%1,x=315+(32+face[0]-160+(i?20:-20))*scale,y=448-height+(40+face[1])*scale+4+t*23;c.fillStyle='#79cfee';c.fillRect(x,y,4,7);c.fillStyle='#dcfaff';c.fillRect(x,y,2,3);} }
 text(value,x,y,size=12,color='#fff4d4'){const c=this.ctx;c.font=`bold ${size}px monospace`;c.textAlign='center';c.fillStyle='#102e35';c.fillText(value,x+1,y+2);c.fillStyle=color;c.fillText(value,x,y);}
 shadow(x,y,w=26){const c=this.ctx;c.fillStyle='#112e324d';c.beginPath();c.ellipse(x,y+2,w,5,0,0,Math.PI*2);c.fill();}
 draw(s){const c=this.ctx,t=s?.frame??0;const living=s?.players.filter(p=>p.hp>0),actors=living?.length?living:s?.players;const target=s?actors.reduce((v,p,_,a)=>v+p.x/a.length,0)-(actors.length>1?480:340):0;this.camera+=((Math.max(0,Math.min(WORLD_END-960,target)))-this.camera)*.1;
  c.imageSmoothingEnabled=false;c.fillStyle='#1a4147';c.fillRect(0,0,960,540);const bg=this.images.forest;if(bg){const w=1040,x=-((this.camera*.12)%w);c.drawImage(bg,x,0,w,540);c.save();c.translate(x+w,0);c.scale(-1,1);c.drawImage(bg,-w,0,w,540);c.restore();}
  const shade=c.createLinearGradient(0,270,0,540);shade.addColorStop(0,'#102c3800');shade.addColorStop(1,'#0b2939b3');c.fillStyle=shade;c.fillRect(0,0,960,540);
  for(let i=0;i<18;i++){const x=(i*167+Math.sin(t*.007+i)*20-this.camera*.3)%980,y=130+(i*67)%270+Math.sin(t*.012+i)*10;c.globalAlpha=.3+Math.sin(t*.03+i)*.25;c.fillStyle='#ffe39c';c.fillRect(x,y,2,2);}c.globalAlpha=1;
  if(!s)return;c.save();c.translate(-Math.round(this.camera),this.worldOffset??0);
  for(const p of s.level.platforms){if(p.x+p.w<this.camera-50||p.x>this.camera+1010)continue;
   const floor=p.y===FLOOR,depth=floor?110:24;c.fillStyle='#24423f';c.fillRect(p.x,p.y,p.w,depth);c.fillStyle='#547064';c.fillRect(p.x,p.y+5,p.w,6);c.fillStyle='#80a977';c.fillRect(p.x,p.y,p.w,5);
   const start=Math.max(p.x,Math.floor(this.camera/32)*32);for(let x=start;x<p.x+p.w&&x<this.camera+1000;x+=32){c.fillStyle='#324e49';c.fillRect(x+3,p.y+17,24,15);c.fillStyle='#729063';c.fillRect(x+7,p.y-3,13,4);if(floor){c.fillStyle='#405b51';c.fillRect(x+13,p.y+40,26,18);c.fillStyle='#233f3d';c.fillRect(x+6,p.y+66,19,28);}}
   const tile=this.frames.tiles[2],width=floor?180:p.w,height=width*tile.h/tile.w;c.save();c.beginPath();c.rect(p.x,p.y-10,p.w,depth+10);c.clip();for(let x=p.x+Math.floor(Math.max(0,this.camera-p.x)/width)*width;x<p.x+p.w&&x<this.camera+1000;x+=width)this.sprite('tiles',2,x+width/2,p.y+height-7,height);c.restore();
  }
  for(const x of s.level.camps){if(Math.abs(x-this.camera-480)>580)continue;this.sprite('tiles',4,x,FLOOR,88);this.text('LUZ +1 · 15 ✦',x,FLOOR-100,10);}
  if(this.camera>WORLD_END-1600)this.sprite('tiles',8,WORLD_END-100,FLOOR,155);
  for(const coin of s.level.coins)if(!coin.used&&coin.x>this.camera-30&&coin.x<this.camera+990)this.sprite('items',8,coin.x,coin.y+10+Math.sin(t*.07+coin.id)*2,18);
  for(const item of s.level.pickups)if(!item.used&&item.x>this.camera-50&&item.x<this.camera+1010){c.fillStyle='#ffe7a91f';c.beginPath();c.arc(item.x,item.y,22,0,Math.PI*2);c.fill();this.sprite('items',ITEM_FRAMES[item.type]??0,item.x,item.y+15+Math.sin(t*.06+item.id)*3,30);}
  for(const e of s.level.enemies)if(e.hp>0&&e.x>this.camera-80&&e.x<this.camera+1040){this.shadow(e.x,e.y,20);this.sprite('enemies',e.type,e.x,e.y+Math.sin(t*.1+e.id)*2,e.type===2?50:56,e.type===0&&e.stolen>0);}
  if(s.stage==='boss'||this.camera>ARENA-1100){const b=s.boss;this.shadow(b.x,b.y,98);const pose=b.action==='roll'?3:b.action==='warning'?2:b.action==='expose'?4:b.action==='recover'?1:0;
   this.sprite('musgo',pose,b.x,b.y+3,pose===3?170:180,false,b.action==='roll'?t*.16*Math.sign(b.vx):0,b.action==='roll');
   if(b.action==='warning'){this.text(b.next==='roll'?'¡AL CAPARAZÓN! · BUSCA ALTURA':b.next==='stomp'?'¡ONDA! · PREPARA EL SALTO':'¡HOJAS! · BUSCA UN HUECO',b.x,b.y-205,12,'#ffcc87');}
   if(b.action==='expose'){this.text('SELLO EXPUESTO',b.x,b.y-190,12,'#fff09c');}
   if(b.action==='ward')for(const [i,x]of RUNE_X.entries()){c.strokeStyle=s.frame-s.sigils[i]<(s.players.filter(p=>p.hp>0).length===1?420:80)?'#fff8b2':'#81d8d1';c.lineWidth=3;c.strokeRect(x-22,FLOOR-8,44,8);this.text('✦',x,FLOOR-18,22);}
  }
  for(const h of s.hazards){c.save();c.translate(h.x,h.y);c.fillStyle=h.type==='leaf'?'#b6d98b':'#ffbd77';if(h.type==='wave'){c.lineWidth=4;c.strokeStyle='#ffc67b';c.beginPath();c.arc(0,10,25,Math.PI,0);c.stroke();}else{c.rotate(t*.09);c.fillRect(-8,-4,16,8);c.fillStyle='#f4e8aa';c.fillRect(-4,-3,8,3);}c.restore();}
  for(const p of s.players){if(p.invulnerable>0&&t%8<3)c.globalAlpha=.4;this.shadow(p.x,p.ground?p.y:FLOOR,19);const pose=p.hp<=0?5:p.dash>0?3:p.attackCooldown>12?4:!p.ground?2:Math.abs(p.vx)>.1?1:0;const walking=p.hp>0&&p.ground&&p.dash<=0&&Math.abs(p.vx)>.1;const bob=walking?Math.sin(t*Math.PI/12)*.7:0;
   this.pet(p.species,pose,p.x,p.y+bob,80,p.facing<0,p.dash>0?p.facing*.08:0,this.loadouts[p.id],walking?t/6:null);c.globalAlpha=1;
   if(s.mode==='partner')this.text(p.id===0?'1':'2',p.x,p.y-73,10,p.id===0?'#ffceac':'#c5ecdb');
   if(p.buffs.shield>0){c.strokeStyle='#b4eacbcc';c.lineWidth=2;c.beginPath();c.ellipse(p.x,p.y-30,30,36,0,0,Math.PI*2);c.stroke();}
   if(p.hp<=0)this.text('MANTÉN PULSO PARA RESCATAR',p.x,p.y-70,9,'#fbd4d2');
  }
  for(const shot of s.shots){c.fillStyle='#ffdf88';c.fillRect(shot.x-6,shot.y-3,12,6);c.fillStyle='#fff8cd';c.fillRect(shot.x,shot.y-1,9,2);}
  for(const e of s.events){const age=t-e.frame;if(['hit','coin','pickup','link','enemy','shield'].includes(e.type)){c.globalAlpha=1-age/45;this.text(e.type==='coin'?'+1':e.type==='link'?'VÍNCULO':e.type==='pickup'?'✦':'✧',e.x,e.y-age*.6,12,e.type==='link'?'#e7baff':'#ffe5a2');c.globalAlpha=1;}}
  c.restore();
 }
}
