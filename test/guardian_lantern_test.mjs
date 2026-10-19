import test from 'node:test';import assert from 'node:assert/strict';
import {createGame,stepGame} from '../assets/runner/guardian/engine.js';
import {RUNE_X,INPUT} from '../assets/runner/guardian/config.js';
import {lanternGuide} from '../assets/runner/guardian/lantern-guide.js';
test('lantern guide reflects actual activation, solo countdown and opening the boss defense',()=>{
 const s=createGame(1,'hard','solo');s.stage='boss';s.boss.action='ward';s.boss.timer=100;s.level.enemies=[];
 assert.equal(lanternGuide(s).count,0);s.players[0].x=RUNE_X[0];
 assert.equal(lanternGuide(s).button,'Encender');stepGame(s,[INPUT.pulse]);
 assert.deepEqual(lanternGuide(s).lit,[true,false]);assert.equal(lanternGuide(s).seconds,7);
 s.players[0].attackCooldown=0;s.players[0].x=RUNE_X[1];stepGame(s,[INPUT.pulse]);
 assert.equal(s.boss.action,'expose');assert.equal(lanternGuide(s),null);
});
test('partner hint explains coordination and never advertises a solo countdown',()=>{
 const s=createGame(1,'hard','partner');s.stage='boss';s.boss.action='ward';s.boss.timer=100;s.level.enemies=[];
 s.players[0].x=RUNE_X[0];s.players[1].x=RUNE_X[1];stepGame(s,[INPUT.pulse,0]);
 assert.match(lanternGuide(s).hint,/tu pareja/);assert.equal(lanternGuide(s).seconds,null);
 stepGame(s,[INPUT.pulse,INPUT.pulse]);assert.equal(s.boss.action,'expose');
});
