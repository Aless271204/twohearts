import { replayRun, replayChunk } from './replay.js';

const headers={'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization, x-client-info, apikey, content-type','Access-Control-Allow-Methods':'POST, OPTIONS','Content-Type':'application/json'};
const reply=(data:unknown,status=200)=>new Response(JSON.stringify(data),{status,headers});
const url=Deno.env.get('SUPABASE_URL')!;
const serviceKey=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
async function rpc(name:string,params:Record<string,unknown>){
  const response=await fetch(`${url}/rest/v1/rpc/${name}`,{method:'POST',headers:{'Content-Type':'application/json',apikey:serviceKey,Authorization:`Bearer ${serviceKey}`},body:JSON.stringify(params)});
  if(!response.ok)throw Error('Database rejected run');
  return response.json();
}
Deno.serve(async req=>{
  if(req.method==='OPTIONS')return new Response(null,{status:204,headers});
  if(req.method!=='POST')return reply({error:'Method not allowed'},405);
  try{
    const authorization=req.headers.get('Authorization');
    if(!authorization?.startsWith('Bearer '))return reply({error:'Sign in required'},401);
    const userResponse=await fetch(`${url}/auth/v1/user`,{headers:{apikey:serviceKey,Authorization:authorization}});
    if(!userResponse.ok)return reply({error:'Invalid session'},401);
    const user=await userResponse.json();
    if(!user.id)return reply({error:'Invalid user'},401);
    const raw=await req.text();if(raw.length>4000000)return reply({error:'Replay is too large'},413);
    const body=JSON.parse(raw);
    if(body.action==='start')return reply(await rpc('runner_start_session',{p_user_id:user.id}));
    if(body.action==='finish'||body.action==='checkpoint'){
      if(typeof body.session_id!=='string'||! /^[0-9a-f-]{36}$/i.test(body.session_id))return reply({error:'Invalid run'},400);
      if(body.replay_version===4||body.replay_version===5){
        if(!Number.isInteger(body.checkpoint_index)||body.checkpoint_index<1)return reply({error:'Invalid checkpoint'},400);
        const response=await fetch(`${url}/rest/v1/runner_sessions?id=eq.${body.session_id}&user_id=eq.${user.id}&select=status,checkpoint_state,checkpoint_index,checkpoint_result`,{headers:{apikey:serviceKey,Authorization:`Bearer ${serviceKey}`}});
        if(!response.ok)throw Error('Checkpoint unavailable');
        const [saved]=await response.json();if(!saved)throw Error('Run not owned');
        if(body.checkpoint_index===saved.checkpoint_index)return reply(saved.checkpoint_result);
        if(saved.status!=='started'||body.checkpoint_index!==saved.checkpoint_index+1)throw Error('Checkpoint out of order');
        if(saved.checkpoint_state && (saved.checkpoint_state.version??4)!==body.replay_version)throw Error('Checkpoint version changed');
        const result=replayChunk(body.frames,saved.checkpoint_state,body.replay_version);
        if((body.action==='finish')!==result.ended)throw Error('Terminal collision does not match checkpoint');
        return reply(await rpc('runner_save_checkpoint',{p_user_id:user.id,p_session_id:body.session_id,p_index:body.checkpoint_index,p_state:result.state,p_terminal:result.ended}));
      }
      if(body.action!=='finish')throw Error('Unsupported checkpoint');
      const result=replayRun(body.frames,body.replay_version??1);
      return reply(await rpc('runner_finish_session',{p_user_id:user.id,p_session_id:body.session_id,p_distance:result.distance,p_coins:result.coins,p_elapsed:result.elapsed}));
    }
    return reply({error:'Unknown action'},400);
  }catch(error){console.error('Runner request rejected',error instanceof Error?error.message:'Unknown error');return reply({error:'Run could not be validated or saved'},400);}
});
