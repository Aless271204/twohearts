import fs from 'node:fs';import assert from 'node:assert/strict';
import {PGlite} from '../tools/sql-test/package/dist/index.js';
const db=new PGlite();await db.waitReady;
await db.exec(`create role anon;create role authenticated;create role service_role;create schema auth;create schema nido_private;
create table auth.users(id uuid primary key);create table public.game_stats(user_id uuid primary key,love_coins integer not null default 0,updated_at timestamptz);`);
await db.exec(fs.readFileSync('design/play-gold-purchases.sql','utf8'));
const a='00000000-0000-4000-8000-000000000001',b='00000000-0000-4000-8000-000000000002';
await db.query('insert into auth.users values($1),($2)',[a,b]);
const credit=(user,product,token,consumed=false)=>db.query('select public.play_credit_verified($1,$2,$3,null,$4,false) result',[user,product,token,consumed]);
await db.exec('set role service_role');
for(const [i,product,gold]of [[1,'nido_gold_500',500],[2,'nido_gold_2500',2500],[3,'nido_gold_10000',10000]]){
 const token=String(i).repeat(64);assert.equal((await credit(a,product,token)).rows[0].result.gold,gold);
 assert.equal((await credit(a,product,token,true)).rows[0].result.already_credited,true);
 await assert.rejects(()=>credit(b,product,token),/owner mismatch/);
}
await assert.rejects(()=>credit(a,'unknown','4'.repeat(64)),/Invalid verified/);
await assert.rejects(()=>credit(a,'nido_gold_500','5'.repeat(64),true),/without receipt/);
await db.exec('reset role');assert.equal((await db.query('select love_coins from public.game_stats where user_id=$1',[a])).rows[0].love_coins,13000);
for(const role of ['anon','authenticated']){await db.exec('set role '+role);await assert.rejects(()=>credit(a,'nido_gold_500','6'.repeat(64)),/permission denied/);await db.exec('reset role');}
await db.close();console.log('PASS: verified product amounts, same-token retries, account ownership, consumed-without-receipt and client write denial.');
