import * as THREE from 'three';

// Each product is an independent mesh origin: floor Y=0, wall +Z, ceiling Y=0.
// Shared construction details keep the reference collections practical on mobile.
export const CHILD_ROOM_PALETTES={
 gamer:['#625299','#3EADB5','#D9B6EA','#313351'],
 space:['#29456D','#6DAACF','#F4C55E','#D9E6EF'],
 cars:['#DF4F46','#55B8C5','#F4C55E','#394857'],
 dolls:['#E7A6B8','#98CBB7','#C8B3DC','#FFF1DF'],
 castle:['#B59BD5','#8EBBD3','#E0BA70','#F4EADB'],
 worldcup:['#408C61','#4288B8','#F1CA55','#E46550'],
 knights:['#35654E','#B76148','#D7AD61','#655149'],
 cities:['#5AADB1','#DB866D','#ECC56E','#5E777D'],
};
export function buildChildrenRoomPiece(style,H){
 if(!style.startsWith('nursery_'))return false;
 const [,theme,...suffix]=style.split('_'),part=suffix.join('_'),P=CHILD_ROOM_PALETTES[theme];if(!P)return false;
 const {mesh,box,soft,cylinder,rounded,heart,cream,wood}=H;
 const [main,accent,gold,dark]=P;
 // Lower tessellation than pet meshes; all detail is batched by material upstream.
 const ball=(rx,ry,rz,c,x=0,y=0,z=0)=>{const m=mesh(new THREE.SphereGeometry(1,16,10),c,x,y,z);m.scale.set(rx,ry,rz);return m;};
 const disk=(r,h,c,x=0,y=0,z=0)=>mesh(new THREE.CylinderGeometry(r,r,h,20),c,x,y,z);
 const rod=(a,b,r,c)=>{const v=new THREE.Vector3(...a),w=new THREE.Vector3(...b),d=w.clone().sub(v),m=mesh(new THREE.CylinderGeometry(r,r,d.length(),8),c,...v.add(w).multiplyScalar(.5).toArray());m.quaternion.setFromUnitVectors(new THREE.Vector3(0,1,0),d.normalize());return m;};
 const star=(x,y,z,r=.06,c=gold)=>{const s=new THREE.Shape();for(let i=0;i<10;i++){const a=Math.PI/2+i*Math.PI/5,rr=i%2?r*.43:r;i?s.lineTo(Math.cos(a)*rr,Math.sin(a)*rr):s.moveTo(Math.cos(a)*rr,Math.sin(a)*rr);}s.closePath();return mesh(new THREE.ExtrudeGeometry(s,{depth:.012,bevelEnabled:false}),c,x,y,z);};
 const ring=(r,c,x,y,z)=>mesh(new THREE.TorusGeometry(r,.009,6,32),c,x,y,z);
 const legs=(w,d,h=.12)=>{for(const x of [-w,w])for(const z of [-d,d])disk(.025,h,wood,x,h/2,z);};
 function emblem(x,y,z,r=.10){
  if(theme==='dolls'){heart(accent,x,y,z,r);return;}
  if(theme==='cars'){for(let i=0;i<4;i++)for(let j=0;j<3;j++)box(r*.46,r*.46,.012,(i+j)%2?cream:dark,x+(i-1.5)*r*.46,y+(j-1)*r*.46,z);return;}
  if(theme==='worldcup'){ball(r,r,.018,cream,x,y,z);for(let i=0;i<5;i++){const a=i*Math.PI*2/5;ball(r*.19,r*.19,.008,dark,x+Math.sin(a)*r*.60,y+Math.cos(a)*r*.60,z+.019);}ball(r*.23,r*.23,.008,dark,x,y,z+.02);return;}
  if(theme==='knights'){const s=new THREE.Shape();s.moveTo(-r,r);s.lineTo(r,r);s.lineTo(r*.85,-r*.3);s.quadraticCurveTo(r*.65,-r,0,-r*1.3);s.quadraticCurveTo(-r*.65,-r,-r*.85,-r*.3);s.closePath();mesh(new THREE.ExtrudeGeometry(s,{depth:.014,bevelEnabled:false}),gold,x,y,z);heart(main,x,y,z+.017,r*.6);return;}
  if(theme==='gamer'){rounded(r*2.2,r,.045,accent,x,y,z,.015);box(r*.6,r*.16,.012,cream,x-r*.6,y,z+.028);box(r*.16,r*.6,.012,cream,x-r*.6,y,z+.028);for(const yy of [-r*.17,r*.17])ball(r*.10,r*.10,.01,gold,x+r*.60,y+yy,z+.028);return;}
  if(theme==='cities'){ball(r,r,.02,accent,x,y,z);for(const sign of [-1,1])rod([x+sign*r*.55,y-r*.65,z+.025],[x+sign*r*.1,y+r*.7,z+.025],.007,gold);box(r*.85,.01,.008,gold,x,y,z+.03);return;}
  star(x,y,z,r,gold);
 }
 function bookRow(y,count=5){for(let i=0;i<count;i++){const h=.15+(i%3)*.022;rounded(.048,h,.13,[main,accent,gold,cream][i%4],-.16+i*.075,y+h/2,.035,.006);box(.032,.009,.006,cream,-.16+i*.075,y+.035,.104);}}
 function tower(x,y,z,h=.6){disk(.075,h,cream,x,y+h/2,z);mesh(new THREE.ConeGeometry(.11,.22,16),main,x,y+h+.11,z);star(x,y+h+.24,z,.032,gold);rounded(.035,.09,.012,accent,x,y+h*.6,z+.075,.01);}
 function screen(x,y,z){rounded(.47,.30,.04,dark,x,y,z,.02);rounded(.42,.25,.01,accent,x,y,z+.024,.008);star(x+.1,y+.05,z+.033,.035,gold);box(.23,.018,.008,main,x-.035,y-.06,z+.033);disk(.014,.10,dark,x,y-.20,z);rounded(.15,.015,.09,dark,x,y-.25,z,.005);}
 function mattress(){rounded(.79,.13,1.02,cream,0,.34,0,.045);rounded(.78,.085,.65,main,0,.435,.17,.03);rounded(.57,.09,.23,accent,0,.445,-.33,.035);for(const x of [-.38,.38])box(.008,.012,.58,gold,x,.481,.17);}
 if(part==='bed'){
  legs(.34,.41,.11);rounded(.88,.17,1.12,wood,0,.20,0,.035);mattress();
  if(theme==='cars'){
   for(const x of [-.44,.44]){rounded(.055,.28,1.13,main,x,.29,0,.02);for(const z of [-.34,.34]){const w=disk(.14,.07,dark,x,.14,z);w.rotation.z=Math.PI/2;const hub=disk(.066,.075,cream,x,.14,z);hub.rotation.z=Math.PI/2;}}rounded(.88,.24,.11,main,0,.27,.57,.035);for(const x of [-.29,.29])ball(.07,.035,.018,gold,x,.30,.634);box(.12,.014,1.10,cream,0,.489,.02);rounded(.84,.40,.09,accent,0,.54,-.53,.025);
  }else if(theme==='space'){
   rounded(.83,.65,.12,cream,0,.62,-.54,.065);ball(.40,.30,.075,cream,0,.98,-.54);ball(.27,.24,.018,accent,0,.82,-.46);ring(.26,gold,0,.82,-.435);for(const x of [-.46,.46]){const fin=rounded(.16,.34,.47,accent,x,.22,.22,.035);fin.rotation.z=Math.sign(x)*-.15;}rounded(.86,.25,.16,cream,0,.31,.56,.05);emblem(0,.33,.65,.085);
  }else if(theme==='castle'){
   rounded(.83,.86,.12,cream,0,.73,-.53,.02);for(const x of [-.44,.44])tower(x,.12,-.53,.91);for(let i=0;i<5;i++)rounded(.09,.10,.13,cream,-.32+i*.16,1.20,-.53,.01);emblem(0,.88,-.45,.12);rounded(.87,.22,.09,cream,0,.32,.53,.01);for(const x of [-.35,-.175,0,.175,.35])rounded(.08,.08,.10,cream,x,.465,.53,.008);
  }else if(theme==='dolls'){
   rounded(.86,.52,.12,accent,0,.54,-.54,.03);for(const x of [-.43,.43])for(const z of [-.52,.52]){disk(.018,1.25,cream,x,.625,z);ball(.035,.035,.035,gold,x,1.285,z);}rounded(.92,.055,1.15,main,0,1.24,0,.02);for(const z of [-.56,.56])for(let i=0;i<9;i++)ball(.06,.09,.02,main,-.40+i*.10,1.18,z);for(const x of [-.43,.43])for(const z of [-.43,.43])rounded(.055,.75,.16,main,x,.84,z,.02);emblem(0,.64,-.46,.1);
  }else if(theme==='worldcup'){
   for(const x of [-.44,.44])rounded(.055,.89,.06,cream,x,.555,-.54,.015);rounded(.91,.055,.06,cream,0,.99,-.54,.015);for(let i=0;i<8;i++)box(.006,.65,.012,cream,-.38+i*.11,.64,-.55);for(let j=0;j<6;j++)box(.84,.006,.012,cream,0,.33+j*.12,-.55);for(const x of [-.24,0,.24])box(.12,.007,.58,accent,x,.482,.17);emblem(0,.46,.505,.09);
  }else{
   rounded(.86,.65,.12,theme==='knights'?wood:main,0,.60,-.54,.035);emblem(0,.75,-.465,.12);rounded(.86,.19,.09,accent,0,.30,.54,.025);for(const x of [-.31,.31])ball(.09,.08,.03,gold,x,.34,.598);
  }
 }else if(part==='chair'){
  legs(.22,.19,.14);rounded(.59,.16,.53,main,0,.24,0,.05);rounded(.56,.51,.12,main,0,.56,-.23,.05);rounded(.46,.065,.43,cream,0,.355,.015,.03);for(const x of [-.275,.275])rounded(.10,.22,.46,accent,x,.39,.015,.03);emblem(0,.63,-.16,.095);if(theme==='castle')for(const x of [-.22,0,.22])star(x,.85,-.21,.05,gold);
 }else if(part==='desk'){
  legs(.32,.17,.48);rounded(.76,.05,.43,wood,0,.505,0,.02);rounded(.23,.32,.35,main,-.23,.33,0,.02);for(const y of [.25,.39]){rounded(.20,.115,.012,accent,-.23,y,.185,.004);ball(.016,.009,.012,gold,-.23,y,.201);}
  if(theme==='gamer') {screen(.08,.78,-.08);rounded(.25,.015,.10,accent,.04,.545,.11,.004);for(let i=0;i<7;i++)box(.023,.005,.065,cream,-.06+i*.032,.557,.11);ball(.027,.012,.035,main,.25,.55,.10);}
  else if(theme==='dolls'){ball(.23,.27,.025,gold,.05,.83,-.13);ball(.20,.24,.009,accent,.05,.83,-.099);heart(main,.05,1.08,-.078,.05);}
  else{rounded(.22,.007,.18,cream,.07,.535,.03,.002);for(const x of [-.01,.04,.09,.14])rod([x,.545,.03],[x+.03,.545,.10],.004,accent);disk(.042,.09,accent,.24,.58,-.1);for(let i=0;i<3;i++)rod([.22+i*.016,.61,-.10],[.22+i*.016,.73,-.10],.004,[main,gold,cream][i]);}
 }else if(part==='shelf'){
  legs(.23,.10,.12);rounded(.57,.99,.035,main,0,.635,-.14,.01);for(const x of [-.27,.27])rounded(.035,1.0,.30,accent,x,.63,0,.01);for(const y of [.15,.47,.80,1.12])rounded(.58,.035,.31,cream,0,y,0,.008);bookRow(.49);bookRow(.82,4);
  if(theme==='space'){mesh(new THREE.ConeGeometry(.32,.28,20),cream,0,1.28,0);for(const x of [-.32,.32])ball(.09,.18,.09,accent,x,.24,0);}
  else if(theme==='castle')for(const x of [-.29,.29])tower(x,.12,0,1.02);
  else if(theme==='dolls'){const s=new THREE.Shape();s.moveTo(-.33,1.14);s.lineTo(0,1.39);s.lineTo(.33,1.14);s.closePath();mesh(new THREE.ExtrudeGeometry(s,{depth:.31,bevelEnabled:false}),main,0,0,-.15);}
  else{rounded(.60,.05,.33,wood,0,1.15,0,.01);emblem(0,.30,.04,.09);}
 }else if(part==='dresser'){
  legs(.24,.13);rounded(.63,.59,.36,main,0,.415,0,.025);rounded(.68,.045,.41,wood,0,.73,0,.015);for(const [i,y] of [.24,.43,.62].entries()){rounded(.55,.155,.025,i===1?accent:cream,0,y,.194,.009);for(const x of [-.15,.15])ball(.018,.012,.013,gold,x,y,.217);}if(theme==='worldcup')for(let i=0;i<3;i++){const x=(i-1)*.18;disk(.04,.025,dark,x,.765,0);disk(.012,.07,gold,x,.81,0);mesh(new THREE.CylinderGeometry(.055,.022,.085,16),gold,x,.89,0);for(const sign of [-1,1]){const handle=ring(.035,gold,x+sign*.049,.90,0);handle.scale.x=.7;}}
 }else if(part==='lamp'){
  disk(.13,.035,wood,0,.0175,0);disk(.012,.62,gold,0,.345,0);
  if(theme==='space'){ball(.16,.16,.16,gold,0,.82,0);const r=ring(.24,accent,0,.82,0);r.rotation.x=1.1;}
  else if(theme==='cars'){rounded(.14,.35,.11,dark,0,.82,0,.02);for(const [y,c] of [[.93,main],[.82,gold],[.71,accent]])ball(.038,.038,.01,c,0,y,.062);}
  else if(theme==='dolls'){for(let i=0;i<6;i++){const a=i*Math.PI/3;ball(.075,.10,.035,main,Math.sin(a)*.11,.82+Math.cos(a)*.11,0);}ball(.065,.065,.045,gold,0,.82,.02);}
  else{mesh(new THREE.CylinderGeometry(.13,.20,.23,24),accent,0,.85,0);disk(.17,.012,cream,0,.729,0);emblem(0,.86,.17,.055);}
 }else if(part==='rug'){
  rounded(1.30,.026,.92,main,0,.013,0,.012);
  if(theme==='worldcup'){for(const z of [-.40,.40])box(1.18,.005,.014,cream,0,.029,z);for(const x of [-.59,0,.59])box(.014,.005,.80,cream,x,.029,0);const r=ring(.13,cream,0,.03,0);r.rotation.x=-Math.PI/2;for(const x of [-.46,.46]){box(.012,.005,.34,cream,x,.03,0);for(const z of [-.17,.17])box(.13,.005,.012,cream,x+Math.sign(x)*.065,.03,z);}}
  else if(theme==='cars'){for(const z of [-.27,.27])rounded(1.03,.005,.14,dark,0,.03,z,.002);for(const x of [-.48,.48])rounded(.14,.005,.54,dark,x,.03,0,.002);for(let i=0;i<9;i++)for(const z of [-.27,.27])box(.045,.005,.012,gold,-.4+i*.10,.036,z);}
  else if(theme==='castle'||theme==='dolls'){for(let i=0;i<12;i++){const a=i*Math.PI/6;ball(.13,.013,.13,main,Math.sin(a)*.55,.013,Math.cos(a)*.36);}for(const x of [-.26,0,.26]){const m=theme==='dolls'?heart(cream,x,.032,0,.1):star(x,0,0,.1,cream);m.rotation.x=-Math.PI/2;if(theme==='castle')m.position.y=.03;}}
  else if(theme==='gamer'){rounded(.70,.008,.36,accent,0,.031,0,.003);box(.17,.005,.045,cream,-.21,.039,0);box(.045,.005,.17,cream,-.21,.039,0);for(const [x,z] of [[.2,-.08],[.29,0],[.11,0],[.2,.08]])ball(.028,.004,.028,gold,x,.04,z);}
  else for(let i=0;i<7;i++){const m=star(Math.sin(i*2.4)*.47,0,Math.cos(i*2.4)*.30,.065,gold);m.rotation.x=-Math.PI/2;m.position.y=.03;}
 }else if(part==='frame'){
  rounded(.70,.44,.045,wood,0,0,0,.012);rounded(.63,.37,.008,accent,0,0,.028,.003);
  if(theme==='cities'){for(const [i,h] of [.10,.17,.23,.14,.11].entries())box(.055,h,.012,i%2?cream:main,-.24+i*.115,-.15+h/2,.04);for(const sign of [-1,1])rod([sign*.085,-.14,.06],[sign*.013,.12,.06],.008,gold);rod([0,.12,.06],[0,.16,.06],.004,gold);box(.12,.014,.012,gold,0,-.03,.06);}
  else{emblem(0,0,.043,.13);for(const x of [-.24,.24])star(x,.10,.04,.025,gold);}
 }else if(part==='pendant'){
  disk(.09,.02,wood,0,-.01,0);disk(.006,.23,gold,0,-.135,0);
  if(theme==='space'){for(let i=0;i<3;i++){const x=(i-1)*.22,y=-.35-(i%2)*.11;rod([0,-.22,0],[x,y,0],.004,gold);ball(.07,.07,.07,[main,accent,gold][i],x,y,0);const r=ring(.10,cream,x,y,0);r.rotation.x=1.15;}}
  else if(theme==='knights'||theme==='castle'){const r=ring(.25,gold,0,-.30,0);r.rotation.x=-Math.PI/2;for(let i=0;i<5;i++){const a=i*Math.PI*2/5,x=Math.sin(a)*.25,z=Math.cos(a)*.25;disk(.016,.11,cream,x,-.30,z);ball(.017,.027,.017,gold,x,-.22,z);}}
  else{mesh(new THREE.CylinderGeometry(.10,.22,.20,24),main,0,-.31,0);disk(.19,.012,cream,0,-.415,0);for(let i=0;i<6;i++){const a=i*Math.PI/3;ball(.024,.025,.024,accent,Math.sin(a)*.17,-.41,Math.cos(a)*.17);}}
 }else if(part==='curtain'){
  rod([-.47,.40,0],[.47,.40,0],.015,wood);for(const sign of [-1,1]){ball(.03,.03,.03,gold,sign*.48,.40,0);for(let i=0;i<5;i++)rounded(.055,.77,.04,i%2?main:accent,sign*(.29+i*.026),-.005,i%2?.02:0,.015);rounded(.16,.04,.065,gold,sign*.34,-.12,.035,.01);}rounded(.88,.11,.055,main,0,.32,.012,.015);
 }else if(part==='chest'){
  rounded(.57,.31,.35,main,0,.180,0,.025);rounded(.59,.07,.37,wood,0,.345,0,.025);for(const x of [-.20,.20])rounded(.03,.30,.018,gold,x,.17,.184,.006);rounded(.055,.07,.018,gold,0,.29,.197,.006);emblem(0,.16,.19,.065);
 }else if(part==='plant'){
  mesh(new THREE.CylinderGeometry(.11,.08,.20,20),accent,0,.10,0);disk(.095,.008,wood,0,.202,0);for(let i=0;i<7;i++){const a=i*2.4,y=.29+i%3*.065;rod([0,.2,0],[Math.sin(a)*.10,y,Math.cos(a)*.10],.004,main);const leaf=ball(.035,.075,.016,main,Math.sin(a)*.10,y,Math.cos(a)*.10);leaf.rotation.z=Math.sin(a)*.6;}emblem(0,.10,.105,.04);
 }else if(part==='toy'){
  if(theme==='space'||theme==='cities'){disk(.12,.025,wood,0,.0125,0);rod([0,.02,0],[0,.17,0],.015,gold);ball(.13,.13,.13,accent,0,.30,0);const r=ring(.15,gold,0,.30,0);r.rotation.z=.25;for(let i=0;i<5;i++)ball(.035,.025,.012,main,Math.sin(i*2)*.09,.30+Math.cos(i*2)*.09,.10);}
  else if(theme==='cars'){rounded(.34,.10,.19,main,0,.09,0,.025);rounded(.18,.10,.16,accent,0,.18,-.025,.025);for(const x of [-.17,.17])for(const z of [-.055,.055]){const w=disk(.044,.022,dark,x,.044,z);w.rotation.z=Math.PI/2;}for(const x of [-.10,.10])ball(.02,.014,.01,gold,x,.11,.10);}
  else if(theme==='worldcup'){ball(.17,.17,.17,cream,0,.17,0);for(let i=0;i<5;i++){const a=i*Math.PI*2/5;ball(.034,.034,.013,dark,Math.sin(a)*.10,.17+Math.cos(a)*.10,.132);}ball(.04,.04,.012,dark,0,.17,.165);}
  else if(theme==='knights'){disk(.12,.025,wood,0,.0125,0);rod([0,.02,0],[0,.36,0],.014,wood);rounded(.19,.17,.10,accent,0,.32,0,.025);ball(.08,.09,.07,cream,0,.46,0);rounded(.12,.022,.012,dark,0,.46,.065,.004);emblem(0,.32,.06,.045);}
  else if(theme==='dolls'||theme==='castle'){rounded(.27,.25,.20,cream,0,.125,0,.01);const s=new THREE.Shape();s.moveTo(-.17,.25);s.lineTo(0,.39);s.lineTo(.17,.25);s.closePath();mesh(new THREE.ExtrudeGeometry(s,{depth:.21,bevelEnabled:false}),main,0,0,-.105);rounded(.05,.09,.012,accent,0,.045,.108,.004);for(const x of [-.075,.075])rounded(.04,.05,.012,gold,x,.17,.108,.004);}
  else{rounded(.31,.10,.18,main,0,.075,0,.025);box(.08,.008,.022,cream,-.08,.158,0);box(.022,.008,.08,cream,-.08,.158,0);for(const z of [-.035,.035])ball(.018,.006,.018,gold,.08,.158,z);}
 }else if(part==='special_one'){
  if(theme==='gamer'){rounded(.22,.44,.35,dark,0,.235,0,.015);rounded(.18,.36,.012,main,0,.24,.184,.008);for(const y of [.14,.32]){const r=ring(.055,accent,0,y,.20);ball(.020,.020,.01,gold,0,y,.203);}legs(.075,.12,.03);}
  else if(theme==='space'){
   for(let i=0;i<3;i++){const a=i*Math.PI*2/3;rod([0,.56,0],[Math.sin(a)*.20,.014,Math.cos(a)*.20],.014,wood);}const tube=mesh(new THREE.CylinderGeometry(.07,.06,.42,20),main,0,.63,0);tube.rotation.z=-.95;const lens=mesh(new THREE.CylinderGeometry(.061,.061,.012,20),accent,.173,.755,0);lens.rotation.z=-.95;rod([-.10,.58,0],[-.18,.51,0],.012,gold);
  }else if(theme==='cars'){
   const tire=disk(.25,.20,dark,0,.10,0);const hole=disk(.14,.012,accent,0,.208,0);for(let i=0;i<12;i++){const a=i*Math.PI/6,block=box(.04,.07,.025,main,Math.sin(a)*.245,.10,Math.cos(a)*.245);block.rotation.y=a;}ball(.18,.035,.18,cream,0,.23,0);
  }else if(theme==='dolls'||theme==='knights'){
   disk(.16,.04,wood,0,.02,0);disk(.045,.35,wood,0,.215,0);disk(.34,.045,wood,0,.415,0);disk(.30,.006,theme==='dolls'?main:accent,0,.441,0);
   for(const x of [-.14,.14]){disk(.07,.008,cream,x,.452,0);disk(.038,.047,cream,x,.48,0);disk(.031,.003,wood,x,.505,0);const handle=ring(.025,gold,x+.044,.48,0);handle.scale.y=.8;}
   if(theme==='dolls'){ball(.075,.065,.075,accent,0,.51,-.11);disk(.035,.01,gold,0,.575,-.11);rod([.04,.54,-.11],[.12,.57,-.11],.017,accent);}
  }else if(theme==='castle'){
   legs(.23,.11,.42);rounded(.59,.04,.33,wood,0,.45,0,.015);ball(.21,.27,.026,gold,0,.78,-.10);ball(.18,.24,.008,accent,0,.78,-.068);for(const x of [-.20,.20])tower(x,.48,-.10,.40);
  }else if(theme==='worldcup'){
   legs(.38,.16,.24);rounded(.91,.06,.38,wood,0,.275,0,.02);for(const x of [-.37,.37])box(.04,.25,.04,accent,x,.42,-.15);for(const y of [.43,.54])rounded(.90,.06,.04,main,0,y,-.15,.01);
  }else{
   rounded(.47,.28,.31,main,0,.155,0,.015);rounded(.50,.04,.33,wood,0,.315,0,.012);for(const x of [-.17,.17])rounded(.03,.24,.018,gold,x,.16,.17,.005);rounded(.13,.025,.025,wood,0,.355,0,.008);for(const x of [-.19,.19]){const wheel=disk(.03,.025,dark,x,.03,-.11);wheel.rotation.z=Math.PI/2;}emblem(0,.16,.18,.06);
  }
 }else if(part==='special_two'){
  if(theme==='gamer'){for(const x of [-.14,.14]){rounded(.18,.28,.15,dark,x,.155,0,.012);for(const y of [.09,.22]){const r=ring(y<.10?.05:.025,accent,x,y,.086);ball(y<.10?.035:.016,y<.10?.035:.016,.012,main,x,y,.089);}}}
  else if(theme==='space'||theme==='castle'){
   ball(.25,.16,.25,theme==='space'?gold:cream,0,.16,0);if(theme==='space')for(let i=0;i<6;i++){const a=i*2.4;ball(.04,.009,.03,accent,Math.sin(a)*.16,.29-Math.abs(Math.sin(a))*.025,Math.cos(a)*.13);}else for(const x of [-.18,0,.18])ball(.13,.13,.16,cream,x,.13,0);
  }else if(theme==='cars'){
   rounded(.27,.03,.27,dark,0,.016,0,.01);mesh(new THREE.ConeGeometry(.11,.30,20),main,0,.18,0);disk(.067,.035,cream,0,.145,0);disk(.038,.03,cream,0,.23,0);
  }else if(theme==='dolls'){
   legs(.13,.13,.24);rounded(.34,.085,.34,main,0,.285,0,.03);rounded(.31,.035,.31,cream,0,.342,0,.015);for(let i=0;i<6;i++){const a=i*Math.PI/3;ball(.035,.008,.035,accent,Math.sin(a)*.10,.369,Math.cos(a)*.10);}
  }else if(theme==='knights'){
   rounded(.36,.49,.025,main,0,0,0,.01);for(const x of [-.20,.20])ball(.023,.023,.023,gold,x,.28,0);rod([-.20,.28,0],[.20,.28,0],.01,wood);emblem(0,.02,.025,.11);for(let i=0;i<5;i++)star(-.14+i*.07,-.18,.025,.018,gold);
  }else if(theme==='worldcup'){
   rounded(.29,.32,.055,accent,0,0,0,.015);for(const sign of [-1,1]){const sleeve=rounded(.14,.12,.055,accent,sign*.18,.10,0,.012);sleeve.rotation.z=-sign*.35;}rounded(.10,.025,.01,gold,0,.15,.036,.006);box(.025,.12,.012,cream,0,-.015,.036);rod([-.07,.18,0],[0,.23,0],.006,wood);rod([0,.23,0],[.07,.18,0],.006,wood);
  }else{
   rounded(.37,.07,.07,main,0,0,0,.025);rounded(.15,.016,.34,accent,-.02,0,0,.006);rounded(.07,.07,.035,accent,-.15,.04,0,.008);ball(.04,.025,.03,gold,.16,0,0);rod([-.12,.10,0],[.12,.10,0],.004,gold);
  }
 }else if(part==='wall'){
  box(4,2.7,.075,main,0,1.35,-2.40);for(const x of [-2,2])box(.075,2.7,3.5,main,x,1.35,-.65);box(4,.80,.025,accent,0,.40,-2.35);for(const x of [-1.95,1.95])box(.025,.80,3.5,accent,x,.40,-.65);box(4,.035,.04,gold,0,.81,-2.32);box(4,.10,.045,cream,0,.05,-2.32);
  for(let i=0;i<12;i++){const x=-1.70+(i%6)*.64,y=1.20+Math.floor(i/6)*.78;emblem(x,y,-2.345,.06);}
 }else if(part==='floor'){
  box(4,.055,3.5,wood,0,-.0275,-.65);for(let i=0;i<16;i++){const z=-2.30+i*.21;box(4,.002,.005,gold,0,.002,z);for(let j=0;j<5;j++)box(.004,.002,.20,gold,Math.min(1.97,-1.75+j*.8+(i%2)*.35),.002,z+.1);}
 }else return false;
 return true;
}


