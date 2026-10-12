import * as THREE from 'three';

export function createEnchantedCanyon(scene){
  const group=new THREE.Group();scene.add(group);
  const stone=new THREE.IcosahedronGeometry(1,1);
  const rocks=['#778b94','#8a9ca3','#697f88'].map(color=>new THREE.MeshStandardMaterial({color,roughness:1}));
  const moss=new THREE.MeshStandardMaterial({color:'#51944b',roughness:1});
  const pineTrunk=new THREE.CylinderGeometry(.13,.22,3,6),pineCrown=new THREE.ConeGeometry(1.1,2.7,7);
  const bark=new THREE.MeshStandardMaterial({color:'#815230',roughness:1});
  const foliage=new THREE.MeshStandardMaterial({color:'#287747',roughness:1});
  for(let i=0;i<22;i++){
    const side=i%2?1:-1,z=-24-Math.floor(i/2)*11;
    const h=5+Math.floor(i/2)*1.5+(i%3)*1.5,x=side*(11+(i%4)*1.1);
    const rock=new THREE.Mesh(stone,rocks[i%3]);rock.position.set(x,h*.45,z);rock.scale.set(4.5,h*.65,7);rock.rotation.y=i*.45;group.add(rock);
    const cap=new THREE.Mesh(stone,moss);cap.position.set(x,h*.95,z);cap.scale.set(4,.9,5.5);group.add(cap);
    const trunk=new THREE.Mesh(pineTrunk,bark);trunk.position.set(x,h+1.2,z);group.add(trunk);
    for(let j=0;j<3;j++){const crown=new THREE.Mesh(pineCrown,foliage);crown.position.set(x,h+2+j*.75,z);crown.scale.setScalar(1-j*.18);group.add(crown);}
  }
  // Foreground boulders make the riverbanks read as a canyon rather than lawns.
  for(let i=0;i<28;i++){
    const rock=new THREE.Mesh(stone,rocks[i%3]);rock.position.set((i%2?1:-1)*(4.3+i%3*.7),.25,-i*3.7);rock.scale.set(.65+i%3*.2,.6+i%2*.3,.9);rock.rotation.y=i*1.7;group.add(rock);
  }
  return group;
}
