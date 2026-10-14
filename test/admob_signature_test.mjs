import test from 'node:test';import assert from 'node:assert/strict';
import {verifyGoogleQuery} from '../supabase/functions/admob-reward/verify.mjs';
function der(raw){const values=[raw.slice(0,32),raw.slice(32)];const fields=values.map(v=>{let a=[...v];while(a.length>1&&a[0]===0)a.shift();if(a[0]&128)a.unshift(0);return [2,a.length,...a];});const data=fields.flat();return Buffer.from([48,data.length,...data]).toString('base64url');}
test('Google SSV accepts a signed event and rejects altered or appended identity',async()=>{
 const pair=await crypto.subtle.generateKey({name:'ECDSA',namedCurve:'P-256'},true,['sign','verify']);
 const key={base64:Buffer.from(await crypto.subtle.exportKey('spki',pair.publicKey)).toString('base64')};
 const query=new URLSearchParams({ad_unit:'6701979953',custom_data:'ticket',timestamp:String(Date.now()),transaction_id:'transaction',user_id:'account'}).toString();
 const signature=der(new Uint8Array(await crypto.subtle.sign({name:'ECDSA',hash:'SHA-256'},pair.privateKey,new TextEncoder().encode(query))));
 const full=query+'&signature='+signature+'&key_id=1';
 assert.equal((await verifyGoogleQuery(full,key)).get('user_id'),'account');
 await assert.rejects(verifyGoogleQuery(full.replace('account','attacker'),key));
 await assert.rejects(verifyGoogleQuery(full+'&reward_amount=99999',key));
 await assert.rejects(verifyGoogleQuery(full+'&user_id=attacker',key));
});
