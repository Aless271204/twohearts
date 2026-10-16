// Uses the production compositor through a native Canvas; not a browser capture.
import assert from 'node:assert/strict';import {createRequire} from 'node:module';import fs from 'node:fs';import path from 'node:path';
import {PixelWardrobe,OUTFITS,ITEMS,eyeLandmark} from '../assets/runner/guardian/wardrobe.js';
import {GuardianRenderer} from '../assets/runner/guardian/render.js';
const require=createRequire(import.meta.url),{createCanvas,loadImage}=require(path.join(process.env.NIDO_NODE_PACKAGES??'C:/Users/Lenovo/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules','@napi-rs/canvas'));
globalThis.document={createElement:()=>createCanvas(1,1)};
const base=await loadImage('assets/runner/guardian/pets-base.webp'),atlas=await loadImage('assets/runner/guardian/wardrobe-atlas.webp'),bodies=Object.fromEntries(await Promise.all(['shirt_love','jacket_denim','coat_cloud','dress_petal','hoodie_nido'].map(async key=>[key,await loadImage('assets/runner/guardian/body-'+key+'.webp')]))),heads=Object.fromEntries(await Promise.all(JSON.parse(fs.readFileSync('assets/runner/guardian/head-fit-manifest.json','utf8')).map(async key=>[key,await loadImage('assets/runner/guardian/head-'+key+'.webp')]))),wardrobe=new PixelWardrobe(base,atlas,undefined,{bodies,heads,feet:Object.fromEntries(await Promise.all(JSON.parse(fs.readFileSync('assets/runner/guardian/feet-fit-manifest.json','utf8')).map(async key=>[key,await loadImage('assets/runner/guardian/feet-'+key+'.webp')])))});
fs.mkdirSync('outputs/guardian-wardrobe',{recursive:true});
const species=['penguin','bear','pig','chick'],presets=['dulce','cozy','chic','pastel'];
for(const outfit of Object.keys(OUTFITS)){
 const c=createCanvas(1440,1000),ctx=c.getContext('2d');ctx.imageSmoothingEnabled=false;ctx.fillStyle='#fff5ed';ctx.fillRect(0,0,c.width,c.height);
 for(let row=0;row<4;row++)for(let pose=0;pose<6;pose++){const x=pose*240,y=row*250;ctx.fillStyle=row%2?'#eff2e7':'#fae6e5';ctx.fillRect(x+3,y+3,234,244);ctx.drawImage(wardrobe.frame(species[row],pose,OUTFITS[outfit]),x,y,240,240);ctx.fillStyle='#503b39';ctx.font='12px sans-serif';ctx.fillText(species[row]+' · '+['idle','run','jump','dash','pulse','down'][pose],x+10,y+240);}
 fs.writeFileSync('outputs/guardian-wardrobe/'+outfit+'.png',c.toBuffer('image/png'));
}
// Also inspect every footwear item independently, including slippers which
// currently do not belong to a named outfit.
for(const item of ['shoes_heart','boots_rain','slippers_cloud','shoes_chic','sandals_summer']){
 const c=createCanvas(1440,1000),ctx=c.getContext('2d');ctx.imageSmoothingEnabled=false;ctx.fillStyle='#fff5ed';ctx.fillRect(0,0,c.width,c.height);
 for(let row=0;row<4;row++)for(let pose=0;pose<6;pose++){const x=pose*240,y=row*250;ctx.fillStyle=row%2?'#eff2e7':'#fae6e5';ctx.fillRect(x+3,y+3,234,244);ctx.drawImage(wardrobe.frame(species[row],pose,[item]),x,y,240,240);ctx.fillStyle='#503b39';ctx.font='12px sans-serif';ctx.fillText(species[row]+' / '+pose,x+10,y+240);}
 fs.writeFileSync('outputs/guardian-wardrobe/feet-'+item+'.png',c.toBuffer('image/png'));
}
const c=createCanvas(960,540),renderer=new GuardianRenderer(c);renderer.wardrobe=wardrobe;
for(const name of ['forest','musgo-laugh']){const image=await loadImage('assets/runner/guardian/'+name+'.webp');renderer.images[name]=image;if(name==='musgo-laugh')renderer.frames[name]=renderer.measure(image,3,1);}
renderer.drawDefeat('penguin',OUTFITS.dulce,1.2);fs.writeFileSync('outputs/guardian-wardrobe/defeat.png',c.toBuffer('image/png'));
// Wearing/recolouring footwear must not repaint the pet's face.
let faceChecks=0;
for(const name of species)for(let pose=0;pose<6;pose++){
 const [ex,ey]=eyeLandmark(name,pose),face=[Math.round(ex+32-55),Math.round(ey+40-65),110,86];
 const baseline=wardrobe.frame(name,pose,[]).getContext('2d').getImageData(...face).data;
 for(const item_key of ['shoes_heart','boots_rain','slippers_cloud','shoes_chic','sandals_summer'])for(const color of [null,'#58AAC6']){
  const look=wardrobe.frame(name,pose,[{item_key,...(color?{color}:{})}]).getContext('2d').getImageData(...face).data;
  assert.deepEqual(look,baseline,name+'/'+pose+'/'+item_key+'/'+color);faceChecks++;
 }
}
fs.writeFileSync('outputs/guardian-wardrobe/checks.json',JSON.stringify({faceChecks,footwearViews:120,outfitViews:120,capture:'native Canvas; not a browser or device recording'},null,2));
console.log('Rendered 120 outfit combinations, 120 footwear combinations; '+faceChecks+' face-preservation checks passed.');
