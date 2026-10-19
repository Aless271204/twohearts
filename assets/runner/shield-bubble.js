import * as THREE from 'three';
export function createShieldBubble(scene){
 const material=new THREE.ShaderMaterial({transparent:true,depthWrite:false,side:THREE.FrontSide,
  uniforms:{time:{value:0},strength:{value:1},impact:{value:0}},
  vertexShader:'varying vec3 n,v;void main(){vec4 p=modelViewMatrix*vec4(position,1.);n=normalize(normalMatrix*normal);v=-p.xyz;gl_Position=projectionMatrix*p;}',
  fragmentShader:'varying vec3 n,v;uniform float time,strength,impact;void main(){float rim=pow(1.-abs(dot(normalize(n),normalize(v))),2.2);float ripple=pow(.5+.5*sin(normalize(n).y*34.-time*8.),12.);vec3 col=mix(vec3(.18,.74,.95),vec3(.82,1.,1.),rim);float a=(.035+rim*.55+ripple*.035+impact*.2)*strength;gl_FragColor=vec4(col,a);\n#include <colorspace_fragment>\n}'});
 const sphere=new THREE.Mesh(new THREE.SphereGeometry(1,24,16),material);sphere.visible=false;sphere.renderOrder=8;scene.add(sphere);let time=0,was=false,fade=0;
 return {update(dt,active,x,y,growth=1){time+=dt;if(was&&!active)fade=.3;was=active;fade=Math.max(0,fade-dt);sphere.visible=active||fade>0;if(!sphere.visible)return;
  sphere.position.set(x,y+.58*growth,0);sphere.scale.setScalar(.83*growth*(1+Math.sin(time*3)*.014+(active?0:(.3-fade)*.7)));material.uniforms.time.value=time;material.uniforms.strength.value=active?1:fade/.3;material.uniforms.impact.value=active?0:fade/.3;
 },reset(){was=false;fade=0;sphere.visible=false;},dispose(){scene.remove(sphere);sphere.geometry.dispose();material.dispose();}};
}
