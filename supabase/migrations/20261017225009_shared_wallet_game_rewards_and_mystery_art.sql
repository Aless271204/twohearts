-- Reciprocal partners use one logical balance, backed by their existing subaccounts.
-- Linking adds balances without copying or deleting existing gold.
create or replace function nido_private.wallet_members(p_user uuid) returns uuid[]
language sql volatile security definer set search_path='' as $$
 select coalesce((select array_agg(x order by x) from (
   select p_user as x union
   select b.id from public.user_profiles a join public.user_profiles b on b.id=a.partner_id and b.partner_id=a.id where a.id=p_user
 ) members),array[p_user])
$$;
create or replace function nido_private.wallet_balance(p_user uuid) returns bigint
language sql volatile security definer set search_path='' as $$
 select coalesce(sum(g.love_coins),0)::bigint from public.game_stats g where g.user_id=any(nido_private.wallet_members(p_user))
$$;
create or replace function nido_private.wallet_lock(p_user uuid) returns void
language plpgsql security definer set search_path='' as $$
declare ids uuid[]; v uuid;
begin
 if p_user is null then raise exception 'Authentication required' using errcode='42501';end if;
 ids:=nido_private.wallet_members(p_user);
 -- Same order as account linking; recheck membership after obtaining profile locks.
 perform 1 from public.user_profiles where id=any(ids) order by id for update;
 if ids is distinct from nido_private.wallet_members(p_user) then raise exception 'La pareja cambió; vuelve a intentar' using errcode='40001';end if;
 foreach v in array ids loop insert into public.game_stats(user_id) values(v) on conflict(user_id) do nothing;end loop;
 perform 1 from public.game_stats where user_id=any(ids) order by user_id for update;
end $$;
create or replace function nido_private.wallet_spend(p_user uuid,p_amount integer) returns bigint
language plpgsql security definer set search_path='' as $$
declare left_to_spend integer:=p_amount; row record; take integer;
begin
 if p_amount is null or p_amount<0 then raise exception 'Importe inválido';end if;
 perform nido_private.wallet_lock(p_user);
 if nido_private.wallet_balance(p_user)<p_amount then raise exception 'No hay suficiente oro compartido';end if;
 for row in select user_id,love_coins from public.game_stats where user_id=any(nido_private.wallet_members(p_user)) order by (user_id=p_user) desc,user_id loop
  take:=least(row.love_coins,left_to_spend);
  update public.game_stats set love_coins=love_coins-take,updated_at=now() where user_id=row.user_id;
  left_to_spend:=left_to_spend-take;exit when left_to_spend=0;
 end loop;
 return nido_private.wallet_balance(p_user);
end $$;
revoke all on function nido_private.wallet_members(uuid),nido_private.wallet_balance(uuid),nido_private.wallet_lock(uuid),nido_private.wallet_spend(uuid,integer) from public,anon,authenticated;

create or replace function public.wallet_snapshot() returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); ids uuid[]; amount bigint;
begin
 if u is null then raise exception 'Inicia sesión' using errcode='42501';end if;
 ids:=nido_private.wallet_members(u);amount:=nido_private.wallet_balance(u);
 return jsonb_build_object('coins',amount,'shared',cardinality(ids)=2,'separation_share',floor(amount*.10)::bigint,'separation_percent',10);
end $$;
revoke all on function public.wallet_snapshot() from public,anon;
grant execute on function public.wallet_snapshot() to authenticated;

create table if not exists nido_private.wallet_separations(
 id uuid primary key default gen_random_uuid(),member_a uuid not null,member_b uuid not null,
 balance_before bigint not null,each_receives bigint not null,discarded bigint not null,created_at timestamptz not null default now());
alter table nido_private.wallet_separations enable row level security;
revoke all on nido_private.wallet_separations from public,anon,authenticated;
create or replace function public.wallet_unlink(p_expected_balance bigint,p_confirm boolean default false) returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();ids uuid[]; amount bigint; share bigint;
begin
 if u is null or p_confirm is distinct from true then raise exception 'Confirma la separación y su reparto de oro' using errcode='42501';end if;
 perform nido_private.wallet_lock(u);ids:=nido_private.wallet_members(u);
 if cardinality(ids)<>2 then raise exception 'No hay una pareja enlazada';end if;
 amount:=nido_private.wallet_balance(u);
 if amount is distinct from p_expected_balance then raise exception 'El saldo cambió. Revisa de nuevo el reparto antes de confirmar';end if;
 share:=floor(amount*.10);
 insert into nido_private.wallet_separations(member_a,member_b,balance_before,each_receives,discarded) values(ids[1],ids[2],amount,share,amount-2*share);
 update public.game_stats set love_coins=share,updated_at=now() where user_id=any(ids);
 update public.user_profiles set partner_id=null where id=any(ids);
 return jsonb_build_object('unlinked',true,'coins',share,'discarded',amount-2*share);
end $$;
revoke all on function public.wallet_unlink(bigint,boolean) from public,anon;
grant execute on function public.wallet_unlink(bigint,boolean) to authenticated;

CREATE OR REPLACE FUNCTION public.inventory_snapshot()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid:=auth.uid();result jsonb;
begin
 if u is null then raise exception 'Inicia sesiÃ³n' using errcode='42501';end if;
 insert into public.game_stats(user_id) values(u) on conflict do nothing;
 select jsonb_build_object('user_id',u,'coins',nido_private.wallet_balance(u),'wallet_shared',cardinality(nido_private.wallet_members(u))=2,
  'catalog',(select coalesce(jsonb_agg(to_jsonb(s)||jsonb_build_object('appearance',s.appearance||case when nido_private.color_hex(o.color_key) is not null then jsonb_build_object('garment_color',nido_private.color_hex(o.color_key)) else '{}'::jsonb end) order by s.sort_order),'[]'::jsonb) from public.shop_items s left join public.owned_items o on o.item_key=s.item_key and o.user_id=u where s.active),
  'owned',(select coalesce(jsonb_agg(to_jsonb(o)),'[]'::jsonb) from public.owned_items o where o.user_id=u),
  'colors',(select coalesce(jsonb_agg(to_jsonb(c)),'[]'::jsonb) from public.inventory_colors c where c.user_id=u)) into result from public.game_stats g where g.user_id=u;
 return result;
end $function$;


CREATE OR REPLACE FUNCTION public.inventory_purchase(p_item_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid:=auth.uid(); s public.shop_items; balance bigint;
begin
 if u is null then raise exception 'Inicia sesión para comprar' using errcode='42501'; end if;
 select * into s from public.shop_items where item_key=p_item_key and active and currency='coins' and price_coins>0;
 if not found then raise exception 'Este objeto no está disponible'; end if;
 perform nido_private.wallet_lock(u);balance:=nido_private.wallet_balance(u);
 if exists(select 1 from public.owned_items where user_id=u and item_key=p_item_key) then return jsonb_build_object('coins',balance,'already_owned',true); end if;
 if balance<s.price_coins then raise exception 'No tienes suficientes LoveCoins'; end if;
 balance:=nido_private.wallet_spend(u,s.price_coins);
 insert into public.owned_items(user_id,item_key,slot) values(u,p_item_key,s.equip_slot);
 return jsonb_build_object('coins',balance,'already_owned',false);
end $function$;


CREATE OR REPLACE FUNCTION nido_private.color_select(p_item_key text, p_color_key text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid:=auth.uid();s public.shop_items;balance bigint;
begin
 if u is null then raise exception 'Inicia sesiÃ³n' using errcode='42501';end if;
 if p_color_key<>'original' and nido_private.color_hex(p_color_key) is null then raise exception 'Color invÃ¡lido';end if;
 select * into s from public.shop_items where item_key=p_item_key and active and scope='pet' and jsonb_typeof(appearance->'color_materials')='array';
 if not found then raise exception 'Esta prenda no admite colores';end if;
 perform nido_private.wallet_lock(u);balance:=nido_private.wallet_balance(u);
 if not exists(select 1 from public.owned_items where user_id=u and item_key=p_item_key) then raise exception 'Adquiere primero la prenda';end if;
 if p_color_key<>'original' and not exists(select 1 from public.inventory_colors where user_id=u and item_key=p_item_key and color_key=p_color_key) then
  if coalesce(balance,0)<10 then raise exception 'Necesitas 10 de oro';end if;
  perform nido_private.wallet_spend(u,10);
  insert into public.inventory_colors(user_id,item_key,color_key) values(u,p_item_key,p_color_key);
 end if;
 update public.owned_items set color_key=p_color_key where user_id=u and item_key=p_item_key;
end $function$;


CREATE OR REPLACE FUNCTION nido_private.pet_family_change(p_action text, p_species text, p_name text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare snapshot jsonb;k text;r public.shared_pets%rowtype;n integer;required_level integer;required_days integer;days integer;balance bigint;
begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='42501';end if;
 if p_species is null or p_species not in ('penguin','bear','pig','chick') or p_name is null or char_length(btrim(p_name))>24 or p_name~'[[:cntrl:]]' then raise exception 'Invalid pet';end if;
 -- Wallet before pair: a colour purchase and adoption use the same lock order.
 perform nido_private.wallet_lock(auth.uid());
 snapshot:=nido_private.pet_family_snapshot();k:=snapshot->>'pair_key';
 select * into r from public.shared_pets where pair_key=k for update;
 if p_action='choose' then
  if r.selection_confirmed then return snapshot;end if;
  update public.shared_pet_animals set species=p_species,name=btrim(p_name) where pair_key=k and species=r.active_species;
  update public.shared_pets set active_species=p_species,name=btrim(p_name),selection_confirmed=true where pair_key=k;
 elsif p_action in ('adopt','adopt_gold') then
  if not r.selection_confirmed then raise exception 'Choose first pet';end if;
  -- Retrying an already completed adoption never charges or switches again.
  if exists(select 1 from public.shared_pet_animals where pair_key=k and species=p_species) then return snapshot;end if;
  select count(*) into n from public.shared_pet_animals where pair_key=k;
  if n>=4 then raise exception 'Family is complete';end if;
  if p_action='adopt_gold' then
   balance:=nido_private.wallet_spend(auth.uid(),4000);
  else
   required_level:=case n when 1 then 8 when 2 then 16 else 24 end;
   required_days:=case n when 1 then 3 when 2 then 7 else 14 end;
   select count(*) into days from public.shared_pet_care_days where pair_key=k;
   if 1+r.care_points/20<required_level or days<required_days then raise exception 'Adoption locked';end if;
  end if;
  insert into public.shared_pet_animals(pair_key,species,name) values(k,p_species,btrim(p_name));
  update public.shared_pets set active_species=p_species,name=btrim(p_name) where pair_key=k;
 elsif p_action='select' then
  if not exists(select 1 from public.shared_pet_animals where pair_key=k and species=p_species) then raise exception 'Pet not adopted';end if;
  update public.shared_pets set active_species=p_species,name=(select name from public.shared_pet_animals where pair_key=k and species=p_species) where pair_key=k;
 elsif p_action='rename' then
  if not exists(select 1 from public.shared_pet_animals where pair_key=k and species=p_species) then raise exception 'Pet not adopted';end if;
  update public.shared_pet_animals set name=btrim(p_name) where pair_key=k and species=p_species;
  -- Renaming a different member must not change the active character.
  update public.shared_pets set name=btrim(p_name) where pair_key=k and active_species=p_species;
 else raise exception 'Invalid action';end if;
 return nido_private.pet_family_snapshot();
end $function$;



alter table nido_private.guardian_rooms add column if not exists engine_version integer not null default 2;
create table if not exists nido_private.guardian_clothing_prizes(room_id uuid primary key references nido_private.guardian_rooms(id) on delete cascade,item_key text references public.shop_items(item_key),created_at timestamptz not null default now());
alter table nido_private.guardian_clothing_prizes enable row level security;
revoke all on nido_private.guardian_clothing_prizes from public,anon,authenticated;
create table if not exists nido_private.art_rewards(room_id uuid references nido_private.art_rooms(id) on delete cascade,user_id uuid references auth.users(id) on delete cascade,amount integer not null check(amount between 0 and 20),created_at timestamptz not null default now(),primary key(room_id,user_id));
alter table nido_private.art_rewards enable row level security;
revoke all on nido_private.art_rewards from public,anon,authenticated;

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
  values(upper(substr(replace(gen_random_uuid()::text,'-',''),1,8)),u,case when p_action='solo' then 'solo' else 'partner' end,p_difficulty,floor(random()*4294967295)::bigint,p_species,case when p_action='solo' then 'running' else 'waiting' end,case when p_action='solo' then now() else null end,p_action='solo',look,case when p_packets->>'engine_version'='3' then 3 else 2 end) returning * into r;
 elsif p_action='join' then
  insert into nido_private.guardian_join_limits values(u,date_trunc('minute',now()),1) on conflict(user_id) do update set
   attempts=case when guardian_join_limits.bucket=date_trunc('minute',now()) then guardian_join_limits.attempts+1 else 1 end,bucket=date_trunc('minute',now()) returning attempts into n;
  if n>20 then return jsonb_build_object('error','Demasiados intentos; espera un minuto'); end if;
  select * into r from nido_private.guardian_rooms where code=upper(trim(p_code)) and mode='partner' and status='waiting' and created_at>now()-interval '15 minutes' for update;
  if r.id is null or r.host_id=u or (r.guest_id is not null and r.guest_id<>u) then return jsonb_build_object('error','La sala no está disponible'); end if;
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
 return jsonb_build_object('id',r.id,'code',r.code,'mode',r.mode,'difficulty',r.difficulty,'seed',r.seed,'role',case when r.host_id=u then 0 else 1 end,'species',jsonb_build_array(r.host_species,coalesce(r.guest_species,'bear')),'loadouts',jsonb_build_array(r.host_loadout,r.guest_loadout),'engine_version',r.engine_version,'host_ready',r.host_ready,'guest_ready',r.guest_ready,'joined',r.guest_id is not null,'status',r.status,'started_at',r.started_at,'server_time',now(),'confirmed',r.confirmed_hash is not null,'prize',(select item_key from nido_private.guardian_clothing_prizes where room_id=r.id),'reward',(select amount from nido_private.guardian_rewards where room_id=r.id and user_id=u));
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
  return jsonb_build_object('saved',true,'prize',(select item_key from nido_private.guardian_clothing_prizes where room_id=r.id),'reward',(select gr.amount from nido_private.guardian_rewards gr where gr.room_id=r.id and gr.user_id=p_user_id));
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
 return result||jsonb_build_object('prize',(select item_key from nido_private.guardian_clothing_prizes where room_id=r.id));
end $function$;

alter table nido_private.art_rooms add column if not exists reference_protocol integer not null default 1, add column if not exists reference_revealed_at timestamptz, add column if not exists host_reference_loaded boolean not null default false, add column if not exists guest_reference_loaded boolean not null default false;
CREATE OR REPLACE FUNCTION nido_private.art_action(p_action text, p_data jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid:=auth.uid(); partner uuid; r nido_private.art_rooms; token text; result jsonb; art text; member uuid; earned integer; amount integer;
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
 result:=(to_jsonb(r)-'host_art'-'guest_art'-'reference_image')||jsonb_build_object('host_submitted',r.host_art is not null,'guest_submitted',r.guest_art is not null);
 if p_action in ('create','join') or coalesce((p_data->>'download')::boolean,false) then result:=result||jsonb_build_object('reference_image',r.reference_image); end if;
 -- No peeking: opponent art only revealed after both submissions; own art is recoverable.
 if p_action not in ('status','ready') or coalesce((p_data->>'download')::boolean,false) or not coalesce((p_data->>'compact')::boolean,false) then
 if r.host_art is not null and r.guest_art is not null then result:=result||jsonb_build_object('host_art',r.host_art,'guest_art',r.guest_art);
 elsif u=r.host then result:=result||jsonb_build_object('host_art',r.host_art);
 else result:=result||jsonb_build_object('guest_art',r.guest_art); end if;
 end if;
 if r.id is not null and r.reference_protocol=2 and r.reference_revealed_at is null then result:=result-'reference_image'-'reference_title';end if;
 return result||jsonb_build_object('reward',(select a.amount from nido_private.art_rewards a where a.room_id=r.id and a.user_id=u),'server_now',now());
end $function$;

