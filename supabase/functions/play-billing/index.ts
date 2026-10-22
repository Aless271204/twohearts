import {PACKAGE,GOLD,accountHash,validatePurchase} from './policy.mjs';
const headers={'Content-Type':'application/json','Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization,apikey,content-type,x-client-info'};
const json=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers});
let cached:{token:string,expires:number}|null=null;
const base64=(data:Uint8Array)=>btoa(String.fromCharCode(...data)).replaceAll('+','-').replaceAll('/','_').replace(/=+$/,'');
async function googleToken() {
  if(cached&&cached.expires>Date.now()+60000)return cached.token;
  const key=JSON.parse(Deno.env.get('GOOGLE_PLAY_SERVICE_ACCOUNT')??'{}');
  if(key.type!=='service_account'||!key.client_email||!key.private_key)throw Error('Billing is not configured');
  const encode=(value:unknown)=>base64(new TextEncoder().encode(JSON.stringify(value)));
  const now=Math.floor(Date.now()/1000);
  const unsigned=encode({alg:'RS256',typ:'JWT'})+'.'+encode({iss:key.client_email,scope:'https://www.googleapis.com/auth/androidpublisher',aud:'https://oauth2.googleapis.com/token',iat:now,exp:now+3600});
  const der=Uint8Array.from(atob(key.private_key.replace(/-----[^-]+-----/g,'').replace(/\s/g,'')),c=>c.charCodeAt(0));
  const signing=await crypto.subtle.importKey('pkcs8',der,{name:'RSASSA-PKCS1-v1_5',hash:'SHA-256'},false,['sign']);
  const signature=await crypto.subtle.sign('RSASSA-PKCS1-v1_5',signing,new TextEncoder().encode(unsigned));
  const response=await fetch('https://oauth2.googleapis.com/token',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({grant_type:'urn:ietf:params:oauth:grant-type:jwt-bearer',assertion:unsigned+'.'+base64(new Uint8Array(signature))}),signal:AbortSignal.timeout(15000)});
  if(!response.ok)throw Error('Google authentication unavailable');
  const data=await response.json();
  if(!data.access_token)throw Error('Google authentication unavailable');
  cached={token:data.access_token,expires:Date.now()+Math.min(3600,data.expires_in??3600)*1000};return cached.token;
}
Deno.serve(async request=>{
  if(request.method==='OPTIONS')return new Response('ok',{headers});
  if(request.method!=='POST')return json({error:'Method not allowed'},405);
  const base=Deno.env.get('SUPABASE_URL')!,anon=Deno.env.get('SUPABASE_ANON_KEY')!,service=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const auth=request.headers.get('Authorization')??'';
  const userResponse=await fetch(base+'/auth/v1/user',{headers:{apikey:anon,Authorization:auth},signal:AbortSignal.timeout(10000)});
  if(!userResponse.ok)return json({error:'Inicia sesión para comprar oro.'},401);
  const user=await userResponse.json();
  const ready=Deno.env.get('NIDO_PLAY_BILLING_ENABLED')==='true'&&!!Deno.env.get('GOOGLE_PLAY_SERVICE_ACCOUNT');
  try {
    if(Number(request.headers.get('content-length')??0)>16000)return json({error:'Solicitud demasiado grande.'},400);
    const input=await request.json();
    if(input.action==='status')return json({ready,products:Object.keys(GOLD)});
    if(!ready)return json({error:'Las compras aún se están preparando.'},503);
    const product=input.product,token=input.token;
    if(typeof product!=='string'||!Object.hasOwn(GOLD,product)||typeof token!=='string'||token.length<10||token.length>8192)return json({error:'Compra no válida.'},400);
    const access=await googleToken();
    const url=`https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE}/purchases/products/${encodeURIComponent(product)}/tokens/${encodeURIComponent(token)}`;
    const google=await fetch(url,{headers:{Authorization:'Bearer '+access},signal:AbortSignal.timeout(15000)});
    if(!google.ok)return json({error:'Google todavía no pudo confirmar la compra. Puedes reintentar.'},503);
    const purchase=await google.json();
    const validated=validatePurchase(purchase,product,await accountHash(user.id));
    const tokenHash=await accountHash(token);
    const rpc=await fetch(base+'/rest/v1/rpc/play_credit_verified',{method:'POST',headers:{apikey:service,Authorization:'Bearer '+service,'Content-Type':'application/json'},body:JSON.stringify({p_user:user.id,p_product:product,p_token_hash:tokenHash,p_order:purchase.orderId??null,p_consumed:purchase.consumptionState===1,p_test:validated.test}),signal:AbortSignal.timeout(15000)});
    if(!rpc.ok)return json({error:'No pudimos guardar la compra todavía. Reintenta sin comprar de nuevo.'},503);
    const receipt=await rpc.json();
    // Credit commits before consumption. A retry repairs a failed consume without granting gold twice.
    if(purchase.consumptionState===0){
      const consumed=await fetch(url+':consume',{method:'POST',headers:{Authorization:'Bearer '+access},signal:AbortSignal.timeout(15000)});
      if(!consumed.ok)return json({error:'Tu oro está guardado. Reintenta para confirmar la compra con Google.'},503);
    }
    return json({verified:true,gold:receipt.gold,already_credited:receipt.already_credited,test:validated.test});
  }catch(_){return json({error:'No se pudo verificar esta compra. No vuelvas a pagar; reintenta la verificación.'},503);}
});
