// Stable inventory identities. The fitted pixel source is an anatomical pattern,
// never an ownership alias: the app must equip the actual item_key.
export const PIXEL_EXTENSIONS={
 shirt_sunday:{base:'jacket_denim',color:'#A3C8E2',detail:'shirt'},
 sweater_forest:{base:'coat_cloud',color:'#9AAA85',detail:'knit'},
 jacket_leather:{base:'jacket_denim',color:'#50362A',detail:'leather'},
 tee_everyday:{base:'shirt_love',color:'#E9E0CD',detail:'tee'},
 jacket_racer:{base:'jacket_denim',color:'#C52D32',detail:'racer'},
 suit_astronaut:{base:'coat_cloud',color:'#E5E9E1',detail:'astronaut'},
 dress_princess:{base:'dress_petal',color:'#B7A1DB',detail:'princess'},
 tiara_princess:{base:'beret_chic',color:'#D4A17D',detail:'tiara',head:true},
};

export function drawPixelDetail(ctx,kind,p){
 ctx.save();ctx.translate(p[0],p[1]);ctx.rotate(p[4]);
 const w=p[2],h=p[3],x=-w*.19,y=-h*.18;
 ctx.fillStyle='#FFF0DC';
 if(kind==='racer'){
  ctx.fillRect(-w*.29,-h*.40,5,h*.72);ctx.fillRect(w*.24,-h*.40,5,h*.72);
  for(let row=0;row<3;row++)for(let col=0;col<4;col++){
   ctx.fillStyle=(row+col)%2?'#FFF0DC':'#354353';ctx.fillRect(x+col*3,y+row*3,3,3);
  }
  // Pixel digits; no font dependency or racing-team branding.
  ctx.fillStyle='#FFF0DC';for(const [dx,dy]of [[0,0],[1,0],[2,0],[0,1],[2,1],[0,2],[2,2],[0,3],[2,3],[0,4],[1,4],[2,4],[4,0],[5,0],[6,0],[6,1],[5,2],[5,3],[4,4]])ctx.fillRect(w*.04+dx*2,y+dy*2,2,2);
 }else if(kind==='astronaut'){
  ctx.fillStyle='#E8A05C';ctx.fillRect(-w*.30,-h*.38,3,h*.72);ctx.fillRect(w*.28,-h*.38,3,h*.72);
  ctx.fillStyle='#405A79';ctx.fillRect(-w*.19,-h*.24,w*.38,h*.28);
  ctx.fillStyle='#FFF0DC';for(const n of [-1,0,1])ctx.fillRect(n*6-1,-3,3,3);
 }else if(kind==='princess'){
  ctx.fillStyle='#FFF0DC';ctx.beginPath();ctx.moveTo(-3,-h*.39);ctx.lineTo(-w*.23,-h*.28);ctx.lineTo(-w*.12,-h*.15);ctx.lineTo(0,-h*.30);ctx.lineTo(w*.12,-h*.15);ctx.lineTo(w*.23,-h*.28);ctx.lineTo(3,-h*.39);ctx.fill();
  ctx.fillStyle='#EDB8C6';ctx.fillRect(-w*.35,h*.06,w*.70,4);
  ctx.fillStyle='#FFF0DC';ctx.fillRect(-12,h*.02,10,11);ctx.fillRect(2,h*.02,10,11);ctx.fillStyle='#D4A17D';ctx.fillRect(-2,h*.06,4,4);
  for(const [x,y]of [[-20,0],[20,0],[-10,-9],[10,-9]]){ctx.fillStyle='#FFF0DC';ctx.fillRect(x,y,2,2);ctx.fillRect(x+4,y,2,2);ctx.fillRect(x,y+2,6,2);ctx.fillRect(x+2,y+4,2,2);}
 }else if(kind==='leather'){
  ctx.fillStyle='#FFF0DC';ctx.beginPath();ctx.moveTo(-9,-h*.35);ctx.lineTo(9,-h*.35);ctx.lineTo(1,h*.27);ctx.fill();
  ctx.strokeStyle='#AD8769';ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(-14,-h*.34);ctx.lineTo(-19,-5);ctx.lineTo(-5,7);ctx.moveTo(14,-h*.34);ctx.lineTo(19,-5);ctx.lineTo(5,7);ctx.stroke();
 }else if(kind==='shirt'){
  ctx.fillRect(-1,-h*.38,2,h*.72);for(const yy of [-12,0,12]){ctx.fillStyle='#BA9A68';ctx.fillRect(-1,yy,3,3);}
 }else if(kind==='knit'){
  ctx.fillStyle='#72846A';for(let xx=-18;xx<19;xx+=4)ctx.fillRect(xx,h*.23,2,7);
 }else if(kind==='tee'){
  ctx.strokeStyle='#BAAF97';ctx.lineWidth=2;ctx.strokeRect(-w*.28,-h*.22,13,12);
 }
 ctx.restore();
}
