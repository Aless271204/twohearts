const http=require('node:http');
const fs=require('node:fs');
const path=require('node:path');
const root=path.resolve(__dirname,'../assets/runner');
const types={'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.json':'application/json','.jpg':'image/jpeg','.png':'image/png','.mp4':'video/mp4','.glb':'model/gltf-binary'};
const server=http.createServer((req,res)=>{
  let url;try{url=decodeURIComponent(req.url.split('?')[0]);}catch{res.writeHead(400);res.end();return;}
  if(url==='/')url='/index.html';
  const file=path.resolve(root,'.'+url);
  if(!file.startsWith(root+path.sep)){res.writeHead(403);res.end();return;}
  fs.readFile(file,(error,data)=>{
    if(error){res.writeHead(404);res.end();return;}
    res.writeHead(200,{'Content-Type':types[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});res.end(data);
  });
});
server.listen(0,'127.0.0.1',()=>console.log(`Vista de prueba: http://127.0.0.1:${server.address().port}/index.html`));
