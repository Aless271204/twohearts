import * as THREE from 'three';

// Optional account loadout. Local models and physics work without the network.
export function equipRunnerCosmetics(penguin, loadout) {
  const group = new THREE.Group(); group.name = 'equipped-cosmetics';
  const material = item => new THREE.MeshStandardMaterial({color:/^#[0-9a-f]{6}$/i.test(item?.color)?item.color:'#91bda7',roughness:.75});
  const box = (item,x,y,z,w,h,d) => {
    const mesh = new THREE.Mesh(new THREE.BoxGeometry(w,h,d),material(item));mesh.position.set(x,y,z);group.add(mesh);return mesh;
  };
  const head=loadout.pet_head;
  if(head){
    if(head.style==='crown'||head.style==='cone'||head.style==='santa'){
      const hat=new THREE.Mesh(new THREE.ConeGeometry(.14,head.style==='crown'?.13:.28,head.style==='crown'?5:20),material(head));hat.position.set(0,1.15,0);group.add(hat);
    }else if(head.style==='bow'){
      box(head,-.085,1.10,-.02,.13,.07,.07);box(head,.085,1.10,-.02,.13,.07,.07);
    }else{const hat=new THREE.Mesh(new THREE.CylinderGeometry(.13,.14,.13,20),material(head));hat.position.set(0,1.13,0);group.add(hat);box(head,0,1.07,0,.4,.025,.28);}
  }
  const scarf=loadout.pet_neck;if(scarf){box(scarf,0,.69,.02,.38,.055,.32);box(scarf,.16,.60,.16,.07,.18,.04);}
  const back=loadout.pet_back;if(back){box(back,0,.52,.25,.30,.35,.13);box(back,0,.55,.32,.23,.04,.015);}
  const body=loadout.pet_body;if(body)box(body,0,.48,.14,.3,.21,.04);
  const eyes=loadout.pet_eyes;if(eyes){box(eyes,-.095,.88,-.18,.13,.055,.025);box(eyes,.095,.88,-.18,.13,.055,.025);}
  penguin.add(group);
  return group;
}
