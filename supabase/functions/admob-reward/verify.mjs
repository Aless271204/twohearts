// Google's signed raw query must be verified before trusting any parameter.
export function base64Bytes(value){
  const normalized=value.replaceAll('-','+').replaceAll('_','/');
  return Uint8Array.from(atob(normalized.padEnd(Math.ceil(normalized.length/4)*4,'=')),c=>c.charCodeAt(0));
}
export function derToRaw(signature){
  let i=0;if(signature[i++]!==0x30)throw Error('Invalid signature');
  const length=signature[i++];if(length>127||length!==signature.length-2)throw Error('Invalid signature length');
  const result=new Uint8Array(64);
  for(let component=0;component<2;component++){
    if(signature[i++]!==2)throw Error('Invalid signature component');
    let size=signature[i++];if(size<1||size>33||i+size>signature.length)throw Error('Invalid component size');
    let bytes=signature.slice(i,i+size);i+=size;
    if(bytes.length===33){if(bytes[0]!==0)throw Error('Oversized component');bytes=bytes.slice(1);}
    result.set(bytes,component*32+32-bytes.length);
  }
  if(i!==signature.length)throw Error('Trailing signature data');
  return result;
}
export async function verifyGoogleQuery(rawQuery,key){
  const split=rawQuery.indexOf('&signature=');if(split<0)throw Error('Missing signature');
  const signed=rawQuery.slice(0,split),params=new URLSearchParams(rawQuery);
  const tail=new URLSearchParams(rawQuery.slice(split+1));
  for(const field of tail.keys())if(!['signature','key_id'].includes(field))throw Error('Unsigned parameter');
  const signature=params.get('signature');if(!signature||!key)throw Error('Missing key');
  for(const field of ['signature','key_id','user_id','custom_data','transaction_id','ad_unit','timestamp'])if(params.getAll(field).length!==1)throw Error('Duplicate parameter');
  const cryptoKey=await crypto.subtle.importKey('spki',base64Bytes(key.base64),{name:'ECDSA',namedCurve:'P-256'},false,['verify']);
  if(!await crypto.subtle.verify({name:'ECDSA',hash:'SHA-256'},cryptoKey,derToRaw(base64Bytes(signature)),new TextEncoder().encode(signed)))throw Error('Invalid Google signature');
  return params;
}
