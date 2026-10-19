export const THEMES=['halloween','christmas','easter','garden'];
export function createMaze(seed=1,difficulty='easy',mode='solo',theme='halloween'){
 if(!['easy','medium','hard'].includes(difficulty)||!['solo','partner'].includes(mode)||!THEMES.includes(theme))throw Error('Opciones inválidas');
 let r=seed>>>0;const rand=()=>{r=(Math.imul(r,1664525)+1013904223)>>>0;return r/4294967296;},size={easy:13,medium:17,hard:21}[difficulty],grid=Array(size*size).fill(1),stack=[[1,1]];grid[size+1]=0;
 while(stack.length){const [x,z]=stack.at(-1),available=[[2,0],[-2,0],[0,2],[0,-2]].filter(([a,b])=>x+a>0&&z+b>0&&x+a<size-1&&z+b<size-1&&grid[(z+b)*size+x+a]);if(!available.length){stack.pop();continue;}const [a,b]=available[Math.floor(rand()*available.length)];grid[(z+b/2)*size+x+a/2]=0;grid[(z+b)*size+x+a]=0;stack.push([x+a,z+b]);}
 const floor=[];for(let z=1;z<size-1;z++)for(let x=1;x<size-1;x++)if(!grid[z*size+x]&&x+z>6&&(x!==size-2||z!==size-2))floor.push([x,z]);
 for(let i=floor.length-1;i>0;i--){const j=Math.floor(rand()*(i+1));[floor[i],floor[j]]=[floor[j],floor[i]];}
 const chests=floor.slice(0,9).map(([x,z],id)=>({id,x,z,type:id<3?'key':id<6?'coins':'surprise',hint:id<6?'leaf':'scratch',opened:false}));
 const traps=floor.slice(9,9+{easy:3,medium:7,hard:12}[difficulty]).map(([x,z],id)=>({id,x,z,used:false}));
 return {version:1,seed,difficulty,mode,theme,size,grid,chests,traps,keys:0,gold:0,status:'playing',moves:0,notice:null,revive:1,players:Array.from({length:mode==='partner'?2:1},(_,id)=>({id,x:1,z:1,hp:{easy:5,medium:3,hard:2}[difficulty],facing:0})),exit:{x:size-2,z:size-2}};
}
export function mazeAction(state,side,action){
 const s=structuredClone(state),p=s.players[side];if(!p||s.status!=='playing')return s;
 if(!action||!['move','open','disarm'].includes(action.kind))throw Error('Acción inválida');s.notice=null;
 p.sequence=(p.sequence??0)+1;
 if(action.kind==='disarm'){const trap=s.traps.find(t=>t.id===action.id&&!t.used&&Math.abs(t.x-p.x)+Math.abs(t.z-p.z)<=1);if(trap&&p.hp>0){trap.used=true;s.notice={kind:'disarmed',side};}return s;}
 if(action.kind==='move'){
  if(p.hp<=0)return s;const dx=action.dx,dz=action.dz;if(!Number.isInteger(dx)||!Number.isInteger(dz)||Math.abs(dx)+Math.abs(dz)!==1)throw Error('Paso inválido');
  const x=p.x+dx,z=p.z+dz;if(x<0||z<0||x>=s.size||z>=s.size||s.grid[z*s.size+x])return s;
  s.moves++;p.facing=Math.atan2(-dx,-dz);const trap=s.traps.find(t=>!t.used&&t.x===x&&t.z===z);
  if(trap){trap.used=true;p.hp--;s.notice={kind:'trap',side,x,z};}else {p.x=x;p.z=z;}
 }else{
  const fallen=s.players.find(q=>q.id!==side&&q.hp<=0&&Math.abs(q.x-p.x)+Math.abs(q.z-p.z)<=1);
  if(fallen&&p.hp>0&&s.revive>0){fallen.hp=1;s.revive--;s.notice={kind:'rescue',side};return s;}
  if(p.hp<=0)return s;
  const chest=s.chests.find(c=>c.id===action.id&&!c.opened&&Math.abs(c.x-p.x)+Math.abs(c.z-p.z)<=1);if(chest){chest.opened=true;if(chest.type==='key')s.keys++;else if(chest.type==='coins')s.gold+=5;else p.hp--;s.notice={kind:chest.type,side,x:chest.x,z:chest.z};}
 }
 if(s.players.every(p=>p.hp<=0))s.status='defeat';
 if(s.keys===3&&s.players.every(p=>p.hp>0&&Math.abs(p.x-s.exit.x)+Math.abs(p.z-s.exit.z)<=1))s.status='victory';
 return s;
}
export function mazeReward(s){if(s.status!=='victory')return 0;return Math.floor(({easy:20,medium:30,hard:50}[s.difficulty]+s.gold)*(s.mode==='solo'?.5:1));}
export function publicMaze(s){const copy=structuredClone(s);copy.chests=copy.chests.map(({type,...c})=>c);return copy;}
