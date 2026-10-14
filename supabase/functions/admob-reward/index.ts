import {verifyGoogleQuery} from './verify.mjs';
let cachedKeys:{expires:number,keys:Array<{keyId:number,base64:string}>}|null=null;
async function keys(refresh=false){
  if(!refresh&&cachedKeys&&cachedKeys.expires>Date.now())return cachedKeys.keys;
  const response=await fetch('https://www.gstatic.com/admob/reward/verifier-keys.json',{signal:AbortSignal.timeout(10000)});
  if(!response.ok)throw Error('Keys unavailable');
  const data=await response.json();if(!Array.isArray(data.keys))throw Error('Invalid keys');
  cachedKeys={expires:Date.now()+3600000,keys:data.keys};return data.keys;
}
Deno.serve(async request=>{
  if(request.method!=='GET')return new Response('Method not allowed',{status:405});
  const url=new URL(request.url);if(url.search.length>8000)return new Response('Invalid callback',{status:400});
  try{
    const keyId=Number(url.searchParams.get('key_id'));
    let key=(await keys()).find((k:{keyId:number})=>k.keyId===keyId);
    if(!key)key=(await keys(true)).find((k:{keyId:number})=>k.keyId===keyId);
    const params=await verifyGoogleQuery(url.search.slice(1),key);
    const adUnit=params.get('ad_unit');
    if(!['6701979953','ca-app-pub-4237033451731865/6701979953'].includes(adUnit??''))return new Response('Unknown ad unit',{status:403});
    const ticket=params.get('custom_data'),user=params.get('user_id'),transaction=params.get('transaction_id');
    const uuid=/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if(!uuid.test(ticket??'')||!uuid.test(user??'')||!transaction)return new Response('Invalid reward identity',{status:400});
    const timestamp=Number(params.get('timestamp'));if(!Number.isFinite(timestamp)||Math.abs(Date.now()-timestamp)>86400000)return new Response('Expired callback',{status:400});
    // Ignore caller-configurable reward_amount: server policy grants exactly 3.
    const base=Deno.env.get('SUPABASE_URL'),secret=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    if(!base||!secret)throw Error('Backend unavailable');
    const result=await fetch(`${base}/rest/v1/rpc/admob_credit_verified`,{method:'POST',headers:{apikey:secret,Authorization:`Bearer ${secret}`,'Content-Type':'application/json'},
      body:JSON.stringify({p_ticket:ticket,p_user_id:user,p_transaction_id:transaction,p_event_time:new Date(timestamp).toISOString()})});
    if(!result.ok)return new Response('Reward could not be confirmed',{status:503});
    return new Response('Reward verified',{status:200});
  }catch(_){return new Response('Invalid or unavailable verification',{status:403});}
});
