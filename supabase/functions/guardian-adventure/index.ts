import {replay} from './engine.js';
import {replay as replayV2} from './engine-v2.js';
import {transcriptHash,validateInputRefs} from './transcript.js';
const headers={'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization, apikey, content-type, x-client-info','Access-Control-Allow-Methods':'POST, OPTIONS','Content-Type':'application/json'};
const reply=(data:unknown,status=200)=>new Response(JSON.stringify(data),{status,headers});
const url=Deno.env.get('SUPABASE_URL')!,key=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
async function rpc(name:string,params:Record<string,unknown>){const r=await fetch(url+'/rest/v1/rpc/'+name,{method:'POST',headers:{apikey:key,Authorization:'Bearer '+key,'Content-Type':'application/json'},body:JSON.stringify(params)});if(!r.ok)throw Error('Run rejected');return r.json();}
Deno.serve(async req=>{
 if(req.method==='OPTIONS')return new Response(null,{status:204,headers});if(req.method!=='POST')return reply({error:'Method not allowed'},405);
 try{
  const authorization=req.headers.get('authorization');if(!authorization?.startsWith('Bearer '))return reply({error:'Sign in required'},401);
  const userResponse=await fetch(url+'/auth/v1/user',{headers:{apikey:key,Authorization:authorization}});if(!userResponse.ok)return reply({error:'Invalid session'},401);const user=await userResponse.json();
  const text=await req.text();if(text.length>1000000)return reply({error:'Replay too large'},413);const body=JSON.parse(text);
  if(typeof body.room!=='string'||!/^[a-f0-9-]{36}$/.test(body.room)||!Number.isInteger(body.frames)||body.frames<600||body.frames>21600)throw Error('Invalid replay');
  const context=await rpc('guardian_validation_context',{p_id:body.room,p_user_id:user.id}),r=context.room;

  validateInputRefs(context,body.events,body.refs);const hash=await transcriptHash(body.room,body.frames,body.events,body.refs);
  if(r.status!=='finished'){const elapsed=(Date.now()-Date.parse(r.started_at))/1000;if(elapsed+3<body.frames/60||elapsed>900)throw Error('Invalid elapsed time');}
  if(r.mode==='partner'&&r.confirmed_hash!==hash)throw Error('Partner has not confirmed this run');
  const validate=r.engine_version>=3?replay:replayV2;const result=validate(Number(r.seed),r.difficulty,r.mode,body.events,body.frames,[r.host_species,r.guest_species],[4,5,7].includes(r.engine_version)?'river':'forest',r.engine_version<5?'legacy':'stones',r.engine_version>=6?'aerial':'legacy');if(result.state.status!=='victory')throw Error('Not a completed victory');
  return reply(await rpc('guardian_settle',{p_id:body.room,p_user_id:user.id,p_hash:hash,p_reward:result.reward,p_frames:body.frames}));
 }catch(error){console.warn('Guardian validation rejected',error instanceof Error?error.message:'Invalid run');return reply({error:'No pudimos validar la partida. Espera a tu pareja y vuelve a guardar.'},400);}
});
