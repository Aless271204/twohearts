create or replace function public.guardian_settle(p_id uuid,p_user_id uuid,p_hash text,p_reward integer,p_frames integer) returns jsonb language plpgsql security definer set search_path='' as $$
declare r nido_private.guardian_rooms; u uuid; amount integer; earned integer; result jsonb:='{}'; maxreward integer;
begin
 select * into r from nido_private.guardian_rooms where id=p_id and host_id=p_user_id for update;
 if r.id is null then raise exception 'Partida inválida'; end if;
 if r.status='finished' then
  if r.replay_hash<>p_hash then raise exception 'La partida ya está cerrada'; end if;
  return jsonb_build_object('saved',true,'reward',(select gr.amount from nido_private.guardian_rewards gr where gr.room_id=r.id and gr.user_id=p_user_id));
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
