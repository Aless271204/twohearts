import test from 'node:test';
import assert from 'node:assert/strict';
import {accountHash,GOLD,PACKAGE,validatePurchase} from '../supabase/functions/play-billing/policy.mjs';
test('only paid state, matching account and known single-quantity products qualify',async()=>{
 const account=await accountHash('test-user');assert.equal(account.length,64);assert.notEqual(account,await accountHash('other-user'));
 const valid={purchaseState:0,obfuscatedExternalAccountId:account,consumptionState:0};
 for(const [product,gold]of Object.entries(GOLD))assert.deepEqual(validatePurchase(valid,product,account),{gold,test:false});
 for(const changes of [{purchaseState:1},{purchaseState:2},{obfuscatedExternalAccountId:'other'},{quantity:2},{consumptionState:5}])assert.throws(()=>validatePurchase({...valid,...changes},'nido_gold_500',account));
 assert.throws(()=>validatePurchase(valid,'unknown',account));
 assert.equal(validatePurchase({...valid,purchaseType:0},'nido_gold_500',account).test,true);
 assert.equal(PACKAGE,'app.nido.twohearts');
});
