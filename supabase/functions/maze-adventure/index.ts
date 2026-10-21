import {createMaze,mazeAction,mazeReward,publicMaze} from './engine.js';
const headers={'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization, x-client-info, apikey, content-type','Access-Control-Allow-Methods':'POST, OPTIONS','Content-Type':'application/json'};
const reply=(data:unknown,status=200)=>new Response(JSON.stringify(data),{status,headers});
const url=Deno.env.get('SUPABASE_URL')!,key=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
async function room(user:string,action:string,id:string|null=null,code='',data:unknown={}){const r=await fetch(`${url}/rest/v1/rpc/maze_room_service`,{method:'POST',headers:{apikey:key,Authorization:`Bearer ${key}`,'Content-Type':'application/json'},body:JSON.stringify({p_user:user,p_action:action,p_id:id,p_code:code,p_data:data})});if(!r.ok)throw Error('La sala no está disponible o la jugada cambió.');return r.json();}
Deno.serve(async req=>{
 if(req.method==='OPTIONS')return new Response(null,{status:204,headers});if(req.method!=='POST')return reply({error:'Method not allowed'},405);
 try{
  const auth=req.headers.get('Authorization');if(!auth?.startsWith('Bearer '))return reply({error:'Inicia sesión'},401);
  const check=await fetch(`${url}/auth/v1/user`,{headers:{apikey:key,Authorization:auth}});if(!check.ok)return reply({error:'Sesión inválida'},401);const user=await check.json();if(!user.id)return reply({error:'Sesión inválida'},401);
  const raw=await req.text();if(raw.length>2000)return reply({error:'Solicitud demasiado grande'},413);const b=JSON.parse(raw);
  if(!['create','solo','join','status','ready','rematch','leave','move','open','disarm','inspect','activate'].includes(b.action))return reply({error:'Acción inválida'},400);
  if(b.id!=null&&!/^[0-9a-f-]{36}$/i.test(b.id))return reply({error:'Sala inválida'},400);
  let info;
  if(['move','open','disarm','inspect','activate'].includes(b.action)){
   for(let attempt=0;attempt<3;attempt++){
    info=await room(user.id,'status',b.id);if(info.status!=='playing'||!info.state)throw Error('La partida no ha comenzado.');
    if(b.generation!==info.generation)throw Error('La partida ya cambió.');
    const sequence=info.state.players[info.side].sequence??0;
    if(Number.isInteger(b.sequence)&&b.sequence<=sequence)break;
    if(b.sequence!==sequence+1)throw Error('Actualiza el estado de la partida.');
    const state=mazeAction(info.state,info.side,{kind:b.action,dx:b.dx,dz:b.dz,id:b.chest,symbols:b.symbols,light:b.light});
    const saved=await room(user.id,'update',info.id,'',{state,revision:info.revision,generation:info.generation,reward:mazeReward(state)});if(!saved.retry){info=saved;break;}if(attempt===2)throw Error('Vuelve a dar el paso.');
   }
  }else info=await room(user.id,b.action,b.id,b.code,{difficulty:b.difficulty,theme:'halloween'});
  if(!info.state&&info.status!=='cancelled')info=await room(user.id,'init',info.id,'',{generation:info.generation,state:createMaze(Number(info.seed),info.difficulty,info.mode,info.theme,b.protocol===2?2:1)});
  if(info.state)info.state=publicMaze(info.state);return reply(info);
 }catch(e){return reply({error:e instanceof Error?e.message:'No pudimos conectar'},400);}
});
