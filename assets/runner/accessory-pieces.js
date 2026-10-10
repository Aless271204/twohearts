import * as THREE from 'three';

// Small editable meshes, shared by equipment and product photography.
export function createAccessory(item, slotName) {
  const root = new THREE.Group();
  root.userData.cosmetic = true;
  const color = /^#[0-9a-f]{6}$/i.test(item?.color) ? item.color : '#91bda7';
  const style = item?.style ?? '';
  const cream = '#fff2df', pink = '#f05280', gold = '#e2b957';
  const materials = new Map();
  const material = c => {
    if (!materials.has(c)) materials.set(c, new THREE.MeshStandardMaterial({color:c, roughness:.75, metalness:c===gold?.3:0, side:THREE.DoubleSide}));
    return materials.get(c);
  };
  function mesh(geometry,c=color,x=0,y=0,z=0) {
    const m=new THREE.Mesh(geometry,material(c));m.position.set(x,y,z);root.add(m);return m;
  }
  function ball(x,y,z,rx,ry,rz,c=color) {
    const m=mesh(new THREE.SphereGeometry(1,16,10),c,x,y,z);m.scale.set(rx,ry,rz);return m;
  }
  function ring(x,y,z,r,t,c=color,horizontal=true) {
    const m=mesh(new THREE.TorusGeometry(r,t,6,32),c,x,y,z);if(horizontal)m.rotation.x=Math.PI/2;return m;
  }
  function tube(points,r,c=color) {return mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(points.map(p=>new THREE.Vector3(...p))),24,r,6,false),c);}
  function badge(kind,x,y,z,size,c=color,hole=false) {
    const s=new THREE.Shape();
    if(kind==='heart') {s.moveTo(0,-.4);s.bezierCurveTo(-.9,.1,-.65,.85,0,.4);s.bezierCurveTo(.65,.85,.9,.1,0,-.4);}
    else for(let i=0;i<10;i++){const a=Math.PI/2+i*Math.PI/5,r=i%2?.42:1;const px=Math.cos(a)*r,py=Math.sin(a)*r;if(i===0)s.moveTo(px,py);else s.lineTo(px,py);}s.closePath();
    if(hole){const path=new THREE.Path();const pts=s.getPoints(32).map(p=>p.multiplyScalar(.76));path.setFromPoints(pts.reverse());s.holes.push(path);}
    const m=mesh(new THREE.ExtrudeGeometry(s,{depth:.012,bevelEnabled:true,bevelSize:.025,bevelThickness:.008,bevelSegments:2,curveSegments:8}),c,x,y,z);m.scale.set(size,size,size);return m;
  }
  function bow(y,z,size=1) {
    for(const sign of [-1,1]){const m=ball(sign*.085*size,y,z,.095*size,.065*size,.035*size);m.rotation.z=sign*.22;}
    ball(0,y,z+.02*size,.032*size,.04*size,.03*size);
  }
  function shell(radius,thetaStart,thetaLength,c=color) {return mesh(new THREE.SphereGeometry(radius,24,16,0,Math.PI*2,thetaStart,thetaLength),c);}

  if(slotName==='pet_head') {
    if(style==='bow'){bow(.055,.16);for(const sign of [-1,1]){const m=ball(sign*.045,-.025,.15,.028,.09,.018);m.rotation.z=sign*.25;}}
    else if(style==='crown'){ring(0,.03,0,.25,.02);for(let i=0;i<5;i++){const a=i*Math.PI*2/5;mesh(new THREE.ConeGeometry(.035,.11,4),gold,Math.sin(a)*.25,.09,Math.cos(a)*.25);}}
    else if(style==='cone'||style==='santa'){mesh(new THREE.ConeGeometry(.24,.32,20),color,0,.12,0);ring(0,-.035,0,.24,.022,cream);if(style==='santa')ball(0,.3,0,.05,.05,.05,cream);}
    else if(style==='cap'){const cap=shell(.285,0,Math.PI/2);cap.scale.y=.62;cap.position.y=-.045;ball(0,-.045,.24,.265,.018,.17);badge('heart',0,.06,.254,.055,cream);}
    else if(style==='beanie'){const hat=shell(.285,0,Math.PI/2);hat.scale.y=.85;hat.position.y=-.06;ring(0,-.045,0,.28,.027,cream);ball(0,.21,0,.065,.065,.065,cream);for(let i=0;i<12;i++){const a=i*Math.PI*2/12;tube([[Math.sin(a)*.28,-.03,Math.cos(a)*.28],[Math.sin(a)*.22,.12,Math.cos(a)*.22],[Math.sin(a)*.08,.2,Math.cos(a)*.08]],.004,cream);}}
    else if(style==='beret'){const m=ball(.025,.035,0,.3,.095,.27);m.rotation.z=-.14;ring(0,-.035,0,.245,.014);ball(.045,.135,0,.014,.025,.014);badge('heart',.14,.035,.22,.045,cream);}
    else if(style==='wig'){const wig=shell(.29,0,1.35);wig.scale.y=.65;wig.position.y=-.035;for(let i=0;i<9;i++){const a=(i/8)*Math.PI*1.5-Math.PI*.75;ball(Math.sin(a)*.265,.015-(i%3)*.02,Math.cos(a)*.255,.075,.095,.04);}for(const sign of [-1,1])tube([[sign*.26,.07,0],[sign*.30,-.1,.02],[sign*.25,-.17,.1]],.038);}
    else{mesh(new THREE.CylinderGeometry(.23,.25,.15,24),color,0,.04,0);const brim=mesh(new THREE.CylinderGeometry(.37,.37,.018,32),color,0,-.035,0);brim.scale.z=.9;ring(0,-.005,0,.25,.013,pink);if(style==='flower_hat'||style==='garden_hat'){for(let i=0;i<5;i++){const a=i*Math.PI*2/5;ball(.25+Math.sin(a)*.022,.025+Math.cos(a)*.022,.05,.018,.018,.01,pink);}ball(.25,.025,.065,.014,.014,.01,cream);}}
  } else if(slotName==='pet_eyes') {
    if(style==='sleep_mask'){ball(0,0,.02,.255,.09,.018);for(const sign of [-1,1])tube([[sign*.13-.035,.01,.041],[sign*.13,-.012,.05],[sign*.13+.035,.01,.041]],.004,'#6b4655');tube([[-.25,0,0],[-.28,0,-.12],[0,0,-.22],[.28,0,-.12],[.25,0,0]],.009);}
    else if(style==='eyepatch'){ball(.13,0,.015,.085,.085,.02,'#30303d');badge('heart',.13,0,.04,.04,pink);tube([[-.25,.10,-.05],[0,.06,.03],[.25,-.025,.03],[.27,0,-.15]],.008,'#30303d');}
    else{
      for(const sign of [-1,1]){
        if(style==='heart_glasses'||style==='star_glasses'){const kind=style==='heart_glasses'?'heart':'star';badge(kind,sign*.13,0,0,.105,color,true);badge(kind,sign*.13,0,-.01,.079,'#403345');}
        else{ring(sign*.13,0,0,.088,.008,color,false);if(style!=='round_glasses')ball(sign*.13,0,-.006,.079,.079,.007,'#403345');}
        tube([[sign*.22,0,0],[sign*.27,0,-.08],[sign*.26,-.015,-.23]],.008);
      }
      tube([[-.04,0,0],[0,.012,.007],[.04,0,0]],.008);
    }
  } else if(slotName==='pet_neck') {
    if(style==='bead_necklace'){for(let i=0;i<22;i++){const a=i*Math.PI*2/22;ball(Math.sin(a)*.25,Math.cos(a)*.015,Math.cos(a)*.2,.018,.018,.018,i%2?cream:color);}badge('heart',0,-.07,.22,.06,pink);}
    else if(style==='gold_chain'){const r=ring(0,0,0,.25,.009,gold);r.scale.y=.8;badge('star',0,-.065,.215,.045,gold);}
    else if(style==='bow_tie'){const r=ring(0,0,0,.25,.016);r.scale.y=.8;bow(0,.215,.75);}
    else if(style==='bandana'){const s=new THREE.Shape();s.moveTo(-.21,.02);s.lineTo(.21,.02);s.lineTo(0,-.22);s.closePath();mesh(new THREE.ExtrudeGeometry(s,{depth:.012,bevelEnabled:true,bevelSize:.006,bevelThickness:.004,bevelSegments:2}),color,0,0,.21);const r=ring(0,0,0,.25,.017);r.scale.y=.8;badge('heart',0,-.1,.227,.03,cream);}
    else{for(let y=0;y<3;y++){const r=ring(0,y*.016,0,.255,.017);r.scale.y=.8;}const tail=ball(.15,-.095,.205,.044,.13,.016);tail.rotation.z=-.22;for(let i=0;i<4;i++)ball(.12+i*.018,-.215,.215,.008,.025,.007,cream);}
  } else if(slotName==='pet_body') {
    // An open shell rather than a solid sphere: head, wings and feet remain free.
    const garment=shell(.285,.42,2.0);garment.scale.set(1,.9,.8);
    ring(0,.233,0,.115,.012,cream).scale.y=.75;
    if(style==='dress'){const skirt=mesh(new THREE.CylinderGeometry(.23,.34,.16,32,1,true),color,0,-.20,0);skirt.scale.z=.8;ring(0,-.12,0,.255,.011,cream).scale.y=.8;bow(.04,.24,.55);}
    else if(style==='coat'){ring(0,.205,0,.145,.025,cream);for(const y of [.10,0,-.10])ball(0,y,.232,.013,.013,.012,gold);}
    else if(style==='denim_jacket'){tube([[0,.21,.18],[0,0,.239],[0,-.19,.18]],.006,cream);for(const sign of [-1,1]){const pocket=mesh(new THREE.BoxGeometry(.075,.065,.01),color,sign*.12,.04,.225);pocket.rotation.y=sign*.15;ball(sign*.12,.06,.238,.008,.008,.008,gold);}}
    else if(style==='hoodie'){const hood=shell(.14,0,Math.PI*1.2);hood.position.set(0,.19,-.16);for(const sign of [-1,1])tube([[sign*.065,.2,.20],[sign*.07,.11,.24]],.005,cream);ball(0,-.10,.225,.09,.04,.015);badge('heart',0,-.10,.246,.04,pink);}
    else badge('heart',0,.025,.236,.075,pink);
  } else if(slotName==='pet_feet') {
    // One shoe; attachment layer creates independent left and right instances.
    const shoe=ball(0,.045,.025,.09,.05,.12);
    const sole=ball(0,.014,.025,.092,.017,.122,cream);
    if(style==='rain_boots'){const boot=mesh(new THREE.CylinderGeometry(.07,.075,.1,18,1,true),color,0,.115,-.012);ring(0,.165,-.012,.07,.008,cream);}
    else if(style==='slippers'){shoe.material=material(cream);for(let i=0;i<7;i++)ball(Math.sin(i)*.04,.09,.065+Math.cos(i)*.02,.025,.023,.025,cream);}
    else if(style==='mary_jane'){tube([[-.075,.075,0],[0,.105,0],[.075,.075,0]],.012);badge('heart',0,.065,.138,.035,cream);}
    else if(style==='sandals'){shoe.visible=false;tube([[-.08,.05,.07],[0,.085,.08],[.08,.05,.07]],.018);tube([[-.07,.04,-.04],[0,.065,-.07],[.07,.04,-.04]],.015);}
    else{for(let i=0;i<3;i++)tube([[-.04,.085,.03+i*.02],[.04,.085,.03+i*.02]],.005,cream);badge('heart',.07,.055,.075,.027,cream).rotation.y=Math.PI/2;}
    root.userData.shoeSole=true;
  } else if(slotName==='pet_back') {
    const m=mesh(new THREE.CapsuleGeometry(.12,.14,4,16));m.scale.set(1.4,1,.6);badge('heart',0,0,-.078,.07,pink).rotation.y=Math.PI;
    for(const sign of [-1,1])tube([[sign*.13,.17,.08],[sign*.14,0,.15],[sign*.13,-.17,.08]],.012);
  }
  root.name=`accessory:${slotName}:${style}`;
  return root;
}

export function disposeAccessory(root) {
  const geometries=new Set(),materials=new Set();
  root.traverse(o=>{if(o.geometry)geometries.add(o.geometry);for(const m of Array.isArray(o.material)?o.material:[o.material])if(m)materials.add(m);});
  geometries.forEach(g=>g.dispose());materials.forEach(m=>m.dispose());root.removeFromParent();
}
