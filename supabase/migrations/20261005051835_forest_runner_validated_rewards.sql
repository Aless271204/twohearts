create table public.runner_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  started_at timestamptz not null default clock_timestamp(),
  finished_at timestamptz,
  status text not null default 'started' check (status in ('started','finished','abandoned')),
  distance integer not null default 0 check (distance >= 0),
  coins_collected integer not null default 0 check (coins_collected >= 0),
  coins_awarded integer not null default 0 check (coins_awarded between 0 and 500),
  elapsed_seconds double precision,
  result jsonb
);
create index runner_sessions_user_time on public.runner_sessions(user_id,started_at desc);
alter table public.runner_sessions enable row level security;
revoke all on public.runner_sessions from public,anon,authenticated;
grant select on public.runner_sessions to authenticated;
grant all on public.runner_sessions to service_role;
create policy runner_sessions_read_own on public.runner_sessions for select to authenticated
using ((select auth.uid()) = user_id);

-- These RPCs are server-only. The Edge Function validates the user's JWT and
-- independently simulates the replay before invoking them with service_role.
create function public.runner_start_session(p_user_id uuid) returns jsonb
language plpgsql security invoker set search_path='' as $$
declare v_id uuid; v_best integer; v_count integer;
begin
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_user_id::text,731));
  if exists(select 1 from public.runner_sessions where user_id=p_user_id and started_at>clock_timestamp()-interval '3 seconds') then
    raise exception 'Please wait before starting another run';
  end if;
  select count(*) into v_count from public.runner_sessions where user_id=p_user_id and started_at>clock_timestamp()-interval '1 hour';
  if v_count >= 120 then raise exception 'Hourly run limit reached'; end if;
  update public.runner_sessions set status='abandoned' where user_id=p_user_id and status='started';
  insert into public.runner_sessions(user_id) values(p_user_id) returning id into v_id;
  select best_score into v_best from public.game_records where user_id=p_user_id and game_id='pebble_runner';
  return jsonb_build_object('session_id',v_id,'best_distance',coalesce(v_best,0));
end $$;

create function public.runner_finish_session(p_user_id uuid,p_session_id uuid,p_distance integer,p_coins integer,p_elapsed double precision) returns jsonb
language plpgsql security invoker set search_path='' as $$
declare v_run public.runner_sessions%rowtype; v_stats public.game_stats%rowtype;
  v_awarded integer; v_today integer; v_xp integer; v_best integer; v_result jsonb;
begin
  select * into v_run from public.runner_sessions where id=p_session_id and user_id=p_user_id for update;
  if not found then raise exception 'Run does not belong to this user'; end if;
  if v_run.status='finished' then return v_run.result; end if;
  if v_run.status <> 'started' then raise exception 'Run is no longer active'; end if;
  if clock_timestamp()-v_run.started_at > interval '24 hours' then raise exception 'Run expired'; end if;
  if p_distance is null or p_coins is null or p_elapsed is null or
     p_distance < 0 or p_distance > 18000 or p_coins < 0 or p_coins > p_distance*6/28+12 or
     p_elapsed < 0 or p_elapsed > 1200 or p_elapsed='NaN'::double precision or
     p_elapsed > extract(epoch from clock_timestamp()-v_run.started_at)+2 or
     p_distance > p_elapsed*14+2 then raise exception 'Invalid run timing or reward'; end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_user_id::text,732));
  select coalesce(sum(coins_awarded),0) into v_today from public.runner_sessions
    where user_id=p_user_id and status='finished' and finished_at>=date_trunc('day',clock_timestamp() at time zone 'UTC') at time zone 'UTC';
  v_awarded:=least(p_coins,500,greatest(0,1000-v_today));
  v_xp:=least(1000,p_distance/10+v_awarded);
  insert into public.game_stats(user_id) values(p_user_id) on conflict(user_id) do nothing;
  update public.game_stats set love_coins=love_coins+v_awarded,xp=xp+v_xp,
    level=case when xp+v_xp<200 then 1 when xp+v_xp<500 then 2 when xp+v_xp<1000 then 3 when xp+v_xp<2000 then 4 else 5 end,
    total_games_played=total_games_played+1,total_coins_earned=total_coins_earned+v_awarded,updated_at=clock_timestamp()
    where user_id=p_user_id returning * into v_stats;
  insert into public.game_scores(user_id,game_id,score,coins_earned) values(p_user_id,'pebble_runner',p_distance,v_awarded);
  insert into public.game_records(user_id,game_id,best_score,best_coins,times_played)
    values(p_user_id,'pebble_runner',p_distance,p_coins,1)
    on conflict(user_id,game_id) do update set
    best_score=greatest(public.game_records.best_score,excluded.best_score),
    best_coins=greatest(public.game_records.best_coins,excluded.best_coins),
    times_played=public.game_records.times_played+1,updated_at=clock_timestamp()
    returning best_score into v_best;
  v_result:=jsonb_build_object('distance',p_distance,'coins_collected',p_coins,'coins_awarded',v_awarded,
    'best_distance',v_best,'love_coins',v_stats.love_coins,'xp',v_stats.xp,'level',v_stats.level);
  update public.runner_sessions set status='finished',finished_at=clock_timestamp(),distance=p_distance,
    coins_collected=p_coins,coins_awarded=v_awarded,elapsed_seconds=p_elapsed,result=v_result where id=p_session_id;
  return v_result;
end $$;
revoke all on function public.runner_start_session(uuid) from public,anon,authenticated;
revoke all on function public.runner_finish_session(uuid,uuid,integer,integer,double precision) from public,anon,authenticated;
grant execute on function public.runner_start_session(uuid) to service_role;
grant execute on function public.runner_finish_session(uuid,uuid,integer,integer,double precision) to service_role;
