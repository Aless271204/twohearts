begin;
create table nido_private.duo_lobbies (
 user_id uuid primary key references public.user_profiles(id) on delete cascade,
 game text not null check(game in('pong','quiz')),
 mode text not null check(mode in('create','random')),
 code text not null unique,
 expires_at timestamptz not null,
 match_id uuid references public.duo_matches(id)
);
alter table nido_private.duo_lobbies enable row level security;
revoke all on nido_private.duo_lobbies from public,anon,authenticated;
create table nido_private.duo_online_matches(match_id uuid primary key references public.duo_matches(id) on delete cascade);
alter table nido_private.duo_online_matches enable row level security;
revoke all on nido_private.duo_online_matches from public,anon,authenticated;
-- Only server-created online matches can bypass the couple-only relationship check.
do $patch$
declare src text; original text := 'if not exists(select 1 from public.user_profiles a join public.user_profiles b on a.partner_id=b.id and b.partner_id=a.id where a.id=m.player_a and b.id=m.player_b) then';
begin
 select pg_get_functiondef('public.duo_tick(uuid,double precision,integer,integer,text)'::regprocedure) into src;
 if position(original in src)=0 then raise exception 'Unexpected duo_tick version';end if;
 execute replace(src,original,'if not exists(select 1 from nido_private.duo_online_matches where match_id=m.id) and not exists(select 1 from public.user_profiles a join public.user_profiles b on a.partner_id=b.id and b.partner_id=a.id where a.id=m.player_a and b.id=m.player_b) then');
end $patch$;
create function nido_private.duo_lobby(p_action text,p_game text,p_code text default '') returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); mine nido_private.duo_lobbies; other nido_private.duo_lobbies; mid uuid; a uuid;b uuid;qs jsonb;st jsonb;
begin
 if u is null then raise exception 'Inicia sesión para jugar' using errcode='42501';end if;
 if p_game not in('pong','quiz') or p_action not in('create','random','join','poll','leave') then raise exception 'Sala no válida';end if;
 perform pg_advisory_xact_lock(hashtextextended('nido-online-lobbies',0));
 if p_action='leave' then
  select * into mine from nido_private.duo_lobbies where user_id=u;
  if mine.match_id is not null then perform public.duo_leave(mine.match_id);end if;
  delete from nido_private.duo_lobbies where user_id=u;
  return jsonb_build_object('left',true);
 end if;
 select * into mine from nido_private.duo_lobbies where user_id=u;
 if mine.match_id is not null then
  if exists(select 1 from public.duo_matches where id=mine.match_id and status in('waiting','playing')) then return public.duo_tick(mine.match_id);end if;
  delete from nido_private.duo_lobbies where user_id=u;mine:=null;
 end if;
 delete from nido_private.duo_lobbies where match_id is null and expires_at<clock_timestamp();
 select * into mine from nido_private.duo_lobbies where user_id=u;
 if p_action='poll' then
  if mine.user_id is null then raise exception 'La sala caducó. Vuelve a crearla.';end if;
  update nido_private.duo_lobbies set expires_at=clock_timestamp()+interval '35 seconds' where user_id=u;
  return jsonb_build_object('lobby',true,'code',case when mine.mode='create' then mine.code else null end);
 end if;
 if p_action='join' then
  select * into other from nido_private.duo_lobbies where code=upper(trim(p_code)) and game=p_game and mode='create' and user_id<>u and match_id is null and expires_at>clock_timestamp() for update;
  if not found then raise exception 'Código de sala no disponible';end if;
 elsif p_action='random' then
  select * into other from nido_private.duo_lobbies where game=p_game and mode='random' and user_id<>u and match_id is null and expires_at>clock_timestamp() order by expires_at limit 1 for update;
 end if;
 if other.user_id is null then
  insert into nido_private.duo_lobbies(user_id,game,mode,code,expires_at)
  values(u,p_game,p_action,upper(substr(replace(gen_random_uuid()::text,'-',''),1,8)),clock_timestamp()+interval '35 seconds')
  on conflict(user_id) do update set game=excluded.game,mode=excluded.mode,expires_at=excluded.expires_at,match_id=null returning * into mine;
  return jsonb_build_object('lobby',true,'code',case when mine.mode='create' then mine.code else null end);
 end if;
 a:=least(u,other.user_id);b:=greatest(u,other.user_id);
 -- Reuse an existing active match between these same participants, never a third account.
 select id into mid from public.duo_matches where player_a=a and player_b=b and game=p_game and status in('waiting','playing');
 if mid is null then
  select jsonb_agg(id) into qs from(select id from public.duo_questions order by random())q;
  st:=jsonb_build_object('ready_a',true,'ready_b',true,'round',1,'wins_a',0,'wins_b',0,'score_a',0,'score_b',0,'phase','countdown','deadline',extract(epoch from clock_timestamp())+3,'question_no',0,'questions',qs,'x',0.5,'y',0.5,'vx',0.35,'vy',0.48,'paddle_a',0.5,'paddle_b',0.5);
  insert into public.duo_matches(game,player_a,player_b,status,state,heartbeat_b) values(p_game,a,b,'playing',st,clock_timestamp()) returning id into mid;
 end if;
 insert into nido_private.duo_online_matches values(mid) on conflict do nothing;
 update nido_private.duo_lobbies set match_id=mid where user_id=other.user_id;
 insert into nido_private.duo_lobbies(user_id,game,mode,code,expires_at,match_id)
 values(u,p_game,'random',upper(substr(replace(gen_random_uuid()::text,'-',''),1,8)),clock_timestamp()+interval '35 seconds',mid)
 on conflict(user_id) do update set match_id=mid,game=p_game;
 return public.duo_tick(mid);
end $$;
create function public.duo_lobby(p_action text,p_game text,p_code text default '') returns jsonb language sql security invoker set search_path='' as $$select nido_private.duo_lobby(p_action,p_game,p_code)$$;
revoke all on function nido_private.duo_lobby(text,text,text),public.duo_lobby(text,text,text) from public,anon;
grant execute on function nido_private.duo_lobby(text,text,text),public.duo_lobby(text,text,text) to authenticated;
commit;
