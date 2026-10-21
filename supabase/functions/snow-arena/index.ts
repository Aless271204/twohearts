import {newArena,stepArena,safeInput,TICK} from './engine.js';
const headers={'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization,apikey,content-type,x-client-info','Access-Control-Allow-Methods':'POST,OPTIONS','Content-Type':'application/json'};
const url=Deno.env.get('SUPABASE_URL')!,key=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const reply=(data:unknown,status=200)=>new Response(JSON.stringify(data),{status,headers});
async function rpc(name:string,args:unknown,token=key){const r=await fetch(url+'/rest/v1/rpc/'+name,{method:'POST',headers:{apikey:key,Authorization:'Bearer '+token,'Content-Type':'application/json'},body:JSON.stringify(args)});if(!r.ok){const e=await r.json().catch(()=>({}));throw Error(e.message??'No pudimos actualizar la sala');}return r.json();}
Deno.serve(async req=>{
 if(req.method==='OPTIONS')return new Response(null,{headers});if(req.method!=='POST')return reply({error:'Método inválido'},405);
 try{
  const token=req.headers.get('authorization')?.replace(/^Bearer /,'');if(!token)return reply({error:'Inicia sesión'},401);
  const auth=await fetch(url+'/auth/v1/user',{headers:{apikey:key,Authorization:'Bearer '+token}});if(!auth.ok)return reply({error:'La sesión ha caducado'},401);const user=await auth.json();
  const text=await req.text();if(text.length>7000)throw Error('Datos excesivos');const body=JSON.parse(text),action=body.action;
  if(!['profile','create','solo','join','status','ready','start','leave','tick'].includes(action))throw Error('Acción inválida');
  if(!['profile','create','solo','join'].includes(action)&&!/^[a-f0-9-]{36}$/.test(body.id??''))throw Error('Sala inválida');
  const data=await rpc('snow_room',{p_action:action==='tick'?'input':action,p_id:body.id??null,p_code:body.code??null,p_data:action==='tick'?{input:safeInput(body.input)}:{species:body.species}},token);
  if(!data.id||data.status!=='playing')return reply(data);
  for(let attempt=0;attempt<3;attempt++){
   const r=await rpc('snow_context',{p_id:data.id,p_user:user.id});if(r.status!=='playing')break;
   const now=Date.now(),sim=Date.parse(r.sim_at);if(now<sim)break;
   const people=r.players.map((p:any)=>({id:p.id,name:p.name,species:p.species}));if(r.mode==='solo')people.push({id:'bot',name:'Nube',species:people[0].species==='bear'?'penguin':'bear',bot:true});
   const state=r.state??newArena(Number(r.seed)+r.generation,people,60,3),inputs=Object.fromEntries(Object.entries(r.inputs).map(([id,value]:[string,any])=>[id,now/1000-value.at<.75?safeInput(value.value):{}]));
   // Real server time controls simulation. Clients never submit position,
   // score, pickups or a reward; compare-and-swap serializes concurrent ticks.
   const frames=Math.min(90,Math.max(0,Math.floor((now-sim)/(TICK*1000))));
   for(let i=0;i<frames&&state.status==='playing';i++)stepArena(state,inputs,TICK);
   const at=new Date(sim+frames*TICK*1000).toISOString();
   if(await rpc('snow_commit',{p_id:data.id,p_user:user.id,p_revision:r.revision,p_state:state,p_sim_at:at}))break;
  }
  return reply(await rpc('snow_room',{p_action:'status',p_id:data.id},token));
 }catch(error){return reply({error:error instanceof Error?error.message:'No se pudo conectar'},400);}
});
