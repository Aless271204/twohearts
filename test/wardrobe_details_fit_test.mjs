import test from 'node:test';
import assert from 'node:assert/strict';
import {loadPet} from './three-runtime.mjs';

for(const species of ['penguin','bear','pig','chick'])for(const [item,bone] of [['bow_neck','Neck'],['shoes_heart',null],['boots_rain',null],['slippers_cloud',null],['shoes_chic',null],['sandals_summer',null]]){
 test(species+' '+item+': every sewn detail follows its own attachment without independent stretching',async()=>{
  const {scene}=await loadPet('../accessories/restart_'+item+'_'+species+'.glb');let meshes=0;
  scene.traverse(mesh=>{
   if(!mesh.isMesh)return;meshes++;
   const names=mesh.userData.nidoBoneNames,j=mesh.geometry.attributes.skinIndex,w=mesh.geometry.attributes.skinWeight;
   const side=mesh.name.includes('Left')?'Left':mesh.name.includes('Right')?'Right':null;
   const expected=bone??(side+'Foot');assert.ok(bone||side,'shoe pieces must identify their foot');
   if(item==='sandals_summer'){
    assert.equal(mesh.userData.nidoSkinTransfer.method,'original_paw_anchor');
    for(let i=0;i<j.count;i++){
     assert.ok(Math.abs(w.getX(i)+w.getY(i)+w.getZ(i)+w.getW(i)-1)<1e-5);
     for(let k=0;k<4;k++)assert.ok(names[j.getComponent(i,k)],'use the immutable pet rig');
     for(let k=0;k<4;k++){
      assert.equal(j.getComponent(i,k),j.getComponent(0,k),'one stable paw anchor');
      assert.equal(w.getComponent(i,k),w.getComponent(0,k),'no independent sole deformation');
     }
    }
    return;
   }
   for(let i=0;i<j.count;i++){
    assert.ok(names[j.getX(i)].endsWith(expected),mesh.name+' uses '+expected);
    assert.equal(w.getX(i),1);assert.equal(w.getY(i)+w.getZ(i)+w.getW(i),0);
   }
  });assert.ok(meshes>0);
 });
}
