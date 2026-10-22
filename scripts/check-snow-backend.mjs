import fs from 'node:fs';import assert from 'node:assert/strict';import {PGlite} from '../tools/sql-test/package/dist/index.js';
process.on('uncaughtException',e=>{console.error(e.message,e.where??'');process.exit(1);});
const db=new PGlite();await db.waitReady;await db.exec(`create role anon;create role authenticated;create role service_role;create schema auth;create schema nido_private;create table auth.users(id uuid primary key);create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;create table game_stats(user_id uuid primary key,love_coins int default 0,total_games_played int default 0,total_coins_earned int default 0,updated_at timestamptz default now());create function nido_private.wallet_lock(uuid) returns void language plpgsql as $$begin return;end$$;create function nido_private.record_bonus(uuid,text,text,text,integer,integer,integer) returns integer language sql as $$select 0$$;create function shared_pet_snapshot() returns jsonb language sql as $$select '{"species":"penguin","name":"Peque","pets":[{"species":"penguin"},{"species":"bear"}],"equipment":[]}'::jsonb$$;grant usage on schema public,auth to authenticated,anon,service_role;`);
await db.exec(fs.readFileSync('supabase/migrations/20261020233000_snow_arena.sql','utf8'));
await db.exec(fs.readFileSync('design/snow-three-minutes.sql','utf8'));
const users=Array.from({length:5},(_,i)=>'00000000-0000-4000-8000-'+String(i+1).padStart(12,'0'));for(const u of users)await db.query('insert into auth.users values($1)',[u]);
async function user(id,role='authenticated'){await db.exec('reset role');await db.query("select set_config('request.jwt.claim.sub',$1,false)",[id??'']);await db.exec('set role '+role);}
const call=async(a,id=null,code=null,data={})=>(await db.query('select snow_room($1,$2,$3,$4) v',[a,id,code,data])).rows[0].v;
await user(users[0]);let r=await call('create',null,null,{species:'penguin'});const id=r.id,code=r.code;
await assert.rejects(call('start',id),/listos/);await assert.rejects(call('create',null,null,{species:'chick'}),/Adopta/);
for(let i=1;i<4;i++){await user(users[i]);r=await call('join',null,code,{species:'bear'});assert.equal(r.players.length,i+1);}
await user(users[4]);await assert.rejects(call('join',null,code,{species:'bear'}),/completa/);await assert.rejects(call('status',id),/disponible/);
for(let i=0;i<4;i++){await user(users[i]);await call('ready',id);}
await user(users[1]);await assert.rejects(call('start',id),/listos/);
await user(users[0]);r=await call('start',id);assert.equal(r.status,'playing');
await assert.rejects(db.query('select snow_commit($1,$2,0,$3,now())',[id,users[0],{}]),/permission/);
await user(users[0],'service_role');const ctx=(await db.query('select snow_context($1,$2) v',[id,users[0]])).rows[0].v;
const state={status:'finished',time:180,players:users.slice(0,4).map(id=>({id,score:2}))};
await assert.rejects(db.query('select snow_commit($1,$2,$3,$4,now())',[id,users[0],ctx.revision,{...state,time:181}]),/Estado inválido/);
assert.equal((await db.query('select snow_commit($1,$2,$3,$4,now()) v',[id,users[0],ctx.revision-1,state])).rows[0].v,false);
assert.equal((await db.query('select snow_commit($1,$2,$3,$4,now()) v',[id,users[0],ctx.revision,state])).rows[0].v,true);
assert.equal((await db.query('select snow_commit($1,$2,$3,$4,now()) v',[id,users[0],ctx.revision,state])).rows[0].v,false);
await user(users[0]);r=await call('status',id);assert.equal(r.reward,9);r=await call('ready',id);assert.equal(r.code,code);assert.equal(r.generation,1);assert.equal(r.players.filter(p=>p.ready).length,1);
await user(null,'anon');await assert.rejects(call('status',id),/permission/);await db.exec('reset role');assert.equal((await db.query('select sum(love_coins)::int n from game_stats')).rows[0].n,36);
console.log('PASS: ownership, 4-player capacity, all-ready gate, host-only start, service-only authority, CAS, idempotent rewards, persistent rematch code and anonymous denial.');await db.close();
