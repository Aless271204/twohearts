import {PixelWardrobe} from '../assets/runner/guardian/wardrobe.js';
// Offline render of the same Canvas renderer. Not a browser/device screenshot.
import {createRequire} from 'node:module';import fs from 'node:fs';import path from 'node:path';
import {GuardianRenderer} from '../assets/runner/guardian/render.js';
import {createGame,stepGame} from '../assets/runner/guardian/engine.js';
import {INPUT,ARENA} from '../assets/runner/guardian/config.js';
const require=createRequire(import.meta.url),packages=process.env.NIDO_NODE_PACKAGES??'C:/Users/Lenovo/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules';
const {createCanvas,loadImage}=require(path.join(packages,'@napi-rs/canvas'));
globalThis.document={createElement:()=>createCanvas(1,1)};
const canvas=createCanvas(960,540),renderer=new GuardianRenderer(canvas);
for(const name of ['forest','musgo','enemies','items','tiles','pets-base','wardrobe-atlas',...['shirt_love','jacket_denim','coat_cloud','dress_petal','hoodie_nido'].map(k=>'body-'+k)]){const image=await loadImage('assets/runner/guardian/'+name+'.webp');renderer.images[name]=image;if(!['forest','pets-base','wardrobe-atlas'].includes(name)&&!name.startsWith('body-'))renderer.frames[name]=renderer.measure(image,name==='items'?4:3,['items','tiles'].includes(name)?3:2);}
const feet=Object.fromEntries(await Promise.all(['shoes_heart','boots_rain','slippers_cloud','shoes_chic','sandals_summer'].map(async k=>[k,await loadImage('assets/runner/guardian/feet-'+k+'.webp')])));
renderer.wardrobe=new PixelWardrobe(renderer.images['pets-base'],renderer.images['wardrobe-atlas'],undefined,{bodies:Object.fromEntries(['shirt_love','jacket_denim','coat_cloud','dress_petal','hoodie_nido'].map(k=>[k,renderer.images['body-'+k]])),feet});
fs.mkdirSync('outputs/guardian-review',{recursive:true});
const states=[];const pathState=createGame(17,'easy','solo');for(let i=0;i<120;i++)stepGame(pathState,[INPUT.right|INPUT.pulse]);states.push(['path',pathState]);
for(const action of ['warning','roll','expose','ward']){const s=createGame(17,'hard','partner',['pig','chick']);s.stage='boss';s.frame=130;s.boss.action=action;s.boss.next='roll';s.boss.timer=40;s.boss.vx=-6.3;s.players[0].x=ARENA+270;s.players[1].x=ARENA+380;s.players[1].y=320;s.players[1].ground=false;s.players[1].vy=-4;states.push([action,s]);}
for(const [name,s]of states){renderer.camera=s.stage==='boss'?ARENA:0;renderer.draw(s);fs.writeFileSync('outputs/guardian-review/'+name+'.webp',canvas.toBuffer('image/png'));}
fs.writeFileSync('outputs/guardian-review/sprite-bounds.json',JSON.stringify(renderer.frames,null,2));console.log('Actual Canvas renderer: five offline scenes written to outputs/guardian-review');
