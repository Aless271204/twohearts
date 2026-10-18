// Pixel wardrobe layers use the same inventory IDs as the shop. No prices or
// purchase state live here: the authenticated app supplies the equipped items.
export const ITEMS={
 cap_pink:['pet_head',15,105,264,158],beanie_cloud:['pet_head',279,77,228,205],hat_garden:['pet_head',507,102,274,172],beret_chic:['pet_head',780,110,231,151],
 glasses_heart:['pet_eyes',1025,126,245,139],glasses_round:['pet_eyes',1281,121,244,139],glasses_star:['pet_eyes',14,323,264,172],patch_pirate:['pet_eyes',287,344,213,152],mask_sleep:['pet_eyes',512,332,272,163],
 scarf_hearts:['pet_neck',783,294,229,214],bandana_sage:['pet_neck',1024,317,249,189],necklace_heart:['pet_neck',1300,307,228,197],chain_gold:['pet_neck',15,542,240,186],bow_neck:['pet_neck',274,559,226,140],
 shirt_love:['pet_body',510,530,249,193],jacket_denim:['pet_body',766,535,244,200],coat_cloud:['pet_body',1023,527,249,211],dress_petal:['pet_body',1274,525,250,214],hoodie_nido:['pet_body',10,743,259,209],
 shoes_heart:['pet_feet',280,787,251,162],boots_rain:['pet_feet',537,769,219,179],slippers_cloud:['pet_feet',762,767,250,187],shoes_chic:['pet_feet',1025,783,251,165],sandals_summer:['pet_feet',1283,777,248,173],
};
export const OUTFITS={dulce:['cap_pink','shirt_love','bow_neck','shoes_heart'],cozy:['beanie_cloud','coat_cloud','scarf_hearts','boots_rain'],jardin:['hat_garden','glasses_round','jacket_denim','bandana_sage','boots_rain'],chic:['beret_chic','dress_petal','necklace_heart','shoes_chic'],pastel:['glasses_star','hoodie_nido','sandals_summer']};
const PRIMARY={cap_pink:'#F05280',beanie_cloud:'#FFF2DF',hat_garden:'#B8DCCB',beret_chic:'#BAA2DB',glasses_heart:'#F05280',glasses_round:'#E2B957',glasses_star:'#BAA2DB',patch_pirate:'#30303D',mask_sleep:'#EFA0AB',scarf_hearts:'#EFA0AB',bandana_sage:'#B8DCCB',necklace_heart:'#EFA0AB',chain_gold:'#E2B957',bow_neck:'#F05280',shirt_love:'#FFF2DF',jacket_denim:'#91B6D6',coat_cloud:'#B8DCCB',dress_petal:'#EFA0AB',hoodie_nido:'#BAA2DB',shoes_heart:'#F05280',boots_rain:'#B8DCCB',slippers_cloud:'#FFF2DF',shoes_chic:'#F05280',sandals_summer:'#F2B29B'};
const rgb=hex=>[1,3,5].map(i=>parseInt(hex.slice(i,i+2),16));
function hsv(r,g,b){const v=Math.max(r,g,b),min=Math.min(r,g,b),d=v-min;let h=!d?0:v===r?((g-b)/d+6)%6:v===g?(b-r)/d+2:(r-g)/d+4;return [h/6,v?d/v:0,v/255];}
// Retain shadows, white trim, embroidery and metal. Body tinting additionally
// requires a real pixel change from the undressed base, protecting pet fur.
function tint(canvas,key,color,base=null,neck=0,bottom=256){if(!color)return;const ctx=canvas.getContext('2d'),data=ctx.getImageData(0,0,canvas.width,canvas.height),target=rgb(color),reference=hsv(...rgb(PRIMARY[key])),original=base?.getContext('2d').getImageData(0,0,base.width,base.height).data;for(let i=0;i<data.data.length;i+=4){if(data.data[i+3]<100||original&&(Math.floor(i/4/canvas.width)<neck||Math.floor(i/4/canvas.width)>bottom||Math.abs(data.data[i]-original[i])+Math.abs(data.data[i+1]-original[i+1])+Math.abs(data.data[i+2]-original[i+2])<48))continue;const [h,s,v]=hsv(data.data[i],data.data[i+1],data.data[i+2]),distance=Math.min(Math.abs(h-reference[0]),1-Math.abs(h-reference[0]));if(reference[1]<.2?s<.28&&(reference[2]>.6?v>.48:v<.45):distance<.10&&s>.13){const shade=v/Math.max(.2,reference[2]);for(let j=0;j<3;j++)data.data[i+j]=Math.min(255,Math.round(target[j]*shade));}}ctx.putImageData(data,0,0);}
// Recolour footwear material components, excluding fur connected to the body.
// This matters for ivory slippers on a penguin and peach sandals on a bear.
function tintFeet(canvas,key,color,neck){
 if(!color)return;const ctx=canvas.getContext('2d'),data=ctx.getImageData(0,0,256,256),ref=hsv(...rgb(PRIMARY[key])),target=rgb(color),candidate=new Uint8Array(65536),seen=new Uint8Array(65536),top=neck+10;
 for(let y=top;y<256;y++)for(let x=0;x<256;x++){const n=y*256+x,i=n*4;if(data.data[i+3]<150)continue;const [h,s,v]=hsv(data.data[i],data.data[i+1],data.data[i+2]),distance=Math.min(Math.abs(h-ref[0]),1-Math.abs(h-ref[0]));if(ref[1]<.2?s<.28&&v>.48:distance<.08&&s>.18)candidate[n]=1;}
 for(let start=top*256;start<65536;start++){
  if(seen[start]||!candidate[start])continue;const queue=[start];seen[start]=1;let minY=256,maxY=0;
  for(let n=0;n<queue.length;n++){const p=queue[n],x=p%256,y=p>>8;minY=Math.min(minY,y);maxY=Math.max(maxY,y);for(const q of [x?p-1:-1,x<255?p+1:-1,y>top?p-256:-1,y<255?p+256:-1])if(q>=0&&!seen[q]&&candidate[q]){seen[q]=1;queue.push(q);}}
  if(minY<=top||maxY-minY>72||queue.length>2800)continue;
  for(const p of queue){const i=p*4,v=Math.max(data.data[i],data.data[i+1],data.data[i+2])/255,shade=v/Math.max(.2,ref[2]);for(let j=0;j<3;j++)data.data[i+j]=Math.min(255,Math.round(target[j]*shade));}
 }
 ctx.putImageData(data,0,0);
}
export function cleanLoadout(items){const found=new Map();for(const raw of Array.isArray(items)?items:[]){const key=typeof raw==='string'?raw:raw?.item_key,definition=Object.hasOwn(ITEMS,key)?ITEMS[key]:null;if(!definition)continue;const color=raw?.color??raw?.appearance?.garment_color;found.set(definition[0],{item_key:key,...(/^#[a-f\d]{6}$/i.test(color??'')?{color}: {})});}return [...found.values()];}
// Anatomical landmarks are in source-cell pixels. Each pose has independent
// head, torso and feet: shoes never share one rigid transform in a running pose.
const POSES=[
 {head:[130,106],neck:164,body:[130,202,108,77,0],feet:[[92,248,46,0],[155,248,46,0]]},
 {head:[139,110],neck:171,body:[121,207,112,75,-.18],feet:[[57,222,40,.45],[151,247,48,-.16]]},
 {head:[137,93],neck:153,body:[126,185,108,72,-.16],feet:[[88,220,45,.55],[159,209,44,-.5]]},
 {head:[147,123],neck:183,body:[122,211,114,65,-.28],feet:[[61,235,39,.2],[169,246,49,-.12]]},
 {head:[139,105],neck:164,body:[135,203,107,78,0],feet:[[102,248,45,0],[161,248,45,0]]},
 {head:[143,113],neck:177,body:[141,209,98,69,.08],feet:[[134,243,43,.68],[192,239,43,-.6]]},
];
const SPECIES={penguin:{row:0,dx:0,dy:0,body:1,head:1},bear:{row:1,dx:0,dy:-2,body:1.06,head:1.05},pig:{row:2,dx:-3,dy:-1,body:1.13,head:1.12},chick:{row:3,dx:-3,dy:0,body:1.06,head:1.03}};
const EYES={penguin:[[164,124],[169,124],[151,99],[174,151],[141,126],[152,142]],bear:[[171,107],[184,107],[168,95],[181,143],[159,105],[160,133]],pig:[[167,100],[183,108],[165,80],[181,139],[159,96],[156,114]],chick:[[171,101],[180,109],[162,83],[187,122],[156,102],[151,115]]};
// Bounds of the actual paws, not an approximate sole position. The visible
// barefoot pixels are replaced only inside these regions when footwear is worn.
export const FOOT_BOUNDS={
 penguin:[[[70,238,116,257],[133,237,181,255]],[[35,206,70,242],[126,225,177,256]],[[62,188,104,230],[144,182,187,225]],[[27,216,59,249],[114,227,171,251]],[[43,238,92,257],[120,234,176,254]],[[117,217,150,258],[167,216,207,256]]],
 bear:[[[56,232,113,257],[127,232,180,257]],[[47,208,85,248],[124,220,184,256]],[[94,184,140,235],[139,192,198,235]],[[22,218,62,249],[143,228,197,254]],[[44,232,103,257],[132,232,194,257]],[[102,211,145,257],[158,213,207,255]]],
 pig:[[[64,226,108,249],[127,223,175,249]],[[41,209,78,239],[123,222,172,251]],[[109,185,143,228],[146,184,183,225]],[[27,211,63,243],[133,217,178,250]],[[64,226,106,250],[131,221,180,249]],[[118,201,157,250],[178,205,213,248]]],
 chick:[[[74,216,124,237],[135,214,182,234]],[[37,183,67,213],[131,204,184,234]],[[91,183,125,220],[147,188,192,222]],[[42,199,74,222],[135,202,193,231]],[[73,215,124,238],[136,213,185,234]],[[119,188,156,232],[173,190,212,234]]]
};
export const FOOTWEAR_KEYS=['shoes_heart','boots_rain','slippers_cloud','shoes_chic','sandals_summer'];
// Original forehoof regions: generated footwear must never dress a pig's hand.
const PIG_FOREHOOF=[[55,178,97,217],[32,136,83,178],[40,118,82,161],[35,154,82,190],[55,176,99,217],[90,166,134,210]];
export class PixelWardrobe{
 walkFrame(species,pose,raw=[],phase=0){
  // Deform the finished ankle pixels, including equipped footwear, as one
  // connected surface. The hip stays fixed; displacement grows toward toes.
  const source=this.frame(species,pose,raw);
  if(pose!==1&&pose!==4)return source;
  const step=((Math.floor(phase)%8)+8)%8,key='walk:'+species+pose+step+JSON.stringify(cleanLoadout(raw));
  this.walkCache??=new Map();if(this.walkCache.has(key))return this.walkCache.get(key);
  const c=this.makeCanvas();c.width=c.height=320;const ctx=c.getContext('2d');ctx.imageSmoothingEnabled=false;
  const bounds=FOOT_BOUNDS[species]?.[pose]??FOOT_BOUNDS.penguin[pose];
  const split=32+(bounds[0][2]+bounds[1][0])/2,top=40+Math.min(bounds[0][1],bounds[1][1])-12;
  ctx.drawImage(source,0,0,320,top,0,0,320,top);
  for(let y=top;y<320;y++)for(let side=0;side<2;side++){
   const x=side?split:0,w=side?320-split:split;
   const ankle=40+bounds[side][1]-12,toe=40+bounds[side][3];
   const amount=Math.max(0,Math.min(1,(y-ankle)/Math.max(1,toe-ankle)));
   const swing=Math.sin(step*Math.PI/4+side*Math.PI);
   ctx.drawImage(source,x,y,w,1,x+Math.round(swing*9*amount),y,w,1);
  }
  if(this.walkCache.size>=32)this.walkCache.delete(this.walkCache.keys().next().value);
  this.walkCache.set(key,c);return c;
 }
 constructor(base,atlas,makeCanvas=()=>document.createElement('canvas'),{bodies={},heads={},feet={}}={}){this.base=base;this.atlas=atlas;this.bodies=bodies;this.heads=heads;this.feet=feet;this.makeCanvas=makeCanvas;this.cache=new Map();this.items=new Map();}
 item(key,color){const cacheKey=key+(color??'');if(this.items.has(cacheKey))return this.items.get(cacheKey);const d=ITEMS[key];if(!d)return null;const c=this.makeCanvas();c.width=d[3];c.height=d[4];const ctx=c.getContext('2d');const scale=this.atlas.width/1536;ctx.drawImage(this.atlas,d[1]*scale,d[2]*scale,d[3]*scale,d[4]*scale,0,0,c.width,c.height);
  tint(c,key,color);
  this.items.set(cacheKey,c);return c;
 }
 garment(species,pose,item,profile){
  const key='garment:'+species+pose+JSON.stringify(item);if(this.items.has(key))return this.items.get(key);
  const source=this.bodies[item.item_key];if(!source)return null;const c=this.makeCanvas();c.width=c.height=256;const ctx=c.getContext('2d'),scale=source.width/1536;
  ctx.imageSmoothingEnabled=false;ctx.drawImage(source,pose*256*scale,profile.row*256*scale,256*scale,256*scale,0,0,256,256);
  const data=ctx.getImageData(0,0,256,256),mask=new Uint8Array(256*256),neck=POSES[pose].neck-3;
  for(let y=neck;y<256;y++)for(let x=25;x<210;x++){
   const n=y*256+x,i=n*4,r=data.data[i],g=data.data[i+1],b=data.data[i+2];if(data.data[i+3]<150||item.item_key==='dress_petal'&&FOOT_BOUNDS[species][pose].some(([l,t,rr,bb])=>x>=l-2&&x<=rr+2&&y>=t-2&&y<=bb+2))continue;
   const cream=r>175&&g>r*.80&&b>r*.67,
    material=item.item_key==='shirt_love'?cream:item.item_key==='coat_cloud'?(g>r*1.01&&g>b*.98):item.item_key==='jacket_denim'?(b>r*1.07&&b>g*.99):item.item_key==='hoodie_nido'?(b>100&&b>g*1.08&&b>r*.98):(r>g*1.22&&b>g*.98);
   if(material||cream)mask[n]=1;
  }
  // Two pixels retain the garment's stitched outline, without bringing back
  // the undressed legs/feet from this independently authored clothing sheet.
  const keep=mask.slice();for(let n=0;n<mask.length;n++)if(mask[n]){const x=n%256,y=n>>8;for(let dy=-2;dy<=2;dy++)for(let dx=-2;dx<=2;dx++)if(x+dx>=0&&x+dx<256&&y+dy>=neck&&y+dy<256)keep[n+dy*256+dx]=1;}
  // Retain only garment-sized components; lantern highlights and particles
  // are not clothing. Fill enclosed holes to preserve hearts, buttons and art.
  const seen=new Uint8Array(keep.length),cloth=new Uint8Array(keep.length);
  for(let start=0;start<keep.length;start++){
   if(seen[start]||!keep[start])continue;const queue=[start];seen[start]=1;let sumX=0;
   for(let n=0;n<queue.length;n++){const p=queue[n],x=p%256,y=p>>8;sumX+=x;for(const q of [x?p-1:-1,x<255?p+1:-1,y?p-256:-1,y<255?p+256:-1])if(q>=0&&!seen[q]&&keep[q]){seen[q]=1;queue.push(q);}}
   if(queue.length>150&&sumX/queue.length<190)for(const p of queue)cloth[p]=1;
  }
  const exterior=new Uint8Array(cloth.length),queue=[];for(let n=0;n<cloth.length;n++){const x=n%256,y=n>>8;if((x===0||x===255||y===0||y===255)&&!cloth[n]){exterior[n]=1;queue.push(n);}}
  for(let n=0;n<queue.length;n++){const p=queue[n],x=p%256,y=p>>8;for(const q of [x?p-1:-1,x<255?p+1:-1,y?p-256:-1,y<255?p+256:-1])if(q>=0&&!cloth[q]&&!exterior[q]){exterior[q]=1;queue.push(q);}}
  for(let n=0;n<mask.length;n++)if(!cloth[n]&&exterior[n])data.data[n*4+3]=0;ctx.putImageData(data,0,0);tint(c,item.item_key,item.color);this.items.set(key,c);return c;
 }
 frame(species,pose,raw=[]){if(!Object.hasOwn(SPECIES,species))species='penguin';const loadout=cleanLoadout(raw),profile=SPECIES[species]??SPECIES.penguin;pose=Math.max(0,Math.min(5,pose|0));const key=species+pose+JSON.stringify(loadout);if(this.cache.has(key))return this.cache.get(key);
  const c=this.makeCanvas();c.width=320;c.height=320;const ctx=c.getContext('2d');ctx.imageSmoothingEnabled=false;ctx.translate(32,40);const p=POSES[pose],scale=this.base.width/1536,sx=pose*256*scale,sy=profile.row*256*scale;
  const selected=loadout.find(i=>ITEMS[i.item_key][0]==='pet_body'),footItem=loadout.find(i=>ITEMS[i.item_key][0]==='pet_feet'),integrated=footItem&&this.feet[footItem.item_key];
  const source=integrated??this.bodies[selected?.item_key]??this.base;
  if(integrated){
   const layer=this.makeCanvas();layer.width=layer.height=256;const fs=integrated.width/1536;layer.getContext('2d').imageSmoothingEnabled=false;layer.getContext('2d').drawImage(integrated,pose*256*fs,profile.row*256*fs,256*fs,256*fs,0,0,256,256);
   if(species==='bear'&&pose===2){
    // The original jump has a tail at x60 and two feet in front of the belly.
    // Restore that anatomy, transferring each fitted ankle/shoe to its real leg.
    const corrected=this.makeCanvas();corrected.width=corrected.height=256;const cc=corrected.getContext('2d');cc.imageSmoothingEnabled=false;cc.drawImage(this.base,sx,sy,256*scale,256*scale,0,0,256,256);
    for(const patch of [{from:[42,178,57,68],to:[92,178,57,68],erase:[115,214,23,29]},{from:[137,180,71,66],to:[137,180,71,66],erase:[169,219,31,24]}]){
     const [x,y,w,h]=patch.from,[tx,ty,tw,th]=patch.to,[ex,ey,rx,ry]=patch.erase;cc.save();cc.beginPath();cc.ellipse(ex,ey,rx,ry,0,0,Math.PI*2);cc.clip();cc.clearRect(ex-rx,ey-ry,rx*2,ry*2);cc.restore();cc.drawImage(layer,x,y,w,h,tx,ty,tw,th);
    }
    const lc=layer.getContext('2d');lc.clearRect(0,0,256,256);lc.drawImage(corrected,0,0);
   }
   tintFeet(layer,footItem.item_key,footItem.color,p.neck);
   const upper=this.makeCanvas();upper.width=upper.height=256;const uc=upper.getContext('2d');uc.imageSmoothingEnabled=false;uc.drawImage(this.bodies[selected?.item_key]??this.base,sx,sy,256*scale,256*scale,0,0,256,256);if(selected?.color){const bare=this.makeCanvas();bare.width=bare.height=256;bare.getContext('2d').drawImage(this.base,sx,sy,256*scale,256*scale,0,0,256,256);tint(upper,selected.item_key,selected.color,bare,p.neck-12);}
   ctx.drawImage(layer,0,0);ctx.save();ctx.beginPath();ctx.rect(0,0,256,p.neck+10);ctx.clip();ctx.clearRect(0,0,256,p.neck+10);ctx.drawImage(upper,0,0);ctx.restore();if(species==='pig'){const [l,t,r,b]=PIG_FOREHOOF[pose];ctx.save();ctx.beginPath();ctx.ellipse((l+r)/2,(t+b)/2,(r-l)/2,(b-t)/2,0,0,Math.PI*2);ctx.clip();ctx.clearRect(l,t,r-l,b-t);ctx.drawImage(upper,0,0);ctx.restore();}if(selected){const garment=this.garment(species,pose,selected,profile);if(garment)ctx.drawImage(garment,0,0);}
  }else if(selected?.color&&source!==this.base){const body=this.makeCanvas(),bare=this.makeCanvas();body.width=bare.width=256;body.height=bare.height=256;body.getContext('2d').drawImage(source,sx,sy,256*scale,256*scale,0,0,256,256);bare.getContext('2d').drawImage(this.base,sx,sy,256*scale,256*scale,0,0,256,256);tint(body,selected.item_key,selected.color,bare,p.neck-12);ctx.drawImage(body,0,0);}else ctx.drawImage(source,sx,sy,256*scale,256*scale,0,0,256,256);
  const bySlot=Object.fromEntries(loadout.map(i=>[ITEMS[i.item_key][0],i]));
  const put=(item,x,y,w,h,angle=0)=>{const image=this.item(item.item_key,item.color);if(!image)return;ctx.save();ctx.translate(Math.round(x),Math.round(y));ctx.rotate(angle);ctx.drawImage(image,-w/2,-h/2,w,h);ctx.restore();};
  // Garment first; the original head is restored over its neckline, preserving
  // the pet's face and letting collars sit under the chin rather than on it.
  if(bySlot.pet_body&&!this.bodies[bySlot.pet_body.item_key]){const [x,y,w,h,a]=p.body;put(bySlot.pet_body,x+profile.dx,y+profile.dy,w*profile.body,h,a);ctx.drawImage(this.base,sx,sy,256*scale,(p.neck-4)*scale,0,0,256,p.neck-4);}
  if(bySlot.pet_neck){const item=bySlot.pet_neck,key=item.item_key,w=key==='bow_neck'?60:key==='scarf_hearts'?89:86,h=key==='bow_neck'?31:key==='scarf_hearts'?64:42,offset={penguin:0,bear:-10,pig:-17,chick:-8}[species];put(item,p.head[0]+8+profile.dx,p.neck+offset+(key==='bow_neck'?8:h/2-2),w*profile.body,h);}
  if(bySlot.pet_head){const item=bySlot.pet_head,key=item.item_key,head=this.heads[key];if(head){const layer=this.makeCanvas();layer.width=layer.height=256;const face=EYES[species][pose],cut=Math.min(p.neck-8,face[1]+40),headCtx=layer.getContext('2d');headCtx.imageSmoothingEnabled=false;headCtx.drawImage(head,sx,sy,256*scale,256*scale,0,0,256,256);if(item.color){const bare=this.makeCanvas();bare.width=bare.height=256;bare.getContext('2d').drawImage(this.base,sx,sy,256*scale,256*scale,0,0,256,256);tint(layer,key,item.color,bare,0,face[1]-5);}ctx.save();ctx.beginPath();ctx.rect(0,0,256,cut);ctx.clip();ctx.clearRect(0,0,256,Math.min(cut,face[1]+5));ctx.drawImage(layer,0,0);ctx.restore();}else{const w=(key==='hat_garden'?185:166)*profile.head,h=key==='beanie_cloud'?112:key==='beret_chic'?88:100;put(item,p.head[0]-5+profile.dx,p.head[1]-63+profile.dy,w,h,pose===3?-.12:0);}}
  if(bySlot.pet_eyes){const [x,y]=EYES[species][pose];put(bySlot.pet_eyes,x,y,111*profile.head,62);}
  if(this.cache.size>48)this.cache.delete(this.cache.keys().next().value);this.cache.set(key,c);return c;
 }
}

export const eyeLandmark=(species,pose)=>EYES[species]?.[pose]??EYES.penguin[pose];
