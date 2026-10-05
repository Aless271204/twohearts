begin;
alter table public.shop_items add column if not exists scope text, add column if not exists equip_slot text, add column if not exists description text not null default '', add column if not exists rarity text not null default 'Común', add column if not exists appearance jsonb not null default '{}', add column if not exists active boolean not null default false;
insert into public.shop_items(item_key,name,emoji,scope,equip_slot,price_coins,description,collection,rarity,appearance,sort_order,currency,active)
select v.*, 'coins',true from (values
('bow_basic','Moño básico','🎀','pet','pet_head',250,'Un lazo suave para Pip.','Dulce','Común','{"color":"#ef91b4","style":"bow","emoji":"🎀"}'::jsonb,0),
('glasses_heart','Gafas corazón','💗','pet','pet_eyes',400,'Montura rosa con lentes en forma de corazón.','Dulce','Raro','{"color":"#f37aaa","style":"heart_glasses","emoji":"💗"}'::jsonb,1),
('cap_pink','Gorra rosa','🧢','pet','pet_head',500,'Gorra de paseo con visera.','Dulce','Común','{"color":"#ef91b4","style":"cap","emoji":"🧢"}'::jsonb,2),
('shirt_love','Camiseta amor','👕','pet','pet_body',700,'Camiseta con un corazón al centro.','Dulce','Común','{"color":"#e993af","style":"shirt","emoji":"👕"}'::jsonb,3),
('backpack_heart','Mochila corazón','🎒','pet','pet_back',900,'Mochila de aventura; también se ve al correr.','Bosque','Raro','{"color":"#779ad5","style":"backpack","emoji":"🎒"}'::jsonb,4),
('hat_special','Sombrero especial','🎩','pet','pet_head',1200,'Sombrero elegante con cinta.','Noche','Especial','{"color":"#785b98","style":"hat","emoji":"🎩"}'::jsonb,5),
('crown_gold','Corona dorada','👑','pet','pet_head',1500,'Una corona para el rey de la casa.','Dorado','Especial','{"color":"#ecc05c","style":"crown","emoji":"👑"}'::jsonb,6),
('flower_hat','Sombrero flores','🌸','pet','pet_head',800,'Sombrero cálido adornado con flores.','Bosque','Raro','{"color":"#efd09b","style":"flower_hat","emoji":"🌸"}'::jsonb,7),
('sunglasses','Gafas de sol','🕶️','pet','pet_eyes',600,'Gafas oscuras para los días luminosos.','Mar','Común','{"color":"#293d56","style":"glasses","emoji":"🕶️"}'::jsonb,8),
('scarf_hearts','Bufanda corazones','🧣','pet','pet_neck',750,'Bufanda rosa con puntitos claros.','Dulce','Raro','{"color":"#e66d93","style":"scarf","emoji":"🧣"}'::jsonb,9),
('valentines_bow','Lazo San Valentín','🎀','pet','pet_head',350,'Un lazo rojo para ocasiones especiales.','Dulce','Común','{"color":"#df577d","style":"bow","emoji":"🎀"}'::jsonb,10),
('halloween_hat','Sombrero Halloween','🧙','pet','pet_head',600,'Sombrero violeta de punta.','Noche','Raro','{"color":"#735490","style":"cone","emoji":"🧙"}'::jsonb,11),
('xmas_hat','Gorro Navidad','🎅','pet','pet_head',600,'Gorro rojo con pompón blanco.','Fiesta','Común','{"color":"#c75760","style":"santa","emoji":"🎅"}'::jsonb,12),
('birthday_hat','Gorro cumpleaños','🥳','pet','pet_head',400,'Gorro dorado para celebrar juntos.','Fiesta','Común','{"color":"#dbab59","style":"cone","emoji":"🥳"}'::jsonb,13),
('beach_glasses','Gafas playa','😎','pet','pet_eyes',500,'Montura turquesa de verano.','Mar','Común','{"color":"#51bcb7","style":"glasses","emoji":"😎"}'::jsonb,14),
('scarf_leaf','Bufanda helecho','🧣','pet','pet_neck',60,'Una primera bufanda inspirada en el bosque.','Bosque','Común','{"color":"#70a889","style":"scarf","emoji":"🧣"}'::jsonb,15),
('bow_sky','Lazo cielo','🎀','pet','pet_head',45,'Un lazo azul ligero.','Cielo','Común','{"color":"#91c9e1","style":"bow","emoji":"🎀"}'::jsonb,16),
('room_wall_forest','Pared · Bosque','🖼️','room','room_wall',80,'Pared con formas suaves y pequeños detalles.','Bosque','Común','{"color":"#7aa98a","style":"wall","emoji":"🖼️"}'::jsonb,17),
('room_floor_forest','Suelo · Bosque','🪵','room','room_floor',70,'Suelo de tablones coordinados con la habitación.','Bosque','Común','{"color":"#7aa98a","style":"floor","emoji":"🪵"}'::jsonb,18),
('room_bed_forest','Cama · Bosque','🛏️','room','room_bed',110,'Una cama redonda y acogedora para Pip.','Bosque','Común','{"color":"#7aa98a","style":"bed","emoji":"🛏️"}'::jsonb,19),
('room_plant_forest','Planta · Bosque','🪴','room','room_plant',55,'Una maceta junto a la mascota.','Bosque','Común','{"color":"#7aa98a","style":"plant","emoji":"🪴"}'::jsonb,20),
('room_lamp_forest','Lámpara · Bosque','💡','room','room_lamp',65,'Una luz cálida en un rincón de la habitación.','Bosque','Común','{"color":"#7aa98a","style":"lamp","emoji":"💡"}'::jsonb,21),
('room_decor_forest','Cuadro · Bosque','🌿','room','room_decor',50,'Un cuadro decorativo sobre la pared.','Bosque','Común','{"color":"#7aa98a","style":"picture","emoji":"🌿"}'::jsonb,22),
('pong_paddle_forest','Paleta · Bosque','🏓','pong','pong_paddle',75,'Cambia el aspecto de tu paleta, manteniendo su tamaño.','Bosque','Común','{"color":"#7aa98a","style":"paddle","emoji":"🏓"}'::jsonb,23),
('pong_ball_forest','Pelota · Bosque','⚪','pong','pong_ball',90,'Color de la pelota en tu pantalla.','Bosque','Común','{"color":"#7aa98a","style":"ball","emoji":"⚪"}'::jsonb,24),
('pong_court_forest','Cancha · Bosque','🏟️','pong','pong_court',120,'Bordes y luces de tu cancha vertical.','Bosque','Común','{"color":"#7aa98a","style":"court","emoji":"🏟️"}'::jsonb,25),
('quiz_card_forest','Cartas · Bosque','🃏','quiz','quiz_card',60,'Marco de las preguntas y sus tres respuestas.','Bosque','Común','{"color":"#7aa98a","style":"card","emoji":"🃏"}'::jsonb,26),
('quiz_table_forest','Mesa · Bosque','🎨','quiz','quiz_table',100,'Fondo de tu partida de preguntas.','Bosque','Común','{"color":"#7aa98a","style":"table","emoji":"🎨"}'::jsonb,27),
('quiz_badge_forest','Insignia · Bosque','💌','quiz','quiz_badge',40,'Un distintivo junto a tu nombre durante la partida.','Bosque','Común','{"color":"#7aa98a","style":"badge","emoji":"💌"}'::jsonb,28),
('room_wall_rose','Pared · Rosa suave','🖼️','room','room_wall',80,'Pared con formas suaves y pequeños detalles.','Dulce','Común','{"color":"#e8a4bd","style":"wall","emoji":"🖼️"}'::jsonb,29),
('room_floor_rose','Suelo · Rosa suave','🪵','room','room_floor',70,'Suelo de tablones coordinados con la habitación.','Dulce','Común','{"color":"#e8a4bd","style":"floor","emoji":"🪵"}'::jsonb,30),
('room_bed_rose','Cama · Rosa suave','🛏️','room','room_bed',110,'Una cama redonda y acogedora para Pip.','Dulce','Común','{"color":"#e8a4bd","style":"bed","emoji":"🛏️"}'::jsonb,31),
('room_plant_rose','Planta · Rosa suave','🪴','room','room_plant',55,'Una maceta junto a la mascota.','Dulce','Común','{"color":"#e8a4bd","style":"plant","emoji":"🪴"}'::jsonb,32),
('room_lamp_rose','Lámpara · Rosa suave','💡','room','room_lamp',65,'Una luz cálida en un rincón de la habitación.','Dulce','Común','{"color":"#e8a4bd","style":"lamp","emoji":"💡"}'::jsonb,33),
('room_decor_rose','Cuadro · Rosa suave','🌿','room','room_decor',50,'Un cuadro decorativo sobre la pared.','Dulce','Común','{"color":"#e8a4bd","style":"picture","emoji":"🌿"}'::jsonb,34),
('pong_paddle_rose','Paleta · Rosa suave','🏓','pong','pong_paddle',75,'Cambia el aspecto de tu paleta, manteniendo su tamaño.','Dulce','Común','{"color":"#e8a4bd","style":"paddle","emoji":"🏓"}'::jsonb,35),
('pong_ball_rose','Pelota · Rosa suave','⚪','pong','pong_ball',90,'Color de la pelota en tu pantalla.','Dulce','Común','{"color":"#e8a4bd","style":"ball","emoji":"⚪"}'::jsonb,36),
('pong_court_rose','Cancha · Rosa suave','🏟️','pong','pong_court',120,'Bordes y luces de tu cancha vertical.','Dulce','Común','{"color":"#e8a4bd","style":"court","emoji":"🏟️"}'::jsonb,37),
('quiz_card_rose','Cartas · Rosa suave','🃏','quiz','quiz_card',60,'Marco de las preguntas y sus tres respuestas.','Dulce','Común','{"color":"#e8a4bd","style":"card","emoji":"🃏"}'::jsonb,38),
('quiz_table_rose','Mesa · Rosa suave','🎨','quiz','quiz_table',100,'Fondo de tu partida de preguntas.','Dulce','Común','{"color":"#e8a4bd","style":"table","emoji":"🎨"}'::jsonb,39),
('quiz_badge_rose','Insignia · Rosa suave','💌','quiz','quiz_badge',40,'Un distintivo junto a tu nombre durante la partida.','Dulce','Común','{"color":"#e8a4bd","style":"badge","emoji":"💌"}'::jsonb,40),
('room_wall_night','Pared · Noche estrellada','🖼️','room','room_wall',120,'Pared con formas suaves y pequeños detalles.','Noche','Raro','{"color":"#6b729f","style":"wall","emoji":"🖼️"}'::jsonb,41),
('room_floor_night','Suelo · Noche estrellada','🪵','room','room_floor',110,'Suelo de tablones coordinados con la habitación.','Noche','Raro','{"color":"#6b729f","style":"floor","emoji":"🪵"}'::jsonb,42),
('room_bed_night','Cama · Noche estrellada','🛏️','room','room_bed',150,'Una cama redonda y acogedora para Pip.','Noche','Raro','{"color":"#6b729f","style":"bed","emoji":"🛏️"}'::jsonb,43),
('room_plant_night','Planta · Noche estrellada','🪴','room','room_plant',95,'Una maceta junto a la mascota.','Noche','Raro','{"color":"#6b729f","style":"plant","emoji":"🪴"}'::jsonb,44),
('room_lamp_night','Lámpara · Noche estrellada','💡','room','room_lamp',105,'Una luz cálida en un rincón de la habitación.','Noche','Raro','{"color":"#6b729f","style":"lamp","emoji":"💡"}'::jsonb,45),
('room_decor_night','Cuadro · Noche estrellada','🌿','room','room_decor',90,'Un cuadro decorativo sobre la pared.','Noche','Raro','{"color":"#6b729f","style":"picture","emoji":"🌿"}'::jsonb,46),
('pong_paddle_night','Paleta · Noche estrellada','🏓','pong','pong_paddle',115,'Cambia el aspecto de tu paleta, manteniendo su tamaño.','Noche','Raro','{"color":"#6b729f","style":"paddle","emoji":"🏓"}'::jsonb,47),
('pong_ball_night','Pelota · Noche estrellada','⚪','pong','pong_ball',130,'Color de la pelota en tu pantalla.','Noche','Raro','{"color":"#6b729f","style":"ball","emoji":"⚪"}'::jsonb,48),
('pong_court_night','Cancha · Noche estrellada','🏟️','pong','pong_court',160,'Bordes y luces de tu cancha vertical.','Noche','Raro','{"color":"#6b729f","style":"court","emoji":"🏟️"}'::jsonb,49),
('quiz_card_night','Cartas · Noche estrellada','🃏','quiz','quiz_card',100,'Marco de las preguntas y sus tres respuestas.','Noche','Raro','{"color":"#6b729f","style":"card","emoji":"🃏"}'::jsonb,50),
('quiz_table_night','Mesa · Noche estrellada','🎨','quiz','quiz_table',140,'Fondo de tu partida de preguntas.','Noche','Raro','{"color":"#6b729f","style":"table","emoji":"🎨"}'::jsonb,51),
('quiz_badge_night','Insignia · Noche estrellada','💌','quiz','quiz_badge',80,'Un distintivo junto a tu nombre durante la partida.','Noche','Raro','{"color":"#6b729f","style":"badge","emoji":"💌"}'::jsonb,52),
('room_wall_honey','Pared · Miel','🖼️','room','room_wall',80,'Pared con formas suaves y pequeños detalles.','Dorado','Común','{"color":"#e5be75","style":"wall","emoji":"🖼️"}'::jsonb,53),
('room_floor_honey','Suelo · Miel','🪵','room','room_floor',70,'Suelo de tablones coordinados con la habitación.','Dorado','Común','{"color":"#e5be75","style":"floor","emoji":"🪵"}'::jsonb,54),
('room_bed_honey','Cama · Miel','🛏️','room','room_bed',110,'Una cama redonda y acogedora para Pip.','Dorado','Común','{"color":"#e5be75","style":"bed","emoji":"🛏️"}'::jsonb,55),
('room_plant_honey','Planta · Miel','🪴','room','room_plant',55,'Una maceta junto a la mascota.','Dorado','Común','{"color":"#e5be75","style":"plant","emoji":"🪴"}'::jsonb,56),
('room_lamp_honey','Lámpara · Miel','💡','room','room_lamp',65,'Una luz cálida en un rincón de la habitación.','Dorado','Común','{"color":"#e5be75","style":"lamp","emoji":"💡"}'::jsonb,57),
('room_decor_honey','Cuadro · Miel','🌿','room','room_decor',50,'Un cuadro decorativo sobre la pared.','Dorado','Común','{"color":"#e5be75","style":"picture","emoji":"🌿"}'::jsonb,58),
('pong_paddle_honey','Paleta · Miel','🏓','pong','pong_paddle',75,'Cambia el aspecto de tu paleta, manteniendo su tamaño.','Dorado','Común','{"color":"#e5be75","style":"paddle","emoji":"🏓"}'::jsonb,59),
('pong_ball_honey','Pelota · Miel','⚪','pong','pong_ball',90,'Color de la pelota en tu pantalla.','Dorado','Común','{"color":"#e5be75","style":"ball","emoji":"⚪"}'::jsonb,60),
('pong_court_honey','Cancha · Miel','🏟️','pong','pong_court',120,'Bordes y luces de tu cancha vertical.','Dorado','Común','{"color":"#e5be75","style":"court","emoji":"🏟️"}'::jsonb,61),
('quiz_card_honey','Cartas · Miel','🃏','quiz','quiz_card',60,'Marco de las preguntas y sus tres respuestas.','Dorado','Común','{"color":"#e5be75","style":"card","emoji":"🃏"}'::jsonb,62),
('quiz_table_honey','Mesa · Miel','🎨','quiz','quiz_table',100,'Fondo de tu partida de preguntas.','Dorado','Común','{"color":"#e5be75","style":"table","emoji":"🎨"}'::jsonb,63),
('quiz_badge_honey','Insignia · Miel','💌','quiz','quiz_badge',40,'Un distintivo junto a tu nombre durante la partida.','Dorado','Común','{"color":"#e5be75","style":"badge","emoji":"💌"}'::jsonb,64)
) as v(item_key,name,emoji,scope,equip_slot,price_coins,description,collection,rarity,appearance,sort_order)
on conflict(item_key) do update set scope=excluded.scope,equip_slot=excluded.equip_slot,description=excluded.description,rarity=excluded.rarity,appearance=excluded.appearance,active=true;
-- Keep every historical purchase. Only supported cosmetics can be equipped.
update public.owned_items o set slot=s.equip_slot from public.shop_items s where o.item_key=s.item_key and s.active;
update public.owned_items set equipped=false where slot is null;
with ranked as(select id,row_number() over(partition by user_id,slot order by purchased_at desc,id) n from public.owned_items where equipped)
update public.owned_items set equipped=false where id in(select id from ranked where n>1);
create unique index if not exists owned_items_one_slot on public.owned_items(user_id,slot) where equipped;
revoke insert,update,delete on public.owned_items from anon,authenticated;
grant select on public.owned_items to authenticated;
create or replace function public.inventory_snapshot() returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); result jsonb;
begin
 if u is null then raise exception 'Inicia sesión para usar tu inventario' using errcode='42501'; end if;
 insert into public.game_stats(user_id) values(u) on conflict(user_id) do nothing;
 select jsonb_build_object('user_id',u,'coins',g.love_coins,'catalog',(select coalesce(jsonb_agg(to_jsonb(s) order by sort_order),'[]') from public.shop_items s where active), 'owned',(select coalesce(jsonb_agg(to_jsonb(o)),'[]') from public.owned_items o where user_id=u)) into result from public.game_stats g where user_id=u;
 return result;
end $$;
create or replace function public.inventory_purchase(p_item_key text) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); s public.shop_items; balance integer;
begin
 if u is null then raise exception 'Inicia sesión para comprar' using errcode='42501'; end if;
 select * into s from public.shop_items where item_key=p_item_key and active and currency='coins' and price_coins>0;
 if not found then raise exception 'Este objeto no está disponible'; end if;
 insert into public.game_stats(user_id) values(u) on conflict(user_id) do nothing;
 select love_coins into balance from public.game_stats where user_id=u for update;
 if exists(select 1 from public.owned_items where user_id=u and item_key=p_item_key) then return jsonb_build_object('coins',balance,'already_owned',true); end if;
 if balance<s.price_coins then raise exception 'No tienes suficientes LoveCoins'; end if;
 update public.game_stats set love_coins=love_coins-s.price_coins,updated_at=now() where user_id=u returning love_coins into balance;
 insert into public.owned_items(user_id,item_key,slot) values(u,p_item_key,s.equip_slot);
 return jsonb_build_object('coins',balance,'already_owned',false);
end $$;
create or replace function public.inventory_equip(p_item_key text,p_equipped boolean default true) returns void language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); target_slot text;
begin
 if u is null then raise exception 'Inicia sesión para equipar' using errcode='42501'; end if;
 perform 1 from public.game_stats where user_id=u for update;
 select s.equip_slot into target_slot from public.shop_items s join public.owned_items o on o.item_key=s.item_key where o.user_id=u and s.item_key=p_item_key and s.active;
 if target_slot is null then raise exception 'Primero debes adquirir este objeto'; end if;
 if p_equipped then update public.owned_items set equipped=false where user_id=u and slot=target_slot; end if;
 update public.owned_items set equipped=p_equipped,slot=target_slot where user_id=u and item_key=p_item_key;
end $$;
revoke all on function public.inventory_snapshot(),public.inventory_purchase(text),public.inventory_equip(text,boolean) from public,anon;
grant execute on function public.inventory_snapshot(),public.inventory_purchase(text),public.inventory_equip(text,boolean) to authenticated;
commit;
