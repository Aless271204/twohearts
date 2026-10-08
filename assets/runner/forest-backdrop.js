import * as THREE from 'three';

// Two triangles replace the previous forest meshes. Art stays independent of
// game rules; only the river and waterfall pixels receive gentle distortion.
export function createForestBackdrop(scene,{video=true}={}){
  let clip,still,videoTexture,disposed=false,frozen=false;
  const uniforms={art:{value:null},time:{value:0},aspect:{value:1},imageAspect:{value:864/1824},lean:{value:0},isVideo:{value:0}};
  const material=new THREE.ShaderMaterial({
    uniforms,depthTest:false,depthWrite:false,toneMapped:false,
    vertexShader:'varying vec2 screenUV; void main(){screenUV=uv;gl_Position=vec4(position.xy,1.0,1.0);}',
    fragmentShader:`uniform sampler2D art; uniform float time,aspect,imageAspect,lean,isVideo; varying vec2 screenUV;
      void main(){
        vec2 uv=screenUV;
        // Cover the viewport without stretching the artwork.
        if(aspect>imageAspect) uv.y=(uv.y-.5)*imageAspect/aspect+.5;
        else uv.x=(uv.x-.5)*aspect/imageAspect+.5;
        // Align the painted landing with the playable bridge's vanishing point.
        uv.x+=(1.-isVideo)*.026;
        vec3 original=texture2D(art,uv).rgb;
        float waterColor=smoothstep(.04,.16,min(original.g-original.r,original.b-original.r));
        float foreground=1.-smoothstep(.56,.60,uv.y);
        float falls=smoothstep(.36,.41,uv.x)*(1.-smoothstep(.59,.63,uv.x))*smoothstep(.58,.60,uv.y)*(1.-smoothstep(.83,.85,uv.y));
        float water=waterColor*max(foreground,falls);
        float phase=time*6.28318530718/8.;
        float foliage=smoothstep(.06,.18,original.g-max(original.r,original.b));
        vec2 flow=vec2(sin(uv.y*95.+phase*2.)*.002,sin(uv.x*80.+phase*3.)*.0014);
        vec2 breeze=vec2(sin(phase+uv.y*14.)*.0016,sin(phase*2.+uv.x*11.)*.0007);
        vec3 color=texture2D(art,uv+(1.-isVideo)*(flow*water+breeze*foliage)).rgb;
        color+=(1.-isVideo)*water*.012*sin(phase*3.+uv.y*170.+uv.x*35.);
        // Video uploads use RGBA8; decode sRGB before the renderer encodes output.
        vec3 linearVideo=mix(color/12.92,pow((color+.055)/1.055,vec3(2.4)),step(vec3(.04045),color));
        color=mix(color,linearVideo,isVideo);
        gl_FragColor=vec4(color,1.);
        #include <colorspace_fragment>
      }`
  });
  const plane=new THREE.Mesh(new THREE.PlaneGeometry(2,2),material);plane.frustumCulled=false;plane.renderOrder=-1000;scene.add(plane);
  return {async load(){
    const texture=await new THREE.TextureLoader().loadAsync('forest-kingdom.jpg');still=texture;
    texture.colorSpace=THREE.SRGBColorSpace;texture.generateMipmaps=false;texture.minFilter=THREE.LinearFilter;
    uniforms.art.value=texture;uniforms.imageAspect.value=texture.image.width/texture.image.height;
    if(video){
      clip=document.createElement('video');clip.src='forest-kingdom-loop.mp4';clip.loop=true;clip.muted=true;clip.playsInline=true;clip.preload='auto';
      clip.id='forest-background-video';clip.style.display='none';clip.setAttribute('aria-hidden','true');document.body.append(clip);
      clip.addEventListener('loadeddata',()=>{
        if(disposed)return;
        videoTexture=new THREE.VideoTexture(clip);videoTexture.colorSpace=THREE.SRGBColorSpace;
        uniforms.art.value=videoTexture;uniforms.isVideo.value=1;
        uniforms.imageAspect.value=clip.videoWidth/clip.videoHeight;
        if(!frozen)clip.play().catch(()=>{uniforms.art.value=still;uniforms.isVideo.value=0;});
      },{once:true});
      clip.load();
    }
  },update(dt,aspect,lean){
    uniforms.time.value=(uniforms.time.value+dt)%8;uniforms.aspect.value=aspect;uniforms.lean.value=lean;
    if(clip&&uniforms.isVideo.value&&!frozen){if(dt===0&&!clip.paused)clip.pause();else if(dt>0&&clip.paused)clip.play().catch(()=>{});}
  },setPaused(value){frozen=value;if(clip){if(value)clip.pause();else if(uniforms.isVideo.value)clip.play().catch(()=>{});}},get video(){return clip;},dispose(){disposed=true;if(clip){clip.pause();clip.removeAttribute('src');clip.load();clip.remove();}videoTexture?.dispose();still?.dispose();}};
}
