-- Verified game settlements only. Existing balances/receipts are not rewritten.
-- A first result establishes the baseline. Ties and repeated saves never earn a bonus.
create table nido_private.game_record_scores (
 user_id uuid not null references auth.users(id) on delete cascade,
 game text not null, scope text not null, best_score bigint,
 current_streak integer not null default 0, attempts integer not null default 0,
 updated_at timestamptz not null default now(), primary key(user_id,game,scope)
);
create table nido_private.game_record_receipts (
 user_id uuid not null references auth.users(id) on delete cascade,
 game text not null, scope text not null, run text not null,
 score bigint not null, base_reward integer not null, bonus integer not null,
 is_record boolean not null, created_at timestamptz not null default now(),
 primary key(user_id,game,scope,run)
);
alter table nido_private.game_record_scores enable row level security;
alter table nido_private.game_record_receipts enable row level security;
revoke all on nido_private.game_record_scores,nido_private.game_record_receipts from public,anon,authenticated;

-- Invoked only inside already-authorized, locked settlement functions.
create function nido_private.record_bonus(p_user uuid,p_game text,p_scope text,p_run text,p_score bigint,p_base integer,p_capacity integer,p_win boolean default null)
returns integer language plpgsql set search_path='' as $$
declare previous nido_private.game_record_scores; score bigint; extra integer; beaten boolean;
begin
 if p_user is null or p_game not in ('pebble_runner','guardian','pong','quiz','penalties','maze','art') or p_scope is null or p_run is null or p_base<0 or p_capacity<0 then raise exception 'Invalid record settlement';end if;
 insert into nido_private.game_record_scores(user_id,game,scope) values(p_user,p_game,p_scope) on conflict do nothing;
 select * into previous from nido_private.game_record_scores where user_id=p_user and game=p_game and scope=p_scope for update;
 if exists(select 1 from nido_private.game_record_receipts where user_id=p_user and game=p_game and scope=p_scope and run=p_run) then return 0;end if;
 score:=case when p_win is null then greatest(0,p_score) when p_win then previous.current_streak+1 else 0 end;
 beaten:=previous.attempts>0 and previous.best_score is not null and score>previous.best_score;
 -- Currency is integral: round up the extra, while preserving each game's daily cap.
 extra:=case when beaten then least(ceil(p_base::numeric/10)::int,greatest(0,p_capacity-p_base)) else 0 end;
 insert into nido_private.game_record_receipts(user_id,game,scope,run,score,base_reward,bonus,is_record) values(p_user,p_game,p_scope,p_run,score,p_base,extra,beaten);
 update nido_private.game_record_scores set best_score=greatest(best_score,score),current_streak=case when p_win is null then current_streak else score::int end,attempts=attempts+1,updated_at=now() where user_id=p_user and game=p_game and scope=p_scope;
 return extra;
end $$;
revoke all on function nido_private.record_bonus(uuid,text,text,text,bigint,integer,integer,boolean) from public,anon,authenticated;

create function nido_private.record_receipt(p_user uuid,p_game text,p_scope text,p_run text) returns jsonb language sql set search_path='' as $$
 select coalesce((select jsonb_build_object('base_reward',base_reward,'record_bonus',bonus,'new_record',is_record) from nido_private.game_record_receipts where user_id=p_user and game=p_game and scope=p_scope and run=p_run),'{}'::jsonb)
$$;
revoke all on function nido_private.record_receipt(uuid,text,text,text) from public,anon,authenticated;

-- Preserve the runner's existing distance record as its baseline.
insert into nido_private.game_record_scores(user_id,game,scope,best_score,attempts)
 select user_id,'pebble_runner','distance',greatest(0,best_score),greatest(1,times_played) from public.game_records where game_id='pebble_runner' on conflict do nothing;

CREATE OR REPLACE FUNCTION public.runner_finish_session(p_user_id uuid, p_session_id uuid, p_distance integer, p_coins integer, p_elapsed double precision)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare v_run public.runner_sessions%rowtype; v_stats public.game_stats%rowtype;
  v_awarded integer; v_today integer; v_xp integer; v_best integer; v_result jsonb;
begin
  select * into v_run from public.runner_sessions where id=p_session_id and user_id=p_user_id for update;
  if not found then raise exception 'Run does not belong to this user'; end if;
  if v_run.status='finished' then return v_run.result; end if;
  if v_run.status <> 'started' then raise exception 'Run is no longer active'; end if;
  if clock_timestamp()-v_run.started_at > interval '24 hours' then raise exception 'Run expired'; end if;
  if p_distance is null or p_coins is null or p_elapsed is null or
     p_distance < 0 or p_coins < 0 or p_coins > p_distance::bigint*12/18+24 or
     p_elapsed < 0 or p_elapsed='NaN'::double precision or
     p_elapsed > extract(epoch from clock_timestamp()-v_run.started_at)+2 or
     p_distance > p_elapsed*48+2 then raise exception 'Invalid run timing or reward'; end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_user_id::text,732));
  select coalesce(sum(coins_awarded),0) into v_today from public.runner_sessions
    where user_id=p_user_id and status='finished' and finished_at>=date_trunc('day',clock_timestamp() at time zone 'UTC') at time zone 'UTC';
  v_awarded:=least(p_coins/50,500,greatest(0,1000-v_today));
  v_awarded:=v_awarded+nido_private.record_bonus(p_user_id,'pebble_runner','distance',p_session_id::text,p_distance,v_awarded,least(500,greatest(0,1000-v_today)));
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
  v_result:=jsonb_build_object('distance',p_distance,'coins_collected',p_coins,'coins_awarded',v_awarded,'points_per_coin',50,
    'best_distance',v_best,'love_coins',v_stats.love_coins,'xp',v_stats.xp,'level',v_stats.level)||nido_private.record_receipt(p_user_id,'pebble_runner','distance',p_session_id::text);
  update public.runner_sessions set status='finished',finished_at=clock_timestamp(),distance=p_distance,
    coins_collected=p_coins,coins_awarded=v_awarded,elapsed_seconds=p_elapsed,result=v_result where id=p_session_id;
  return v_result;
end $function$;

CREATE OR REPLACE FUNCTION public.guardian_settle(p_id uuid, p_user_id uuid, p_hash text, p_reward integer, p_frames integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r nido_private.guardian_rooms; u uuid; amount integer; earned integer; result jsonb:='{}'; maxreward integer; prize text; members uuid[];
begin
 select * into r from nido_private.guardian_rooms where id=p_id and host_id=p_user_id for update;
 if r.id is null then raise exception 'Partida inválida'; end if;
 if r.status='finished' then
  if r.replay_hash<>p_hash then raise exception 'La partida ya está cerrada'; end if;
  return jsonb_build_object('saved',true,'total_reward',(select coalesce(sum(gr.amount),0) from nido_private.guardian_rewards gr where gr.room_id=r.id),'prize',(select item_key from nido_private.guardian_clothing_prizes where room_id=r.id),'reward',(select gr.amount from nido_private.guardian_rewards gr where gr.room_id=r.id and gr.user_id=p_user_id));
 end if;
 maxreward:=200;
 if r.mode='partner' then maxreward:=maxreward*2; end if;
 if r.status<>'running' or p_reward<0 or p_reward>maxreward or p_frames<600 or p_frames>21600 or p_hash is null or p_hash!~'^[a-f0-9]{64}$' or now()<r.started_at+make_interval(secs=>p_frames/60.0-3) or now()>r.started_at+interval '15 minutes' then raise exception 'Partida no válida'; end if;
 if r.mode='partner' and (r.guest_id is null or r.confirmed_hash is distinct from p_hash) then raise exception 'Falta la confirmación de tu pareja'; end if;
 for u in select x from unnest(array[r.host_id,r.guest_id]) as x where x is not null order by x loop
  perform pg_advisory_xact_lock(hashtextextended('guardian-reward:'||u::text,0));
  select coalesce(sum(g.amount),0) into earned from nido_private.guardian_rewards g where g.user_id=u and g.created_at>=date_trunc('day',now());
  -- p_reward is the expedition total, not a duplicated per-player award.
  amount:=least(case when r.mode='partner' then p_reward/2+case when u=r.host_id then p_reward%2 else 0 end else p_reward end,greatest(0,200-earned));
  amount:=amount+nido_private.record_bonus(u,'guardian',r.difficulty||':'||r.mode||':'||case when r.engine_version in (4,5,7) then 'river' else 'forest' end,r.id::text,21601-p_frames,amount,greatest(0,200-earned));
  insert into nido_private.guardian_rewards values(r.id,u,amount,now());
  insert into public.game_stats(user_id,love_coins,total_games_played,total_coins_earned) values(u,amount,1,amount) on conflict(user_id) do update set love_coins=game_stats.love_coins+excluded.love_coins,total_games_played=game_stats.total_games_played+1,total_coins_earned=game_stats.total_coins_earned+excluded.total_coins_earned,updated_at=now();
  if u=p_user_id then result:=jsonb_build_object('saved',true,'reward',amount)||nido_private.record_receipt(u,'guardian',r.difficulty||':'||r.mode||':'||case when r.engine_version in (4,5,7) then 'river' else 'forest' end,r.id::text); end if;
 end loop;
 update nido_private.guardian_rooms set status='finished',finished_at=now(),replay_hash=p_hash,reward=p_reward,frames=p_frames where id=r.id;
 if r.difficulty='hard' then
  members:=array_remove(array[r.host_id,r.guest_id],null);
  -- One claim per verified victory, even when all eligible pieces are owned.
  if not exists(select 1 from nido_private.guardian_clothing_prizes where room_id=r.id) then
   select s.item_key into prize from public.shop_items s where s.active and s.scope='pet' and s.price_coins between 50 and 60
    and s.item_key in ('bandana_sage','bow_neck','glasses_heart','patch_pirate','shirt_love','mask_sleep','glasses_round')
    and not exists(select 1 from public.owned_items o where o.user_id=any(members) and o.item_key=s.item_key) order by random() limit 1;
   insert into nido_private.guardian_clothing_prizes(room_id,item_key) values(r.id,prize);
   if prize is not null then insert into public.owned_items(user_id,item_key,slot) select x,prize,s.equip_slot from unnest(members) x cross join public.shop_items s where s.item_key=prize on conflict(user_id,item_key) do nothing;end if;
  end if;
 end if;
 return result||jsonb_build_object('total_reward',(select coalesce(sum(gr.amount),0) from nido_private.guardian_rewards gr where gr.room_id=r.id),'prize',(select item_key from nido_private.guardian_clothing_prizes where room_id=r.id));
end $function$;

CREATE OR REPLACE FUNCTION public.duo_tick(p_match_id uuid, p_paddle double precision DEFAULT NULL::double precision, p_choice integer DEFAULT NULL::integer, p_question_no integer DEFAULT NULL::integer, p_phase text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid:=auth.uid();m public.duo_matches;st jsonb;phase text;ts double precision:=extract(epoch from clock_timestamp());qn integer;qa public.duo_answers;qb public.duo_answers;sa integer;sb integer;wa integer;wb integer;round_n integer;question public.duo_questions;uid uuid;reward integer;earned integer;paused boolean;old_st jsonb;
begin
 select * into m from public.duo_matches where id=p_match_id for update;
 if u is null or not found or u not in(m.player_a,m.player_b) then raise exception 'No tienes acceso a esta partida' using errcode='42501';end if;
 if not exists(select 1 from nido_private.duo_online_matches where match_id=m.id) and not exists(select 1 from public.user_profiles a join public.user_profiles b on a.partner_id=b.id and b.partner_id=a.id where a.id=m.player_a and b.id=m.player_b) then raise exception 'La pareja ya no estÃ¡ vinculada';end if;
 if u=m.player_a then m.heartbeat_a:=clock_timestamp();else m.heartbeat_b:=clock_timestamp();end if;
 st:=m.state;
 if m.game='pong' and p_phase in('powerups-v1','powerups-v2') then
  st:=st||jsonb_build_object(case when u=m.player_a then 'power_client_a' else 'power_client_b' end,true,
   case when u=m.player_a then 'power_version_a' else 'power_version_b' end,case when p_phase='powerups-v2' then 2 else 1 end);
  if st->>'power_client_a'='true' and st->>'power_client_b'='true' then st:=st||'{"powerups_enabled":true}'::jsonb;end if;
  st:=st||jsonb_build_object('powerups_v2',coalesce((st->>'power_version_a')::integer,1)>=2 and coalesce((st->>'power_version_b')::integer,1)>=2);
 end if;
 phase:=st->>'phase';qn:=(st->>'question_no')::int;
 paused:=m.status='playing' and (m.heartbeat_a<clock_timestamp()-interval '4 seconds' or m.heartbeat_b is null or m.heartbeat_b<clock_timestamp()-interval '4 seconds');
 if paused then st:=st||jsonb_build_object('paused',true,'deadline',ts+case when m.game='quiz' then 20 else 15 end);
 elsif st->>'paused'='true' then st:=st||jsonb_build_object('paused',false,'deadline',ts+case when phase='countdown' then 3 when m.game='quiz' and phase='reveal' then 5 when m.game='quiz' and phase='question_intro' then 2 when m.game='quiz' then 20 else 15 end);
 elsif m.status='playing' then
  if p_paddle is not null and m.game='pong' and p_paddle::text not in('NaN','Infinity','-Infinity') then st:=jsonb_set(st,array[case when u=m.player_a then 'paddle_a' else 'paddle_b' end],to_jsonb(greatest(0.11,least(0.89,p_paddle))));end if;
  if p_choice is not null and m.game='quiz' and p_choice between 0 and 2 and p_question_no=qn and p_phase=phase and phase in('self','guess') and ts<(st->>'deadline')::float8 then
   insert into public.duo_answers(match_id,question_no,user_id) values(m.id,qn,u) on conflict do nothing;
   if phase='self' then update public.duo_answers set self_choice=p_choice where match_id=m.id and question_no=qn and user_id=u and self_choice is null;
   else update public.duo_answers set guess=p_choice where match_id=m.id and question_no=qn and user_id=u and guess is null;end if;
  end if;
  select * into qa from public.duo_answers where match_id=m.id and question_no=qn and user_id=m.player_a;
  select * into qb from public.duo_answers where match_id=m.id and question_no=qn and user_id=m.player_b;
  if m.game='pong' and phase='play' then
   old_st:=st;st:=public.duo_pong_step(st,extract(epoch from clock_timestamp()-m.last_tick));
   if st->>'score_a'<>old_st->>'score_a' or st->>'score_b'<>old_st->>'score_b' then
    sa:=(st->>'score_a')::int;sb:=(st->>'score_b')::int;
    st:=st||jsonb_build_object('x',0.5,'y',0.5,'vx',case when random()<0.5 then -0.35 else 0.35 end,'vy',case when sa>(old_st->>'score_a')::int then -0.48 else 0.48 end,'phase','countdown','deadline',ts+3);
    if greatest(sa,sb)>=7 then
     wa:=(st->>'wins_a')::int+case when sa>sb then 1 else 0 end;wb:=(st->>'wins_b')::int+case when sb>sa then 1 else 0 end;
     st:=st||jsonb_build_object('wins_a',wa,'wins_b',wb,'round',(st->>'round')::int+1,'score_a',0,'score_b',0);
     if greatest(wa,wb)=2 then m.status:='finished';m.winner:=case when wa>wb then m.player_a else m.player_b end;end if;
    end if;
   end if;
  elsif phase='countdown' and ts>=(st->>'deadline')::float8 then st:=st||jsonb_build_object('phase',case when m.game='pong' then 'play' else 'self' end,'deadline',ts+case when m.game='quiz' then 20 else 15 end);
  elsif m.game='quiz' and phase='self' and (ts>=(st->>'deadline')::float8 or (qa.self_choice is not null and qb.self_choice is not null)) then st:=st||jsonb_build_object('phase','guess','deadline',ts+20);
  elsif m.game='quiz' and phase='guess' and (ts>=(st->>'deadline')::float8 or (qa.guess is not null and qb.guess is not null)) then
   sa:=(st->>'score_a')::int+case when qa.guess=qb.self_choice then 1 else 0 end;sb:=(st->>'score_b')::int+case when qb.guess=qa.self_choice then 1 else 0 end;
   st:=st||jsonb_build_object('score_a',sa,'score_b',sb,'streak_a',case when qa.guess is not null and qa.guess=qb.self_choice then greatest(coalesce((st->>'streak_a')::int,0),0)+1 else least(coalesce((st->>'streak_a')::int,0),0)-1 end,'streak_b',case when qb.guess is not null and qb.guess=qa.self_choice then greatest(coalesce((st->>'streak_b')::int,0),0)+1 else least(coalesce((st->>'streak_b')::int,0),0)-1 end,'phase','reveal','deadline',ts+5,'answer_a',qa.self_choice,'answer_b',qb.self_choice,'guess_a',qa.guess,'guess_b',qb.guess);
  elsif m.game='quiz' and phase='question_intro' and ts>=(st->>'deadline')::float8 then st:=st||jsonb_build_object('phase','self','deadline',ts+20); elsif m.game='quiz' and phase='reveal' and ts>=(st->>'deadline')::float8 then
   sa:=(st->>'score_a')::int;sb:=(st->>'score_b')::int;
   round_n:=coalesce((st->>'round_questions')::int,0)+1;
   if round_n>=5 and sa<>sb then
    wa:=(st->>'wins_a')::int+case when sa>sb then 1 else 0 end;wb:=(st->>'wins_b')::int+case when sb>sa then 1 else 0 end;
    st:=st||jsonb_build_object('wins_a',wa,'wins_b',wb,'round',(st->>'round')::int+1,'score_a',0,'score_b',0);round_n:=0;
    if greatest(wa,wb)=2 then m.status:='finished';m.winner:=case when wa>wb then m.player_a else m.player_b end;end if;
   end if;
   st:=(st-'answer_a'-'answer_b'-'guess_a'-'guess_b')||jsonb_build_object('question_no',qn+1,'round_questions',round_n,'phase','question_intro','deadline',ts+2);qn:=qn+1;qa:=null;qb:=null;
   -- A cap prevents an endless all-AFK or always-tied match from yielding rewards.
   if qn>=60 and m.status<>'finished' then m.status:='cancelled';end if;
  end if;
 end if;
 if m.status='finished' then
  for uid in select v from unnest(array[m.player_a,m.player_b])v order by v loop
   insert into public.game_stats(user_id) values(uid) on conflict(user_id) do nothing;
   perform 1 from public.game_stats where user_id=uid for update;
   if not exists(select 1 from public.duo_rewards where match_id=m.id and user_id=uid) then
    select coalesce(sum(coins),0) into earned from public.duo_rewards where user_id=uid and created_at>=(date_trunc('day',now() at time zone 'UTC') at time zone 'UTC');
    reward:=case when clock_timestamp()-m.created_at>=interval '30 seconds' then least(greatest(300-earned,0),case when uid=m.winner then 20 else 8 end) else 0 end;
    if clock_timestamp()-m.created_at>=interval '30 seconds' then reward:=reward+nido_private.record_bonus(uid,m.game,'wins',m.id::text,0,reward,greatest(300-earned,0),uid=m.winner);end if;
    insert into public.duo_rewards(match_id,user_id,coins) values(m.id,uid,reward);
    update public.game_stats set love_coins=love_coins+reward,total_coins_earned=total_coins_earned+reward,total_games_played=total_games_played+1,updated_at=now() where user_id=uid;
   end if;
  end loop;
  select coins into reward from public.duo_rewards where match_id=m.id and user_id=u;
 end if;
 update public.duo_matches set state=st,status=m.status,winner=m.winner,heartbeat_a=m.heartbeat_a,heartbeat_b=m.heartbeat_b,last_tick=clock_timestamp() where id=m.id;
 -- Return my lock status only. Never return the other player's secret selections.
 st:=st-'questions';
 if m.game='pong' then st:=st||jsonb_build_object('opponent_paddle_color',(select s.appearance->>'color' from public.shop_items s join public.owned_items o on o.item_key=s.item_key where o.user_id=case when u=m.player_a then m.player_b else m.player_a end and o.equipped and s.equip_slot='pong_paddle' and s.active));end if;
 if m.game='quiz' then
  select * into question from public.duo_questions where id=(m.state->'questions'->>(qn%jsonb_array_length(m.state->'questions')))::int;
  st:=st||jsonb_build_object('question',jsonb_build_object('category',question.category,'prompt',question.prompt,'options',question.options),'my_choice',case when st->>'phase'='self' then case when u=m.player_a then qa.self_choice else qb.self_choice end when st->>'phase'='guess' then case when u=m.player_a then qa.guess else qb.guess end else null end);
 end if;
 return jsonb_build_object('id',m.id,'game',m.game,'side',case when u=m.player_a then 'a' else 'b' end,'status',m.status,'winner',m.winner,'server_time',ts,'reward',reward,'players',nido_private.duo_players(m.id),'state',st)||nido_private.record_receipt(u,m.game,'wins',m.id::text);
end $function$;

CREATE OR REPLACE FUNCTION nido_private.penalty_room(p_action text, p_id uuid DEFAULT NULL::uuid, p_code text DEFAULT ''::text, p_data jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
     award:=award+nido_private.record_bonus(member,'penalties','wins',r.id::text||':'||r.generation,0,award,greatest(0,100-daily),idx=win);
     insert into nido_private.penalty_rewards(room_id,generation,user_id,amount) values(r.id,r.generation,member,award) on conflict do nothing;
     if found then update public.game_stats set love_coins=love_coins+award where user_id=member;end if;
    end loop;
   end if;
  end if;
 elsif p_action='leave' then r.status:='cancelled';
 elsif p_action not in ('status','create','join') then raise exception 'Acción inválida';end if;
 update nido_private.penalty_rooms set state=s,choices=r.choices,ready=r.ready,status=r.status,generation=r.generation,resolved_at=r.resolved_at,deadline=r.deadline,updated_at=now() where id=r.id;
 return jsonb_build_object('id',r.id,'code',r.code,'side',side,'status',r.status,'generation',r.generation,'state',s,'ready',r.ready,'joined',r.guest_id is not null,'chosen',r.choices ? side::text,'opponent_chosen',r.choices ? (1-side)::text,'deadline',r.deadline,'server_time',clock_timestamp(),'species',jsonb_build_array(r.host_species,r.guest_species),'reward',(select amount from nido_private.penalty_rewards where room_id=r.id and generation=r.generation and user_id=u))||nido_private.record_receipt(u,'penalties','wins',r.id::text||':'||r.generation);
end $function$;

CREATE OR REPLACE FUNCTION public.maze_room_service(p_user uuid, p_action text, p_id uuid DEFAULT NULL::uuid, p_code text DEFAULT ''::text, p_data jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
     amount:=amount+nido_private.record_bonus(member,'maze',r.difficulty||':'||r.mode,r.id::text||':'||r.generation,greatest(0,1000000-coalesce((r.state->>'moves')::int,1000000)),amount,greatest(0,100-daily));
     insert into nido_private.maze_rewards values(r.id,r.generation,member,amount,now()) on conflict do nothing;
     if found then insert into public.game_stats(user_id,love_coins) values(member,amount) on conflict(user_id) do update set love_coins=public.game_stats.love_coins+excluded.love_coins;end if;
    end loop;
   end if;
  end if;
 elsif p_action='leave' then r.status:='cancelled';
 elsif p_action not in ('create','solo','join','status') then raise exception 'Acción inválida';end if;
 update nido_private.maze_rooms set state=r.state,revision=r.revision,generation=r.generation,seed=r.seed,status=r.status,ready=r.ready,last_host_move=r.last_host_move,last_guest_move=r.last_guest_move where id=r.id;
 return jsonb_build_object('id',r.id,'code',r.code,'side',side,'mode',r.mode,'difficulty',r.difficulty,'theme',r.theme,'seed',r.seed,'status',r.status,'generation',r.generation,'revision',r.revision,'state',r.state,'ready',r.ready,'joined',r.guest_id is not null,'reward',(select rw.amount from nido_private.maze_rewards rw where rw.room_id=r.id and rw.generation=r.generation and rw.user_id=p_user))||nido_private.record_receipt(p_user,'maze',r.difficulty||':'||r.mode,r.id::text||':'||r.generation);
end $function$;

CREATE OR REPLACE FUNCTION nido_private.art_action(p_action text, p_data jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid:=auth.uid(); partner uuid; r nido_private.art_rooms; token text; result jsonb; art text; member uuid; earned integer; amount integer; extra integer;
begin
 if u is null then raise exception 'Inicia sesión'; end if;
 if p_action in ('create','note','widget_token') then perform pg_advisory_xact_lock(hashtextextended(u::text,614)); end if;
 select p.partner_id into partner from public.user_profiles p
 join public.user_profiles q on q.id=p.partner_id and q.partner_id=p.id where p.id=u;
 if p_action='revoke_widget' then delete from nido_private.art_widget_tokens where user_id=u; return '{}'; end if;
 if partner is null then raise exception 'Vincula primero tu cuenta con tu pareja'; end if;
 if p_action='widget_token' then
  token:=encode(extensions.gen_random_bytes(32),'hex');
  insert into nido_private.art_widget_tokens values(u,extensions.digest(token,'sha256'),now()+interval '30 days')
  on conflict(user_id) do update set token_hash=excluded.token_hash,expires_at=excluded.expires_at;
  return jsonb_build_object('token',token);
 elsif p_action='note' then
  if exists(select 1 from nido_private.partner_art_notes where sender=u and sent_at>now()-interval '5 seconds') then raise exception 'Espera unos segundos'; end if;
  art:=p_data->>'content';
  if p_data->>'kind'='text' then
   if length(trim(art)) not between 1 and 500 then raise exception 'Escribe hasta 500 caracteres'; end if;
  elsif p_data->>'kind'='image' then
   if not nido_private.valid_art_png(art) then raise exception 'Imagen PNG no válida o demasiado grande'; end if;
  else raise exception 'Tipo no válido'; end if;
  insert into nido_private.partner_art_notes values(u,partner,p_data->>'kind',art,now())
  on conflict(sender) do update set recipient=excluded.recipient,kind=excluded.kind,content=excluded.content,sent_at=now();
  return jsonb_build_object('sent',true);
 elsif p_action='inbox' then
  select to_jsonb(n)-'recipient' into result from nido_private.partner_art_notes n where sender=partner and recipient=u;
  if result->>'sent_at'=p_data->>'sent_at' then return '{"unchanged":true}'; end if;
  return coalesce(result,'{}');
 elsif p_action='create' then
  if (select count(*) from nido_private.art_rooms where host=u and created_at>now()-interval '1 day')>=20 then raise exception 'Máximo 20 partidas al día'; end if;
  art:=nullif(p_data->>'reference_image','');
  if art is not null and (not nido_private.valid_art_png(art)) then raise exception 'Referencia PNG no valida'; end if;
  insert into nido_private.art_rooms(code,host,guest,difficulty,scene,reference_protocol)
  values(upper(left(replace(gen_random_uuid()::text,'-',''),8)),u,partner,(p_data->>'difficulty')::int,coalesce((p_data->>'scene')::int,floor(random()*12)::int),case when p_data->>'protocol'='2' then 2 else 1 end) returning * into r;
  if art is not null then update nido_private.art_rooms set reference_image=art,reference_title=left(coalesce(p_data->>'reference_title','Nuestro recuerdo'),160),reference_style=coalesce(p_data->>'reference_style','photo') where id=r.id returning * into r; end if;
 elsif p_action='join' then
  select * into r from nido_private.art_rooms where guest=u and host=partner and deadline is null and created_at>now()-interval '30 minutes' order by created_at desc limit 1;
  if r.id is null then raise exception 'Tu pareja debe crear una partida primero'; end if;
 else
  select * into r from nido_private.art_rooms where id=(p_data->>'id')::uuid and ((host=u and guest=partner) or (guest=u and host=partner)) and created_at>now()-interval '30 days' for update;
  if r.id is null then raise exception 'Partida no disponible'; end if;
  if p_action='ready' and r.deadline is null then
   update nido_private.art_rooms set host_ready=host_ready or host=u,guest_ready=guest_ready or guest=u where id=r.id returning * into r;
   if r.reference_protocol=1 and r.host_ready and r.guest_ready then update nido_private.art_rooms set deadline=now()+interval '5 minutes',reference_revealed_at=now() where id=r.id returning * into r;end if;
   if r.host_ready and r.guest_ready and r.reference_revealed_at is null then update nido_private.art_rooms set reference_revealed_at=now() where id=r.id returning * into r; end if;
  elsif p_action='reference_ready' then
   if r.reference_revealed_at is null then raise exception 'Esperen a estar ambos listos';end if;
   update nido_private.art_rooms set host_reference_loaded=host_reference_loaded or host=u,guest_reference_loaded=guest_reference_loaded or guest=u where id=r.id returning * into r;
   if r.host_reference_loaded and r.guest_reference_loaded and r.deadline is null then update nido_private.art_rooms set deadline=now()+interval '5 minutes 3 seconds' where id=r.id returning * into r;end if;
  elsif p_action='submit' then
   if r.deadline is null or now()<r.deadline then raise exception 'Aún quedan minutos para dibujar'; end if;
   if now()>r.deadline+interval '10 minutes' then raise exception 'El plazo para enviar terminó. Puedes guardar tu dibujo'; end if;
   art:=p_data->>'content';
   if not nido_private.valid_art_png(art) then raise exception 'PNG no válido'; end if;
   update nido_private.art_rooms set host_art=case when host=u then coalesce(host_art,art) else host_art end,
    guest_art=case when guest=u then coalesce(guest_art,art) else guest_art end where id=r.id returning * into r;
  elsif p_action='vote' then
   if r.host_art is null or r.guest_art is null then raise exception 'Esperen los dos dibujos'; end if;
   if (p_data->>'winner')::uuid not in(r.host,r.guest) then raise exception 'Voto no válido'; end if;
   update nido_private.art_rooms set host_vote=case when host=u then coalesce(host_vote,(p_data->>'winner')::uuid) else host_vote end,
    guest_vote=case when guest=u then coalesce(guest_vote,(p_data->>'winner')::uuid) else guest_vote end where id=r.id returning * into r;
  elsif p_action<>'status' then raise exception 'Acción no válida'; end if;
 end if;
 if r.host_art is not null and r.guest_art is not null and r.deadline is not null and now()>=r.deadline then
  for member in select x from unnest(array[r.host,r.guest]) x order by x loop
   perform pg_advisory_xact_lock(hashtextextended('art-reward:'||member::text,0));
   if not exists(select 1 from nido_private.art_rewards where room_id=r.id and user_id=member) then
    select coalesce(sum(a.amount),0) into earned from nido_private.art_rewards a where a.user_id=member and a.created_at>=date_trunc('day',now());
    amount:=least(10+r.difficulty*5,greatest(0,100-earned));
    insert into nido_private.art_rewards(room_id,user_id,amount) values(r.id,member,amount);
    insert into public.game_stats(user_id,love_coins,total_games_played,total_coins_earned) values(member,amount,1,amount)
     on conflict(user_id) do update set love_coins=game_stats.love_coins+excluded.love_coins,total_games_played=game_stats.total_games_played+1,total_coins_earned=game_stats.total_coins_earned+excluded.total_coins_earned,updated_at=now();
   end if;
  end loop;
 end if;
 -- Only a mutually agreed vote counts as a drawing victory; never trust a client visual score.
 if r.host_vote is not null and r.host_vote=r.guest_vote and r.deadline is not null and now()>=r.deadline then
  for member in select x from unnest(array[r.host,r.guest]) x order by x loop
   perform pg_advisory_xact_lock(hashtextextended('art-reward:'||member::text,0));
   select a.amount into amount from nido_private.art_rewards a where a.room_id=r.id and a.user_id=member;
   select coalesce(sum(a.amount),0) into earned from nido_private.art_rewards a where a.user_id=member and a.created_at>=date_trunc('day',now());
   if amount is not null then
    extra:=nido_private.record_bonus(member,'art','wins:'||r.difficulty,r.id::text,0,amount,amount+greatest(0,100-earned),member=r.host_vote);
    if extra>0 then
     update nido_private.art_rewards a set amount=a.amount+extra where a.room_id=r.id and a.user_id=member;
     update public.game_stats set love_coins=love_coins+extra,total_coins_earned=total_coins_earned+extra,updated_at=now() where user_id=member;
    end if;
   end if;
  end loop;
 end if;
 result:=(to_jsonb(r)-'host_art'-'guest_art'-'reference_image')||jsonb_build_object('host_submitted',r.host_art is not null,'guest_submitted',r.guest_art is not null);
 if p_action in ('create','join') or coalesce((p_data->>'download')::boolean,false) then result:=result||jsonb_build_object('reference_image',r.reference_image); end if;
 -- No peeking: opponent art only revealed after both submissions; own art is recoverable.
 if p_action not in ('status','ready') or coalesce((p_data->>'download')::boolean,false) or not coalesce((p_data->>'compact')::boolean,false) then
 if r.host_art is not null and r.guest_art is not null then result:=result||jsonb_build_object('host_art',r.host_art,'guest_art',r.guest_art);
 elsif u=r.host then result:=result||jsonb_build_object('host_art',r.host_art);
 else result:=result||jsonb_build_object('guest_art',r.guest_art); end if;
 end if;
 if r.id is not null and r.reference_protocol=2 and r.reference_revealed_at is null then result:=result-'reference_image'-'reference_title';end if;
 return result||jsonb_build_object('reward',(select a.amount from nido_private.art_rewards a where a.room_id=r.id and a.user_id=u),'server_now',now())||nido_private.record_receipt(u,'art','wins:'||r.difficulty,r.id::text);
end $function$;
