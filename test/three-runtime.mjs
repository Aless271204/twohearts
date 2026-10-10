import {readFileSync} from 'node:fs';
const modules=new Map();
export function runtimeUrl(path) {
  const url=new URL(path,import.meta.url);
  if(modules.has(url.href))return modules.get(url.href);
  let source=readFileSync(url,'utf8');
  source=source.replace(/((?:^|\n)(?:import|export)\s+(?:\{[^}]*\}|\*[^;]*?|\w+)\s+from\s+)(['"])([^'"]+)\2/g,(text,prefix,quote,specifier)=>{
    const target=specifier==='three'?new URL('../assets/runner/vendor/three.module.js',import.meta.url).href:
      specifier.startsWith('three/addons/')?runtimeUrl('../assets/runner/vendor/'+specifier.slice(13)):
      specifier.startsWith('.')?runtimeUrl(new URL(specifier,url).href):specifier;
    return `${prefix}${JSON.stringify(target)}`;
  });
  const result='data:text/javascript;base64,'+Buffer.from(source).toString('base64');modules.set(url.href,result);return result;
}
export async function loadPet(filename) {
  const bytes=readFileSync(new URL('../assets/runner/play-models/'+filename,import.meta.url));
  const length=bytes.readUInt32LE(12),json=JSON.parse(bytes.subarray(20,20+length));
  // Geometry and animation tests do not need browser image decoders.
  delete json.images;delete json.textures;delete json.materials;
  for(const mesh of json.meshes)for(const primitive of mesh.primitives)delete primitive.material;
  const chunk=Buffer.from(JSON.stringify(json));const padded=Buffer.alloc(Math.ceil(chunk.length/4)*4,32);chunk.copy(padded);
  const binary=bytes.subarray(20+length);const output=Buffer.alloc(20+padded.length+binary.length);
  output.writeUInt32LE(0x46546c67,0);output.writeUInt32LE(2,4);output.writeUInt32LE(output.length,8);output.writeUInt32LE(padded.length,12);output.writeUInt32LE(0x4e4f534a,16);padded.copy(output,20);binary.copy(output,20+padded.length);
  const {GLTFLoader}=await import(runtimeUrl('../assets/runner/vendor/loaders/GLTFLoader.js'));
  return new GLTFLoader().parseAsync(output.buffer.slice(output.byteOffset,output.byteOffset+output.length),'');
}
