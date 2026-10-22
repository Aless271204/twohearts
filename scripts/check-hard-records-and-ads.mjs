import fs from 'node:fs';
import assert from 'node:assert/strict';
import {PGlite} from '../tools/sql-test/package/dist/index.js';
const db=new PGlite();await db.waitReady;
await db.exec(`create role anon;create role authenticated;create role service_role;create schema auth;create schema nido_private;
create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
create table public.game_stats(user_id uuid primary key,love_coins integer not null default 0,updated_at timestamptz);
create table public.user_profiles(id uuid primary key,full_name text,nickname text,partner_id uuid);
create table public.social_blocks(user_id uuid,blocked_id uuid);create table public.social_follows(follower_id uuid,following_id uuid);
grant usage on schema nido_private,auth to authenticated;`);
const records=fs.readFileSync('supabase/migrations/20261019014026_guardian_ten_points_and_record_bonus.sql','utf8');
await db.exec(records.slice(0,records.indexOf('-- Preserve the runner')));
await db.exec(fs.readFileSync('supabase/migrations/20261020134230_social_weekly_rankings.sql','utf8'));
const ads=fs.readFileSync('supabase/migrations/20261014182543_store_economy_colors_rewarded_ads.sql','utf8');
await db.exec(ads.slice(ads.indexOf('create table public.rewarded_ad_sessions'),ads.indexOf('revoke all on function nido_private.color_hex')));
await db.exec(fs.readFileSync('design/unlimited-rewarded-videos.sql','utf8'));
await db.exec(fs.readFileSync('design/hard-records-only.sql','utf8'));
const a='00000000-0000-4000-8000-000000000001';
await db.query('insert into auth.users values($1)',[a]);
await db.query('insert into public.user_profiles values($1,\'Test\',null,null)',[a]);
await db.query("select set_config('request.jwt.claim.sub',$1,false)",[a]);
const scalar=async(sql,args=[])=>(await db.query(sql,args)).rows[0].v;
const bonus=(game,scope,run,score)=>scalar('select nido_private.record_bonus($1,$2,$3,$4,$5,20,100) v',[a,game,scope,run,score]);
for(const [game,scope]of [['guardian','easy:solo:forest'],['guardian','medium:partner:forest'],['maze','easy:solo'],['art','wins:0'],['art','wins:1']]){
 assert.equal(await bonus(game,scope,'1',100),0);assert.equal(await bonus(game,scope,'2',101),0);
 assert.equal(await scalar('select count(*)::int v from nido_private.game_record_receipts where game=$1 and scope=$2',[game,scope]),0);
}
for(const [game,scope]of [['guardian','hard:partner:forest'],['maze','hard:solo'],['art','wins:2'],['penalties','wins'],['pong','wins'],['quiz','wins'],['pebble_runner','distance'],['snow','scores']]){
 assert.equal(await bonus(game,scope,'1',100),0);assert.equal(await bonus(game,scope,'2',101),2);assert.equal(await bonus(game,scope,'2',101),0);
}
await db.query("insert into nido_private.game_record_receipts(user_id,game,scope,run,score,base_reward,bonus,is_record) values($1,'guardian','easy:solo:forest','historical',9999,1,0,false)",[a]);
assert.equal((await scalar("select public.social_weekly_ranking('guardian','friends','easy:solo:forest') v")).mine,null);
assert.equal((await scalar("select public.social_weekly_ranking('guardian','friends','hard:partner:forest') v")).mine.score,101);
assert.equal((await scalar("select public.social_weekly_ranking('snow','friends','scores') v")).mine.score,101);
const status=await scalar('select public.rewarded_ad_status() v');assert.equal(status.unlimited,true);assert.equal(status.remaining,null);assert.equal(status.gold,3);
for(let i=0;i<21;i++){
 const ticket=(await scalar('select public.rewarded_ad_begin() v')).ticket;
 const receipt=await scalar('select public.admob_credit_verified($1,$2,$3,now()) v',[ticket,a,'verified-test-'+i]);assert.equal(receipt.gold,3);
 assert.equal((await scalar('select public.admob_credit_verified($1,$2,$3,now()) v',[ticket,a,'verified-test-'+i])).already_processed,true);
}
assert.equal(await scalar('select love_coins v from public.game_stats where user_id=$1',[a]),63);
const expired=(await scalar('select public.rewarded_ad_begin() v')).ticket;
await db.query("update public.rewarded_ad_sessions set expires_at=now()-interval '1 minute' where ticket=$1",[expired]);
await assert.rejects(()=>scalar('select public.admob_credit_verified($1,$2,$3,now()) v',[expired,a,'invalid-expired']),/Invalid reward window/);
await db.close();console.log('PASS: only hard mode qualifies; ungraded games retained; historical easy excluded; 21 videos without cooldown; three coins each; duplicate and expired rewards protected.');
