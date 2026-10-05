create or replace function public.duo_tick(p_match_id uuid,p_paddle double precision default null,p_choice integer default null,p_question_no integer default null,p_phase text default null) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();m public.duo_matches;st jsonb;phase text;ts double precision:=extract(epoch from clock_timestamp());qn integer;qa public.duo_answers;qb public.duo_answers;sa integer;sb integer;wa integer;wb integer;round_n integer;question public.duo_questions;uid uuid;reward integer;earned integer;paused boolean;old_st jsonb;
begin
 select * into m from public.duo_matches where id=p_match_id for update;
 if u is null or not found or u not in(m.player_a,m.player_b) then raise exception 'No tienes acceso a esta partida' using errcode='42501';end if;
 if not exists(select 1 from public.user_profiles a join public.user_profiles b on a.partner_id=b.id and b.partner_id=a.id where a.id=m.player_a and b.id=m.player_b) then raise exception 'La pareja ya no está vinculada';end if;
 if u=m.player_a then m.heartbeat_a:=clock_timestamp();else m.heartbeat_b:=clock_timestamp();end if;
 st:=m.state;phase:=st->>'phase';qn:=(st->>'question_no')::int;
 paused:=m.status='playing' and (m.heartbeat_a<clock_timestamp()-interval '4 seconds' or m.heartbeat_b is null or m.heartbeat_b<clock_timestamp()-interval '4 seconds');
 if paused then st:=st||jsonb_build_object('paused',true,'deadline',ts+15);
 elsif st->>'paused'='true' then st:=st||jsonb_build_object('paused',false,'deadline',ts+case when phase='countdown' then 3 else 15 end);
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
  elsif phase='countdown' and ts>=(st->>'deadline')::float8 then st:=st||jsonb_build_object('phase',case when m.game='pong' then 'play' else 'self' end,'deadline',ts+15);
  elsif m.game='quiz' and phase='self' and (ts>=(st->>'deadline')::float8 or (qa.self_choice is not null and qb.self_choice is not null)) then st:=st||jsonb_build_object('phase','guess','deadline',ts+15);
  elsif m.game='quiz' and phase='guess' and (ts>=(st->>'deadline')::float8 or (qa.guess is not null and qb.guess is not null)) then
   sa:=(st->>'score_a')::int+case when qa.guess=qb.self_choice then 1 else 0 end;sb:=(st->>'score_b')::int+case when qb.guess=qa.self_choice then 1 else 0 end;
   st:=st||jsonb_build_object('score_a',sa,'score_b',sb,'phase','reveal','deadline',ts+4,'answer_a',qa.self_choice,'answer_b',qb.self_choice,'guess_a',qa.guess,'guess_b',qb.guess);
  elsif m.game='quiz' and phase='reveal' and ts>=(st->>'deadline')::float8 then
   sa:=(st->>'score_a')::int;sb:=(st->>'score_b')::int;
   round_n:=coalesce((st->>'round_questions')::int,0)+1;
   if round_n>=5 and sa<>sb then
    wa:=(st->>'wins_a')::int+case when sa>sb then 1 else 0 end;wb:=(st->>'wins_b')::int+case when sb>sa then 1 else 0 end;
    st:=st||jsonb_build_object('wins_a',wa,'wins_b',wb,'round',(st->>'round')::int+1,'score_a',0,'score_b',0);round_n:=0;
    if greatest(wa,wb)=2 then m.status:='finished';m.winner:=case when wa>wb then m.player_a else m.player_b end;end if;
   end if;
   st:=(st-'answer_a'-'answer_b'-'guess_a'-'guess_b')||jsonb_build_object('question_no',qn+1,'round_questions',round_n,'phase','self','deadline',ts+15);qn:=qn+1;qa:=null;qb:=null;
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
    insert into public.duo_rewards(match_id,user_id,coins) values(m.id,uid,reward);
    update public.game_stats set love_coins=love_coins+reward,total_coins_earned=total_coins_earned+reward,total_games_played=total_games_played+1,updated_at=now() where user_id=uid;
   end if;
  end loop;
  select coins into reward from public.duo_rewards where match_id=m.id and user_id=u;
 end if;
 update public.duo_matches set state=st,status=m.status,winner=m.winner,heartbeat_a=m.heartbeat_a,heartbeat_b=m.heartbeat_b,last_tick=clock_timestamp() where id=m.id;
 -- Return my lock status only. Never return the other player's secret selections.
 st:=st-'questions';
 if m.game='quiz' then
  select * into question from public.duo_questions where id=(m.state->'questions'->>(qn%jsonb_array_length(m.state->'questions')))::int;
  st:=st||jsonb_build_object('question',jsonb_build_object('category',question.category,'prompt',question.prompt,'options',question.options),'my_choice',case when st->>'phase'='self' then case when u=m.player_a then qa.self_choice else qb.self_choice end when st->>'phase'='guess' then case when u=m.player_a then qa.guess else qb.guess end else null end);
 end if;
 return jsonb_build_object('id',m.id,'game',m.game,'side',case when u=m.player_a then 'a' else 'b' end,'status',m.status,'winner',m.winner,'server_time',ts,'reward',reward,'state',st);
end $$;
