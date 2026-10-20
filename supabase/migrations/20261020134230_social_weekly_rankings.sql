-- Rankings read settlement receipts; clients never submit scores here.
create table nido_private.ranking_preferences (
 user_id uuid primary key references auth.users(id) on delete cascade,
 global_visible boolean not null default false
);
alter table nido_private.ranking_preferences enable row level security;
revoke all on nido_private.ranking_preferences from public,anon,authenticated;
create index game_record_week_lookup on nido_private.game_record_receipts(game,scope,created_at,user_id);

create function nido_private.weekly_ranking(p_game text,p_audience text,p_scope text,p_visible boolean default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); start_at timestamptz; end_at timestamptz; result jsonb; visible boolean;
begin
 if u is null then raise exception 'Inicia sesión para ver el ranking' using errcode='42501';end if;
 if p_game is null or p_audience is null or p_scope is null or p_game not in ('pebble_runner','guardian','pong','quiz','penalties','maze','art') or p_audience not in ('friends','global') or length(p_scope)>80 then raise exception 'Ranking no válido';end if;
 if p_game='pebble_runner' and p_scope<>'distance' or p_game in ('pong','quiz','penalties') and p_scope<>'wins'
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
  where game=p_game and scope=p_scope and created_at>=start_at and created_at<end_at
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
end $$;
create function public.social_weekly_ranking(p_game text default 'pebble_runner',p_audience text default 'friends',p_scope text default 'distance',p_visible boolean default null)
returns jsonb language sql security invoker set search_path='' as $$select nido_private.weekly_ranking(p_game,p_audience,p_scope,p_visible)$$;
revoke all on function nido_private.weekly_ranking(text,text,text,boolean),public.social_weekly_ranking(text,text,text,boolean) from public,anon;
grant execute on function nido_private.weekly_ranking(text,text,text,boolean),public.social_weekly_ranking(text,text,text,boolean) to authenticated;
