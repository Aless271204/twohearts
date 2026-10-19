import test from 'node:test';import assert from 'node:assert/strict';
import {createMaze,publicMaze} from '../assets/runner/maze/engine.js';
import {movementDirection,nearbyInteraction,objectiveText,MazeTrail,doorFacing} from '../assets/runner/maze/navigation.js';

test('exit door faces a walkable arrival corridor for every difficulty',()=>{
 for(const difficulty of ['easy','medium','hard'])for(let seed=0;seed<60;seed++){
  const s=createMaze(seed,difficulty),yaw=doorFacing(s);
  const x=s.exit.x+Math.round(Math.sin(yaw)),z=s.exit.z+Math.round(Math.cos(yaw));
  assert.equal(s.grid[z*s.size+x],0,`${difficulty} seed ${seed}: door faces a wall`);
 }
});
test('joystick follows the flashlight at all four headings and ignores its dead zone',()=>{
 const expected=[[0,-1],[-1,0],[0,1],[1,0]];
 for(let i=0;i<4;i++){const d=movementDirection(0,1,i*Math.PI/2);assert.ok(Math.abs(d.dx-expected[i][0])<.001&&Math.abs(d.dz-expected[i][1])<.001);}
 assert.equal(movementDirection(.1,.1,0),null);
});
test('context identifies a safe chest, a surprise, a trap and a teammate without revealing hidden contents',()=>{
 const s=publicMaze(createMaze(17,'easy','partner')),p=s.players[0];
 s.traps=[];s.chests=[{id:0,x:p.x,z:p.z,hint:'leaf',opened:false}];
 assert.match(nearbyInteraction(s,0).hint,/seguro/);assert.equal(s.chests[0].type,undefined);
 s.chests[0].hint='scratch';assert.match(nearbyInteraction(s,0).hint,/sorpresa/);
 s.traps=[{id:0,x:p.x,z:p.z,used:false}];assert.equal(nearbyInteraction(s,0).action,'disarm');
 s.players[1].hp=0;assert.equal(nearbyInteraction(s,0).label,'Ayudar');
 s.players[0].hp=0;assert.equal(nearbyInteraction(s,0),null);
});
test('trail reveals only immediate surroundings, resets for a new maze and updates the three-key objective',()=>{
 const trail=new MazeTrail(),s=publicMaze(createMaze(17));trail.update(s,0);assert.equal(trail.visited.size,1);assert.equal(trail.seen.size,5);assert.ok(!trail.seen.has(s.exit.z*s.size+s.exit.x));
 s.players[0].x++;trail.update(s,0);assert.equal(trail.visited.size,2);
 const next=publicMaze(createMaze(18));trail.update(next,0);assert.equal(trail.visited.size,1);
 assert.match(objectiveText(s),/0\/3/);s.keys=3;assert.match(objectiveText(s),/puerta/);
});
