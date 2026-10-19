-- New settlements only; historical balances and saved run results are preserved.
-- Runner: 50 points per coin. Guardian: 20 points per expedition coin, solo half.
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
    'best_distance',v_best,'love_coins',v_stats.love_coins,'xp',v_stats.xp,'level',v_stats.level);
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
 maxreward:=100;
 if r.mode='partner' then maxreward:=maxreward*2; end if;
 if r.status<>'running' or p_reward<0 or p_reward>maxreward or p_frames<600 or p_frames>21600 or p_hash is null or p_hash!~'^[a-f0-9]{64}$' or now()<r.started_at+make_interval(secs=>p_frames/60.0-3) or now()>r.started_at+interval '15 minutes' then raise exception 'Partida no válida'; end if;
 if r.mode='partner' and (r.guest_id is null or r.confirmed_hash is distinct from p_hash) then raise exception 'Falta la confirmación de tu pareja'; end if;
 for u in select x from unnest(array[r.host_id,r.guest_id]) as x where x is not null order by x loop
  perform pg_advisory_xact_lock(hashtextextended('guardian-reward:'||u::text,0));
  select coalesce(sum(g.amount),0) into earned from nido_private.guardian_rewards g where g.user_id=u and g.created_at>=date_trunc('day',now());
  -- p_reward is the expedition total, not a duplicated per-player award.
  amount:=least(case when r.mode='partner' then p_reward/2+case when u=r.host_id then p_reward%2 else 0 end else p_reward end,greatest(0,200-earned));
  insert into nido_private.guardian_rewards values(r.id,u,amount,now());
  insert into public.game_stats(user_id,love_coins,total_games_played,total_coins_earned) values(u,amount,1,amount) on conflict(user_id) do update set love_coins=game_stats.love_coins+excluded.love_coins,total_games_played=game_stats.total_games_played+1,total_coins_earned=game_stats.total_coins_earned+excluded.total_coins_earned,updated_at=now();
  if u=p_user_id then result:=jsonb_build_object('saved',true,'reward',amount); end if;
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


CREATE OR REPLACE FUNCTION nido_private.guardian_room(p_action text, p_id uuid, p_code text, p_difficulty text, p_species text, p_packets jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid:=auth.uid(); r nido_private.guardian_rooms; item jsonb; n integer; oldmask integer; hash text; pets jsonb; look jsonb;
begin
 if u is null then raise exception 'Inicia sesión para jugar'; end if;
 if p_action='profile' then pets:=nido_private.pet_family_snapshot();return jsonb_build_object('species',pets->>'species','pets',pets->'pets','loadout',(select coalesce(jsonb_agg(jsonb_build_object('item_key',e->>'item_key','color',e->'appearance'->>'garment_color')),'[]'::jsonb) from jsonb_array_elements(public.shared_pet_snapshot()->'equipment') e where e->>'scope'='pet'));end if;
 if p_action in ('create','solo','join') then pets:=nido_private.pet_family_snapshot();if not exists(select 1 from jsonb_array_elements(pets->'pets') x where x->>'species'=p_species) then raise exception 'Adopta esta mascota en NIDO antes de elegirla';end if;end if;
 if p_action in ('create','solo','join') and p_species not in ('penguin','bear','pig','chick') then raise exception 'Mascota inválida'; end if;
 if p_action in ('create','solo','join') then
  select coalesce(jsonb_agg(jsonb_build_object('item_key',e->>'item_key','color',e->'appearance'->>'garment_color')),'[]'::jsonb) into look from jsonb_array_elements(public.shared_pet_snapshot()->'equipment') e where e->>'scope'='pet';
 end if;
 if p_action in ('create','solo') then
  if p_difficulty not in ('easy','medium','hard') then raise exception 'Dificultad inválida'; end if;
  perform pg_advisory_xact_lock(hashtextextended('guardian-create:'||u::text,0));
  if (select count(*) from nido_private.guardian_rooms where host_id=u and created_at>now()-interval '10 minutes')>=15 then raise exception 'Espera un momento antes de crear otra sala'; end if;
  insert into nido_private.guardian_rooms(code,host_id,mode,difficulty,seed,host_species,status,started_at,host_ready,host_loadout,engine_version)
  values(upper(substr(replace(gen_random_uuid()::text,'-',''),1,8)),u,case when p_action='solo' then 'solo' else 'partner' end,p_difficulty,floor(random()*4294967295)::bigint,p_species,case when p_action='solo' then 'running' else 'waiting' end,case when p_action='solo' then now() else null end,p_action='solo',look,case when p_packets->>'engine_version'='4' and p_packets->>'chapter'='river' then 4 when p_packets->>'engine_version' in ('3','4') then 3 else 2 end) returning * into r;
 elsif p_action='join' then
  insert into nido_private.guardian_join_limits values(u,date_trunc('minute',now()),1) on conflict(user_id) do update set
   attempts=case when guardian_join_limits.bucket=date_trunc('minute',now()) then guardian_join_limits.attempts+1 else 1 end,bucket=date_trunc('minute',now()) returning attempts into n;
  if n>20 then return jsonb_build_object('error','Demasiados intentos; espera un minuto'); end if;
  select * into r from nido_private.guardian_rooms where code=upper(trim(p_code)) and mode='partner' and status='waiting' and created_at>now()-interval '15 minutes' for update;
  if r.engine_version=4 and coalesce(p_packets->>'engine_version','')<>'4' then return jsonb_build_object('error','Actualiza NIDO para jugar este capítulo');end if; if r.id is null or r.host_id=u or (r.guest_id is not null and r.guest_id<>u) then return jsonb_build_object('error','La sala no está disponible'); end if;
  update nido_private.guardian_rooms set guest_id=u,guest_species=p_species,guest_loadout=look where id=r.id returning * into r;
 else
  select * into r from nido_private.guardian_rooms where id=p_id and (host_id=u or guest_id=u) for update;
  if r.id is null then raise exception 'Sala no disponible'; end if;
  if r.created_at<now()-interval '30 minutes' and p_action<>'status' then raise exception 'La sala ha caducado'; end if;
  if p_action='ready' then
   if r.status<>'waiting' then return jsonb_build_object('status',r.status); end if;
   update nido_private.guardian_rooms set host_ready=host_ready or host_id=u,guest_ready=guest_ready or coalesce(guest_id=u,false) where id=r.id returning * into r;
   if r.engine_version=2 and r.host_ready and r.guest_ready then update nido_private.guardian_rooms set status='running',started_at=now()+interval '3 seconds' where id=r.id returning * into r; end if;
  elsif p_action='start' then
   if r.host_id<>u or r.status<>'waiting' or r.guest_id is null or not r.host_ready or not r.guest_ready then raise exception 'Ambos deben estar listos y el anfitrión debe iniciar';end if;
   update nido_private.guardian_rooms set status='running',started_at=now()+interval '3 seconds' where id=r.id returning * into r;
  elsif p_action='inputs' then
   if r.status not in ('running','finished') or jsonb_typeof(p_packets)<>'array' or jsonb_array_length(p_packets)>128 then raise exception 'Entradas inválidas'; end if;
   for item in select value from jsonb_array_elements(p_packets) loop
    if jsonb_typeof(item)<>'array' or jsonb_array_length(item)<>2 or (item->>0)!~'^[0-9]{1,5}$' or (item->>1)!~'^[0-9]{1,2}$' then raise exception 'Entrada inválida'; end if;
    select mask into oldmask from nido_private.guardian_inputs where room_id=r.id and user_id=u and seq=(item->>0)::int;
    if found and oldmask<>(item->>1)::int then raise exception 'La entrada ya está registrada'; end if;
    insert into nido_private.guardian_inputs values(r.id,u,(item->>0)::int,(item->>1)::int) on conflict do nothing;
   end loop;
  elsif p_action='confirm' then
   hash:=p_packets->>'hash';
   if r.guest_id<>u or r.mode<>'partner' or r.status<>'running' or hash is null or hash!~'^[a-f0-9]{64}$' then raise exception 'Confirmación inválida'; end if;
   if r.confirmed_hash is not null and r.confirmed_hash<>hash then raise exception 'La confirmación no coincide'; end if;
   update nido_private.guardian_rooms set confirmed_hash=hash where id=r.id returning * into r;
  elsif p_action='cancel' then
   update nido_private.guardian_rooms set status='cancelled' where id=r.id and status in ('waiting','running') returning * into r;
  elsif p_action<>'status' then raise exception 'Acción inválida'; end if;
 end if;
 return jsonb_build_object('id',r.id,'code',r.code,'mode',r.mode,'difficulty',r.difficulty,'seed',r.seed,'role',case when r.host_id=u then 0 else 1 end,'species',jsonb_build_array(r.host_species,coalesce(r.guest_species,'bear')),'loadouts',jsonb_build_array(r.host_loadout,r.guest_loadout),'engine_version',r.engine_version,'host_ready',r.host_ready,'guest_ready',r.guest_ready,'joined',r.guest_id is not null,'status',r.status,'started_at',r.started_at,'server_time',now(),'confirmed',r.confirmed_hash is not null,'prize',(select item_key from nido_private.guardian_clothing_prizes where room_id=r.id),'reward',(select amount from nido_private.guardian_rewards where room_id=r.id and user_id=u),'total_reward',(select coalesce(sum(gr.amount),0) from nido_private.guardian_rewards gr where gr.room_id=r.id));
end $function$;
