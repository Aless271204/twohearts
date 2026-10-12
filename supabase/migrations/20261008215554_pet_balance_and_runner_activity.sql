begin;
alter table public.runner_sessions add column checkpoint_saved_at timestamptz;
do $$declare definition text;begin
select pg_get_functiondef('public.runner_finish_session(uuid,uuid,integer,integer,double precision)'::regprocedure) into definition;
definition:=replace(definition,'clock_timestamp()-v_run.started_at > interval', 'clock_timestamp()-coalesce(v_run.checkpoint_saved_at,v_run.started_at) > interval');
execute definition;
end $$;
create or replace function public.runner_save_checkpoint(p_user_id uuid,p_session_id uuid,p_index integer,p_state jsonb,p_terminal boolean)
returns jsonb language plpgsql security invoker set search_path='' as $$
declare r public.runner_sessions%rowtype; v_checkpoint_result jsonb; d integer; c integer; t double precision;
begin
 select * into r from public.runner_sessions where id=p_session_id and user_id=p_user_id for update;
 if not found then raise exception 'Run not owned'; end if;
 if p_index=r.checkpoint_index then return r.checkpoint_result; end if;
 if r.status<>'started' or p_index<>r.checkpoint_index+1 then raise exception 'Checkpoint out of order'; end if;
 d:=floor((p_state->>'distance')::double precision);c:=(p_state->>'coins')::integer;t:=(p_state->>'elapsed')::double precision;
 if d is null or c is null or t is null or d<0 or c<0 or t<0 or t='NaN'::double precision or
   t>extract(epoch from clock_timestamp()-r.started_at)+2 or d>t*14+2 or
   t-coalesce((r.checkpoint_state->>'elapsed')::double precision,0)>180.1 or
   t<coalesce((r.checkpoint_state->>'elapsed')::double precision,0) then raise exception 'Invalid checkpoint timing'; end if;
 if p_terminal then
  v_checkpoint_result:=public.runner_finish_session(p_user_id,p_session_id,d,c,t);
 else
  insert into public.game_records(user_id,game_id,best_score,best_coins,times_played)
   values(p_user_id,'pebble_runner',d,c,0)
   on conflict(user_id,game_id) do update set best_score=greatest(public.game_records.best_score,excluded.best_score),best_coins=greatest(public.game_records.best_coins,excluded.best_coins),updated_at=clock_timestamp();
  v_checkpoint_result:=jsonb_build_object('checkpoint',p_index,'distance',d,'best_distance',(select best_score from public.game_records where user_id=p_user_id and game_id='pebble_runner'));
 end if;
 update public.runner_sessions set checkpoint_state=p_state,checkpoint_index=p_index,checkpoint_result=v_checkpoint_result,checkpoint_saved_at=clock_timestamp() where id=p_session_id;
 return v_checkpoint_result;
end $$;

create or replace function nido_private.pet_snapshot() returns jsonb language plpgsql security definer set search_path='' as $$
declare m uuid[]:=nido_private.pet_members(); k text:=array_to_string(m,':'); r public.shared_pets%rowtype; hours integer; created integer;
begin
 insert into public.shared_pets(pair_key,members) values(k,m) on conflict do nothing;
 get diagnostics created=row_count;
 if created>0 then
  insert into public.shared_pet_equipment(pair_key,slot,item_key,owner_id)
  select distinct on (s.equip_slot) k,s.equip_slot,s.item_key,o.user_id from public.owned_items o join public.shop_items s on s.item_key=o.item_key
  where o.user_id=any(m) and o.equipped and s.scope in ('pet','room') and s.active order by s.equip_slot,o.user_id;
 end if;
 select * into r from public.shared_pets where pair_key=k for update;
 hours:=greatest(0,floor(extract(epoch from now()-r.updated_at)/3600));
 if hours>0 then update public.shared_pets set hunger=greatest(0,hunger-least(hours,100)*4),energy=greatest(0,energy-least(hours,100)*2),joy=greatest(0,joy-least(hours,100)*3),updated_at=updated_at+hours*interval '1 hour' where pair_key=k returning * into r; end if;
 return (to_jsonb(r)-'last_actions')||jsonb_build_object('level',case when cardinality(m)=2 then 1+least(coalesce((r.contributions->>m[1]::text)::integer,0),coalesce((r.contributions->>m[2]::text)::integer,0))/10 else 1+r.care_points/20 end,'equipment',
  (select coalesce(jsonb_agg(to_jsonb(s)),'[]'::jsonb) from public.shared_pet_equipment e join public.shop_items s on s.item_key=e.item_key where e.pair_key=k));
end $$;

commit;
