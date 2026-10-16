grant usage on schema nido_private to authenticated;
-- Guardianes: private two-phone rooms, authenticated input provenance and payouts.
create table nido_private.guardian_rooms (
 id uuid primary key default gen_random_uuid(), code text not null unique,
 host_id uuid not null references auth.users(id) on delete cascade,
 guest_id uuid references auth.users(id) on delete cascade,
 mode text not null check(mode in ('solo','partner')),
 difficulty text not null check(difficulty in ('easy','medium','hard')),
 seed bigint not null check(seed between 0 and 4294967295),
 host_species text not null, guest_species text,
 status text not null default 'waiting' check(status in ('waiting','running','finished','cancelled')),
 host_ready boolean not null default false, guest_ready boolean not null default false,
 created_at timestamptz not null default now(), started_at timestamptz, finished_at timestamptz,
 confirmed_hash text, replay_hash text, reward integer, frames integer,
 check(guest_id is null or host_id<>guest_id)
);
create index guardian_host_created on nido_private.guardian_rooms(host_id,created_at desc);
create table nido_private.guardian_inputs (
 room_id uuid not null references nido_private.guardian_rooms(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 seq integer not null check(seq between 1 and 12000), mask integer not null check(mask between 0 and 63),
 primary key(room_id,user_id,seq)
);
create table nido_private.guardian_rewards (
 room_id uuid not null references nido_private.guardian_rooms(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 amount integer not null check(amount between 0 and 60), created_at timestamptz not null default now(),
 primary key(room_id,user_id)
);
create index guardian_rewards_daily on nido_private.guardian_rewards(user_id,created_at);
create table nido_private.guardian_join_limits(user_id uuid primary key references auth.users(id) on delete cascade, bucket timestamptz not null, attempts integer not null default 0);
alter table nido_private.guardian_rooms enable row level security;
alter table nido_private.guardian_inputs enable row level security;
alter table nido_private.guardian_rewards enable row level security;
alter table nido_private.guardian_join_limits enable row level security;
revoke all on nido_private.guardian_rooms,nido_private.guardian_inputs,nido_private.guardian_rewards,nido_private.guardian_join_limits from public,anon,authenticated;

create function nido_private.guardian_room(p_action text,p_id uuid,p_code text,p_difficulty text,p_species text,p_packets jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); r nido_private.guardian_rooms; item jsonb; n integer; oldmask integer; hash text;
begin
 if u is null then raise exception 'Inicia sesión para jugar'; end if;
 if p_action in ('create','solo','join') and p_species not in ('penguin','bear','pig','chick') then raise exception 'Mascota inválida'; end if;
 if p_action in ('create','solo') then
  if p_difficulty not in ('easy','medium','hard') then raise exception 'Dificultad inválida'; end if;
  perform pg_advisory_xact_lock(hashtextextended('guardian-create:'||u::text,0));
  if (select count(*) from nido_private.guardian_rooms where host_id=u and created_at>now()-interval '10 minutes')>=15 then raise exception 'Espera un momento antes de crear otra sala'; end if;
  insert into nido_private.guardian_rooms(code,host_id,mode,difficulty,seed,host_species,status,started_at,host_ready)
  values(upper(substr(replace(gen_random_uuid()::text,'-',''),1,8)),u,case when p_action='solo' then 'solo' else 'partner' end,p_difficulty,floor(random()*4294967295)::bigint,p_species,case when p_action='solo' then 'running' else 'waiting' end,case when p_action='solo' then now() else null end,p_action='solo') returning * into r;
 elsif p_action='join' then
  insert into nido_private.guardian_join_limits values(u,date_trunc('minute',now()),1) on conflict(user_id) do update set
   attempts=case when guardian_join_limits.bucket=date_trunc('minute',now()) then guardian_join_limits.attempts+1 else 1 end,bucket=date_trunc('minute',now()) returning attempts into n;
  if n>20 then return jsonb_build_object('error','Demasiados intentos; espera un minuto'); end if;
  select * into r from nido_private.guardian_rooms where code=upper(trim(p_code)) and mode='partner' and status='waiting' and created_at>now()-interval '15 minutes' for update;
  if r.id is null or r.host_id=u or (r.guest_id is not null and r.guest_id<>u) then return jsonb_build_object('error','La sala no está disponible'); end if;
  update nido_private.guardian_rooms set guest_id=u,guest_species=p_species where id=r.id returning * into r;
 else
  select * into r from nido_private.guardian_rooms where id=p_id and (host_id=u or guest_id=u) for update;
  if r.id is null then raise exception 'Sala no disponible'; end if;
  if r.created_at<now()-interval '30 minutes' and p_action<>'status' then raise exception 'La sala ha caducado'; end if;
  if p_action='ready' then
   if r.status<>'waiting' then return jsonb_build_object('status',r.status); end if;
   update nido_private.guardian_rooms set host_ready=host_ready or host_id=u,guest_ready=guest_ready or guest_id=u where id=r.id returning * into r;
   if r.host_ready and r.guest_ready then update nido_private.guardian_rooms set status='running',started_at=now()+interval '3 seconds' where id=r.id returning * into r; end if;
  elsif p_action='inputs' then
   if r.status not in ('running','finished') or jsonb_typeof(p_packets)<>'array' or jsonb_array_length(p_packets)>128 then raise exception 'Entradas inválidas'; end if;
   for item in select value from jsonb_array_elements(p_packets) loop
    if jsonb_typeof(item)<>'array' or jsonb_array_length(item)<>2 or (item->>0)!~'^[0-9]{1,5}$' or (item->>1)!~'^[0-9]{1,2}$' then raise exception 'Entrada inválida'; end if;
    select mask into oldmask from nido_private.guardian_inputs where room_id=r.id and user_id=u and seq=(item->>0)::int;
    if found and oldmask<>(item->>1)::int then raise exception 'La entrada ya está registrada'; end if;
    insert into nido_private.guardian_inputs values(r.id,u,(item->>0)::int,(item->>1)::int) on conflict do nothing;
   end loop;
  elsif p_action='confirm' then
   hash:=p_packets->>'hash';
   if r.guest_id<>u or r.mode<>'partner' or r.status<>'running' or hash is null or hash!~'^[a-f0-9]{64}$' then raise exception 'Confirmación inválida'; end if;
   if r.confirmed_hash is not null and r.confirmed_hash<>hash then raise exception 'La confirmación no coincide'; end if;
   update nido_private.guardian_rooms set confirmed_hash=hash where id=r.id returning * into r;
  elsif p_action='cancel' then
   update nido_private.guardian_rooms set status='cancelled' where id=r.id and status in ('waiting','running') returning * into r;
  elsif p_action<>'status' then raise exception 'Acción inválida'; end if;
 end if;
 return jsonb_build_object('id',r.id,'code',r.code,'mode',r.mode,'difficulty',r.difficulty,'seed',r.seed,'role',case when r.host_id=u then 0 else 1 end,'species',jsonb_build_array(r.host_species,coalesce(r.guest_species,'bear')),'joined',r.guest_id is not null,'status',r.status,'started_at',r.started_at,'server_time',now(),'confirmed',r.confirmed_hash is not null,'reward',(select amount from nido_private.guardian_rewards where room_id=r.id and user_id=u));
end $$;
revoke all on function nido_private.guardian_room(text,uuid,text,text,text,jsonb) from public,anon;
grant execute on function nido_private.guardian_room(text,uuid,text,text,text,jsonb) to authenticated;
create function public.guardian_room(p_action text,p_id uuid default null,p_code text default null,p_difficulty text default 'easy',p_species text default 'penguin',p_packets jsonb default '[]') returns jsonb language sql security invoker set search_path='' as $$select nido_private.guardian_room(p_action,p_id,p_code,p_difficulty,p_species,p_packets)$$;
revoke all on function public.guardian_room(text,uuid,text,text,text,jsonb) from public,anon;
grant execute on function public.guardian_room(text,uuid,text,text,text,jsonb) to authenticated;

create function nido_private.guardian_channel(p_topic text,p_send boolean) returns boolean language plpgsql stable security definer set search_path='' as $$
declare r nido_private.guardian_rooms; parts text[];
begin
 if auth.uid() is null or p_topic!~'^guardian:[a-f0-9-]{36}:(host|guest)$' then return false; end if;
 parts:=string_to_array(p_topic,':');
 select * into r from nido_private.guardian_rooms where id=parts[2]::uuid and (host_id=auth.uid() or guest_id=auth.uid()) and status<>'cancelled' and created_at>now()-interval '30 minutes';
 if r.id is null then return false; end if;
 return not p_send or (parts[3]='host' and r.host_id=auth.uid()) or (parts[3]='guest' and r.guest_id=auth.uid());
exception when invalid_text_representation then return false;
end $$;
revoke all on function nido_private.guardian_channel(text,boolean) from public,anon;
grant execute on function nido_private.guardian_channel(text,boolean) to authenticated;
create policy guardian_broadcast_receive on realtime.messages for select to authenticated using(extension='broadcast' and nido_private.guardian_channel((select realtime.topic()),false));
create policy guardian_broadcast_send on realtime.messages for insert to authenticated with check(extension='broadcast' and nido_private.guardian_channel((select realtime.topic()),true));

create function public.guardian_validation_context(p_id uuid,p_user_id uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare r nido_private.guardian_rooms;
begin
 select * into r from nido_private.guardian_rooms where id=p_id and host_id=p_user_id and status in ('running','finished');
 if r.id is null then raise exception 'Partida no disponible'; end if;
 return jsonb_build_object('room',to_jsonb(r),'inputs',(select coalesce(jsonb_agg(jsonb_build_array(case when user_id=r.host_id then 0 else 1 end,seq,mask)),'[]') from nido_private.guardian_inputs where room_id=r.id));
end $$;
revoke all on function public.guardian_validation_context(uuid,uuid) from public,anon,authenticated;
grant execute on function public.guardian_validation_context(uuid,uuid) to service_role;
create function public.guardian_settle(p_id uuid,p_user_id uuid,p_hash text,p_reward integer,p_frames integer) returns jsonb language plpgsql security definer set search_path='' as $$
declare r nido_private.guardian_rooms; u uuid; amount integer; earned integer; result jsonb:='{}'; maxreward integer;
begin
 select * into r from nido_private.guardian_rooms where id=p_id and host_id=p_user_id for update;
 if r.id is null then raise exception 'Partida inválida'; end if;
 if r.status='finished' then
  if r.replay_hash<>p_hash then raise exception 'La partida ya está cerrada'; end if;
  return jsonb_build_object('saved',true,'reward',(select amount from nido_private.guardian_rewards where room_id=r.id and user_id=p_user_id));
 end if;
 maxreward:=(case r.difficulty when 'easy' then 10 when 'medium' then 15 else 25 end)+5;
 if r.mode='partner' then maxreward:=maxreward*2; end if;
 if r.status<>'running' or p_reward<0 or p_reward>maxreward or p_frames<600 or p_frames>21600 or p_hash is null or p_hash!~'^[a-f0-9]{64}$' or now()<r.started_at+make_interval(secs=>p_frames/60.0-3) or now()>r.started_at+interval '15 minutes' then raise exception 'Partida no válida'; end if;
 if r.mode='partner' and (r.guest_id is null or r.confirmed_hash is distinct from p_hash) then raise exception 'Falta la confirmación de tu pareja'; end if;
 for u in select x from unnest(array[r.host_id,r.guest_id]) as x where x is not null order by x loop
  perform pg_advisory_xact_lock(hashtextextended('guardian-reward:'||u::text,0));
  select coalesce(sum(g.amount),0) into earned from nido_private.guardian_rewards g where g.user_id=u and g.created_at>=date_trunc('day',now());
  amount:=least(p_reward,greatest(0,200-earned));
  insert into nido_private.guardian_rewards values(r.id,u,amount,now());
  insert into public.game_stats(user_id,love_coins,total_games_played,total_coins_earned) values(u,amount,1,amount) on conflict(user_id) do update set love_coins=game_stats.love_coins+excluded.love_coins,total_games_played=game_stats.total_games_played+1,total_coins_earned=game_stats.total_coins_earned+excluded.total_coins_earned,updated_at=now();
  if u=p_user_id then result:=jsonb_build_object('saved',true,'reward',amount); end if;
 end loop;
 update nido_private.guardian_rooms set status='finished',finished_at=now(),replay_hash=p_hash,reward=p_reward,frames=p_frames where id=r.id;
 return result;
end $$;
revoke all on function public.guardian_settle(uuid,uuid,text,integer,integer) from public,anon,authenticated;
grant execute on function public.guardian_settle(uuid,uuid,text,integer,integer) to service_role;
