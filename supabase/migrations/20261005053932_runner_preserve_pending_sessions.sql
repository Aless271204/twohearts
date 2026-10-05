create or replace function public.runner_start_session(p_user_id uuid) returns jsonb
language plpgsql security invoker set search_path='' as $$
declare v_id uuid; v_best integer; v_count integer;
begin
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_user_id::text,731));
  if exists(select 1 from public.runner_sessions where user_id=p_user_id and started_at>clock_timestamp()-interval '3 seconds') then
    raise exception 'Please wait before starting another run';
  end if;
  select count(*) into v_count from public.runner_sessions where user_id=p_user_id and started_at>clock_timestamp()-interval '1 hour';
  if v_count >= 120 then raise exception 'Hourly run limit reached'; end if;
  update public.runner_sessions set status='abandoned' where user_id=p_user_id and status='started' and started_at < clock_timestamp()-interval '24 hours';
  insert into public.runner_sessions(user_id) values(p_user_id) returning id into v_id;
  select best_score into v_best from public.game_records where user_id=p_user_id and game_id='pebble_runner';
  return jsonb_build_object('session_id',v_id,'best_distance',coalesce(v_best,0));
end $$;
