import * as THREE from 'three';

// Reproducible toy-scale furnishings. Built with the room's existing material
// cache and batching pipeline; no extra renderer, texture atlas or pet model.
export function buildThemedRoomPiece(style,H){
 const {mesh,box,soft,cylinder,rounded,heart,color,cream,wood,gold}=H;
 const dark='#51485E',mint='#AED9CF',pink='#EAB5C8',blue='#B5D1E8';
 const star=(x,y,z,r=.06,c=gold)=>{const s=new THREE.Shape();for(let i=0;i<10;i++){const a=Math.PI/2+i*Math.PI/5,rr=i%2?r*.45:r;const p=[Math.cos(a)*rr,Math.sin(a)*rr];i?s.lineTo(...p):s.moveTo(...p);}s.closePath();return mesh(new THREE.ExtrudeGeometry(s,{depth:.012,bevelEnabled:true,bevelSize:.003,bevelThickness:.003,bevelSegments:1}),c,x,y,z);};
 const rod=(a,b,r,c)=>{const from=new THREE.Vector3(...a),to=new THREE.Vector3(...b),delta=to.clone().sub(from),m=mesh(new THREE.CylinderGeometry(r,r,delta.length(),10),c,...from.clone().add(to).multiplyScalar(.5).toArray());m.quaternion.setFromUnitVectors(new THREE.Vector3(0,1,0),delta.normalize());return m;};
 const feet=(x=.25,z=.18,h=.12)=>{for(const xx of [-x,x])for(const zz of [-z,z])cylinder(.025,h,wood,xx,h/2,zz);};
 function seat(backStyle='round',wide=false){const w=wide?1.08:.68;feet(wide?.40:.24,.18);rounded(w,.18,.57,color,0,.23,0,.05);rounded(w-.07,.46,.13,color,0,.50,-.24,.045);for(const x of [-(w/2-.025),w/2-.025])rounded(.13,.30,.51,color,x,.36,0,.045);if(wide){for(const x of [-.23,.23])soft(.22,.06,.23,cream,x,.36,.025);}else soft(.25,.06,.23,cream,0,.36,.025);if(backStyle==='heart')heart(pink,0,.56,-.155,.115);}
 const screen=(x,y,z,w=.45,h=.27)=>{rounded(w,h,.045,dark,x,y,z,.015);rounded(w-.035,h-.035,.008,blue,x,y,z+.027,.003);star(x+w*.22,y+h*.12,z+.034,.035,cream);};
 const lampBase=()=>{cylinder(.13,.035,wood,0,.0175,0);cylinder(.012,.56,wood,0,.315,0);};
 const rug=()=>soft(.64,.018,.44,color,0,.018,0);
 const frame=()=>{rounded(.74,.42,.04,wood,0,0,0,.012);rounded(.67,.35,.008,cream,0,0,.026,.003);};
 const theme=style.split('_')[0],part=style.slice(theme.length+1);
 if(theme==='gamer'){
  if(part==='desk'){feet(.31,.16,.48);rounded(.77,.045,.44,wood,0,.50,0);screen(0,.72,-.08);cylinder(.015,.12,dark,0,.57,-.08);rounded(.17,.016,.10,dark,0,.534,-.08,.005);rounded(.29,.018,.11,color,-.08,.54,.12,.005);for(let i=0;i<8;i++)rounded(.022,.005,.06,cream,-.195+i*.032,.553,.12,.001);soft(.035,.015,.045,color,.20,.545,.11);}
  else if(part==='chair'){seat();rounded(.18,.055,.04,dark,0,.66,-.155,.012);for(const x of [-.22,.22])rounded(.045,.30,.018,cream,x,.52,-.16,.008);}
  else if(part==='lamp'){lampBase();const pad=soft(.21,.11,.06,color,0,.70,0);for(const x of [-.10,.10])soft(.07,.07,.05,color,x,.65,0);box(.07,.022,.012,cream,-.10,.71,.056);box(.022,.07,.012,cream,-.10,.71,.056);for(const [x,y] of [[.09,.73],[.13,.69]])soft(.012,.012,.008,cream,x,y,.056);}
  else if(part==='rug'){rug();for(const x of [-.12,.12])soft(.15,.006,.12,cream,x,.038,0);box(.11,.005,.025,dark,-.12,.046,0);box(.025,.005,.11,dark,-.12,.046,0);for(const z of [-.04,.04])soft(.018,.004,.018,pink,.13,.046,z);}
  else if(part==='frame'){frame();for(let i=0;i<5;i++){const r=star(-.20+i*.10,Math.sin(i)*.04,.037,.045,i%2?color:pink);r.rotation.z=(i-2)*.07;}}
  else return false;return true;
 }
 if(theme==='space'){
  if(part==='chair'){seat();soft(.32,.24,.10,color,0,.63,-.24);for(const x of [-.18,.18])star(x,.62,-.115,.045,cream);}
  else if(part==='shelf'){feet(.20,.10);rounded(.51,1.06,.04,color,0,.65,-.13,.02);for(const x of [-.25,.25])rounded(.045,1.05,.27,color,x,.65,0,.014);for(const y of [.16,.49,.82,1.14])rounded(.51,.04,.28,cream,0,y,0,.012);mesh(new THREE.ConeGeometry(.29,.25,24),color,0,1.285,-.01);for(let i=0;i<5;i++)rounded(.05,.17,.12,i%2?blue:cream,-.13+i*.06,.60,.04,.008);for(const x of [-.32,.32])soft(.09,.20,.10,color,x,.23,0);}
  else if(part==='lamp'){lampBase();soft(.18,.18,.18,color,0,.78,0);const ring=mesh(new THREE.TorusGeometry(.25,.018,8,48),gold,0,.78,0);ring.rotation.x=1.18;ring.rotation.y=.2;star(.20,1.02,0,.05,cream);}
  else if(part==='rug'){rug();for(let i=0;i<7;i++){const s=star(Math.sin(i*2.4)*.42,0,Math.cos(i*2.4)*.28,.055,cream);s.rotation.x=-Math.PI/2;s.position.y=.04;}}
  else if(part==='frame'){frame();soft(.065,.065,.012,color,-.14,.04,.045);const r=mesh(new THREE.TorusGeometry(.10,.007,6,32),gold,-.14,.04,.058);r.rotation.z=.3;for(let i=0;i<4;i++)star(.02+i*.065,(i%2?-.05:.08),.04,.025,blue);}
  else return false;return true;
 }
 if(theme==='cars'){
  if(part==='bed'){rounded(.76,.22,.94,color,0,.23,0,.055);rounded(.63,.12,.72,cream,0,.35,0,.045);rounded(.59,.06,.22,blue,0,.43,-.22,.025);for(const x of [-.38,.38])for(const z of [-.28,.28]){const wheel=cylinder(.105,.055,dark,x,.105,z);wheel.rotation.z=Math.PI/2;const hub=cylinder(.045,.058,cream,x,.105,z);hub.rotation.z=Math.PI/2;}for(const x of [-.23,.23])soft(.065,.035,.018,cream,x,.25,.478);}
  else if(part==='dresser'){feet(.24,.12);rounded(.61,.54,.33,color,0,.39,0);for(const y of [.25,.40,.55]){rounded(.53,.13,.018,cream,0,y,.18,.007);rounded(.13,.015,.02,dark,0,y,.201,.004);}rounded(.66,.035,.38,wood,0,.69,0,.012);}
  else if(part==='lamp'){lampBase();rounded(.15,.36,.12,dark,0,.80,0,.022);for(const [y,c] of [[.91,pink],[.80,gold],[.69,mint]])soft(.043,.043,.012,c,0,y,.07);}
  else if(part==='rug'){rug();const road=mesh(new THREE.TorusGeometry(.30,.075,4,64),dark,0,.045,0);road.rotation.x=-Math.PI/2;road.scale.y=.7;for(let i=0;i<12;i++){const a=i*Math.PI/6,m=box(.034,.004,.012,cream,Math.sin(a)*.30,.10,Math.cos(a)*.21);m.rotation.y=a;}}
  else if(part==='frame'){frame();for(let i=0;i<5;i++)for(let j=0;j<3;j++)box(.055,.055,.008,(i+j)%2?color:cream,-.20+i*.055,-.055+j*.055,.039);star(.20,.02,.043,.085,gold);}
  else return false;return true;
 }
 if(theme==='dolls'){
  if(part==='sofa'){seat('heart',true);for(let i=0;i<7;i++)soft(.085,.07,.045,color,-.45+i*.15,.76,-.24);}
  else if(part==='vanity'){feet(.26,.13,.45);rounded(.63,.045,.34,color,0,.47,0);soft(.22,.28,.035,wood,0,.80,-.11);soft(.19,.25,.008,blue,0,.80,-.068);for(const x of [-.16,.16])rounded(.09,.10,.07,cream,x,.55,.04,.012);heart(pink,0,1.03,-.045,.06);}
  else if(part==='lamp'){lampBase();for(let i=0;i<6;i++){const a=i*Math.PI/3;const petal=soft(.08,.12,.045,color,Math.sin(a)*.11,.78+Math.cos(a)*.11,0);petal.rotation.z=-a;}soft(.07,.07,.05,gold,0,.78,.025);}
  else if(part==='rug'){rug();for(let i=0;i<10;i++){const a=i*Math.PI/5;soft(.085,.007,.065,cream,Math.sin(a)*.54,.028,Math.cos(a)*.37);}heart(pink,0,.043,0,.18).rotation.x=-Math.PI/2;}
  else if(part==='shelf'){feet(.22,.10);rounded(.54,.83,.025,color,0,.55,-.13);for(const x of [-.26,.26])rounded(.035,.83,.28,color,x,.55,0,.01);for(const y of [.16,.52,.95])rounded(.54,.035,.29,cream,0,y,0,.01);const roof=new THREE.Shape();roof.moveTo(-.32,.96);roof.lineTo(0,1.20);roof.lineTo(.32,.96);roof.closePath();mesh(new THREE.ExtrudeGeometry(roof,{depth:.28,bevelEnabled:false}),pink,0,0,-.14);heart(pink,0,.73,.04,.10);for(let i=0;i<3;i++)rounded(.06,.17,.13,[color,cream,pink][i],-.10+i*.09,.27,.03,.008);}
  else return false;return true;
 }
 if(theme==='castle'){
  if(part==='throne'){seat('heart');for(const x of [-.26,0,.26])star(x,.86-Math.abs(x)*.22,-.23,.065,gold);rounded(.51,.11,.10,color,0,.76,-.24);}
  else if(part==='shelf'){feet(.23,.11);rounded(.57,.95,.04,color,0,.60,-.13);for(const x of [-.27,.27]){cylinder(.07,1.05,color,x,.58,0);mesh(new THREE.ConeGeometry(.10,.22,16),pink,x,1.21,0);}for(const y of [.15,.47,.79,1.06])rounded(.51,.035,.27,cream,0,y,0,.01);for(let i=0;i<4;i++)rounded(.045,.16,.12,i%2?pink:cream,-.12+i*.07,.57,.025,.007);}
  else if(part==='lamp'){lampBase();cylinder(.14,.26,color,0,.73,0);mesh(new THREE.ConeGeometry(.19,.26,24),pink,0,.99,0);star(0,1.15,0,.035,gold);for(const x of [-.06,.06])rounded(.035,.08,.01,cream,x,.76,.137,.006);}
  else if(part==='rug'){rug();for(const x of [-.20,0,.20])heart(cream,x,.04,0,.09).rotation.x=-Math.PI/2;}
  else if(part==='frame'){frame();rounded(.29,.14,.008,color,0,-.06,.04,.005);for(const x of [-.13,.13]){rounded(.07,.23,.008,color,x,-.015,.04,.004);const roof=mesh(new THREE.ConeGeometry(.055,.075,3),pink,x,.14,.044);roof.rotation.y=Math.PI/2;}star(0,.11,.045,.045,gold);}
  else return false;return true;
 }
 if(theme==='worldcup'){
  if(part==='chair'){seat();soft(.18,.18,.06,cream,0,.57,-.135);for(let i=0;i<5;i++){const a=i*Math.PI*2/5;soft(.035,.035,.008,dark,Math.sin(a)*.10,.57+Math.cos(a)*.10,-.068);}soft(.04,.04,.01,dark,0,.57,-.067);}
  else if(part==='shelf'){feet(.25,.12);rounded(.64,.58,.32,color,0,.40,0);rounded(.66,.045,.36,wood,0,.72,0);for(const y of [.26,.49]){rounded(.55,.19,.012,cream,0,y,.18,.004);rounded(.13,.018,.018,dark,0,y,.195,.004);}for(let i=0;i<3;i++){const x=(i-1)*.19;cylinder(.045,.025,dark,x,.755,0);cylinder(.012,.09,gold,x,.81,0);mesh(new THREE.CylinderGeometry(.055,.022,.09,16),gold,x,.90,0);for(const sign of [-1,1]){const handle=mesh(new THREE.TorusGeometry(.035,.006,5,18,Math.PI),gold,x+sign*.045,.91,0);handle.rotation.z=sign*Math.PI/2;}}}
  else if(part==='lamp'){lampBase();rounded(.43,.26,.035,cream,0,.76,0,.015);rounded(.37,.20,.018,color,0,.76,.025,.008);for(let i=0;i<5;i++)box(.005,.20,.006,cream,-.15+i*.075,.76,.039);for(let i=0;i<3;i++)box(.37,.005,.006,cream,0,.69+i*.07,.039);soft(.045,.045,.03,gold,0,.77,.06);}
  else if(part==='rug'){rug();const o=box(.79,.004,.48,cream,0,.040,0);box(.76,.005,.45,color,0,.044,0);box(.008,.006,.45,cream,0,.049,0);const ring=mesh(new THREE.TorusGeometry(.075,.004,4,32),cream,0,.051,0);ring.rotation.x=-Math.PI/2;for(const x of [-.30,.30]){box(.008,.005,.19,cream,x,.051,0);for(const z of [-.095,.095])box(.08,.005,.008,cream,x+Math.sign(x)*.04,.051,z);}}
  else if(part==='frame'){frame();for(const x of [-.19,0,.19]){rod([x,-.12,.04],[x,.12,.04],.003,wood);for(let i=0;i<3;i++)box(.045,.04,.008,[color,gold,cream][i],x+.022,.09-i*.04,.047);}star(-.25,.08,.04,.04,gold);}
  else return false;return true;
 }
 if(theme==='knights'){
  if(part==='chair'){seat();rounded(.46,.19,.08,color,0,.77,-.24,.018);star(0,.77,-.18,.07,gold);for(const x of [-.31,.31])soft(.06,.06,.06,gold,x,.54,.17);}
  else if(part==='table'){cylinder(.18,.06,wood,0,.03,0);cylinder(.085,.36,wood,0,.23,0);cylinder(.36,.05,wood,0,.44,0);for(let i=0;i<6;i++){const a=i*Math.PI/3;star(Math.sin(a)*.25,.473,Math.cos(a)*.25,.04,gold).rotation.x=-Math.PI/2;}soft(.07,.015,.07,color,0,.48,0);}
  else if(part==='stand'){feet(.18,.09);cylinder(.022,.80,wood,0,.52,0);rounded(.32,.29,.14,color,0,.76,0,.04);soft(.13,.14,.12,cream,0,1.02,0);rounded(.19,.045,.02,dark,0,1.02,.116,.006);for(const sign of [-1,1])rod([sign*.14,.81,0],[sign*.24,.61,.02],.045,color);heart(gold,0,.77,.081,.09);}
  else if(part==='lamp'){lampBase();rounded(.18,.19,.12,wood,0,.71,0);for(let i=0;i<3;i++)soft(.035,.09,.025,i%2?gold:cream,(i-1)*.037,.88+(i%2)*.035,0);}
  else if(part==='frame'){frame();const shield=new THREE.Shape();shield.moveTo(-.13,.12);shield.lineTo(.13,.12);shield.lineTo(.12,-.04);shield.quadraticCurveTo(.09,-.12,0,-.15);shield.quadraticCurveTo(-.09,-.12,-.12,-.04);shield.closePath();mesh(new THREE.ExtrudeGeometry(shield,{depth:.012,bevelEnabled:true,bevelSize:.006,bevelThickness:.004,bevelSegments:2}),color,0,0,.038);star(0,.015,.06,.06,gold);}
  else return false;return true;
 }
 if(style.startsWith('city_')){
  frame();rounded(.65,.33,.006,blue,0,0,.033,.002);box(.65,.035,.008,mint,0,-.145,.041);
  for(let i=0;i<9;i++){const h=.055+(i*7%5)*.022;box(.040,h,.008,i%2?cream:color,-.29+i*.071,-.127+h/2,.045);}
  const city=style.slice(5);const base=-.12;
  if(city==='paris'){for(const sign of [-1,1])rod([sign*.09,base,.063],[sign*.015,.12,.063],.007,color);for(const y of [-.045,.025])box(y<0?.13:.075,.012,.013,color,0,y,.065);rod([0,.10,.063],[0,.155,.063],.004,color);}
  else if(city==='newyork'){box(.075,.22,.018,color,0,-.01,.061);box(.045,.04,.018,color,0,.12,.061);rod([0,.14,.061],[0,.162,.061],.003,color);for(const x of [-.015,.015])for(let i=0;i<5;i++)box(.006,.009,.004,cream,x,-.08+i*.032,.073);}
  else if(city==='london'){box(.074,.25,.018,color,-.04,.005,.06);const roof=mesh(new THREE.ConeGeometry(.057,.065,4),gold,-.04,.139,.06);roof.rotation.y=Math.PI/4;const face=mesh(new THREE.CircleGeometry(.026,24),cream,-.04,.092,.073);rod([-.04,.092,.077],[-.04,.11,.077],.002,color);rod([-.04,.092,.077],[-.025,.092,.077],.002,color);}
  else if(city==='rio'){soft(.13,.06,.012,mint,0,-.10,.06);box(.019,.105,.018,color,0,.015,.075);box(.15,.016,.018,color,0,.065,.075);soft(.015,.019,.012,color,0,.095,.075);}
  else if(city==='kyoto'){for(let i=0;i<3;i++){const w=.18-i*.045,y=base+i*.065;box(w*.7,.05,.018,cream,0,y+.028,.06);const roof=new THREE.Shape();roof.moveTo(-w/2,y+.048);roof.lineTo(0,y+.085);roof.lineTo(w/2,y+.048);roof.closePath();mesh(new THREE.ExtrudeGeometry(roof,{depth:.012,bevelEnabled:false}),color,0,0,.067);}rod([0,.10,.07],[0,.15,.07],.003,gold);}
  else if(city==='quito'){box(.13,.13,.018,cream,0,-.05,.06);for(const x of [-.065,.065]){box(.027,.20,.02,color,x,-.01,.07);const roof=mesh(new THREE.ConeGeometry(.024,.07,4),color,x,.125,.07);roof.rotation.y=Math.PI/4;}soft(.022,.022,.008,blue,0,-.015,.079);}
  else if(city==='venice'){box(.65,.025,.008,blue,0,-.13,.05);for(const x of [-.10,0,.10]){box(.065,.13,.015,cream,x,-.05,.065);soft(.034,.025,.008,color,x,.023,.07);}rod([.21,-.12,.06],[.21,.15,.06],.009,color);const roof=mesh(new THREE.ConeGeometry(.035,.06,4),gold,.21,.14,.06);roof.rotation.y=Math.PI/4;}
  else if(city==='barcelona'){for(let i=0;i<4;i++){const x=(i-1.5)*.05,h=.16+(i%2)*.06;box(.025,h,.016,color,x,base+h/2,.06);soft(.019,.029,.012,gold,x,base+h+.01,.06);}box(.19,.055,.012,cream,0,-.10,.073);}
  else return false;return true;
 }
 return false;
}
