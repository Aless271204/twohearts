-- Four cute power-ups, negotiated by both clients. Old clients retain two.
-- Twenty seconds for each quiz response; existing access checks/rewards retained.
CREATE OR REPLACE FUNCTION public.duo_pong_step(st jsonb, dt double precision)
 RETURNS jsonb
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO ''
AS $function$
declare x double precision:=(st->>'x')::float8;y double precision:=(st->>'y')::float8;vx double precision:=(st->>'vx')::float8;vy double precision:=(st->>'vy')::float8;old_y double precision;p double precision;hit double precision;sa integer:=(st->>'score_a')::int;sb integer:=(st->>'score_b')::int;steps integer;i integer;step_dt double precision;
 clock double precision:=coalesce((st->>'power_clock')::float8,0);
 wide_a double precision:=greatest(0,coalesce((st->>'wide_a')::float8,0)-least(greatest(dt,0),.25));
 wide_b double precision:=greatest(0,coalesce((st->>'wide_b')::float8,0)-least(greatest(dt,0),.25));
 shield_a boolean:=coalesce((st->>'shield_a')::boolean,false);shield_b boolean:=coalesce((st->>'shield_b')::boolean,false);
 enabled boolean:=coalesce((st->>'powerups_enabled')::boolean,false);
 extended boolean:=coalesce((st->>'powerups_v2')::boolean,false);
 tempo_remaining double precision:=greatest(0,coalesce((st->>'tempo_remaining')::float8,0)-least(greatest(dt,0),.25));
 tempo_kind integer:=coalesce((st->>'tempo_kind')::integer,0);rate double precision:=1;
 power_n integer:=coalesce((st->>'power_n')::integer,0);kind integer:=coalesce((st->>'power_kind')::integer,0);
 power_x double precision:=coalesce((st->>'power_x')::float8,.5);last_hit text:=st->>'last_hit';

begin
 steps:=greatest(1,ceil(least(greatest(dt,0),0.25)/0.01)::int);step_dt:=least(greatest(dt,0),0.25)/steps;
 clock:=clock+least(greatest(dt,0),.25);
 if not extended and kind>2 then kind:=0;end if;
 if extended and tempo_remaining>0 then rate:=case when tempo_kind=3 then 1.3 when tempo_kind=4 then .72 else 1 end;else tempo_kind:=0;end if;
 if enabled and floor(clock/8)>power_n then power_n:=floor(clock/8);kind:=1+(power_n%case when extended then 4 else 2 end);power_x:=.5+sin(power_n*2.399)*.25;end if;
 if clock-power_n*8>5 then kind:=0;end if;
 for i in 1..steps loop
  old_y:=y;x:=x+vx*step_dt*rate;y:=y+vy*step_dt*rate;
  if x<0.025 then x:=0.05-x;vx:=abs(vx);elsif x>0.975 then x:=1.95-x;vx:=-abs(vx);end if;
  if vy>0 and old_y<0.9 and y>=0.9 then p:=(st->>'paddle_a')::float8;hit:=x-p;if abs(hit)<=(case when enabled and wide_a>0 then .195 else .135 end) then last_hit:='a';y:=1.8-y;vy:=-least(abs(vy)*1.035,0.85);vx:=greatest(-0.7,least(0.7,hit*4));end if;
  elsif vy<0 and old_y>0.1 and y<=0.1 then p:=(st->>'paddle_b')::float8;hit:=x-p;if abs(hit)<=(case when enabled and wide_b>0 then .195 else .135 end) then last_hit:='b';y:=0.2-y;vy:=least(abs(vy)*1.035,0.85);vx:=greatest(-0.7,least(0.7,hit*4));end if;end if;
  if enabled and kind>0 and last_hit in ('a','b') and abs(x-power_x)<.055 and abs(y-.5)<.055 then
   if kind=1 then if last_hit='a' then wide_a:=6;else wide_b:=6;end if;
   elsif kind=2 then if last_hit='a' then shield_a:=true;else shield_b:=true;end if;
   elsif extended and kind in(3,4) then tempo_kind:=kind;tempo_remaining:=4;rate:=case when kind=3 then 1.3 else .72 end;
   end if;kind:=0;
  end if;
  if enabled and y>.98 and shield_a then y:=.98;vy:=-abs(vy);shield_a:=false;
  elsif enabled and y<.02 and shield_b then y:=.02;vy:=abs(vy);shield_b:=false;end if;
  if y>1.05 then sb:=sb+1;exit;elsif y< -0.05 then sa:=sa+1;exit;end if;
 end loop;
 return st||jsonb_build_object('x',x,'y',y,'vx',vx,'vy',vy,'score_a',sa,'score_b',sb,'power_clock',clock,'power_n',power_n,'power_kind',kind,'power_x',power_x,'last_hit',last_hit,'wide_a',wide_a,'wide_b',wide_b,'shield_a',shield_a,'shield_b',shield_b,'tempo_kind',tempo_kind,'tempo_remaining',tempo_remaining,'tempo_rate',rate);
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
 elsif st->>'paused'='true' then st:=st||jsonb_build_object('paused',false,'deadline',ts+case when phase='countdown' then 3 when m.game='quiz' then 20 else 15 end);
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
   st:=st||jsonb_build_object('score_a',sa,'score_b',sb,'phase','reveal','deadline',ts+4,'answer_a',qa.self_choice,'answer_b',qb.self_choice,'guess_a',qa.guess,'guess_b',qb.guess);
  elsif m.game='quiz' and phase='reveal' and ts>=(st->>'deadline')::float8 then
   sa:=(st->>'score_a')::int;sb:=(st->>'score_b')::int;
   round_n:=coalesce((st->>'round_questions')::int,0)+1;
   if round_n>=5 and sa<>sb then
    wa:=(st->>'wins_a')::int+case when sa>sb then 1 else 0 end;wb:=(st->>'wins_b')::int+case when sb>sa then 1 else 0 end;
    st:=st||jsonb_build_object('wins_a',wa,'wins_b',wb,'round',(st->>'round')::int+1,'score_a',0,'score_b',0);round_n:=0;
    if greatest(wa,wb)=2 then m.status:='finished';m.winner:=case when wa>wb then m.player_a else m.player_b end;end if;
   end if;
   st:=(st-'answer_a'-'answer_b'-'guess_a'-'guess_b')||jsonb_build_object('question_no',qn+1,'round_questions',round_n,'phase','self','deadline',ts+20);qn:=qn+1;qa:=null;qb:=null;
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
 if m.game='pong' then st:=st||jsonb_build_object('opponent_paddle_color',(select s.appearance->>'color' from public.shop_items s join public.owned_items o on o.item_key=s.item_key where o.user_id=case when u=m.player_a then m.player_b else m.player_a end and o.equipped and s.equip_slot='pong_paddle' and s.active));end if;
 if m.game='quiz' then
  select * into question from public.duo_questions where id=(m.state->'questions'->>(qn%jsonb_array_length(m.state->'questions')))::int;
  st:=st||jsonb_build_object('question',jsonb_build_object('category',question.category,'prompt',question.prompt,'options',question.options),'my_choice',case when st->>'phase'='self' then case when u=m.player_a then qa.self_choice else qb.self_choice end when st->>'phase'='guess' then case when u=m.player_a then qa.guess else qb.guess end else null end);
 end if;
 return jsonb_build_object('id',m.id,'game',m.game,'side',case when u=m.player_a then 'a' else 'b' end,'status',m.status,'winner',m.winner,'server_time',ts,'reward',reward,'players',nido_private.duo_players(m.id),'state',st);
end $function$;
