-- Preserve historical receipts and balances. Non-hard results no longer qualify for record bonuses or weekly rankings in difficulty-based games.
CREATE OR REPLACE FUNCTION nido_private.record_bonus(p_user uuid, p_game text, p_scope text, p_run text, p_score bigint, p_base integer, p_capacity integer, p_win boolean DEFAULT NULL::boolean)
 RETURNS integer
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare previous nido_private.game_record_scores; score bigint; extra integer; beaten boolean;
begin
 if p_user is null or p_game not in ('pebble_runner','guardian','pong','quiz','penalties','maze','art','snow') or p_scope is null or p_run is null or p_base<0 or p_capacity<0 then raise exception 'Invalid record settlement';end if;

 -- Only hard-mode settlements qualify in games that expose a difficulty.
 if (p_game in ('guardian','maze') and split_part(p_scope,':',1)<>'hard')
   or (p_game='art' and p_scope<>'wins:2') then return 0; end if;
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
end $function$
;
CREATE OR REPLACE FUNCTION nido_private.weekly_ranking(p_game text, p_audience text, p_scope text, p_visible boolean DEFAULT NULL::boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid:=auth.uid(); start_at timestamptz; end_at timestamptz; result jsonb; visible boolean;
begin
 if u is null then raise exception 'Inicia sesión para ver el ranking' using errcode='42501';end if;
 if p_game is null or p_audience is null or p_scope is null or p_game not in ('pebble_runner','guardian','pong','quiz','penalties','maze','art','snow') or p_audience not in ('friends','global') or length(p_scope)>80 then raise exception 'Ranking no válido';end if;
 if p_game='snow' and p_scope<>'scores' or p_game='pebble_runner' and p_scope<>'distance' or p_game in ('pong','quiz','penalties') and p_scope<>'wins'
 or p_game='guardian' and p_scope!~'^(easy|medium|hard):(solo|partner):(forest|river)$'
 or p_game='maze' and p_scope!~'^(easy|medium|hard):(solo|partner)$'
 or p_game='art' and p_scope!~'^wins:[012]$' then raise exception 'Categoría no válida';end if;
 if p_visible is not null then
  insert into nido_private.ranking_preferences values(u,p_visible)
  on conflict(user_id) do update set global_visible=excluded.global_visible;
 end if;
 select coalesce((select global_visible from nido_private.ranking_preferences where user_id=u),false) into visible;
 start_at:=date_trunc('week',clock_timestamp() at time zone 'America/Bogota') at time zone 'America/Bogota';
 end_at:=start_at+interval '7 days';
 with receipts as (
  select user_id,run,score,created_at,
    sum(case when score=0 then 1 else 0 end) over(partition by user_id order by created_at,run) loss_group
  from nido_private.game_record_receipts
  where game=p_game and scope=p_scope
    and (p_game not in ('guardian','maze','art') or p_game in ('guardian','maze') and split_part(scope,':',1)='hard' or p_game='art' and scope='wins:2')
    and created_at>=start_at and created_at<end_at
 ), metrics as (
  select user_id,case when p_game in ('pong','quiz','penalties','art') then
    count(*) filter(where score>0) over(partition by user_id,loss_group order by created_at,run)
    else score end metric from receipts
 ), best as (select user_id,max(metric) score from metrics group by user_id),
 eligible as (
  select b.user_id,b.score,left(coalesce(nullif(p.nickname,''),nullif(p.full_name,''),'Jugador de NIDO'),64) name
  from best b join public.user_profiles p on p.id=b.user_id
  where not exists(select 1 from public.social_blocks bl where (bl.user_id=u and bl.blocked_id=b.user_id) or (bl.user_id=b.user_id and bl.blocked_id=u))
   and case when p_audience='global' then exists(select 1 from nido_private.ranking_preferences rp where rp.user_id=b.user_id and rp.global_visible)
    else b.user_id=u or exists(select 1 from public.user_profiles me where me.id=u and me.partner_id=b.user_id and p.partner_id=u)
      or (exists(select 1 from public.social_follows f where f.follower_id=u and f.following_id=b.user_id)
       and exists(select 1 from public.social_follows f where f.follower_id=b.user_id and f.following_id=u)) end
 ), ranked as (select *,dense_rank() over(order by score desc) position from eligible),
 limited as (select * from ranked order by position,name,user_id limit 50)
 select jsonb_build_object('week_start',start_at,'week_end',end_at,'server_now',clock_timestamp(),'global_visible',visible,
  'rows',coalesce((select jsonb_agg(jsonb_build_object('rank',position,'name',name,'score',score,'is_me',user_id=u) order by position,name,user_id) from limited),'[]'::jsonb),
  'mine',(select jsonb_build_object('score',b.score,'rank',(select position from ranked where user_id=u)) from best b where b.user_id=u)) into result;
 return result;
end $function$
;
