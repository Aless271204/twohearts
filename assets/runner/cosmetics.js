import * as THREE from 'three';

// One renderer and one loadout in Home, inventory and the forest.
export function equipRunnerCosmetics(penguin, loadout) {
  const previous=penguin.userData.cosmetics;
  if(previous){for(const slot of previous.userData.slots??[]){slot.removeFromParent();slot.traverse(o=>{o.geometry?.dispose();o.material?.dispose();});}previous.traverse(o=>{o.geometry?.dispose();o.material?.dispose();});previous.removeFromParent();}
  let neckBone;penguin.traverse(o=>{if(o.isBone&&/neck$/i.test(o.name))neckBone=o;});
  const neckHeight=neckBone?penguin.worldToLocal(neckBone.getWorldPosition(new THREE.Vector3())).y:.52;
  const group=new THREE.Group();group.name='equipped-cosmetics';group.userData.slots=[];penguin.add(group);
  const safeColor=item=>/^#[0-9a-f]{6}$/i.test(item?.color)?item.color:'#91bda7';
  let slot;
  const mesh=(geometry,item,x,y,z)=>{const object=new THREE.Mesh(geometry,new THREE.MeshStandardMaterial({color:safeColor(item),roughness:.9,metalness:0}));object.position.set(x,y,z);slot.add(object);return object;};
  const box=(item,x,y,z,w,h,d)=>mesh(new THREE.BoxGeometry(w,h,d),item,x,y,z);
  const ring=(item,x,y,z,radius,tube)=>{const object=mesh(new THREE.TorusGeometry(radius,tube,6,24),item,x,y,z);object.rotation.x=Math.PI/2;return object;};
  const heart=(item,x,y,z,size,hollow=false)=>{const shape=new THREE.Shape();shape.moveTo(0,-.4);shape.bezierCurveTo(-.9,.1,-.65,.85,0,.4);shape.bezierCurveTo(.65,.85,.9,.1,0,-.4);if(hollow){const inner=new THREE.Path();inner.moveTo(0,-.28);inner.bezierCurveTo(-.63,.07,-.455,.595,0,.28);inner.bezierCurveTo(.455,.595,.63,.07,0,-.28);shape.holes.push(inner);}const object=mesh(new THREE.ExtrudeGeometry(shape,{depth:.018,bevelEnabled:false,curveSegments:8}),item,x,y,z);object.scale.set(size,size,1);return object;};
  const begin=()=>{slot=new THREE.Group();group.add(slot);return slot;};
  const anchors=[];
  const head=loadout.pet_head;
  if(head){begin();slot.position.y=-.08;anchors.push([slot,'head']);
    if(head.style==='crown'){
      ring(head,0,1.06,0,.235,.025);
      for(let i=0;i<5;i++){const angle=i*Math.PI*2/5;mesh(new THREE.ConeGeometry(.035,.105,4),head,Math.sin(angle)*.235,1.105,Math.cos(angle)*.235);}
    }else if(head.style==='bow'){
      // Ribbon loops and tails share the real equipped and thumbnail mesh.
      for(const side of [-1,1]){
        const loop=new THREE.Shape();loop.moveTo(0,0);loop.bezierCurveTo(.07,.035,.155,.11,.17,.065);loop.bezierCurveTo(.205,-.015,.16,-.08,.12,-.06);loop.bezierCurveTo(.06,-.035,.025,-.018,0,0);
        const wing=mesh(new THREE.ExtrudeGeometry(loop,{depth:.035,bevelEnabled:true,bevelThickness:.012,bevelSize:.01,bevelSegments:3,curveSegments:12}),head,side*.018,1.08,.10);wing.scale.x=side;
        const tail=new THREE.Shape();tail.moveTo(0,0);tail.lineTo(.04,0);tail.lineTo(.09,-.14);tail.lineTo(.05,-.12);tail.lineTo(.025,-.15);tail.closePath();
        const ribbon=mesh(new THREE.ExtrudeGeometry(tail,{depth:.02,bevelEnabled:true,bevelThickness:.005,bevelSize:.005,bevelSegments:2}),head,side*.01,1.07,.095);ribbon.scale.x=side;
      }
      const knot=mesh(new THREE.SphereGeometry(.038,14,10),head,0,1.08,.13);knot.scale.set(.8,1,.7);
    }else if(head.style==='cone'||head.style==='santa'){
      mesh(new THREE.ConeGeometry(.22,.32,20),head,0,1.16,0);ring(head,0,1.005,0,.22,.025);
      if(head.style==='santa')mesh(new THREE.SphereGeometry(.055,10,8),{color:'#fff5e5'},0,1.32,0);
    }else if(head.style==='cap'){
      const cap=mesh(new THREE.SphereGeometry(.25,16,8,0,Math.PI*2,0,Math.PI/2),head,0,1.02,0);cap.scale.y=.5;
      const visor=box(head,0,1.02,.21,.39,.035,.22);visor.rotation.x=-.1;
    }else{
      mesh(new THREE.CylinderGeometry(.18,.21,.15,20),head,0,1.1,0);
      mesh(new THREE.CylinderGeometry(.31,.31,.025,24),head,0,1.025,0);
      if(head.style==='flower_hat')for(let i=0;i<5;i++)mesh(new THREE.SphereGeometry(.035,8,6),{color:'#f4a8c0'},Math.sin(i*1.2)*.21,1.06,Math.cos(i*1.2)*.21);
    }
  }
  const scarf=loadout.pet_neck;if(scarf){begin();slot.position.y=neckHeight+.015-.65;anchors.push([slot,'neck']);const collar=ring(scarf,0,.65,0,.245,.028);collar.scale.set(1,.8,.8);box(scarf,.18,.57,.17,.065,.18,.035);}
  const back=loadout.pet_back;if(back){begin();anchors.push([slot,'body']);const pack=mesh(new THREE.CapsuleGeometry(.12,.14,4,12),back,0,.47,-.29);pack.scale.set(1.4,1,.6);box(back,0,.46,-.375,.25,.17,.04);heart({color:'#f7bbbd'},0,.46,-.401,.07).rotation.y=Math.PI;
    for(const side of [-1,1])box(back,side*.145,.50,-.22,.035,.34,.035);
  }
  const body=loadout.pet_body;if(body){begin();slot.position.y=-.10;anchors.push([slot,'body']);const shirt=mesh(new THREE.SphereGeometry(.27,20,12,0,Math.PI*2,.5,2.05),body,0,.43,0);shirt.scale.set(1,.85,1);heart({color:'#ffe9e8'},0,.46,.29,.10);}
  const eyes=loadout.pet_eyes;if(eyes){begin();slot.position.y=-.18;anchors.push([slot,'head']);
    for(const side of [-1,1]){
      if(eyes.style==='heart_glasses')heart(eyes,side*.125,.88,.34,.095,true);
      else {const lens=mesh(new THREE.TorusGeometry(.085,.012,6,18),eyes,side*.125,.88,.33);lens.scale.y=.75;}
    }
    box(eyes,0,.88,.34,.08,.018,.025);
    for(const side of [-1,1])box(eyes,side*.22,.88,.19,.015,.018,.29);
  }
  penguin.updateMatrixWorld(true);
  let headBone,bodyBone;penguin.traverse(o=>{if(!o.isBone)return;if(/head$/i.test(o.name))headBone=o;if(/spine2$/i.test(o.name))bodyBone=o;});
  for(const [part,name] of anchors){const bone=name==='head'?headBone:name==='neck'?neckBone:bodyBone;if(bone){bone.attach(part);group.userData.slots.push(part);}}
  penguin.userData.cosmetics=group;return group;
}
