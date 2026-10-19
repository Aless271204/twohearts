create table nido_private.maze_rooms(
 id uuid primary key default gen_random_uuid(),code text unique not null,host_id uuid not null references auth.users(id) on delete cascade,guest_id uuid references auth.users(id) on delete cascade,
 mode text not null,difficulty text not null,theme text not null,seed bigint not null,state jsonb,revision int not null default 0,generation int not null default 0,
 ready boolean[] not null default array[false,false],status text not null default 'waiting',last_host_move timestamptz,last_guest_move timestamptz,
 created_at timestamptz not null default now(),expires_at timestamptz not null default now()+interval '2 hours',
 check(mode in ('solo','partner')),check(difficulty in ('easy','medium','hard')),check(theme in ('halloween','christmas','easter','garden')),check(status in ('waiting','playing','finished','cancelled')),check(guest_id is null or guest_id<>host_id)
);
alter table nido_private.maze_rooms enable row level security;revoke all on nido_private.maze_rooms from public,anon,authenticated;
create index maze_rooms_host on nido_private.maze_rooms(host_id,created_at);create index maze_rooms_guest on nido_private.maze_rooms(guest_id,created_at);
create table nido_private.maze_rewards(room_id uuid references nido_private.maze_rooms(id) on delete cascade,generation int not null,user_id uuid references auth.users(id) on delete cascade,amount int not null,created_at timestamptz not null default now(),primary key(room_id,generation,user_id));
alter table nido_private.maze_rewards enable row level security;revoke all on nido_private.maze_rewards from public,anon,authenticated;
create index maze_rewards_daily on nido_private.maze_rewards(user_id,created_at);

-- Service-role only. The authenticated Edge function reconstructs all actions with the shared engine.
create or replace function public.maze_room_service(p_user uuid,p_action text,p_id uuid default null,p_code text default '',p_data jsonb default '{}') returns jsonb language plpgsql security definer set search_path='' as $$
declare r nido_private.maze_rooms;side int;member uuid;amount int;daily int;begin
 if p_user is null then raise exception 'Authentication required';end if;
 if p_action in ('create','solo') then
  if (select count(*) from nido_private.maze_rooms where host_id=p_user and created_at>now()-interval '1 hour')>=20 then raise exception 'Demasiadas salas';end if;
  if coalesce(p_data->>'difficulty','easy') not in ('easy','medium','hard') or coalesce(p_data->>'theme','halloween') not in ('halloween','christmas','easter','garden') then raise exception 'Opciones inválidas';end if;
  insert into nido_private.maze_rooms(code,host_id,mode,difficulty,theme,seed,status) values(upper(substr(replace(gen_random_uuid()::text,'-',''),1,8)),p_user,case when p_action='solo' then 'solo' else 'partner' end,coalesce(p_data->>'difficulty','easy'),coalesce(p_data->>'theme','halloween'),floor(random()*2147483647)::bigint,case when p_action='solo' then 'playing' else 'waiting' end) returning * into r;
 elsif p_action='join' then
  select * into r from nido_private.maze_rooms where code=upper(p_code) and expires_at>now() and mode='partner' for update;
  if r.id is null or r.status='cancelled' then raise exception 'Sala no disponible';end if;
  if p_user<>r.host_id and r.guest_id is null and r.status='waiting' then update nido_private.maze_rooms set guest_id=p_user where id=r.id returning * into r;
  elsif p_user<>r.host_id and p_user is distinct from r.guest_id then raise exception 'Sala completa';end if;
 else select * into r from nido_private.maze_rooms where id=p_id and expires_at>now() for update;end if;
 if r.id is null or (p_user<>r.host_id and p_user is distinct from r.guest_id) then raise exception 'Sala no disponible';end if;
 side:=case when p_user=r.host_id then 0 else 1 end;
 if p_action='init' then
  if r.state is null and (p_data->>'generation')::int=r.generation and p_data->'state' is not null then r.state:=p_data->'state';r.revision:=r.revision+1;end if;
 elsif p_action in ('ready','rematch') then
  if p_action='ready' and r.status<>'waiting' or p_action='rematch' and r.status<>'finished' then raise exception 'La sala cambió';end if;
  r.ready[side+1]:=true;
  if r.mode='solo' or (r.guest_id is not null and r.ready[1] and r.ready[2]) then
   r.status:='playing';r.ready:=array[false,false];if p_action='rematch' then r.generation:=r.generation+1;r.seed:=floor(random()*2147483647)::bigint;r.state:=null;r.revision:=r.revision+1;end if;
  end if;
 elsif p_action='update' then
  if r.status<>'playing' or (p_data->>'revision')::int is distinct from r.revision or (p_data->>'generation')::int is distinct from r.generation then return jsonb_build_object('retry',true);end if;
  if clock_timestamp()<coalesce(case when side=0 then r.last_host_move else r.last_guest_move end,'-infinity'::timestamptz)+interval '180 milliseconds' then raise exception 'Espera al siguiente paso';end if;
  if side=0 then r.last_host_move:=clock_timestamp();else r.last_guest_move:=clock_timestamp();end if;
  r.state:=p_data->'state';r.revision:=r.revision+1;
  if r.state->>'status' in ('victory','defeat') then
   r.status:='finished';if r.state->>'status'='victory' then
    for member in select unnest(case when r.mode='solo' then array[r.host_id] else array[r.host_id,r.guest_id] end) order by 1 loop
     perform nido_private.wallet_lock(member);
     select coalesce(sum(rw.amount),0) into daily from nido_private.maze_rewards rw where rw.user_id=member and rw.created_at>=date_trunc('day',now());
     amount:=least(100-greatest(0,least(100,daily)),greatest(0,least(80,(p_data->>'reward')::int)));
     insert into nido_private.maze_rewards values(r.id,r.generation,member,amount,now()) on conflict do nothing;
     if found then insert into public.game_stats(user_id,love_coins) values(member,amount) on conflict(user_id) do update set love_coins=public.game_stats.love_coins+excluded.love_coins;end if;
    end loop;
   end if;
  end if;
 elsif p_action='leave' then r.status:='cancelled';
 elsif p_action not in ('create','solo','join','status') then raise exception 'Acción inválida';end if;
 update nido_private.maze_rooms set state=r.state,revision=r.revision,generation=r.generation,seed=r.seed,status=r.status,ready=r.ready,last_host_move=r.last_host_move,last_guest_move=r.last_guest_move where id=r.id;
 return jsonb_build_object('id',r.id,'code',r.code,'side',side,'mode',r.mode,'difficulty',r.difficulty,'theme',r.theme,'seed',r.seed,'status',r.status,'generation',r.generation,'revision',r.revision,'state',r.state,'ready',r.ready,'joined',r.guest_id is not null);
end $$;
revoke all on function public.maze_room_service(uuid,text,uuid,text,jsonb) from public,anon,authenticated;
grant execute on function public.maze_room_service(uuid,text,uuid,text,jsonb) to service_role;
