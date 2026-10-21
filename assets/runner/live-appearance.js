// Only the embedding NIDO view can publish an appearance update. This carries
// visual state, never ownership, currency or a gameplay input.
let listener=null, latest=null;
export function watchAppearance(callback){listener=callback;if(latest)listener(latest);return()=>{if(listener===callback)listener=null;};}
export function acceptAppearance(value){
 if(!value||typeof value!=='object'||Array.isArray(value))return false;
 latest=Object.fromEntries(Object.entries(value).filter(([slot,item])=>/^(pet_(head|body|neck|feet|eyes|face|back)|room_[a-z_]+)$/.test(slot)&&item&&typeof item==='object'&&!Array.isArray(item)));
 if(listener)Promise.resolve(listener(latest)).catch(error=>console.warn('Appearance refresh pending',error));
 return true;
}
globalThis.nidoSetAppearance=acceptAppearance;
if(globalThis.addEventListener)globalThis.addEventListener('message',event=>{
 if(event.origin!==globalThis.location?.origin||event.source!==globalThis.parent)return;
 if(event.data?.type==='nido-appearance')acceptAppearance(event.data.appearance);
});
