import { replayRun } from './replay.js';

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
    if(body.action==='finish'){
      if(typeof body.session_id!=='string'||! /^[0-9a-f-]{36}$/i.test(body.session_id))return reply({error:'Invalid run'},400);
      const result=replayRun(body.frames);
      return reply(await rpc('runner_finish_session',{p_user_id:user.id,p_session_id:body.session_id,p_distance:result.distance,p_coins:result.coins,p_elapsed:result.elapsed}));
    }
    return reply({error:'Unknown action'},400);
  }catch(error){console.error('Runner request rejected',error instanceof Error?error.message:'Unknown error');return reply({error:'Run could not be validated or saved'},400);}
});
