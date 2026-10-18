import json
from pathlib import Path
r=Path(__file__).resolve().parents[1]
defs=json.loads((r/'outputs/feature-schema-functions.json').read_text())
step=next(d['definition'] for d in defs if d['proname']=='duo_pong_step')
step=step.replace('step_dt double precision;',"""step_dt double precision;
 clock double precision:=coalesce((st->>'power_clock')::float8,0);
 wide_a double precision:=greatest(0,coalesce((st->>'wide_a')::float8,0)-least(greatest(dt,0),.25));
 wide_b double precision:=greatest(0,coalesce((st->>'wide_b')::float8,0)-least(greatest(dt,0),.25));
 shield_a boolean:=coalesce((st->>'shield_a')::boolean,false);shield_b boolean:=coalesce((st->>'shield_b')::boolean,false);
 enabled boolean:=coalesce((st->>'powerups_enabled')::boolean,false);
 power_n integer:=coalesce((st->>'power_n')::integer,0);kind integer:=coalesce((st->>'power_kind')::integer,0);
 power_x double precision:=coalesce((st->>'power_x')::float8,.5);last_hit text:=st->>'last_hit';
""")
step=step.replace('for i in 1..steps loop',"""clock:=clock+least(greatest(dt,0),.25);
 if enabled and floor(clock/8)>power_n then power_n:=floor(clock/8);kind:=1+(power_n%2);power_x:=.5+sin(power_n*2.399)*.25;end if;
 if clock-power_n*8>5 then kind:=0;end if;
 for i in 1..steps loop""")
step=step.replace('if abs(hit)<=0.135 then y:=1.8-y;',"if abs(hit)<=(case when enabled and wide_a>0 then .195 else .135 end) then last_hit:='a';y:=1.8-y;")
step=step.replace('if abs(hit)<=0.135 then y:=0.2-y;',"if abs(hit)<=(case when enabled and wide_b>0 then .195 else .135 end) then last_hit:='b';y:=0.2-y;")
step=step.replace('if y>1.05 then',"""if enabled and kind>0 and last_hit in ('a','b') and abs(x-power_x)<.055 and abs(y-.5)<.055 then
   if kind=1 then if last_hit='a' then wide_a:=6;else wide_b:=6;end if;
   else if last_hit='a' then shield_a:=true;else shield_b:=true;end if;end if;kind:=0;
  end if;
  if enabled and y>.98 and shield_a then y:=.98;vy:=-abs(vy);shield_a:=false;
  elsif enabled and y<.02 and shield_b then y:=.02;vy:=abs(vy);shield_b:=false;end if;
  if y>1.05 then""")
step=step.replace("'score_b',sb)","'score_b',sb,'power_clock',clock,'power_n',power_n,'power_kind',kind,'power_x',power_x,'last_hit',last_hit,'wide_a',wide_a,'wide_b',wide_b,'shield_a',shield_a,'shield_b',shield_b)")
tick=next(d['definition'] for d in defs if d['proname']=='duo_tick')
tick=tick.replace("st:=m.state;phase:=", """st:=m.state;
 if m.game='pong' and p_phase='powerups-v1' then
  st:=st||jsonb_build_object(case when u=m.player_a then 'power_client_a' else 'power_client_b' end,true);
  if st->>'power_client_a'='true' and st->>'power_client_b'='true' then st:=st||'{"powerups_enabled":true}'::jsonb;end if;
 end if;
 phase:=""")
target=sorted((r/'supabase/migrations').glob('*pong_powerups_and_paired_adoption.sql'))[-1]
snapshot=next(d['definition'] for d in defs if d['nspname']=='nido_private' and d['proname']=='pet_family_snapshot')
snapshot=snapshot.replace('days integer;','days integer;m uuid[];')
snapshot=snapshot.replace("base:=nido_private.pet_snapshot();", """m:=nido_private.pet_members();
 if cardinality(m)<2 then return jsonb_build_object('members',to_jsonb(m),'pets','[]'::jsonb,'selection_confirmed',false,'adoption_required',true,'paired',false);end if;
 base:=nido_private.pet_snapshot();""")
snapshot=snapshot.replace("if not exists(select 1 from public.shared_pet_animals where pair_key=k) then", """if not r.selection_confirmed then return base||jsonb_build_object('pets','[]'::jsonb,'selection_confirmed',false,'adoption_required',true,'paired',true);end if;
 if not exists(select 1 from public.shared_pet_animals where pair_key=k) then""")
snapshot=snapshot.replace("'selection_confirmed',r.selection_confirmed)", "'selection_confirmed',r.selection_confirmed,'adoption_required',false,'arrival_pending',r.arrival_revision>0 and not exists(select 1 from nido_private.pet_arrival_receipts a where a.pair_key=k and a.user_id=auth.uid() and a.revision=r.arrival_revision))")
wallet=(r/'supabase/migrations/20261017225009_shared_wallet_game_rewards_and_mystery_art.sql').read_text(encoding='utf-8')
change=wallet[wallet.index('CREATE OR REPLACE FUNCTION nido_private.pet_family_change'):wallet.index('alter table nido_private.guardian_rooms')]
change=change.replace("perform nido_private.wallet_lock(auth.uid());", "if cardinality(nido_private.pet_members())<>2 then raise exception 'Enlaza primero las cuentas para adoptar juntos';end if;\n perform nido_private.wallet_lock(auth.uid());")
change=change.replace("update public.shared_pets set active_species=p_species,name=btrim(p_name),selection_confirmed=true where pair_key=k;", """insert into public.shared_pet_animals(pair_key,species,name) values(k,p_species,btrim(p_name)) on conflict(pair_key,species) do update set name=excluded.name;
  update public.shared_pets set active_species=p_species,name=btrim(p_name),selection_confirmed=true,arrival_revision=arrival_revision+1 where pair_key=k;""")
adoption="""
alter table public.shared_pets add column if not exists arrival_revision integer not null default 0;
create table if not exists nido_private.pet_arrival_receipts(pair_key text not null,user_id uuid not null,revision integer not null,primary key(pair_key,user_id,revision));
alter table nido_private.pet_arrival_receipts enable row level security;
revoke all on nido_private.pet_arrival_receipts from public,anon,authenticated;
create or replace function public.pet_arrival_ack() returns void language plpgsql security definer set search_path='' as $$
declare m uuid[];k text;r public.shared_pets;
begin
 if auth.uid() is null then raise exception 'Inicia sesión';end if;
 m:=nido_private.pet_members();k:=array_to_string(m,':');
 select * into r from public.shared_pets where pair_key=k and selection_confirmed;
 if r.pair_key is null then raise exception 'Adopten primero su mascota';end if;
 insert into nido_private.pet_arrival_receipts values(k,auth.uid(),r.arrival_revision) on conflict do nothing;
end $$;
revoke all on function public.pet_arrival_ack() from public,anon;
grant execute on function public.pet_arrival_ack() to authenticated;
"""
target.write_text(step.rstrip()+';\n'+tick.rstrip()+';\n'+adoption+snapshot.rstrip()+';\n'+change,encoding='utf-8')
print(target.name)
