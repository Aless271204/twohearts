begin;

alter table public.runner_sessions add column checkpoint_state jsonb;
alter table public.runner_sessions add column checkpoint_index integer not null default 0;
alter table public.runner_sessions add column checkpoint_result jsonb;

-- Keep the old validated endpoint; only remove the old 20-minute score ceiling.
do $$ declare definition text; begin
 select pg_get_functiondef('public.runner_finish_session(uuid,uuid,integer,integer,double precision)'::regprocedure) into definition;
 if position('p_distance > 18000' in definition)=0 or position('p_elapsed > 1200' in definition)=0 then raise exception 'Unexpected runner function'; end if;
 definition:=replace(definition,' or p_distance > 18000','');
 definition:=replace(definition,' or p_elapsed > 1200','');
 definition:=replace(definition,'p_distance*6/28+12','p_distance::bigint*6/18+12');
 execute definition;
end $$;

create function public.runner_save_checkpoint(p_user_id uuid,p_session_id uuid,p_index integer,p_state jsonb,p_terminal boolean)
returns jsonb language plpgsql security invoker set search_path='' as $$
declare r public.runner_sessions%rowtype; result jsonb; d integer; c integer; t double precision;
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
  result:=public.runner_finish_session(p_user_id,p_session_id,d,c,t);
 else
  insert into public.game_records(user_id,game_id,best_score,best_coins,times_played)
   values(p_user_id,'pebble_runner',d,c,0)
   on conflict(user_id,game_id) do update set best_score=greatest(public.game_records.best_score,excluded.best_score),best_coins=greatest(public.game_records.best_coins,excluded.best_coins),updated_at=clock_timestamp();
  result:=jsonb_build_object('checkpoint',p_index,'distance',d,'best_distance',(select best_score from public.game_records where user_id=p_user_id and game_id='pebble_runner'));
 end if;
 update public.runner_sessions set checkpoint_state=p_state,checkpoint_index=p_index,checkpoint_result=result where id=p_session_id;
 return result;
end $$;
revoke all on function public.runner_save_checkpoint(uuid,uuid,integer,jsonb,boolean) from public,anon,authenticated;
grant execute on function public.runner_save_checkpoint(uuid,uuid,integer,jsonb,boolean) to service_role;

create schema if not exists nido_private;
revoke all on schema nido_private from public,anon;
grant usage on schema nido_private to authenticated;
create function nido_private.pet_members() returns uuid[] language plpgsql stable security definer set search_path='' as $$
declare u uuid:=auth.uid(); p uuid;
begin
 if u is null then raise exception 'Inicia sesión' using errcode='42501'; end if;
 select a.partner_id into p from public.user_profiles a join public.user_profiles b on b.id=a.partner_id and b.partner_id=a.id where a.id=u;
 if p is null then return array[u]; end if;
 return array(select member from unnest(array[u,p]) member order by member);
end $$;
revoke all on function nido_private.pet_members() from public,anon;
grant execute on function nido_private.pet_members() to authenticated;

create table public.shared_pets (
 pair_key text primary key,members uuid[] not null,name text not null default 'Pip' check(char_length(name) between 1 and 24),
 hunger integer not null default 80 check(hunger between 0 and 100),energy integer not null default 80 check(energy between 0 and 100),joy integer not null default 80 check(joy between 0 and 100),
 care_points integer not null default 0,contributions jsonb not null default '{}',last_actions jsonb not null default '{}',
 updated_at timestamptz not null default now(),check(cardinality(members) between 1 and 2)
);
create table public.shared_pet_equipment (
 pair_key text references public.shared_pets(pair_key) on delete cascade,slot text not null,item_key text not null references public.shop_items(item_key),owner_id uuid not null references public.user_profiles(id),
 primary key(pair_key,slot)
);
create table public.pet_messages (
 id uuid primary key default gen_random_uuid(),sender_id uuid not null references public.user_profiles(id) on delete cascade,recipient_id uuid not null references public.user_profiles(id) on delete cascade,
 content text not null check(char_length(content) between 1 and 500),plays integer not null default 0 check(plays between 0 and 4),created_at timestamptz not null default now(),check(sender_id<>recipient_id)
);
create index pet_messages_recipient on public.pet_messages(recipient_id,created_at desc);
create index pet_messages_sender on public.pet_messages(sender_id,created_at desc);
alter table public.shared_pets enable row level security;
alter table public.shared_pet_equipment enable row level security;
alter table public.pet_messages enable row level security;
-- All state and message content is accessed through checked RPCs, never raw writes.
revoke all on public.shared_pets,public.shared_pet_equipment,public.pet_messages from public,anon,authenticated;
grant all on public.shared_pets,public.shared_pet_equipment,public.pet_messages to service_role;

create function nido_private.pet_snapshot() returns jsonb language plpgsql security definer set search_path='' as $$
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
 return (to_jsonb(r)-'last_actions')||jsonb_build_object('level',1+r.care_points/20,'equipment',
  (select coalesce(jsonb_agg(to_jsonb(s)),'[]'::jsonb) from public.shared_pet_equipment e join public.shop_items s on s.item_key=e.item_key where e.pair_key=k));
end $$;
create function public.shared_pet_snapshot() returns jsonb language sql security invoker set search_path='' as $$ select nido_private.pet_snapshot(); $$;

create function nido_private.pet_care(p_action text) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); snapshot jsonb; k text; r public.shared_pets%rowtype; action_key text; last_time timestamptz;
begin
 if p_action is null or p_action not in ('feed','rest','play','stroke') then raise exception 'Cuidado no válido'; end if;
 snapshot:=nido_private.pet_snapshot();k:=snapshot->>'pair_key';
 select * into r from public.shared_pets where pair_key=k for update;
 action_key:=u::text||'_'||p_action;last_time:=(r.last_actions->>action_key)::timestamptz;
 if last_time>now()-interval '30 seconds' then raise exception 'Espera unos segundos antes de repetir este cuidado'; end if;
 update public.shared_pets set hunger=least(100,hunger+case when p_action='feed' then 15 else 0 end),energy=greatest(0,least(100,energy+case when p_action='rest' then 15 when p_action='play' then -3 else 0 end)),
 joy=least(100,joy+case when p_action in ('play','stroke') then 10 else 3 end),care_points=care_points+1,
 contributions=jsonb_set(contributions,array[u::text],to_jsonb(coalesce((contributions->>u::text)::integer,0)+1)),
 last_actions=jsonb_set(last_actions,array[action_key],to_jsonb(now())) where pair_key=k;
 return nido_private.pet_snapshot();
end $$;
create function public.shared_pet_care(p_action text) returns jsonb language sql security invoker set search_path='' as $$select nido_private.pet_care(p_action);$$;

create function nido_private.pet_equip(p_item_key text,p_equipped boolean) returns void language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); snapshot jsonb; k text; slot_name text;
begin
 snapshot:=nido_private.pet_snapshot();k:=snapshot->>'pair_key';
 select s.equip_slot into slot_name from public.shop_items s join public.owned_items o on o.item_key=s.item_key and o.user_id=u where s.item_key=p_item_key and s.active and s.scope in ('pet','room');
 if slot_name is null then raise exception 'Debes adquirir este objeto para usarlo en vuestro nido'; end if;
 if p_equipped then insert into public.shared_pet_equipment(pair_key,slot,item_key,owner_id) values(k,slot_name,p_item_key,u) on conflict(pair_key,slot) do update set item_key=excluded.item_key,owner_id=excluded.owner_id;
 else delete from public.shared_pet_equipment where pair_key=k and slot=slot_name and item_key=p_item_key; end if;
end $$;
create function public.shared_pet_equip(p_item_key text,p_equipped boolean default true) returns void language sql security invoker set search_path='' as $$select nido_private.pet_equip(p_item_key,p_equipped);$$;

create function nido_private.message_send(p_content text) returns uuid language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); m uuid[]:=nido_private.pet_members(); p uuid; result uuid;
begin
 select member into p from unnest(m) member where member<>u;
 if p is null then raise exception 'Vincula a tu pareja para enviar mensajes'; end if;
 if char_length(btrim(p_content)) not between 1 and 500 then raise exception 'Mensaje de 1 a 500 caracteres'; end if;
 perform pg_advisory_xact_lock(hashtextextended(u::text,832));
 if (select count(*) from public.pet_messages where sender_id=u and created_at>now()-interval '1 day')>=30 then raise exception 'Límite diario de mensajes'; end if;
 if (select count(*) from public.pet_messages where sender_id=u)>=50 then raise exception 'Tu pareja tiene muchos mensajes pendientes'; end if;
 insert into public.pet_messages(sender_id,recipient_id,content) values(u,p,btrim(p_content)) returning id into result;return result;
end $$;
create function public.pet_message_send(p_content text) returns uuid language sql security invoker set search_path='' as $$select nido_private.message_send(p_content);$$;

create function nido_private.message_list() returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); m uuid[]:=nido_private.pet_members();
begin
 return (select coalesce(jsonb_agg(jsonb_build_object('id',id,'created_at',created_at,'remaining',5-plays) order by created_at desc),'[]'::jsonb) from public.pet_messages where recipient_id=u and sender_id=any(m));
end $$;
create function public.pet_message_list() returns jsonb language sql security invoker set search_path='' as $$select nido_private.message_list();$$;

create function nido_private.message_play(p_id uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); m uuid[]:=nido_private.pet_members(); r public.pet_messages%rowtype;
begin
 select * into r from public.pet_messages where id=p_id and recipient_id=u and sender_id=any(m) for update;
 if not found then raise exception 'Mensaje no disponible'; end if;
 if r.plays=4 then delete from public.pet_messages where id=p_id;else update public.pet_messages set plays=plays+1 where id=p_id;end if;
 return jsonb_build_object('content',r.content,'remaining',4-r.plays);
end $$;
create function public.pet_message_play(p_id uuid) returns jsonb language sql security invoker set search_path='' as $$select nido_private.message_play(p_id);$$;

revoke all on all functions in schema nido_private from public,anon;
grant execute on all functions in schema nido_private to authenticated;
revoke all on function public.shared_pet_snapshot(),public.shared_pet_care(text),public.shared_pet_equip(text,boolean),public.pet_message_send(text),public.pet_message_list(),public.pet_message_play(uuid) from public,anon;
grant execute on function public.shared_pet_snapshot(),public.shared_pet_care(text),public.shared_pet_equip(text,boolean),public.pet_message_send(text),public.pet_message_list(),public.pet_message_play(uuid) to authenticated;
commit;
