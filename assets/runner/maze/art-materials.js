import * as T from 'three';

// Authored surface detail, shared by every maze cell. No per-frame baking.
export function loadGardenArt(renderer){
 const loader=new T.TextureLoader(),maps={};
 for(const [name,file] of Object.entries({ivy:'ivy.webp',paving:'paving.webp',stone:'stone.webp'})){
  const texture=loader.load(new URL('./art/'+file,import.meta.url).href,()=>{texture.userData.ready=true;},undefined,()=>{texture.userData.failed=true;});
  texture.colorSpace=T.SRGBColorSpace;texture.wrapS=texture.wrapT=T.RepeatWrapping;
  texture.anisotropy=Math.min(4,renderer.capabilities.getMaxAnisotropy());maps[name]=texture;
 }
 return maps;
}
export function gardenMaterial(color,map,roughness=.92){
 return new T.MeshStandardMaterial({color,map:map??null,roughness});
}
