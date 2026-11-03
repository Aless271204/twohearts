import fs from 'node:fs';
import assert from 'node:assert/strict';
import {PGlite} from '../tools/sql-check/node_modules/@electric-sql/pglite/dist/index.js';

const db = new PGlite(); await db.waitReady;
await db.exec(`
create role anon; create role authenticated;
create schema auth; create schema nido_private;
create function auth.uid() returns uuid language sql stable as $$
select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
grant usage on schema public,auth to anon,authenticated;
create table auth.users(id uuid primary key);
create table public.user_profiles(id uuid primary key,partner_id uuid,invite_code text unique,connection_type text,relationship_start date);
`);
const a='00000000-0000-0000-0000-000000000001';
const b='00000000-0000-0000-0000-000000000002';
const c='00000000-0000-0000-0000-000000000003';
await db.exec(`insert into auth.users values('${a}'),('${b}'),('${c}');
insert into public.user_profiles(id,invite_code) values('${a}','AAAAAA'),('${b}','BBBBBB'),('${c}','CCCCCC');`);
for(const item of JSON.parse(fs.readFileSync('docs/play-console/invite-before-20261103.json','utf8'))) await db.exec(item.definition);
const before=(await db.query('select * from public.user_profiles order by id')).rows;
const files=fs.readdirSync('supabase/migrations').filter(x=>x.endsWith('_private_invite_attempt_limits.sql'));
assert.equal(files.length,1);
await db.exec(fs.readFileSync(`supabase/migrations/${files[0]}`,'utf8'));
assert.deepEqual((await db.query('select * from public.user_profiles order by id')).rows,before);
let checks=1;
async function identity(uid){await db.exec(`reset role;set request.jwt.claim.sub='${uid}';set role authenticated;`);}
async function link(code,type='pareja'){
  return (await db.query('select public.link_partner_by_invite_code($1,null,$2) as result',[code,type])).rows[0].result;
}
async function expectResult(code,result,type){assert.equal(await link(code,type),result);checks++;}
async function fails(sql){await assert.rejects(db.query(sql));checks++;}
await identity('');await expectResult('BBBBBB','not_authenticated');
await db.exec('reset role;set role anon');await fails("select public.link_partner_by_invite_code('BBBBBB')");
await identity(a);
await fails('select * from nido_private.invite_attempt_limits');
await fails('select nido_private.take_invite_attempt()');
await expectResult('BBBBBB','invalid_connection_type','invalid');
for(let i=0;i<5;i++) await expectResult('NOPE','not_found');
await expectResult('BBBBBB','rate_limited');
await db.exec('reset role');
assert.deepEqual((await db.query('select * from public.user_profiles order by id')).rows,before);checks++;
// A new caller has an independent quota. Self-links do not mutate a profile.
await identity(c);await expectResult('CCCCCC','self');
await db.exec(`reset role; update nido_private.invite_attempt_limits set minute_started=now()-interval '61 seconds' where user_id='${a}';`);
await identity(a);await expectResult(' bbbbbb ','linked');
await db.exec('reset role');
const linked=(await db.query('select id,partner_id from public.user_profiles order by id')).rows;
assert.equal(linked[0].partner_id,b);assert.equal(linked[1].partner_id,a);assert.equal(linked[2].partner_id,null);checks++;
await identity(a);await expectResult('CCCCCC','caller_already_linked');
await identity(c);await expectResult('BBBBBB','target_already_linked');
// Daily budget survives minute resets and rejected requests cannot overflow it.
await db.exec(`reset role; update public.user_profiles set partner_id=null;
update nido_private.invite_attempt_limits set minute_started=now()-interval '61 seconds',minute_count=5,day_count=19 where user_id='${a}';`);
await identity(a);await expectResult('NOPE','not_found');await expectResult('BBBBBB','rate_limited');
await db.exec(`reset role; update nido_private.invite_attempt_limits set minute_started=now()-interval '61 seconds' where user_id='${a}';`);
await identity(a);await expectResult('BBBBBB','rate_limited');
await db.exec(`reset role;update nido_private.invite_attempt_limits set day_started=now()-interval '25 hours',minute_started=now()-interval '61 seconds' where user_id='${a}';`);
await identity(a);await expectResult('BBBBBB','linked');
// Multiple calls in one statement consume atomic per-user counters too.
await db.exec(`reset role;update public.user_profiles set partner_id=null;delete from nido_private.invite_attempt_limits where user_id='${a}';`);
await identity(a);
const batch=(await db.query("select public.link_partner_by_invite_code('NOPE') as result from generate_series(1,12)")).rows;
assert.equal(batch.filter(x=>x.result==='not_found').length,5);
assert.equal(batch.filter(x=>x.result==='rate_limited').length,7);checks++;
await db.exec('reset role');
const acl=(await db.query(`select has_function_privilege('anon','public.link_partner_by_invite_code(text,date,text)','execute') as anon,
has_function_privilege('authenticated','public.link_partner_by_invite_code(text,date,text)','execute') as auth,
has_table_privilege('authenticated','nido_private.invite_attempt_limits','select') as counter_read,
(select relrowsecurity from pg_class where oid='nido_private.invite_attempt_limits'::regclass) as rls`)).rows[0];
assert.deepEqual(acl,{anon:false,auth:true,counter_read:false,rls:true});checks++;
// The only stored metadata is a bounded per-user pair of counters/windows.
const columns=(await db.query("select column_name from information_schema.columns where table_schema='nido_private' and table_name='invite_attempt_limits' order by ordinal_position")).rows.map(x=>x.column_name);
assert.deepEqual(columns,['user_id','minute_started','minute_count','day_started','day_count']);checks++;
await db.exec(`delete from auth.users where id='${c}'`);
assert.equal((await db.query('select count(*)::integer as n from nido_private.invite_attempt_limits where user_id=$1',[c])).rows[0].n,0);checks++;
await db.close();console.log(`PASS: ${checks} isolated invite scenarios; no live account linked or changed.`);
