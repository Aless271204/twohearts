import fs from 'node:fs';
import assert from 'node:assert/strict';
import {PGlite} from '../tools/sql-test/package/dist/index.js';
const db=new PGlite();await db.waitReady;
await db.exec(`create role anon;create role authenticated;create schema auth;create schema nido_private;create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
grant usage on schema nido_private,auth to authenticated;
create function nido_private.pet_family_snapshot() returns jsonb language sql as $$select '{"species":"penguin","pets":[{"species":"penguin"},{"species":"bear"}]}'::jsonb$$;
create function public.shared_pet_snapshot() returns jsonb language sql as $$select '{"equipment":[]}'::jsonb$$;`);
const original=fs.readFileSync('supabase/migrations/20261016121308_guardian_online_rooms.sql','utf8');
await db.exec(original.slice(0,original.indexOf('create function nido_private.guardian_room')));
await db.exec(`alter table nido_private.guardian_rooms add column engine_version integer default 6, add column host_loadout jsonb default '[]',add column guest_loadout jsonb default '[]';create table nido_private.guardian_clothing_prizes(room_id uuid primary key references nido_private.guardian_rooms(id),item_key text);`);
await db.exec(fs.readFileSync('test/fixtures/guardian-room-before-progress.sql','utf8'));
await db.exec(fs.readFileSync('design/guardian-progress/change.sql','utf8'));
await db.exec(`create function public.guardian_room(p_action text,p_id uuid default null,p_code text default null,p_difficulty text default 'easy',p_species text default 'penguin',p_packets jsonb default '{}') returns jsonb language sql as $$select nido_private.guardian_room(p_action,p_id,p_code,p_difficulty,p_species,p_packets)$$;grant execute on function nido_private.guardian_room(text,uuid,text,text,text,jsonb) to authenticated;`);
const a='00000000-0000-4000-8000-000000000001',b='00000000-0000-4000-8000-000000000002',c='00000000-0000-4000-8000-000000000003';
await db.query('insert into auth.users values($1),($2),($3)',[a,b,c]);
async function user(id){await db.exec('reset role');await db.query("select set_config('request.jwt.claim.sub',$1,false)",[id]);await db.exec('set role authenticated');}
async function call(action,chapter='forest',code=null){return(await db.query('select public.guardian_room($1,null,$2,\'hard\',\'penguin\',$3::jsonb) result',[action,code,JSON.stringify({chapter,engine_version:7})])).rows[0].result;}
await user(a);assert.deepEqual((await call('profile')).unlocked_chapters,['forest']);
assert.equal((await call('create')).engine_version,6,'Forest with modern engine must remain available');
await assert.rejects(call('solo','river'),/Desbloquea/);await assert.rejects(call('create','river'),/Desbloquea/);
await assert.rejects(db.query('select nido_private.guardian_river_unlocked($1)',[a]),/permission denied/);
async function receipt({mode='partner',difficulty='hard',status='finished',version=6,prize=true}={}){await db.exec('reset role');const id=(await db.query("insert into nido_private.guardian_rooms(code,host_id,guest_id,mode,difficulty,seed,host_species,status,engine_version) values(substr(gen_random_uuid()::text,1,8),$1,$2,$3,$4,1,'penguin',$5,$6) returning id",[a,mode==='partner'?b:null,mode,difficulty,status,version])).rows[0].id;if(prize)await db.query('insert into nido_private.guardian_clothing_prizes values($1,null)',[id]);}
for(const variant of [{mode:'solo'},{difficulty:'easy'},{difficulty:'medium'},{status:'cancelled'},{version:7},{prize:false}]){await receipt(variant);await user(a);assert.deepEqual((await call('profile')).unlocked_chapters,['forest']);}
await receipt();await user(a);assert.deepEqual((await call('profile')).unlocked_chapters,['forest','river']);const river=await call('create','river');assert.equal(river.engine_version,7);
await user(c);await assert.rejects(call('join','forest',river.code),/Desbloquea/);assert.deepEqual((await call('profile')).unlocked_chapters,['forest']);
await user(b);assert.deepEqual((await call('profile')).unlocked_chapters,['forest','river']);assert.equal((await call('join','forest',river.code)).joined,true);
await db.exec('reset role');await db.exec('set role anon');await assert.rejects(call('profile'),/permission denied/);
await db.close();console.log('GUARDIAN_PROGRESS_PASS: verified hard couple forest receipt unlocks both accounts; solo, easy, medium, defeat/no receipt, river wins and outsiders do not; create/join protected; existing receipts count.');
