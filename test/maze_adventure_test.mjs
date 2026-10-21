import test from 'node:test';import assert from 'node:assert/strict';
import {createMaze,mazeAction,publicMaze,bridgeIsOpen} from '../assets/runner/maze/engine.js';
import {companionBearing,adventureBearing} from '../assets/runner/maze/navigation.js';
test('lanterns require light, proximity and the exact revealed combination; mistakes do not cost hearts',()=>{
 for(const difficulty of ['easy','medium','hard']){
 let s=createMaze(51,difficulty);const c=s.chests[0],pattern=c.pattern;assert.equal(pattern.length,{easy:1,medium:2,hard:3}[difficulty]);
 assert.equal(publicMaze(s).chests[0].pattern,undefined);
 s=mazeAction(s,0,{kind:'inspect',id:0,light:true});assert.equal(s.chests[0].revealed,false);
 s.players[0].x=c.x;s.players[0].z=c.z;
 s=mazeAction(s,0,{kind:'open',id:0,symbols:pattern});assert.equal(s.keys,0);assert.equal(s.notice.kind,'needLight');
 s=mazeAction(s,0,{kind:'inspect',id:0,light:false});assert.equal(s.chests[0].revealed,false);
 s=mazeAction(s,0,{kind:'inspect',id:0,light:true});assert.deepEqual(publicMaze(s).chests[0].pattern,pattern);
 const hp=s.players[0].hp;
 s=mazeAction(s,0,{kind:'open',id:0,symbols:pattern.map(v=>(v+1)%3)});assert.equal(s.keys,0);assert.equal(s.players[0].hp,hp);
 s=mazeAction(s,0,{kind:'open',id:0,symbols:pattern});assert.equal(s.keys,1);
 s=mazeAction(s,0,{kind:'open',id:0,symbols:pattern});assert.equal(s.keys,1,'cannot collect the same lantern twice');
 }
});
test('bridges have reachable arrival switches, timed solo crossing and permanent safe return',()=>{
 for(const mode of ['solo','partner'])for(let seed=1;seed<=80;seed++){
 let s=createMaze(seed,'hard',mode);assert.equal(s.bridges.length,1);const b=s.bridges[0];
 assert.equal(s.grid[b.z*s.size+b.x],0);assert.equal(s.grid[b.plate.z*s.size+b.plate.x],0);assert.equal(Math.abs(b.x-b.plate.x)+Math.abs(b.z-b.plate.z),1);
 assert.ok(!s.chests.some(c=>(c.x===b.x&&c.z===b.z)||(c.x===b.plate.x&&c.z===b.plate.z)));
 // The switch is accessible without first crossing the locked bridge.
 const seen=new Set([s.size+1]),q=[s.size+1];for(let i=0;i<q.length;i++){const c=q[i];for(const d of [-1,1,-s.size,s.size]){const n=c+d;if(n>=0&&n<s.grid.length&&!s.grid[n]&&n!==b.z*s.size+b.x&&!seen.has(n)){seen.add(n);q.push(n);}}}
 assert.ok(seen.has(b.plate.z*s.size+b.plate.x));assert.equal(bridgeIsOpen(s,b,1000),false);
 s.players[0].x=b.plate.x;s.players[0].z=b.plate.z;
 s=mazeAction(s,0,{kind:'activate',id:b.id},1000);assert.ok(bridgeIsOpen(s,s.bridges[0],1001));
 if(mode==='solo')assert.equal(bridgeIsOpen(s,s.bridges[0],22000),false);
 s=mazeAction(s,0,{kind:'move',dx:b.x-b.plate.x,dz:b.z-b.plate.z},1001);assert.equal(s.bridges[0].secured,true);assert.ok(bridgeIsOpen(s,s.bridges[0],999999));
 }
});
test('legacy rooms finish without migration and the compass reports teammate direction',()=>{
 const s=createMaze(3,'easy','partner');delete s.bridges;s.version=1;for(const c of s.chests){delete c.lantern;delete c.pattern;delete c.revealed;}
 const c=s.chests[0];s.players[0].x=c.x;s.players[0].z=c.z;assert.equal(mazeAction(s,0,{kind:'open',id:0}).keys,1);
 s.players[0].x=1;s.players[0].z=1;s.players[1].x=2;s.players[1].z=1;assert.equal(companionBearing(s,0,0).angle,Math.PI/2);assert.equal(companionBearing(s,0,0).distance,1);
});

test('exit guidance appears only after three lanterns and prioritizes a fallen companion',()=>{
 const s=createMaze(4);assert.equal(adventureBearing(s,0,0),null);s.keys=3;assert.equal(adventureBearing(s,0,0).goal,true);
 const duo=createMaze(4,'easy','partner');duo.keys=3;duo.players[1].hp=0;assert.equal(adventureBearing(duo,0,0).fallen,true);
});
