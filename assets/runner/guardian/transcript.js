import {VERSION} from './config.js';
export async function transcriptHash(room,frames,events,refs){
 const bytes=new TextEncoder().encode(JSON.stringify({version:VERSION,room,frames,events,refs}));
 return [...new Uint8Array(await crypto.subtle.digest('SHA-256',bytes))].map(x=>x.toString(16).padStart(2,'0')).join('');
}
export function validateInputRefs(context,events,refs){
 if(!Array.isArray(events)||!Array.isArray(refs)||events.length!==refs.length||events.length>12000)throw Error('Invalid transcript');
 const saved=new Map(context.inputs.map(([role,seq,mask])=>[role+':'+seq,mask])),previous=[0,0];
 for(let i=0;i<events.length;i++){
  const e=events[i],seq=refs[i];if(!Array.isArray(e)||e.length!==3||!Number.isInteger(seq)||seq<=previous[e[1]]||saved.get(e[1]+':'+seq)!==e[2])throw Error('Input ownership mismatch');
  previous[e[1]]=seq;
 }
}
