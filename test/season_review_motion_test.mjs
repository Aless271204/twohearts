import test from 'node:test';
import assert from 'node:assert/strict';
import * as THREE from '../assets/runner/vendor/three.module.js';
import {loadPet, runtimeUrl} from './three-runtime.mjs';
const {createSeasonReviewMotion} = await import(runtimeUrl('../assets/runner/season-review-motion.js'));
const {measurePetSoles} = await import(runtimeUrl('../assets/runner/pet-rest-pose.js'));

for (const file of ['Meshy_AI_Pip_the_Penguin_All_Animations.glb', 'bear.glb', 'pig.glb', 'chick.glb']) {
  test(file + ': seasonal preview runs with articulated feet, grounded stance and a complete jump', async () => {
    const {scene, animations} = await loadPet(file);
    const original = animations.map(c => c.tracks.map(t => Array.from(t.values)));
    const b = new THREE.Box3().setFromObject(scene);
    scene.scale.multiplyScalar(1.15 / (b.max.y - b.min.y));
    const fitted = new THREE.Box3().setFromObject(scene), c = fitted.getCenter(new THREE.Vector3());
    scene.position.sub(new THREE.Vector3(c.x, fitted.min.y, c.z));
    const pet = new THREE.Group();
    pet.add(scene);
    pet.rotation.y = Math.PI;
    const motion = createSeasonReviewMotion(pet, animations);
    assert.equal(motion.animation, 'Running');
    assert.ok(motion.contactSampleCount > 0 && motion.contactSampleCount <= 1024);
    const leg = [];
    pet.traverse(bone => { if (bone.isBone && /LeftUpLeg$/.test(bone.name)) leg.push(bone); });
    assert.equal(leg.length, 1);
    const samples = [];
    for (let i = 0; i < 24; i++) {
      motion.update(1 / 30, 24);
      samples.push(leg[0].quaternion.clone());
      if (i % 4 === 0) {
        const sole = pet.position.y + measurePetSoles(pet);
        assert.ok(Math.abs(sole - .183) < .018, `sole ${sole} must rest on the .18 m deck`);
      }
      assert.equal(pet.position.x, 0);
      assert.equal(pet.position.z, 0);
    }
    assert.ok(samples.some(q => q.angleTo(samples[0]) > .1), 'legs must move, not a resting pose');
    const pausedPosition = pet.position.clone(), pausedLeg = leg[0].quaternion.clone();
    motion.update(0, 24);
    assert.ok(pet.position.equals(pausedPosition));
    assert.ok(leg[0].quaternion.equals(pausedLeg));
    motion.jump();
    let maximum = 0;
    for (let i = 0; i < 60; i++) {
      motion.update(1 / 60, 24);
      maximum = Math.max(maximum, motion.height);
      if (i === 6) {
        assert.equal(motion.animation, 'Regular_Jump');
        const h = motion.height;
        motion.jump();
        assert.equal(motion.height, h, 'a second press cannot reset an airborne jump');
      }
    }
    assert.ok(maximum > 1.4 && maximum < 1.7);
    assert.equal(motion.height, 0);
    assert.equal(motion.animation, 'Running');
    for (let i = 0; i < animations.length; i++) {
      for (let j = 0; j < animations[i].tracks.length; j++) assert.deepEqual(Array.from(animations[i].tracks[j].values), original[i][j]);
    }
    motion.dispose();
  });
}
