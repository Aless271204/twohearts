export const PACKAGE = 'app.nido.twohearts';
export const GOLD = Object.freeze({nido_gold_500:500,nido_gold_2500:2500,nido_gold_10000:10000});
export async function accountHash(userId) {
  const bytes=await crypto.subtle.digest('SHA-256',new TextEncoder().encode(userId));
  return Array.from(new Uint8Array(bytes),b=>b.toString(16).padStart(2,'0')).join('');
}
export function validatePurchase(purchase, product, account) {
  if(!Object.hasOwn(GOLD,product))throw Error('Unknown product');
  if(purchase.purchaseState!==0)throw Error('Purchase not completed');
  if(purchase.obfuscatedExternalAccountId!==account)throw Error('Purchase belongs to another account');
  if((purchase.quantity??1)!==1)throw Error('Unsupported quantity');
  if(![0,1].includes(purchase.consumptionState))throw Error('Invalid consumption state');
  return {gold:GOLD[product],test:purchase.purchaseType===0};
}
