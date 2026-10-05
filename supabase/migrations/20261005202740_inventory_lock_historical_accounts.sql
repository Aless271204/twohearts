create or replace function public.inventory_equip(p_item_key text,p_equipped boolean default true) returns void language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); target_slot text;
begin
 if u is null then raise exception 'Inicia sesión para equipar' using errcode='42501'; end if;
 insert into public.game_stats(user_id) values(u) on conflict(user_id) do nothing;
 perform 1 from public.game_stats where user_id=u for update;
 select s.equip_slot into target_slot from public.shop_items s join public.owned_items o on o.item_key=s.item_key where o.user_id=u and s.item_key=p_item_key and s.active;
 if target_slot is null then raise exception 'Primero debes adquirir este objeto'; end if;
 if p_equipped then update public.owned_items set equipped=false where user_id=u and slot=target_slot; end if;
 update public.owned_items set equipped=p_equipped,slot=target_slot where user_id=u and item_key=p_item_key;
end $$;
