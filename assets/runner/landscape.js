import * as THREE from 'three';

export function createLandscape(scene) {
  const backdrop=new THREE.Group();scene.add(backdrop);
  const sky=new THREE.Mesh(new THREE.SphereGeometry(240,32,16),new THREE.ShaderMaterial({
    side:THREE.BackSide,depthWrite:false,
    uniforms:{zenith:{value:new THREE.Color('#86c8e0')},horizon:{value:new THREE.Color('#f8edcb')}},
    vertexShader:'varying vec3 vPosition; void main(){vPosition=position;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.0);}',
    fragmentShader:'uniform vec3 zenith; uniform vec3 horizon; varying vec3 vPosition; void main(){float h=smoothstep(0.0,0.65,normalize(vPosition).y);gl_FragColor=vec4(mix(horizon,zenith,h),1.0);}'
  }));backdrop.add(sky);
  function ridge(z,color,base,amplitude,phase){
    const vertices=[],indices=[];
    for(let i=0;i<=48;i++){
      const x=-170+i*340/48;
      const y=base+Math.sin(i*.36+phase)*amplitude+Math.sin(i*.81+phase)*amplitude*.25+Math.abs(x)*.035;
      vertices.push(x,-10,z,x,y,z);
      if(i<48){const a=i*2;indices.push(a,a+2,a+1,a+1,a+2,a+3);}
    }
    const geometry=new THREE.BufferGeometry();geometry.setAttribute('position',new THREE.Float32BufferAttribute(vertices,3));geometry.setIndex(indices);geometry.computeVertexNormals();
    backdrop.add(new THREE.Mesh(geometry,new THREE.MeshBasicMaterial({color,side:THREE.DoubleSide,fog:false})));
  }
  ridge(-190,'#b6cdb3',29,10,1.2);
  ridge(-150,'#93b8a1',23,8,2.4);
  ridge(-112,'#78a68a',15,5,.8);
  const sun=new THREE.Mesh(new THREE.SphereGeometry(5.5,24,16),new THREE.MeshBasicMaterial({color:'#fff1b6',fog:false}));sun.position.set(-34,40,-165);backdrop.add(sun);
  const canvas=document.createElement('canvas');canvas.width=canvas.height=128;
  const ctx=canvas.getContext('2d'),gradient=ctx.createRadialGradient(64,64,8,64,64,64);
  gradient.addColorStop(0,'rgba(255,235,169,.75)');gradient.addColorStop(.35,'rgba(255,233,162,.25)');gradient.addColorStop(1,'rgba(255,235,169,0)');
  ctx.fillStyle=gradient;ctx.fillRect(0,0,128,128);
  const halo=new THREE.Sprite(new THREE.SpriteMaterial({map:new THREE.CanvasTexture(canvas),transparent:true,depthWrite:false,fog:false,blending:THREE.AdditiveBlending}));halo.position.copy(sun.position);halo.scale.set(38,38,1);backdrop.add(halo);
  const clouds=[],cloudMaterial=new THREE.MeshBasicMaterial({color:'#fff5df',transparent:true,opacity:.8,depthWrite:false,fog:false});
  const cloudGeometry=new THREE.SphereGeometry(1,12,8);
  for(let i=0;i<7;i++){
    const cloud=new THREE.Group();cloud.position.set(-95+i*31,32+(i%3)*9,-155-(i%2)*20);
    for(let j=0;j<5;j++){const puff=new THREE.Mesh(cloudGeometry,cloudMaterial);puff.scale.set(7+j%2*2,2.5+j%3,3);puff.position.set((j-2)*5,Math.sin(j*2)*1.1,0);cloud.add(puff);}
    clouds.push(cloud);backdrop.add(cloud);
  }
  return {update(dt){for(const cloud of clouds){cloud.position.x+=dt*.12;if(cloud.position.x>140)cloud.position.x=-140;}}};
}
