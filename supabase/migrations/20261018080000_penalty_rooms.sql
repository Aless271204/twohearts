-- Secret simultaneous choices live only in the private schema. Public RPC never returns them.
create table nido_private.penalty_rooms(
 id uuid primary key default gen_random_uuid(),code text unique not null,
 host_id uuid not null references auth.users(id) on delete cascade,
 guest_id uuid references auth.users(id) on delete cascade,
 host_species text not null default 'penguin',guest_species text not null default 'bear',
 state jsonb not null default '{"round":0,"score":[0,0],"attempts":[[],[]],"winner":null,"last":null}',
 choices jsonb not null default '{}',ready boolean[] not null default array[false,false],
 status text not null default 'waiting',generation integer not null default 0,
 updated_at timestamptz not null default now(),created_at timestamptz not null default now(),
 resolved_at timestamptz,deadline timestamptz,expires_at timestamptz not null default now()+interval '2 hours',
 check(status in ('waiting','playing','finished','cancelled')),check(guest_id is null or guest_id<>host_id)
);
alter table nido_private.penalty_rooms enable row level security;
revoke all on nido_private.penalty_rooms from public,anon,authenticated;
create index penalty_rooms_host on nido_private.penalty_rooms(host_id,created_at);
create index penalty_rooms_guest on nido_private.penalty_rooms(guest_id,created_at);
create table nido_private.penalty_rewards(
 room_id uuid references nido_private.penalty_rooms(id) on delete cascade,generation int not null,
 user_id uuid references auth.users(id) on delete cascade,amount int not null,created_at timestamptz not null default now(),
 primary key(room_id,generation,user_id)
);
alter table nido_private.penalty_rewards enable row level security;
revoke all on nido_private.penalty_rewards from public,anon,authenticated;
create index penalty_reward_daily on nido_private.penalty_rewards(user_id,created_at);

create or replace function nido_private.penalty_room(p_action text,p_id uuid default null,p_code text default '',p_data jsonb default '{}') returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();r nido_private.penalty_rooms;side int;v jsonb;w jsonb;s jsonb;other jsonb;shot jsonb;keeper jsonb;
 rnd int;scores int[];attempts jsonb;kind text;goal boolean;is_out boolean;post boolean;win int;member uuid;award int;daily int;idx int;
begin
 if u is null then raise exception 'Inicia sesión para jugar';end if;
 if octet_length(p_data::text)>1500 then raise exception 'Solicitud demasiado grande';end if;
 if p_action='create' then
  if (select count(*) from nido_private.penalty_rooms where host_id=u and created_at>now()-interval '1 hour')>=20 then raise exception 'Demasiadas salas. Reutiliza una sala existente';end if;
  insert into nido_private.penalty_rooms(code,host_id,host_species) values(upper(substr(replace(gen_random_uuid()::text,'-',''),1,8)),u,case when p_data->>'species' in ('penguin','bear','pig','chick') then p_data->>'species' else 'penguin' end) returning * into r;
 elsif p_action='join' then
  select * into r from nido_private.penalty_rooms where code=upper(p_code) and expires_at>now() for update;
  if r.id is null or r.status='cancelled' then raise exception 'Sala no disponible';end if;
  if r.host_id<>u and r.guest_id is null and r.status='waiting' then
   update nido_private.penalty_rooms set guest_id=u,guest_species=case when p_data->>'species' in ('penguin','bear','pig','chick') then p_data->>'species' else 'bear' end where id=r.id returning * into r;
  elsif u<>r.host_id and u is distinct from r.guest_id then raise exception 'La sala ya está completa';end if;
 else
  select * into r from nido_private.penalty_rooms where id=p_id and expires_at>now() for update;
 end if;
 if r.id is null or (u<>r.host_id and u is distinct from r.guest_id) then raise exception 'Sala no disponible';end if;
 side:=case when u=r.host_id then 0 else 1 end;s:=r.state;rnd:=(s->>'round')::int;
 if p_action in ('ready','rematch') then
  if p_action='rematch' and r.status<>'finished' then raise exception 'La partida no ha terminado';end if;
  if p_action='ready' and r.status<>'waiting' then raise exception 'Sala ya iniciada';end if;
  r.ready[side+1]:=true;
  if r.guest_id is not null and r.ready[1] and r.ready[2] then
   r.status:='playing';r.ready:=array[false,false];r.choices:='{}';r.resolved_at:=null;r.deadline:=clock_timestamp()+interval '15 seconds';
   if p_action='rematch' then r.generation:=r.generation+1;s:='{"round":0,"score":[0,0],"attempts":[[],[]],"winner":null,"last":null}';end if;
  end if;
 elsif p_action='choose' or (p_action='status' and r.status='playing' and clock_timestamp()>=r.deadline) then
  if p_action='choose' then
  if clock_timestamp()>=r.deadline then raise exception 'Se acabó el tiempo. Actualiza la jugada';end if;
  if r.status<>'playing' or (p_data->>'round')::int is distinct from rnd or (p_data->>'generation')::int is distinct from r.generation then raise exception 'La jugada ya cambió';end if;
  if r.resolved_at is not null and now()<r.resolved_at+interval '2.5 seconds' then raise exception 'Espera a que termine la jugada';end if;
  if r.choices ? side::text then raise exception 'Ya confirmaste tu elección';end if;
  v:=p_data->'choice';
  if jsonb_typeof(v->'x') is distinct from 'number' or jsonb_typeof(v->'y') is distinct from 'number' or jsonb_typeof(v->'power') is distinct from 'number' then raise exception 'Elección inválida';end if;
  if (v->>'x')::numeric not between 0 and 1 or (v->>'y')::numeric not between 0 and 1 or (v->>'power')::numeric not between 0 and 1 then raise exception 'Elección fuera del campo';end if;
  r.choices:=jsonb_set(r.choices,array[side::text],v);
  else
   for idx in 0..1 loop
    if not r.choices ? idx::text then
     r.choices:=jsonb_set(r.choices,array[idx::text],case when idx=rnd%2 then '{"x":0,"y":1,"power":1}'::jsonb else '{"x":0.5,"y":0.5,"power":0.5}'::jsonb end);
    end if;
   end loop;
  end if;
  if r.choices ? '0' and r.choices ? '1' then
   shot:=r.choices->(rnd%2)::text;keeper:=r.choices->(1-rnd%2)::text;
   is_out:=(shot->>'power')::numeric>.96 and ((shot->>'x')::numeric<.08 or (shot->>'x')::numeric>.92 or (shot->>'y')::numeric>.92);
   post:=not is_out and (shot->>'power')::numeric>.86 and ((shot->>'x')::numeric<.035 or (shot->>'x')::numeric>.965);
   kind:=case when is_out then 'miss' when post then 'post' when sqrt(power(((shot->>'x')::numeric-(keeper->>'x')::numeric)*1.3,2)+power((shot->>'y')::numeric-(keeper->>'y')::numeric,2))<.23+(1-(shot->>'power')::numeric)*.12 then 'save' else 'goal' end;
   goal:=kind='goal';scores:=array[(s->'score'->>0)::int,(s->'score'->>1)::int];scores[rnd%2+1]:=scores[rnd%2+1]+case when goal then 1 else 0 end;
   attempts:=jsonb_set(s->'attempts',array[(rnd%2)::text],(s->'attempts'->(rnd%2))||to_jsonb(goal));
   s:=jsonb_build_object('round',rnd+1,'score',scores,'attempts',attempts,'winner',null,'last',jsonb_build_object('kind',kind,'shot',shot,'keeper',keeper,'side',rnd%2));
   r.choices:='{}';r.resolved_at:=clock_timestamp();r.deadline:=clock_timestamp()+interval '17.8 seconds';
   if rnd+1>=10 and (rnd+1)%2=0 and scores[1]<>scores[2] then
    win:=case when scores[1]>scores[2] then 0 else 1 end;s:=jsonb_set(s,'{winner}',to_jsonb(win));r.status:='finished';
    -- Room lock serializes settlement; unique ledger protects every generation from duplicate credit.
    for member in select unnest(array[r.host_id,r.guest_id]) order by 1 loop perform nido_private.wallet_lock(member);end loop;
    for idx in 0..1 loop
     member:=case when idx=0 then r.host_id else r.guest_id end;
     insert into public.game_stats(user_id,love_coins) values(member,0) on conflict(user_id) do nothing;
     select coalesce(sum(amount),0) into daily from nido_private.penalty_rewards where user_id=member and created_at>=date_trunc('day',now());
     award:=least(case when idx=win then 20 else 8 end,greatest(0,100-daily));
     insert into nido_private.penalty_rewards(room_id,generation,user_id,amount) values(r.id,r.generation,member,award) on conflict do nothing;
     if found then update public.game_stats set love_coins=love_coins+award where user_id=member;end if;
    end loop;
   end if;
  end if;
 elsif p_action='leave' then r.status:='cancelled';
 elsif p_action not in ('status','create','join') then raise exception 'Acción inválida';end if;
 update nido_private.penalty_rooms set state=s,choices=r.choices,ready=r.ready,status=r.status,generation=r.generation,resolved_at=r.resolved_at,deadline=r.deadline,updated_at=now() where id=r.id;
 return jsonb_build_object('id',r.id,'code',r.code,'side',side,'status',r.status,'generation',r.generation,'state',s,'ready',r.ready,'joined',r.guest_id is not null,'chosen',r.choices ? side::text,'opponent_chosen',r.choices ? (1-side)::text,'deadline',r.deadline,'server_time',clock_timestamp(),'species',jsonb_build_array(r.host_species,r.guest_species));
end $$;
revoke all on function nido_private.penalty_room(text,uuid,text,jsonb) from public,anon,authenticated;
create or replace function public.penalty_room(p_action text,p_id uuid default null,p_code text default '',p_data jsonb default '{}') returns jsonb
language sql security invoker set search_path='' as $$select nido_private.penalty_room(p_action,p_id,p_code,p_data)$$;
-- Only the vetted entry function can access the private API; no table grants.
grant usage on schema nido_private to authenticated;
grant execute on function nido_private.penalty_room(text,uuid,text,jsonb) to authenticated;
revoke all on function public.penalty_room(text,uuid,text,jsonb) from public,anon;
grant execute on function public.penalty_room(text,uuid,text,jsonb) to authenticated;
