import * as THREE from 'three';
import {createNaturalRest} from './pet-rest-pose.js';
import {keepJumpFacingForward} from './pet-jump-heading.js';
import {jumpStep} from './physics.js';

// This viewer must show a stride, not a resting pet over a scrolling belt.
// Reuse the imported clips and game physics without editing the source GLBs.
export function createSeasonReviewMotion(model, animations, floorY = .18) {
  const mixer = new THREE.AnimationMixer(model);
  const rest = mixer.clipAction(createNaturalRest(model));
  rest.play();
  mixer.update(0);
  const runClip = keepJumpFacingForward(model, animations.find(c => c.name === 'Running'));
  const jumpClip = keepJumpFacingForward(model, animations.find(c => c.name === 'Regular_Jump'));
  if (!runClip || !jumpClip) throw Error('La mascota no incluye carrera y salto');
  const run = mixer.clipAction(runClip), leap = mixer.clipAction(jumpClip);
  leap.setLoop(THREE.LoopOnce, 1);
  leap.clampWhenFinished = true;

  // Cache a bounded set of real foot vertices once. Measuring full body bounds
  // each frame is expensive and also mistakes moving hands for the soles.
  const contacts = [];
  model.traverse(mesh => {
    if (!mesh.isSkinnedMesh || mesh.userData.cosmetic) return;
    const {skinIndex, skinWeight, position} = mesh.geometry.attributes;
    if (!skinIndex || !skinWeight) return;
    const indices = [];
    for (let i = 0; i < position.count; i++) {
      let weight = 0;
      for (let k = 0; k < 4; k++) {
        if (/(Foot|ToeBase|Toe_End)$/.test(mesh.skeleton.bones[skinIndex.getComponent(i, k)]?.name ?? '')) {
          weight += skinWeight.getComponent(i, k);
        }
      }
      if (weight > .5) indices.push(i);
    }
    const sampled = indices.length <= 256 ? indices : Array.from({length: 256}, (_, i) => indices[Math.floor(i * indices.length / 256)]);
    if (sampled.length) contacts.push({mesh, indices: sampled});
  });
  if (!contacts.length) throw Error('No se encontraron las patas de la mascota');

  const vertex = new THREE.Vector3();
  let height = 0, velocity = 0, elapsedJump = 0, active = run;
  const flightDuration = 2 * 8 / 20; // Same initial impulse/gravity as the runner.
  rest.stop();
  run.play();

  function alignSoles() {
    model.position.y = 0;
    model.updateMatrixWorld(true);
    let lowest = Infinity;
    for (const {mesh, indices} of contacts) {
      mesh.skeleton.update();
      for (const index of indices) {
        vertex.fromBufferAttribute(mesh.geometry.attributes.position, index);
        mesh.applyBoneTransform(index, vertex);
        mesh.localToWorld(vertex);
        lowest = Math.min(lowest, vertex.y);
      }
    }
    model.position.y = floorY + height + .003 - lowest;
    model.updateMatrixWorld(true);
  }
  alignSoles();
  return {
    get height() { return height; },
    get animation() { return active === leap ? 'Regular_Jump' : 'Running'; },
    get contactSampleCount() { return contacts.reduce((n, c) => n + c.indices.length, 0); },
    jump() {
      if (height > 0 || velocity > 0) return;
      velocity = 8;
      elapsedJump = 0;
      active.fadeOut(.08);
      active = leap;
      leap.reset().fadeIn(.08).play();
      leap.timeScale = leap.getClip().duration / flightDuration;
    },
    update(dt, speed = 12) {
      if (dt <= 0) return;
      if (velocity !== 0 || height > 0) {
        elapsedJump += dt;
        [height, velocity] = jumpStep(height, velocity, dt);
      }
      if (active === leap && height === 0 && elapsedJump > 0) {
        leap.fadeOut(.10);
        active = run;
        run.reset().fadeIn(.10).play();
      }
      run.timeScale = Math.min(1.7, speed / 14);
      mixer.update(dt);
      alignSoles();
    },
    dispose() {
      mixer.stopAllAction();
      mixer.uncacheRoot(model);
    },
  };
}
