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
 update public.runner_sessions set checkpoint_state=p_state,checkpoint_index=p_index,checkpoint_result=v_checkpoint_result where id=p_session_id;
 return v_checkpoint_result;
end $$;
