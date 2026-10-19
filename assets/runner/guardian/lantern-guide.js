import {RUNE_X} from './config.js';
export function lanternGuide(s,side=0){
 if(s.stage!=='boss'||s.boss.action!=='ward')return null;
 const alone=s.players.filter(p=>p.hp>0).length===1,window=alone?420:80;
 const lit=s.sigils.map(frame=>s.frame-frame<=window),p=s.players[side];
 const near=RUNE_X.findIndex(x=>Math.abs(x-p.x)<100),count=lit.filter(Boolean).length;
 return {lit,count,near,button:near>=0?'Encender':'Disparar',title:`Enciende los dos farolitos · ${count}/2`,
  hint:near>=0?(alone?'Mantén Disparar; después ve al otro farol.':'Mantén Disparar mientras tu pareja enciende el otro.'):'Acércate a un farol y pulsa Disparar.',
  seconds:alone&&count===1?Math.max(0,Math.ceil((window-(s.frame-s.sigils[lit[0]?0:1]))/60)):null};
}
