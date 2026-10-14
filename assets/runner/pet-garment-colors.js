import * as THREE from 'three';
// Dye designated cloth only. Preserve relief, roughness, embroidery and soles.
export function applyGarmentColor(part, appearance) {
  const hex=appearance?.garment_color, names=appearance?.color_materials;
  if(!/^#[0-9a-fA-F]{6}$/.test(hex??'')||!Array.isArray(names))return;
  const base=new THREE.Color(appearance.color_base??'#FFFFFF');
  const sourceLuma=Math.max(.015,.2126*base.r+.7152*base.g+.0722*base.b);
  const target=new THREE.Color(hex);
  part.traverse(mesh=>{
    if(!mesh.isMesh)return;
    const recolor=material=>{
      if(!names.includes(material.name))return material;
      const dyed=material.clone();
      dyed.onBeforeCompile=shader=>{
        shader.uniforms.nidoDye={value:target};
        shader.uniforms.nidoSourceLuma={value:sourceLuma};
        shader.fragmentShader='uniform vec3 nidoDye;\nuniform float nidoSourceLuma;\n'+shader.fragmentShader;
        shader.fragmentShader=shader.fragmentShader.replace('#include <map_fragment>',
          '#include <map_fragment>\nfloat clothShade=clamp(dot(diffuseColor.rgb,vec3(.2126,.7152,.0722))/nidoSourceLuma,.12,1.45);\ndiffuseColor.rgb=nidoDye*clothShade;');
      };
      dyed.customProgramCacheKey=()=> 'nido-textile-dye-v1';
      dyed.userData={...dyed.userData,nidoDye:hex};dyed.needsUpdate=true;
      return dyed;
    };
    mesh.material=Array.isArray(mesh.material)?mesh.material.map(recolor):recolor(mesh.material);
  });
}
