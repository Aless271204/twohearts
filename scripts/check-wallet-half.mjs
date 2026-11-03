import fs from 'node:fs';
import assert from 'node:assert/strict';
import {PGlite} from 'file:///C:/Users/Lenovo/.codex/.chatgpt-projects/g-p-6ac66fdf30ac819199fd481b4c501ef0/nido-game/tools/sql-test/package/dist/index.js';
const db = new PGlite(); await db.waitReady;
await db.exec(`
create role anon;create role authenticated;
create schema auth;create schema nido_private;
create function auth.uid() returns uuid language sql stable as $$
select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
grant usage on schema public,auth to authenticated,anon;
create table public.user_profiles(id uuid primary key,partner_id uuid);
create table public.game_stats(user_id uuid primary key,love_coins integer not null default 0 check(love_coins>=0),updated_at timestamptz default now());
create table public.inventory_fixture(user_id uuid,item_key text,primary key(user_id,item_key));
create table nido_private.wallet_separations(id bigserial primary key,member_a uuid,member_b uuid,balance_before bigint,each_receives bigint,discarded bigint,created_at timestamptz default now());
alter table nido_private.wallet_separations enable row level security;
`);
const old = fs.readFileSync('supabase/migrations/20261017225009_shared_wallet_game_rewards_and_mystery_art.sql','utf8');
await db.exec(old.slice(old.indexOf('create or replace function nido_private.wallet_members'),old.indexOf('create or replace function public.wallet_snapshot')));
for (const row of JSON.parse(fs.readFileSync('docs/play-console/wallet-before-20261103.json','utf8'))) await db.exec(row.definition);
const a='00000000-0000-0000-0000-000000000001',b='00000000-0000-0000-0000-000000000002',c='00000000-0000-0000-0000-000000000003';
await db.exec(`insert into public.user_profiles values('${a}','${b}'),('${b}','${a}'),('${c}',null);
insert into public.game_stats(user_id,love_coins) values('${a}',4000),('${b}',6000),('${c}',77);
insert into public.inventory_fixture values('${a}','hat'),('${b}','lamp');`);
const before=(await db.query('select * from public.game_stats order by user_id')).rows;
await db.exec(fs.readFileSync('supabase/migrations/20261103203140_wallet_half_separation.sql','utf8'));
assert.deepEqual((await db.query('select * from public.game_stats order by user_id')).rows,before,'installation must not change current balances');
const owners=(await db.query('select * from public.inventory_fixture order by user_id')).rows;
let checks=1;
async function identity(uid){await db.exec(`reset role;set request.jwt.claim.sub='${uid}';set role authenticated;`);}
async function fails(sql){await assert.rejects(db.query(sql));checks++;}
await identity(a);
await fails(`select public.wallet_unlink(10000,false)`);
await fails(`select public.wallet_unlink(9999,true)`);
await identity(c);await fails(`select public.wallet_unlink(77,true)`);
await identity('');await fails(`select public.wallet_snapshot()`);
await db.exec('reset role;set role anon');await fails(`select public.wallet_unlink(10000,true)`);
for(const caller of [a,b])for(const amount of [0,1,9999,10000,10001,4294967293,4294967294]){
  await db.exec(`reset role;update public.user_profiles set partner_id=case when id='${a}' then '${b}'::uuid when id='${b}' then '${a}'::uuid end where id in ('${a}','${b}');
  update public.game_stats set love_coins=case when user_id='${a}' then ${Math.floor(amount/2)} else ${Math.ceil(amount/2)} end where user_id in ('${a}','${b}');`);
  await identity(caller);
  const preview=(await db.query('select public.wallet_snapshot() as value')).rows[0].value;
  assert.equal(preview.separation_percent,50);assert.equal(preview.separation_discarded,0);
  assert.equal(preview.separation_own_share+preview.separation_partner_share,amount);
  const applied=(await db.query(`select public.wallet_unlink(${amount},true) as value`)).rows[0].value;
  assert.equal(applied.coins,preview.separation_own_share);
  assert.equal(applied.partner_coins,preview.separation_partner_share);
  assert.equal(applied.discarded,0);
  await db.exec('reset role');
  const balances=(await db.query(`select user_id,love_coins from public.game_stats order by user_id`)).rows;
  assert.equal(balances[0].love_coins,Math.ceil(amount/2));assert.equal(balances[1].love_coins,Math.floor(amount/2));assert.equal(balances[2].love_coins,77);
  assert.deepEqual((await db.query('select * from public.inventory_fixture order by user_id')).rows,owners);
  assert((await db.query(`select partner_id from public.user_profiles where id in ('${a}','${b}')`)).rows.every(x=>x.partner_id===null));
  const receipt=(await db.query('select * from nido_private.wallet_separations order by id desc limit 1')).rows[0];
  assert.equal(Number(receipt.discarded),0);assert.equal(receipt.rounding_member,amount%2?a:null);
  await identity(caller);await fails(`select public.wallet_unlink(${amount},true)`);
  checks++;
}
await db.close();console.log(`PASS: ${checks} isolated wallet scenarios; no live user or balance modified.`);
