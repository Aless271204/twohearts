let nextId=0;
const pending=new Map();
function response(message){
  if(message?.type!=='runner-response')return;
  const request=pending.get(message.id);if(!request)return;
  pending.delete(message.id);clearTimeout(request.timer);
  if(message.ok)request.resolve(message.result);else request.reject(Error(message.error||'No pudimos guardar la partida.'));
}
window.runnerBridgeResponse=response;
addEventListener('message',event=>{
  if(event.source!==window.parent||event.origin!==location.origin)return;
  try{response(typeof event.data==='string'?JSON.parse(event.data):event.data);}catch{}
});
export function requestHost(action,payload={}){
  if(!window.RunnerBridge&&window.parent===window)return Promise.resolve({guest:true});
  return new Promise((resolve,reject)=>{
    const id=++nextId,message=JSON.stringify({type:'runner-request',id,action,payload});
    const timer=setTimeout(()=>{pending.delete(id);reject(Error('La conexión tardó demasiado. Vuelve a intentarlo.'));},30000);
    pending.set(id,{resolve,reject,timer});
    if(window.RunnerBridge)window.RunnerBridge.postMessage(message);else window.parent.postMessage(message,location.origin);
  });
}
