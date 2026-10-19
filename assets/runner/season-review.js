import * as T from 'three';
import {GLTFLoader} from './vendor/loaders/GLTFLoader.js';
import {createLivingForest} from './living-forest.js?revision=polish-3';
import {createBridgeBelt} from './loop-bridge.js';
import {createShieldBubble} from './shield-bubble.js';
import {createStorm} from './storm.js';
import {createSeasonReviewMotion} from './season-review-motion.js';
import {limitTextureMemory} from './texture_budget.js';
import {seasonAt} from './seasons.js';
import {runnerDifficulty} from './difficulty.js';

const $ = id => document.getElementById(id);
const scene = new T.Scene();
const camera = new T.PerspectiveCamera(56, innerWidth / innerHeight, .08, 300);
const renderer = new T.WebGLRenderer({antialias:true});
renderer.setPixelRatio(Math.min(devicePixelRatio, 1.25));
renderer.setSize(innerWidth, innerHeight);
renderer.outputColorSpace = T.SRGBColorSpace;
document.body.prepend(renderer.domElement);
scene.add(new T.HemisphereLight('#d3f5ff', '#435d45', 1.35));
const sun = new T.DirectionalLight('#ffe4aa', 2.5);
sun.position.set(-10, 18, -16);
scene.add(sun);
const world = createLivingForest(scene), deck = createBridgeBelt();
const bubble = createShieldBubble(scene), storm = createStorm(scene);
scene.add(deck);

const canvas = document.createElement('canvas');
canvas.width = canvas.height = 64;
const ctx = canvas.getContext('2d');
const gradient = ctx.createRadialGradient(32, 32, 0, 32, 32, 32);
gradient.addColorStop(0, 'rgba(27,48,32,.28)');
gradient.addColorStop(1, 'rgba(27,48,32,0)');
ctx.fillStyle = gradient;
ctx.fillRect(0, 0, 64, 64);
const shadow = new T.Mesh(new T.PlaneGeometry(1.3, .9), new T.MeshBasicMaterial({map:new T.CanvasTexture(canvas), transparent:true, depthWrite:false}));
shadow.rotation.x = -Math.PI / 2;
shadow.position.y = .191;
shadow.visible = false;
scene.add(shadow);

let pet, motion, shield = true, paused = false, last = performance.now(), offset = 0;
let request = 0, closed = false, frameId;
function release(model) {
  const geometries = new Set(), materials = new Set(), textures = new Set(), skeletons = new Set();
  model.traverse(o => {
    if (o.geometry) geometries.add(o.geometry);
    if (o.skeleton) skeletons.add(o.skeleton);
    for (const m of Array.isArray(o.material) ? o.material : [o.material]) {
      if (!m) continue;
      materials.add(m);
      for (const t of Object.values(m)) if (t?.isTexture) textures.add(t);
    }
  });
  geometries.forEach(g => g.dispose());
  materials.forEach(m => m.dispose());
  textures.forEach(t => t.dispose());
  skeletons.forEach(s => s.dispose());
}

async function load() {
  const version = ++request;
  $('load').hidden = false;
  $('load').textContent = 'Preparando la carrera…';
  $('jump').disabled = true;
  try {
    const name = $('species').value;
    const file = name === 'penguin' ? 'Meshy_AI_Pip_the_Penguin_All_Animations.glb' : name + '.glb';
    const g = await new GLTFLoader().loadAsync('play-models/' + file);
    if (closed || version !== request) { release(g.scene); return; }
    limitTextureMemory(g.scene, 1024);
    const b = new T.Box3().setFromObject(g.scene), size = b.getSize(new T.Vector3());
    g.scene.scale.multiplyScalar(1.15 / size.y);
    const box = new T.Box3().setFromObject(g.scene), c = box.getCenter(new T.Vector3());
    g.scene.position.sub(new T.Vector3(c.x, box.min.y, c.z));
    const next = new T.Group();
    next.add(g.scene);
    next.rotation.y = Math.PI;
    const nextMotion = createSeasonReviewMotion(next, g.animations);
    motion?.dispose();
    if (pet) { scene.remove(pet); release(pet); }
    pet = next;
    motion = nextMotion;
    scene.add(pet);
    shadow.visible = true;
    $('load').hidden = true;
    $('jump').disabled = paused;
    document.body.dataset.species = name;
  } catch (error) {
    if (version === request && !closed) $('load').textContent = 'No se pudo cargar la carrera. Cambia de mascota para reintentar.';
    console.error('Season review:', error);
  }
}

$('species').onchange = load;
$('distance').onchange = () => { offset = 0; };
$('shield').onclick = e => {
  shield = !shield;
  e.currentTarget.textContent = 'Escudo: ' + (shield ? 'encendido' : 'apagado');
};
$('jump').onclick = () => { if (!paused) motion?.jump(); };
$('pause').onclick = e => {
  paused = !paused;
  e.currentTarget.textContent = paused ? 'Continuar' : 'Pausar';
  $('jump').disabled = paused || !motion;
};
addEventListener('keydown', e => {
  if ((e.code === 'Space' || e.code === 'ArrowUp') && !['SELECT','BUTTON','A'].includes(document.activeElement?.tagName)) {
    e.preventDefault();
    if (!paused && !e.repeat) motion?.jump();
  }
});

function frame(now) {
  if (closed) return;
  frameId = requestAnimationFrame(frame);
  const dt = Math.min(.04, (now - last) / 1000);
  last = now;
  const base = Number($('distance').value), speed = runnerDifficulty(base, 10).speed;
  if (!paused && motion) { offset += dt * speed; motion.update(dt, speed); }
  const distance = base + offset, step = paused || !motion ? 0 : dt;
  deck.position.z = distance % 12;
  // Move through the scene while keeping the selected season available for
  // inspection. The actual game still changes seasons with travelled distance.
  world.update(step, camera.aspect, 0, distance, base);
  bubble.update(step, shield, 0, .18 + (motion?.height ?? 0));
  storm.update(step, base, 0);
  sun.intensity = 2.5 - seasonAt(base).storm * 1.6;
  shadow.material.opacity = 1 / (1 + (motion?.height ?? 0));
  shadow.scale.setScalar(1 + (motion?.height ?? 0) * .18);
  camera.position.set(0, 2.35, 5.8);
  camera.lookAt(0, .95, -10);
  renderer.render(scene, camera);
  document.body.dataset.animation = motion?.animation ?? 'loading';
  document.body.dataset.season = seasonAt(base).id;
  $('stats').textContent = `${seasonAt(base).label} · ${Math.round(speed)} m/s · ${renderer.info.render.calls} dibujos · Revisión artística`;
}
load();
frameId = requestAnimationFrame(frame);
addEventListener('resize', () => {
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
});
addEventListener('pagehide', () => {
  closed = true;
  ++request;
  cancelAnimationFrame(frameId);
  motion?.dispose();
  bubble.dispose();
  storm.dispose();
  world.dispose();
  release(scene);
  renderer.dispose();
}, {once:true});
