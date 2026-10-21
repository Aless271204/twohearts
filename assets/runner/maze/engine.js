export const THEMES=['halloween','christmas','easter','garden'];
export function createMaze(seed=1,difficulty='easy',mode='solo',theme='halloween'){
 if(!['easy','medium','hard'].includes(difficulty)||!['solo','partner'].includes(mode)||!THEMES.includes(theme))throw Error('Opciones inválidas');
 let r=seed>>>0;const rand=()=>{r=(Math.imul(r,1664525)+1013904223)>>>0;return r/4294967296;},size={easy:13,medium:17,hard:21}[difficulty],grid=Array(size*size).fill(1),stack=[[1,1]];grid[size+1]=0;
 while(stack.length){const [x,z]=stack.at(-1),available=[[2,0],[-2,0],[0,2],[0,-2]].filter(([a,b])=>x+a>0&&z+b>0&&x+a<size-1&&z+b<size-1&&grid[(z+b)*size+x+a]);if(!available.length){stack.pop();continue;}const [a,b]=available[Math.floor(rand()*available.length)];grid[(z+b/2)*size+x+a/2]=0;grid[(z+b)*size+x+a]=0;stack.push([x+a,z+b]);}
 const floor=[];for(let z=1;z<size-1;z++)for(let x=1;x<size-1;x++)if(!grid[z*size+x]&&x+z>6&&(x!==size-2||z!==size-2))floor.push([x,z]);
 for(let i=floor.length-1;i>0;i--){const j=Math.floor(rand()*(i+1));[floor[i],floor[j]]=[floor[j],floor[i]];}
 const chests=floor.slice(0,9).map(([x,z],id)=>({id,x,z,type:id<3?'key':id<6?'coins':'surprise',hint:id<6?'leaf':'scratch',opened:false,...(id<3?{lantern:true,revealed:false,pattern:Array.from({length:{easy:1,medium:2,hard:3}[difficulty]},()=>Math.floor(rand()*3))}:{})}));
 const traps=floor.slice(9,9+{easy:3,medium:7,hard:12}[difficulty]).map(([x,z],id)=>({id,x,z,used:false}));
 // A bridge lies on the guaranteed route, with its switch on the arrival side.
 const goal=(size-2)*size+size-2,queue=[size+1],parents=new Map([[size+1,null]]);
 for(let i=0;i<queue.length&&!parents.has(goal);i++){const cell=queue[i],x=cell%size,z=Math.floor(cell/size);for(const [dx,dz]of [[1,0],[-1,0],[0,1],[0,-1]]){const nx=x+dx,nz=z+dz,n=nz*size+nx;if(nx>0&&nz>0&&nx<size-1&&nz<size-1&&!grid[n]&&!parents.has(n)){parents.set(n,cell);queue.push(n);}}}
 const route=[];for(let c=goal;c!=null;c=parents.get(c))route.unshift(c);
 const occupied=new Set([...chests,...traps].map(c=>c.z*size+c.x));
 const gate=route.find((c,i)=>i>route.length*.35&&i<route.length-2&&!occupied.has(c)&&!occupied.has(route[i-1]));
 const plate=gate==null?null:parents.get(gate);
 const bridges=gate==null?[]:[{id:0,x:gate%size,z:Math.floor(gate/size),plate:{x:plate%size,z:Math.floor(plate/size)},until:0,secured:false}];
 return {version:2,bridges,seed,difficulty,mode,theme,size,grid,chests,traps,keys:0,gold:0,status:'playing',moves:0,notice:null,revive:1,players:Array.from({length:mode==='partner'?2:1},(_,id)=>({id,x:1,z:1,hp:{easy:5,medium:3,hard:2}[difficulty],facing:0})),exit:{x:size-2,z:size-2}};
}
export function bridgeIsOpen(s,b,now=Date.now()){
 return b.secured||now<b.until||(s.mode==='partner'&&s.players.some(p=>p.hp>0&&p.x===b.plate.x&&p.z===b.plate.z));
}
export function mazeAction(state,side,action,now=Date.now()){
 const s=structuredClone(state),p=s.players[side];if(!p||s.status!=='playing')return s;
 if(!action||!['move','open','disarm','inspect','activate'].includes(action.kind))throw Error('Acción inválida');s.notice=null;
 p.sequence=(p.sequence??0)+1;
 if(action.kind==='activate'){
  const b=s.bridges?.find(b=>b.id===action.id&&Math.abs(b.plate.x-p.x)+Math.abs(b.plate.z-p.z)<=1);
  if(b&&p.hp>0){b.until=now+(s.mode==='solo'?20000:14000);s.notice={kind:'bridge',side,x:b.x,z:b.z};}return s;
 }
 if(action.kind==='inspect'){
  const c=s.chests.find(c=>c.id===action.id&&c.lantern&&!c.opened&&Math.abs(c.x-p.x)+Math.abs(c.z-p.z)<=1);
  if(c&&p.hp>0&&action.light===true){c.revealed=true;s.notice={kind:'revealed',side,x:c.x,z:c.z};}return s;
 }
 if(action.kind==='disarm'){const trap=s.traps.find(t=>t.id===action.id&&!t.used&&Math.abs(t.x-p.x)+Math.abs(t.z-p.z)<=1);if(trap&&p.hp>0){trap.used=true;s.notice={kind:'disarmed',side};}return s;}
 if(action.kind==='move'){
  if(p.hp<=0)return s;const dx=action.dx,dz=action.dz;if(!Number.isInteger(dx)||!Number.isInteger(dz)||Math.abs(dx)+Math.abs(dz)!==1)throw Error('Paso inválido');
  const x=p.x+dx,z=p.z+dz;if(x<0||z<0||x>=s.size||z>=s.size||s.grid[z*s.size+x])return s;
  const bridge=s.bridges?.find(b=>b.x===x&&b.z===z);
  if(bridge&&!bridgeIsOpen(s,bridge,now)){s.notice={kind:'blockedBridge',side};return s;}
  if(bridge){bridge.secured=true;s.notice={kind:'crossed',side};}
  s.moves++;p.facing=Math.atan2(-dx,-dz);const trap=s.traps.find(t=>!t.used&&t.x===x&&t.z===z);
  if(trap){trap.used=true;p.hp--;s.notice={kind:'trap',side,x,z};}else {p.x=x;p.z=z;}
 }else{
  const fallen=s.players.find(q=>q.id!==side&&q.hp<=0&&Math.abs(q.x-p.x)+Math.abs(q.z-p.z)<=1);
  if(fallen&&p.hp>0&&s.revive>0){fallen.hp=1;s.revive--;s.notice={kind:'rescue',side};return s;}
  if(p.hp<=0)return s;
  const chest=s.chests.find(c=>c.id===action.id&&!c.opened&&Math.abs(c.x-p.x)+Math.abs(c.z-p.z)<=1);if(chest){
   if(chest.lantern){
    if(!chest.revealed){s.notice={kind:'needLight',side};return s;}
    if(!Array.isArray(action.symbols)||action.symbols.length!==chest.pattern.length||!action.symbols.every((v,i)=>Number.isInteger(v)&&v===chest.pattern[i])){s.notice={kind:'incorrect',side};return s;}
   }
   chest.opened=true;if(chest.type==='key')s.keys++;else if(chest.type==='coins')s.gold+=5;else p.hp--;s.notice={kind:chest.type,side,x:chest.x,z:chest.z};}
 }
 if(s.players.every(p=>p.hp<=0))s.status='defeat';
 if(s.keys===3&&s.players.every(p=>p.hp>0&&Math.abs(p.x-s.exit.x)+Math.abs(p.z-s.exit.z)<=1))s.status='victory';
 return s;
}
export function mazeReward(s){if(s.status!=='victory')return 0;return Math.floor(({easy:20,medium:30,hard:50}[s.difficulty]+s.gold)*(s.mode==='solo'?.5:1));}
export function publicMaze(s){const copy=structuredClone(s);copy.chests=copy.chests.map(({type,pattern,...c})=>({...c,...(c.revealed?{pattern}:{} )}));return copy;}
