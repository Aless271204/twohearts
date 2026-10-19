import * as THREE from 'three';
import {mergeGeometries} from 'three/addons/utils/BufferGeometryUtils.js';

const wrap = z => ((z + 140) % 144 + 144) % 144 - 140;
const variation = n => { const v=Math.sin(n*127.1+19.3)*43758.5453;return v-Math.floor(v); };
const profiles = {
  blossom: [1, .06, 0, 0, 0], meadow: [1, .35, .04, 0, 0],
  fruit: [.8, 1, .6, 0, .15], sunflower: [0, 1, .12, 0, 0],
  fallen: [0, 0, 1, 0, 0], snow: [0, 0, 0, 1, 0],
};

function canopyRadius(p) {
  return 1 + .035*Math.sin(p.x*5+p.z*3)*Math.sin(p.y*4-1) + .018*Math.cos(p.z*7-p.x*2);
}

export function createRoundedCanopyGeometry() {
  const geometry=new THREE.SphereGeometry(1,14,10),p=geometry.attributes.position;
  const vertex=new THREE.Vector3(),color=new THREE.Color(),colors=new Float32Array(p.count*3);
  for(let i=0;i<p.count;i++) {
    vertex.fromBufferAttribute(p,i).multiplyScalar(canopyRadius(vertex));
    p.setXYZ(i,vertex.x,vertex.y,vertex.z);
    const shade=.75+.25*Math.min(1,Math.max(0,(vertex.y+.8)/1.8));
    color.setRGB(shade,shade*.98,shade*.97).toArray(colors,i*3);
  }
  geometry.setAttribute('color',new THREE.BufferAttribute(colors,3));
  geometry.computeVertexNormals();
  return geometry;
}

function colored(geometry, color) {
  const shade = new THREE.Color(color), values = new Float32Array(geometry.attributes.position.count * 3);
  for (let i = 0; i < values.length; i += 3) shade.toArray(values, i);
  geometry.setAttribute('color', new THREE.BufferAttribute(values, 3));
  return geometry;
}

// Rounded petals and a raised centre are real geometry, seen from either side.
// One merged flower is shared by hundreds of instances, without image textures.
function flowerGeometry(petals = 5, sunflower = false, stem = false) {
  const parts = [], sphere = new THREE.SphereGeometry(1, 6, 4);
  for (let i = 0; i < petals; i++) {
    const a = i * Math.PI * 2 / petals;
    const petal = sphere.clone();
    petal.scale(sunflower ? .105 : .17, .28, .085);
    // Cup the tips gently, and taper their colour towards the raised centre.
    const positions=petal.attributes.position;
    for(let k=0;k<positions.count;k++) {
      const tip=(positions.getY(k)+.28)/.56;
      positions.setZ(k,positions.getZ(k)+.07*tip*tip);
    }
    petal.computeVertexNormals();
    petal.rotateZ(a - Math.PI / 2);
    petal.translate(Math.cos(a) * .27, Math.sin(a) * .27, 0);
    colored(petal, sunflower ? '#ffd451' : '#fff1f5');
    const colors=petal.attributes.color;
    for(let k=0;k<colors.count;k++) {
      const shade=.92+.08*variation(i*53+k);
      colors.setXYZ(k,colors.getX(k)*shade,colors.getY(k)*shade,colors.getZ(k)*shade);
    }
    parts.push(petal);
  }
  parts.push(colored(sphere.clone().scale(sunflower ? .19 : .115, sunflower ? .19 : .115, .11).translate(0, 0, .065), sunflower ? '#98652f' : '#ffcc65'));
  if (stem) {
    const stalk = new THREE.CylinderGeometry(.025, .035, .65, 5);
    stalk.translate(0, -.65, -.025);
    parts.push(colored(stalk, '#548644'));
    const leaf = sphere.clone().scale(.12, .25, .045).rotateZ(-.7).translate(.12, -.55, 0);
    parts.push(colored(leaf, '#7caa4c'));
  }
  sphere.dispose();
  const result = mergeGeometries(parts);
  parts.forEach(g => g.dispose());
  return result;
}

function fruitGeometry() {
  const parts = [];
  const apple = new THREE.SphereGeometry(1, 10, 7);
  const positions = apple.attributes.position;
  for (let i = 0; i < positions.count; i++) {
    const x = positions.getX(i), y = positions.getY(i), z = positions.getZ(i);
    const ribs = 1 + .06 * Math.cos(Math.atan2(z, x) * 5);
    positions.setXYZ(i, x * ribs, y * .91 - Math.max(0, y - .7) * .4, z * ribs);
  }
  apple.computeVertexNormals();
  colored(apple, '#ef7766');
  const appleColors=apple.attributes.color,blush=new THREE.Color('#e96063'),gold=new THREE.Color('#f6ad76'),shade=new THREE.Color();
  for(let i=0;i<positions.count;i++) {
    shade.copy(blush).lerp(gold,Math.max(0,positions.getY(i)*.5+positions.getX(i)*.3+.25));
    shade.toArray(appleColors.array,i*3);
  }
  parts.push(apple);
  const stalk = new THREE.CylinderGeometry(.06, .08, .42, 5);
  stalk.rotateZ(-.18); stalk.translate(.03, .91, 0);
  parts.push(colored(stalk, '#805d36'));
  const leaf = new THREE.SphereGeometry(1, 6, 4);
  leaf.scale(.45, .12, .2); leaf.rotateZ(.4); leaf.translate(.32, 1.06, 0);
  parts.push(colored(leaf, '#6fa74c'));
  const result = mergeGeometries(parts);
  parts.forEach(g => g.dispose());
  return result;
}

function fallenLeafGeometry() {
  const shape = new THREE.Shape();
  shape.moveTo(0, -.35);
  for (const [x,y] of [[-.13,-.13],[-.38,-.06],[-.27,.10],[-.38,.28],[-.13,.24],[0,.51],[.13,.24],[.38,.28],[.27,.10],[.38,-.06],[.13,-.13],[0,-.35]]) shape.lineTo(x,y);
  const geometry = new THREE.ExtrudeGeometry(shape, {depth:.022, bevelEnabled:false});
  geometry.rotateX(-Math.PI / 2);
  return geometry;
}

export function createSeasonalBotany(scene, trees) {
  const group = new THREE.Group();
  group.name = 'seasonal-botany';
  scene.add(group);
  const material = new THREE.MeshLambertMaterial({vertexColors:true});
  const batches = [];
  function batch(name, geometry, count, profile, vertexColors = true) {
    const mesh = new THREE.InstancedMesh(geometry, vertexColors ? material : new THREE.MeshLambertMaterial({color:'#ffffff'}), count);
    mesh.name = name;
    mesh.frustumCulled = false;
    const items = [];
    batches.push({mesh, items, profile});
    group.add(mesh);
    return batches.at(-1);
  }
  const blooms = batch('spring-canopy-blossoms', flowerGeometry(), trees.length * 15, 'blossom');
  const meadow = batch('spring-meadow-flowers', flowerGeometry(5, false, true), trees.length * 4, 'meadow');
  const fruit = batch('orchard-fruit', fruitGeometry(), trees.length * 3, 'fruit');
  const sunflowers = batch('summer-sunflowers', flowerGeometry(10, true, true), trees.length * 2, 'sunflower');
  const fallen = batch('autumn-leaf-carpet', fallenLeafGeometry(), trees.length * 5, 'fallen', false);
  const caps = batch('winter-crown-snow', new THREE.SphereGeometry(1, 8, 5), trees.length * 3, 'snow', false);
  const facing = new THREE.Vector3(0,0,1), normal = new THREE.Vector3(), yAxis = new THREE.Vector3(0,1,0), surface = new THREE.Vector3();
  const rotation = new THREE.Quaternion(), dummy = new THREE.Object3D();
  function add(batch, x,y,z, sx,sy,sz, q, color = '#ffffff') {
    batch.items.push({x,y,z,sx,sy,sz,q:q.clone()});
    batch.mesh.setColorAt(batch.items.length - 1, new THREE.Color(color));
  }
  function attachToCrown(batch,cx,cy,cz,yaw) {
    const p=batch.items.at(-1),inverse=new THREE.Quaternion().setFromAxisAngle(yAxis,-yaw);
    p.crown={cx,cy,cz,yaw,phase:cz*.41+cx,
      offset:new THREE.Vector3(p.x-cx,p.y-cy,p.z-cz).applyQuaternion(inverse),
      rotation:inverse.multiply(p.q)};
  }
  for (let i = 0; i < trees.length; i++) {
    const {x,z,height,side,row} = trees[i];
    for (let crown = 0; crown < 3; crown++) {
      const cx = x + side * crown * .55, cy = height * .6 + crown * .8;
      const rx = 2.7 - crown * .35, yaw = z*.41+cx;
      for (let j = 0; j < 5; j++) {
        const a = j * 2.399 + i * .71 + crown;
        normal.set(-side * (.4 + (j % 3) * .2), Math.sin(a) * .65, .45 + Math.cos(a) * .35).normalize();
        rotation.setFromUnitVectors(facing, normal);
        surface.copy(normal).applyAxisAngle(yAxis,-yaw);
        surface.multiplyScalar(canopyRadius(surface)*.985).multiply(new THREE.Vector3(rx,2.1,2.4)).applyAxisAngle(yAxis,yaw);
        const size = .58 + (i + j) % 4 * .1;
        add(blooms, cx + surface.x, cy + surface.y, z + surface.z, size,size,size,rotation, ['#ffa8cb','#ffdaea','#ffffff','#f8b6d9'][(j + i) % 4]);
        attachToCrown(blooms,cx,cy,z,yaw);
      }
      // A separate cap gives snow a rounded upper surface, instead of merely
      // turning every leaf white. It follows this exact tree's scrolling anchor.
      rotation.setFromAxisAngle(yAxis,yaw);
      add(caps, cx, cy + 1.53, z, rx * .88,.63,2.03,rotation,'#eff8ff');
      attachToCrown(caps,cx,cy,z,yaw);
      const a = (crown + i) * 1.4;
      normal.set(-side*.7,-.36,.6).normalize();
      surface.copy(normal).applyAxisAngle(yAxis,-yaw);
      surface.multiplyScalar(canopyRadius(surface)).multiply(new THREE.Vector3(rx,2.1,2.4)).applyAxisAngle(yAxis,yaw);
      const fx = cx + surface.x, fy = cy + surface.y - .12, fz = z + surface.z;
      rotation.setFromAxisAngle(new THREE.Vector3(0,1,0), a);
      const size = .24 + (i % 3) * .03;
      add(fruit,fx,fy,fz,size,size,size,rotation,i % 3 === 0 ? '#ffe2a0' : '#ffffff');
      attachToCrown(fruit,cx,cy,z,yaw);
    }
    for (let j = 0; j < 4; j++) {
      const px = side * (3.17 + variation(i*17+j*31)*.8), pz = z - 2.1 + j * 1.15 + (variation(i*43+j)-.5)*.8;
      // The stems descend to the riverbank, not the water or an empty gap.
      rotation.setFromAxisAngle(yAxis, -side*.35+(variation(i+j*11)-.5)*.7);
      const size = .52 + variation(i*71+j*13)*.42;
      add(meadow,px,-.26 + size*.96,pz,size,size,size,rotation,['#ffffff','#ffc4de','#e4ccff','#fff0ba'][(row+j)%4]);
    }
    for (let j = 0; j < 2; j++) {
      rotation.setFromAxisAngle(new THREE.Vector3(0,1,0), -side * .45);
      const size = .95 + (row+j) % 3 * .18;
      add(sunflowers,side * (3.5+j*.6),-.26+size*.96,z+j*2,size,size,size,rotation);
    }
    for (let j = 0; j < 5; j++) {
      rotation.setFromAxisAngle(new THREE.Vector3(0,1,0), i+j*1.9);
      // On the boardwalk edge; central lanes stay legible and unobstructed.
      add(fallen,side*(2.05+(j%2)*.23),.193,z+j*.8,.45,.45,.45,rotation,['#e98142','#f3b24d','#cc6051'][(i+j)%3]);
    }
  }
  for (const {mesh,items} of batches) {
    mesh.count = items.length;
    mesh.instanceColor.needsUpdate = true;
  }
  const state = {},crownRotation=new THREE.Quaternion(),crownEuler=new THREE.Euler(),crownOffset=new THREE.Vector3();
  return {
    group,
    update(season, distance, time=0) {
      for (const {mesh,items,profile} of batches) {
        const weights = profiles[profile];
        const from = weights[Math.max(0,season.index-1)], to = weights[season.index];
        const amount = from+(to-from)*season.blend;
        state[profile] = amount;
        mesh.visible = amount > .015;
        if (!mesh.visible) continue;
        for (let i = 0; i < items.length; i++) {
          const p = items[i];
          if(p.crown) {
            const c=p.crown;
            crownRotation.setFromEuler(crownEuler.set(0,c.yaw,Math.sin(time*.8+c.phase)*.025));
            crownOffset.copy(c.offset).applyQuaternion(crownRotation);
            dummy.position.set(c.cx+crownOffset.x,c.cy+crownOffset.y,wrap(c.cz+distance)+crownOffset.z);
            dummy.quaternion.copy(crownRotation).multiply(c.rotation);
          } else {
            dummy.position.set(p.x,p.y,wrap(p.z+distance));
            dummy.quaternion.copy(p.q);
          }
          dummy.scale.set(p.sx*amount,p.sy*amount,p.sz*amount);
          dummy.updateMatrix();
          mesh.setMatrixAt(i,dummy.matrix);
        }
        mesh.instanceMatrix.needsUpdate = true;
      }
      group.userData.season = season.id;
    },
    get amounts() { return {...state}; },
    dispose() {
      scene.remove(group);
      const materials = new Set();
      for (const {mesh} of batches) { mesh.geometry.dispose(); materials.add(mesh.material); mesh.dispose(); }
      materials.forEach(m => m.dispose());
    },
  };
}
