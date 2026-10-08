import * as THREE from 'three';

export function createFlowMaterial(vertical=false){
  return new THREE.ShaderMaterial({
    side:THREE.DoubleSide,
    uniforms:{time:{value:0},vertical:{value:vertical?1:0}},
    vertexShader:'varying vec2 waterUV; void main(){waterUV=uv;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.0);}',
    fragmentShader:`varying vec2 waterUV; uniform float time; uniform float vertical;
      void main(){vec2 p=waterUV*vec2(8.,mix(65.,12.,vertical));
        float ripple=sin(p.y*2.+time*1.7+sin(p.x*2.)*.3)*.5+.5;
        vec3 color=mix(vec3(.04,.40,.48),vec3(.13,.67,.70),ripple*.55);
        float foam=pow(max(0.,sin(p.y*3.+time*2.8+sin(p.x*4.)*.8)),18.)*.25;
        color=mix(color,vec3(.65,.96,.93),foam);
        float streak=sin(p.x*2.+sin(p.y*.7+time*2.)*.7+sin(p.y*1.4+time)*.25)*.5+.5;
        vec3 falling=mix(vec3(.45,.82,.90),vec3(.83,.98,.96),streak*.4);
        color=mix(color,falling,vertical);
        gl_FragColor=vec4(color,1.);}`
  });
}

export function createKingdom(parent){
  const kingdom=new THREE.Group();kingdom.position.set(0,10.3,-2);parent.add(kingdom);
  const ivory=new THREE.MeshStandardMaterial({color:'#ffe8bc',roughness:.75});
  const roof=new THREE.MeshStandardMaterial({color:'#9865cc',roughness:.5,metalness:.15});
  const gold=new THREE.MeshStandardMaterial({color:'#ffd36e',metalness:.45,roughness:.35});
  const glow=new THREE.MeshBasicMaterial({color:'#8ef5f3'});
  const towerGeometry=new THREE.CylinderGeometry(.65,.8,3,10);
  const roofGeometry=new THREE.ConeGeometry(1,1.7,10);
  for(let i=0;i<5;i++){
    const tower=new THREE.Group();tower.position.set((i-2)*1.6,0,i===2?-1.7:0);const h=i===2?1.4:1+(i%2)*.2;
    const body=new THREE.Mesh(towerGeometry,ivory);body.position.y=1.5*h;body.scale.y=h;tower.add(body);
    const cap=new THREE.Mesh(roofGeometry,roof);cap.position.y=3*h+.85;tower.add(cap);
    const finial=new THREE.Mesh(new THREE.SphereGeometry(.12,8,6),gold);finial.position.y=3*h+1.75;tower.add(finial);
    const window=new THREE.Mesh(new THREE.SphereGeometry(.21,8,6),glow);window.scale.set(.65,1.3,.2);window.position.set(0,2*h,.73);tower.add(window);
    const flag=new THREE.Mesh(new THREE.PlaneGeometry(.55,.3),roof);flag.material=roof;flag.position.set(.3,3*h+1.9,0);flag.material.side=THREE.DoubleSide;tower.add(flag);
    kingdom.add(tower);
  }
  const wall=new THREE.Mesh(new THREE.BoxGeometry(7,1.2,1),ivory);wall.position.set(0,.6,.2);kingdom.add(wall);
  const gate=new THREE.Mesh(new THREE.TorusGeometry(.68,.14,6,20,Math.PI),gold);gate.position.set(0,.85,.78);kingdom.add(gate);
  const portal=new THREE.Mesh(new THREE.PlaneGeometry(.95,1.4),glow);portal.position.set(0,.7,.8);kingdom.add(portal);
  return kingdom;
}
