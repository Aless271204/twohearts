import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import * as T from '../assets/runner/vendor/three.module.js';

const three = new URL('../assets/runner/vendor/three.module.js', import.meta.url).href;
const load = source => import('data:text/javascript;base64,' + Buffer.from(source.replace("from 'three'", `from '${three}'`)).toString('base64'));
const original = fs.readFileSync(new URL('./fixtures/cloth_wrap_reference.txt',import.meta.url),'utf8');
const updated = fs.readFileSync(new URL('../assets/runner/pet-cloth-wrap.js',import.meta.url),'utf8');
function fixture() {
  const model=new T.Group(), source=new T.Mesh(new T.BufferGeometry(),new T.MeshBasicMaterial());
  source.name='body';source.isSkinnedMesh=true;
  source.geometry.setAttribute('position',new T.Float32BufferAttribute([0,0,0,1,0,0,0,1,0],3));
  let calls=0, phase=0;
  const skeleton={update(){calls++;}};
  source.skeleton=skeleton;source.applyBoneTransform=(_i,p)=>p.setZ(phase);
  model.add(source);
  const garment=new T.Mesh(new T.BufferGeometry(),new T.MeshBasicMaterial()),count=3000;
  const ids=[],weights=[],offsets=[],positions=[];
  for(let i=0;i<count;i++){ids.push(0,1,2);weights.push(.2,.3,.5);offsets.push(0,0,.05);positions.push(.2,.3,.1);}
  garment.geometry.setAttribute('position',new T.Float32BufferAttribute(positions,3));
  garment.geometry.setAttribute('_nido_wrap_indices',new T.Uint16BufferAttribute(ids,3));
  garment.geometry.setAttribute('_nido_wrap_weights',new T.Float32BufferAttribute(weights,3));
  garment.geometry.setAttribute('_nido_wrap_offset',new T.Float32BufferAttribute(offsets,3));
  garment.geometry.setAttribute('_nido_wrap_blend',new T.Float32BufferAttribute(Array(count).fill(.7),1));
  garment.userData.nidoSurfaceWrap={sources:[{name:'body',offset:0,count:3}]};
  const skin={matrixWorld:new T.Matrix4(),bindMatrixInverse:new T.Matrix4(),skeleton,
    applyBoneTransform(_i,p){return p.setZ(phase+.1);}};
  garment.userData.nidoWrapSkin=skin;model.add(garment);
  return {model,garment,setPhase(v){phase=v;calls=0;},get calls(){return calls;}};
}
test('moving garment is unchanged while skeleton calculation is once per frame',async()=>{
  const before=await load(original),after=await load(updated),a=fixture(),b=fixture();
  const oldWrap=before.createClothWrap(a.model,[a.garment]),newWrap=after.createClothWrap(b.model,[b.garment]);
  for(const phase of [0,.2,.7,1,.4]){
    a.setPhase(phase);b.setPhase(phase);oldWrap.update();newWrap.update();
    assert.deepEqual(b.garment.geometry.attributes.position.array,a.garment.geometry.attributes.position.array);
    assert.deepEqual(b.garment.geometry.attributes.normal.array,a.garment.geometry.attributes.normal.array);
    assert.equal(b.calls,1);assert.equal(a.calls,3004);
  }
  console.log('3004 → 1 skeleton updates; identical vertices and normals across five poses');
});
