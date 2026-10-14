begin;
-- Existing purchases stay owned. Repricing changes neither balance nor ownership.
update public.shop_items set price_coins=case equip_slot
 when 'pet_eyes' then 50 when 'pet_head' then 70 when 'pet_neck' then 50
 when 'pet_body' then 100 when 'pet_feet' then 100 when 'pet_back' then 120
 when 'room_decor' then 60 when 'room_plant' then 100 when 'room_wall' then 140
 when 'room_floor' then 180 when 'room_bed' then 400 when 'room_lamp' then 160
 else price_coins end where scope in ('pet','room') and active;

alter table public.owned_items add column if not exists color_key text not null default 'original';
create table if not exists public.inventory_colors(
 user_id uuid not null references auth.users(id) on delete cascade,
 item_key text not null references public.shop_items(item_key) on delete cascade,
 color_key text not null check(color_key in ('coral','sage','lavender','cream','sky')),
 acquired_at timestamptz not null default now(),primary key(user_id,item_key,color_key)
);
alter table public.inventory_colors enable row level security;
revoke all on public.inventory_colors from public,anon,authenticated;
grant select on public.inventory_colors to authenticated;
create policy own_colors on public.inventory_colors for select to authenticated using((select auth.uid())=user_id);
create or replace function nido_private.color_hex(k text) returns text language sql immutable set search_path='' as $$
 select case k when 'coral' then '#F05280' when 'sage' then '#B8DCCB' when 'lavender' then '#BAA2DB' when 'cream' then '#FFF0D9' when 'sky' then '#92B9D5' else null end;
$$;
create or replace function nido_private.color_select(p_item_key text,p_color_key text) returns void language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();s public.shop_items;balance integer;
begin
 if u is null then raise exception 'Inicia sesiÃ³n' using errcode='42501';end if;
 if p_color_key<>'original' and nido_private.color_hex(p_color_key) is null then raise exception 'Color invÃ¡lido';end if;
 select * into s from public.shop_items where item_key=p_item_key and active and scope='pet' and jsonb_typeof(appearance->'color_materials')='array';
 if not found then raise exception 'Esta prenda no admite colores';end if;
 select love_coins into balance from public.game_stats where user_id=u for update;
 if not exists(select 1 from public.owned_items where user_id=u and item_key=p_item_key) then raise exception 'Adquiere primero la prenda';end if;
 if p_color_key<>'original' and not exists(select 1 from public.inventory_colors where user_id=u and item_key=p_item_key and color_key=p_color_key) then
  if coalesce(balance,0)<10 then raise exception 'Necesitas 10 de oro';end if;
  update public.game_stats set love_coins=love_coins-10,updated_at=now() where user_id=u;
  insert into public.inventory_colors(user_id,item_key,color_key) values(u,p_item_key,p_color_key);
 end if;
 update public.owned_items set color_key=p_color_key where user_id=u and item_key=p_item_key;
end $$;
create or replace function public.inventory_color_select(p_item_key text,p_color_key text) returns void language sql set search_path='' as $$select nido_private.color_select(p_item_key,p_color_key);$$;
create or replace function public.inventory_snapshot() returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();result jsonb;
begin
 if u is null then raise exception 'Inicia sesiÃ³n' using errcode='42501';end if;
 insert into public.game_stats(user_id) values(u) on conflict do nothing;
 select jsonb_build_object('user_id',u,'coins',g.love_coins,
  'catalog',(select coalesce(jsonb_agg(to_jsonb(s)||jsonb_build_object('appearance',s.appearance||case when nido_private.color_hex(o.color_key) is not null then jsonb_build_object('garment_color',nido_private.color_hex(o.color_key)) else '{}'::jsonb end) order by s.sort_order),'[]'::jsonb) from public.shop_items s left join public.owned_items o on o.item_key=s.item_key and o.user_id=u where s.active),
  'owned',(select coalesce(jsonb_agg(to_jsonb(o)),'[]'::jsonb) from public.owned_items o where o.user_id=u),
  'colors',(select coalesce(jsonb_agg(to_jsonb(c)),'[]'::jsonb) from public.inventory_colors c where c.user_id=u)) into result from public.game_stats g where g.user_id=u;
 return result;
end $$;
create or replace function public.shared_pet_snapshot() returns jsonb language plpgsql security definer set search_path='' as $$
declare base jsonb;
begin
 base:=nido_private.pet_family_snapshot();
 return base||jsonb_build_object('equipment',(select coalesce(jsonb_agg(to_jsonb(s)||jsonb_build_object('appearance',s.appearance||case when nido_private.color_hex(o.color_key) is not null then jsonb_build_object('garment_color',nido_private.color_hex(o.color_key)) else '{}'::jsonb end)),'[]'::jsonb)
 from public.shared_pet_equipment e join public.shop_items s on s.item_key=e.item_key left join public.owned_items o on o.item_key=e.item_key and o.user_id=e.owner_id where e.pair_key=base->>'pair_key'));
end $$;

-- Five verified videos per rolling twelve hours. Client cannot credit gold.
create table public.rewarded_ad_sessions(
 ticket uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(),expires_at timestamptz not null default now()+interval '20 minutes',
 status text not null default 'reserved' check(status in ('reserved','completed','cancelled')),
 completed_at timestamptz,transaction_id text unique
);
create index rewarded_user_window on public.rewarded_ad_sessions(user_id,created_at desc);
alter table public.rewarded_ad_sessions enable row level security;
revoke all on public.rewarded_ad_sessions from public,anon,authenticated;
grant select on public.rewarded_ad_sessions to authenticated;
create policy own_ad_sessions on public.rewarded_ad_sessions for select to authenticated using((select auth.uid())=user_id);
create or replace function nido_private.ad_status() returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();used integer;first_time timestamptz;
begin
 if u is null then raise exception 'Inicia sesiÃ³n' using errcode='42501';end if;
 select count(*),min(created_at) into used,first_time from public.rewarded_ad_sessions where user_id=u and created_at>now()-interval '12 hours' and (status='completed' or status='reserved' and expires_at>now());
 return jsonb_build_object('remaining',greatest(0,5-used),'gold',3,'limit',5,'window_hours',12,'next_available_at',case when used>=5 then first_time+interval '12 hours' else now() end);
end $$;
create or replace function public.rewarded_ad_status() returns jsonb language sql set search_path='' as $$select nido_private.ad_status();$$;
create or replace function nido_private.ad_begin() returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();t uuid;
begin
 if u is null then raise exception 'Inicia sesiÃ³n' using errcode='42501';end if;
 insert into public.game_stats(user_id) values(u) on conflict do nothing;
 perform 1 from public.game_stats where user_id=u for update;
 if (nido_private.ad_status()->>'remaining')::integer<=0 then raise exception 'Has visto cinco vÃ­deos en las Ãºltimas doce horas';end if;
 insert into public.rewarded_ad_sessions(user_id) values(u) returning ticket into t;
 return jsonb_build_object('ticket',t,'gold',3);
end $$;
create or replace function public.rewarded_ad_begin() returns jsonb language sql set search_path='' as $$select nido_private.ad_begin();$$;
create or replace function public.rewarded_ad_cancel(p_ticket uuid) returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'Inicia sesiÃ³n' using errcode='42501';end if;
 update public.rewarded_ad_sessions set status='cancelled' where ticket=p_ticket and user_id=auth.uid() and status='reserved';
end $$;
create or replace function public.rewarded_ad_result(p_ticket uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare s public.rewarded_ad_sessions;
begin
 if auth.uid() is null then raise exception 'Inicia sesiÃ³n' using errcode='42501';end if;
 select * into s from public.rewarded_ad_sessions where ticket=p_ticket and user_id=auth.uid();
 if not found then raise exception 'Recompensa no disponible';end if;
 return jsonb_build_object('status',s.status,'gold',case when s.status='completed' then 3 else 0 end);
end $$;
create or replace function public.admob_credit_verified(p_ticket uuid,p_user_id uuid,p_transaction_id text,p_event_time timestamptz) returns jsonb language plpgsql security definer set search_path='' as $$
declare s public.rewarded_ad_sessions;balance integer;
begin
 if length(p_transaction_id)<8 or length(p_transaction_id)>200 then raise exception 'Invalid transaction';end if;
 perform 1 from public.game_stats where user_id=p_user_id for update;
 select * into s from public.rewarded_ad_sessions where ticket=p_ticket and user_id=p_user_id for update;
 if not found then raise exception 'Unknown reward';end if;
 if s.status='completed' then
  if s.transaction_id<>p_transaction_id then raise exception 'Transaction mismatch';end if;
  return jsonb_build_object('credited',false,'already_processed',true);
 end if;
 if s.status<>'reserved' or p_event_time<s.created_at-interval '1 minute' or p_event_time>s.expires_at or now()-p_event_time>interval '24 hours' or p_event_time>now()+interval '1 minute' then raise exception 'Invalid reward window';end if;
 if exists(select 1 from public.rewarded_ad_sessions where transaction_id=p_transaction_id) then raise exception 'Repeated transaction';end if;
 if (select count(*) from public.rewarded_ad_sessions where user_id=p_user_id and status='completed' and created_at>now()-interval '12 hours')>=5 then raise exception 'Reward limit reached';end if;
 update public.rewarded_ad_sessions set status='completed',completed_at=now(),transaction_id=p_transaction_id where ticket=p_ticket;
 update public.game_stats set love_coins=love_coins+3,updated_at=now() where user_id=p_user_id returning love_coins into balance;
 return jsonb_build_object('credited',true,'gold',3,'coins',balance);
end $$;
revoke all on function nido_private.color_hex(text),nido_private.color_select(text,text),nido_private.ad_status(),nido_private.ad_begin() from public,anon;
grant execute on function nido_private.color_select(text,text),nido_private.ad_status(),nido_private.ad_begin() to authenticated;
revoke all on function public.inventory_color_select(text,text),public.inventory_snapshot(),public.shared_pet_snapshot(),public.rewarded_ad_status(),public.rewarded_ad_begin(),public.rewarded_ad_cancel(uuid),public.rewarded_ad_result(uuid) from public,anon;
grant execute on function public.inventory_color_select(text,text),public.inventory_snapshot(),public.shared_pet_snapshot(),public.rewarded_ad_status(),public.rewarded_ad_begin(),public.rewarded_ad_cancel(uuid),public.rewarded_ad_result(uuid) to authenticated;
revoke all on function public.admob_credit_verified(uuid,uuid,text,timestamptz) from public,anon,authenticated;
grant execute on function public.admob_credit_verified(uuid,uuid,text,timestamptz) to service_role;
update public.shop_items set price_coins=70,appearance=appearance||'{"color_materials": ["AlgodÃ³n coral"], "color_base": "#F05280"}'::jsonb where item_key='cap_pink';
update public.shop_items set price_coins=90,appearance=appearance||'{"color_materials": ["knit Â· #FFF2DF"], "color_base": "#FFF2DF"}'::jsonb where item_key='beanie_cloud';
update public.shop_items set price_coins=120,appearance=appearance||'{"color_materials": ["straw Â· #B8DCCB"], "color_base": "#B8DCCB"}'::jsonb where item_key='hat_garden';
update public.shop_items set price_coins=80,appearance=appearance||'{"color_materials": ["felt Â· #BAA2DB"], "color_base": "#BAA2DB"}'::jsonb where item_key='beret_chic';
update public.shop_items set price_coins=50,appearance=appearance||'{}'::jsonb where item_key='glasses_heart';
update public.shop_items set price_coins=60,appearance=appearance||'{}'::jsonb where item_key='glasses_round';
update public.shop_items set price_coins=75,appearance=appearance||'{}'::jsonb where item_key='glasses_star';
update public.shop_items set price_coins=50,appearance=appearance||'{}'::jsonb where item_key='patch_pirate';
update public.shop_items set price_coins=55,appearance=appearance||'{"color_materials": ["cotton Â· #EFA0AB"], "color_base": "#EFA0AB"}'::jsonb where item_key='mask_sleep';
update public.shop_items set price_coins=80,appearance=appearance||'{"color_materials": ["knit Â· #EFA0AB"], "color_base": "#EFA0AB"}'::jsonb where item_key='scarf_hearts';
update public.shop_items set price_coins=50,appearance=appearance||'{"color_materials": ["cotton Â· #B8DCCB"], "color_base": "#B8DCCB"}'::jsonb where item_key='bandana_sage';
update public.shop_items set price_coins=90,appearance=appearance||'{}'::jsonb where item_key='necklace_heart';
update public.shop_items set price_coins=110,appearance=appearance||'{}'::jsonb where item_key='chain_gold';
update public.shop_items set price_coins=50,appearance=appearance||'{"color_materials": ["AlgodÃ³n coral nuevo"], "color_base": "#EC6276"}'::jsonb where item_key='bow_neck';
update public.shop_items set price_coins=50,appearance=appearance||'{"color_materials": ["AlgodÃ³n crema grueso"], "color_base": "#FFF0D9"}'::jsonb where item_key='shirt_love';
update public.shop_items set price_coins=140,appearance=appearance||'{"color_materials": ["denim Â· #92B9D5"], "color_base": "#92B9D5"}'::jsonb where item_key='jacket_denim';
update public.shop_items set price_coins=180,appearance=appearance||'{"color_materials": ["wool Â· #B3C4A2"], "color_base": "#B3C4A2"}'::jsonb where item_key='coat_cloud';
update public.shop_items set price_coins=160,appearance=appearance||'{"color_materials": ["poplin Â· #F5A8B6"], "color_base": "#F5A8B6"}'::jsonb where item_key='dress_petal';
update public.shop_items set price_coins=120,appearance=appearance||'{"color_materials": ["cotton Â· #C1ADE2"], "color_base": "#C1ADE2"}'::jsonb where item_key='hoodie_nido';
update public.shop_items set price_coins=130,appearance=appearance||'{"color_materials": ["AlgodÃ³n coral nuevo"], "color_base": "#EC6276"}'::jsonb where item_key='shoes_heart';
update public.shop_items set price_coins=140,appearance=appearance||'{"color_materials": ["plastic Â· #B8DCCB"], "color_base": "#B8DCCB"}'::jsonb where item_key='boots_rain';
update public.shop_items set price_coins=100,appearance=appearance||'{"color_materials": ["wool Â· #FFF2DF"], "color_base": "#FFF2DF"}'::jsonb where item_key='slippers_cloud';
update public.shop_items set price_coins=120,appearance=appearance||'{"color_materials": ["cotton Â· #F05280"], "color_base": "#F05280"}'::jsonb where item_key='shoes_chic';
update public.shop_items set price_coins=100,appearance=appearance||'{"color_materials": ["cotton Â· #F2B29B"], "color_base": "#F2B29B"}'::jsonb where item_key='sandals_summer';
commit;
