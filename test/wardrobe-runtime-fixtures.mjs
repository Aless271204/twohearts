import {readFileSync} from 'node:fs';
import {runtimeUrl} from './three-runtime.mjs';
const {GLTFLoader}=await import(runtimeUrl('../assets/runner/vendor/loaders/GLTFLoader.js'));
const {registerAccessoryAsset}=await import(runtimeUrl('../assets/runner/accessory-pieces.js'));

// Node cannot decode GPU image textures. Material/PNG hashes are checked in
// the asset tests; this fixture loads the exact mesh, UVs and skin attributes.
export async function registerWardrobeGeometry(path){
 const bytes=readFileSync(new URL('../'+path,import.meta.url)),length=bytes.readUInt32LE(12),doc=JSON.parse(bytes.subarray(20,20+length));
 delete doc.images;delete doc.textures;delete doc.materials;
 for(const mesh of doc.meshes)for(const primitive of mesh.primitives)delete primitive.material;
 const json=Buffer.from(JSON.stringify(doc)),chunk=Buffer.alloc(Math.ceil(json.length/4)*4,32);json.copy(chunk);
 const bin=bytes.subarray(20+length),result=Buffer.alloc(20+chunk.length+bin.length);
 result.writeUInt32LE(0x46546c67,0);result.writeUInt32LE(2,4);result.writeUInt32LE(result.length,8);result.writeUInt32LE(chunk.length,12);result.writeUInt32LE(0x4e4f534a,16);chunk.copy(result,20);bin.copy(result,20+chunk.length);
 const gltf=await new GLTFLoader().parseAsync(result.buffer.slice(result.byteOffset,result.byteOffset+result.length),'');registerAccessoryAsset(path,gltf.scene);return gltf.scene;
}
