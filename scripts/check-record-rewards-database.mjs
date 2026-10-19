import fs from 'node:fs';
import assert from 'node:assert/strict';
import {PGlite} from '../tools/sql-test/package/dist/index.js';
process.on('uncaughtException',error=>{console.error(error.message);if(error.detail)console.error(error.detail);if(error.where)console.error(error.where);process.exit(1);});
const db=new PGlite();await db.waitReady;
await db.exec(`create role anon;create role authenticated;create role service_role;
create schema auth;create schema nido_private;create schema extensions;
create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
set check_function_bodies=off;`);
const quote=s=>'"'+s.replaceAll('"','""')+'"';
for(const t of JSON.parse(fs.readFileSync('outputs/feature-schema-tables.json'))){
 const columns=t.columns.map(c=>quote(c.name)+' '+c.type+(c.default&&!/extensions\./.test(c.default)?' default '+c.default:'')+(c.notnull?' not null':''));
 await db.exec(`create table ${quote(t.schema)}.${quote(t.name)} (${[...columns,...t.constraints??[]].join(',')});`);
}
for(const f of JSON.parse(fs.readFileSync('outputs/feature-schema-functions.json')))await db.exec(f.definition);
for(const name of ['20261017225009_shared_wallet_game_rewards_and_mystery_art.sql','20261017233649_pong_powerups_and_paired_adoption.sql','20261018061000_endless_runner_and_river_chapter.sql','20261018080000_penalty_rooms.sql','20261018100000_maze_rooms.sql','20261018194207_game_point_reward_rates.sql'])await db.exec(fs.readFileSync('supabase/migrations/'+name,'utf8'));
for(const f of JSON.parse(fs.readFileSync('outputs/reward-functions-before.json')))await db.exec(f.definition);
await db.exec(fs.readFileSync('supabase/migrations/20261019014026_guardian_ten_points_and_record_bonus.sql','utf8'));
await db.exec(fs.readFileSync('supabase/migrations/20261019015436_record_reward_service_access.sql','utf8'));
const a='00000000-0000-4000-8000-000000000001',b='00000000-0000-4000-8000-000000000002';
await db.exec(`insert into auth.users values('${a}'),('${b}');insert into public.user_profiles(id,full_name,email,partner_id) values('${a}','Test A','a@example.invalid','${b}'),('${b}','Test B','b@example.invalid','${a}');insert into public.game_stats(user_id) values('${a}'),('${b}');select set_config('request.jwt.claim.sub','${a}',false);`);
const scalar=async(sql,args=[])=>(await db.query(sql,args)).rows[0].value;
const bonus=async(game,scope,run,score,base,cap,win=null)=>scalar('select nido_private.record_bonus($1,$2,$3,$4,$5,$6,$7,$8) value',[a,game,scope,run,score,base,cap,win]);
for(const game of ['pong','quiz','penalties','art']){
 assert.equal(await bonus(game,'test','1',0,20,100,true),0,'first result establishes a baseline');
 assert.equal(await bonus(game,'test','2',0,20,100,true),2,'a longer winning streak earns 10 percent');
 assert.equal(await bonus(game,'test','2',0,20,100,true),0,'the same run cannot advance a streak or credit twice');
 assert.equal(await bonus(game,'test','3',0,8,100,false),0,'a loss resets the streak');
 assert.equal(await bonus(game,'test','4',0,20,100,true),0,'matching a previous best earns nothing');
}
assert.equal(await bonus('maze','hard:solo','1',100,20,100),0);
assert.equal(await bonus('maze','hard:solo','2',101,20,21),1,'daily cap constrains the bonus');
assert.equal(await bonus('maze','hard:solo','3',102,3,100),1,'small rewards round up to an integral coin');
const run=async(distance,points)=>{const start=await scalar('select public.runner_start_session($1) value',[a]);await db.query("update public.runner_sessions set started_at=now()-interval '100 seconds' where id=$1",[start.session_id]);const args=[a,start.session_id,distance,points,100];const saved=await scalar('select public.runner_finish_session($1,$2,$3,$4,$5) value',args);assert.deepEqual(await scalar('select public.runner_finish_session($1,$2,$3,$4,$5) value',args),saved);return saved;};
assert.equal((await run(1000,500)).coins_awarded,10);
const record=await run(1200,500);assert.equal(record.coins_awarded,11);assert.equal(record.record_bonus,1);assert.equal(record.new_record,true);
assert.equal((await run(1200,500)).coins_awarded,10,'a tied distance is not a record');
async function guardian(frames,reward){const id=crypto.randomUUID(),hash='a'.repeat(64);await db.query(`insert into nido_private.guardian_rooms(id,code,host_id,guest_id,mode,difficulty,seed,status,started_at,confirmed_hash,host_species,guest_species) values($1,upper(substr(replace(($1::uuid)::text,'-',''),1,8)),$2,$3,'partner','easy',17,'running',now()-interval '60 seconds',$4,'penguin','bear')`,[id,a,b,hash]);const before=await scalar('select nido_private.wallet_balance($1) value',[a]);const args=[id,a,hash,reward,frames];const saved=await scalar('select public.guardian_settle($1,$2,$3,$4,$5) value',args);const balance=await scalar('select nido_private.wallet_balance($1) value',[a]);assert.equal(Number(balance)-Number(before),saved.total_reward);await scalar('select public.guardian_settle($1,$2,$3,$4,$5) value',args);assert.equal(await scalar('select nido_private.wallet_balance($1) value',[a]),balance);return saved;}
assert.equal((await guardian(1200,20)).total_reward,20);
assert.equal((await guardian(1100,20)).total_reward,22,'two account shares sum to one shared-wallet reward plus each record bonus');
assert.equal((await guardian(1100,20)).total_reward,20,'matching completion time earns no extra');
// Synthetic finished states isolate the actual settlement code from gameplay.
for(const game of ['pong','quiz'])for(let i=0;i<2;i++){
 const id=crypto.randomUUID();
 await db.query(`insert into public.duo_matches(id,game,player_a,player_b,status,winner,state,created_at) values($1,$2,$3,$4,'finished',$3,'{"phase":"reveal","question_no":0,"wins_a":2,"wins_b":0,"questions":[1]}',now()-interval '1 minute')`,[id,game,a,b]);
 const saved=await scalar('select public.duo_tick($1) value',[id]);assert.equal(saved.reward,i?22:20);assert.equal(saved.record_bonus,i?2:0);
 assert.equal((await scalar('select public.duo_tick($1) value',[id])).reward,saved.reward);
}
for(let i=0;i<2;i++){
 const id=crypto.randomUUID();
 await db.query(`insert into nido_private.art_rooms(id,code,host,guest,difficulty,scene,deadline,host_art,guest_art,host_vote,guest_vote) values($1,upper(substr(replace(($1::uuid)::text,'-',''),1,8)),$2,$3,1,0,now()-interval '1 minute','synthetic-art-a','synthetic-art-b',$2,$2)`,[id,a,b]);
 const saved=await scalar("select nido_private.art_action('status',$1) value",[JSON.stringify({id})]);assert.equal(saved.reward,i?17:15);
 assert.equal((await scalar("select nido_private.art_action('status',$1) value",[JSON.stringify({id})])).reward,saved.reward);
}
for(let i=0;i<2;i++){
 const id=crypto.randomUUID(),state={status:'playing',moves:i?100:120,players:[{hp:3}]};
 await db.query(`insert into nido_private.maze_rooms(id,code,host_id,mode,difficulty,theme,seed,status,state) values($1,upper(substr(replace(($1::uuid)::text,'-',''),1,8)),$2,'solo','easy','halloween',17,'playing',$3)`,[id,a,JSON.stringify(state)]);
 const saved=await scalar("select public.maze_room_service($1,'update',$2,'',$3) value",[a,id,JSON.stringify({revision:0,generation:0,state:{...state,status:'victory'},reward:20})]);assert.equal(saved.reward,i?22:20);
 assert.equal((await scalar("select public.maze_room_service($1,'status',$2) value",[a,id])).reward,saved.reward);
}
for(let i=0;i<2;i++){
 const id=crypto.randomUUID(),state={round:9,score:[5,0],attempts:[[true,true,true,true,true],[false,false,false,false]],winner:null,last:null};
 await db.query(`insert into nido_private.penalty_rooms(id,code,host_id,guest_id,status,state,choices,deadline) values($1,upper(substr(replace(($1::uuid)::text,'-',''),1,8)),$2,$3,'playing',$4,'{"0":{"x":0.5,"y":0.5,"power":0.5}}',now()+interval '15 seconds')`,[id,a,b,JSON.stringify(state)]);
 await db.query("select set_config('request.jwt.claim.sub',$1,false)",[b]);
 await scalar("select public.penalty_room('choose',$1,'',$2) value",[id,JSON.stringify({round:9,generation:0,choice:{x:.5,y:.5,power:.5}})]);
 await db.query("select set_config('request.jwt.claim.sub',$1,false)",[a]);
 const saved=await scalar("select public.penalty_room('status',$1) value",[id]);assert.equal(saved.reward,i?22:20);
 assert.equal((await scalar("select public.penalty_room('status',$1) value",[id])).reward,saved.reward);
}
for(const role of ['anon','authenticated'])assert.equal(await scalar(`select has_function_privilege('${role}','nido_private.record_bonus(uuid,text,text,text,bigint,integer,integer,boolean)','execute') value`),false);
await db.exec('alter role service_role bypassrls; set role service_role;');
assert.equal(await bonus('pong','service-test','1',0,20,100,true),0);
assert.equal(await bonus('pong','service-test','2',0,20,100,true),2,'the trusted server can actually read and write the private record tables');
await db.exec('reset role;');
console.log('PASS: all seven game settlements, record thresholds, 10% rounding, streak resets, ties, repeated saves, cap, shared Guardian ledger and restricted privileges. Synthetic local accounts only.');
await db.close();
