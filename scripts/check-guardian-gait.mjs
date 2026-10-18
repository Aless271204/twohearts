// Uses the production compositor through a native Canvas; not a browser capture.
import assert from 'node:assert/strict';import {createRequire} from 'node:module';import fs from 'node:fs';import path from 'node:path';
import {PixelWardrobe,OUTFITS,ITEMS,eyeLandmark} from '../assets/runner/guardian/wardrobe.js';
import {GuardianRenderer} from '../assets/runner/guardian/render.js';
const require=createRequire(import.meta.url),{createCanvas,loadImage}=require(path.join(process.env.NIDO_NODE_PACKAGES??'C:/Users/Lenovo/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules','@napi-rs/canvas'));
globalThis.document={createElement:()=>createCanvas(1,1)};
const base=await loadImage('assets/runner/guardian/pets-base.webp'),atlas=await loadImage('assets/runner/guardian/wardrobe-atlas.webp'),bodies=Object.fromEntries(await Promise.all(['shirt_love','jacket_denim','coat_cloud','dress_petal','hoodie_nido'].map(async key=>[key,await loadImage('assets/runner/guardian/body-'+key+'.webp')]))),heads=Object.fromEntries(await Promise.all(JSON.parse(fs.readFileSync('assets/runner/guardian/head-fit-manifest.json','utf8')).map(async key=>[key,await loadImage('assets/runner/guardian/head-'+key+'.webp')]))),wardrobe=new PixelWardrobe(base,atlas,undefined,{bodies,heads,feet:Object.fromEntries(await Promise.all(JSON.parse(fs.readFileSync('assets/runner/guardian/feet-fit-manifest.json','utf8')).map(async key=>[key,await loadImage('assets/runner/guardian/feet-'+key+'.webp')])))});
fs.mkdirSync('outputs/guardian-gait',{recursive:true});
const c=createCanvas(1280,640),ctx=c.getContext('2d');ctx.fillStyle='#fff2e7';ctx.fillRect(0,0,1280,640);ctx.imageSmoothingEnabled=false;
for(const [row,species] of ['penguin','bear','pig','chick'].entries())for(let phase=0;phase<8;phase++){
 const image=wardrobe.walkFrame(species,1,OUTFITS.dulce,phase);ctx.drawImage(image,phase*160,row*160,160,160);
 const a=image.getContext('2d').getImageData(0,0,320,210).data,b=wardrobe.frame(species,1,OUTFITS.dulce).getContext('2d').getImageData(0,0,320,210).data;assert.deepEqual(a,b);
 for(const pose of [1,4])for(const look of [[],...Object.keys(wardrobe.feet).map(item=>[item])]){
  const first=wardrobe.walkFrame(species,pose,look,2).toBuffer('image/png'),second=wardrobe.walkFrame(species,pose,look,6).toBuffer('image/png');assert.notDeepEqual(first,second);
 }
 assert.equal(wardrobe.walkFrame(species,0,[],phase),wardrobe.frame(species,0,[]));
}
fs.writeFileSync('outputs/guardian-gait/contact.png',c.toBuffer('image/png'));console.log('Four species: alternating bare/equipped feet while running and firing; upper body and idle unchanged.');