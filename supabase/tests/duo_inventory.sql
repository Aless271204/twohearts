begin;
create temporary table fixtures(a uuid,b uuid,c uuid,m uuid);
insert into fixtures values(gen_random_uuid(),gen_random_uuid(),gen_random_uuid(),null);
insert into auth.users(id,email,raw_user_meta_data) select a,'inventory-a@invalid.example','{}'::jsonb from fixtures union all select b,'inventory-b@invalid.example','{}'::jsonb from fixtures union all select c,'inventory-c@invalid.example','{}'::jsonb from fixtures;
update public.user_profiles set partner_id=(select b from fixtures) where id=(select a from fixtures);
update public.user_profiles set partner_id=(select a from fixtures) where id=(select b from fixtures);
insert into public.game_stats(user_id,love_coins) select a,1000 from fixtures union all select b,0 from fixtures;
select set_config('request.jwt.claim.sub',(select a::text from fixtures),true);
do $$declare result jsonb;balance integer;s jsonb;
begin
 result:=public.inventory_purchase('bow_sky');result:=public.inventory_purchase('bow_sky');
 select love_coins into balance from public.game_stats where user_id=auth.uid();
 if balance<>955 or result->>'already_owned'<>'true' then raise exception 'Double purchase charged twice';end if;
 perform public.inventory_equip('bow_sky');
 perform public.inventory_purchase('bow_basic');perform public.inventory_equip('bow_basic');
 if (select count(*) from public.owned_items where user_id=auth.uid() and equipped and slot='pet_head')<>1 then raise exception 'Slot collision';end if;
 begin perform public.inventory_equip('crown_gold');raise exception 'Unowned equip succeeded';exception when raise_exception then if sqlerrm='Unowned equip succeeded' then raise;end if;end;
 result:=public.duo_join('quiz');update fixtures set m=(result->>'id')::uuid;
end $$;
select set_config('request.jwt.claim.sub',(select b::text from fixtures),true);
do $$declare result jsonb;
begin
 begin perform public.inventory_purchase('bow_sky');raise exception 'Insufficient balance accepted';exception when raise_exception then if sqlerrm='Insufficient balance accepted' then raise;end if;end;
 if exists(select 1 from public.owned_items where user_id=auth.uid()) then raise exception 'Failed purchase created ownership';end if;
 result:=public.duo_join('quiz');if result->>'status'<>'playing' then raise exception 'Couple did not join same match';end if;
end $$;
update public.duo_matches set state=state||jsonb_build_object('phase','self','deadline',extract(epoch from now())+15) where id=(select m from fixtures);
select set_config('request.jwt.claim.sub',(select a::text from fixtures),true);
do $$declare result jsonb;
begin
 result:=public.duo_tick((select m from fixtures),null,0,0,'self');
 if result->'state'?'answer_a' or result->'state'?'answer_b' then raise exception 'Secret leaked';end if;
 perform public.duo_tick((select m from fixtures),null,2,0,'self');
 if (select self_choice from public.duo_answers where user_id=auth.uid())<>0 then raise exception 'Answer overwritten';end if;
end $$;
select set_config('request.jwt.claim.sub',(select b::text from fixtures),true);
do $$declare result jsonb;
begin result:=public.duo_tick((select m from fixtures),null,1,0,'self');if result->'state'->>'phase'<>'guess' then raise exception 'Guess phase did not start';end if;if result->'state'?'answer_a' then raise exception 'Partner self-answer leaked before guessing';end if;perform public.duo_tick((select m from fixtures),null,0,0,'guess');end $$;
select set_config('request.jwt.claim.sub',(select a::text from fixtures),true);
do $$declare result jsonb;
begin result:=public.duo_tick((select m from fixtures),null,1,0,'guess');if result->'state'->>'phase'<>'reveal' or result->'state'->>'score_a'<>'1' or result->'state'->>'score_b'<>'1' then raise exception 'Quiz reveal or scoring incorrect';end if;end $$;
select set_config('request.jwt.claim.sub',(select c::text from fixtures),true);
do $$begin begin perform public.duo_tick((select m from fixtures));raise exception 'Third account entered';exception when insufficient_privilege then null;end;end $$;
do $$declare st jsonb;r jsonb;
begin
 st:='{"x":0.5,"y":0.89,"vx":0,"vy":0.5,"paddle_a":0.5,"paddle_b":0.5,"score_a":0,"score_b":0}';r:=public.duo_pong_step(st,.05);
 if (r->>'vy')::float8>=0 then raise exception 'Paddle collision failed';end if;
 st:=st||'{"x":0.9,"y":1.04}';r:=public.duo_pong_step(st,.05);if (r->>'score_b')::int<>1 then raise exception 'Missed paddle did not score';end if;
end $$;
set local role authenticated;
do $$begin
 begin insert into public.owned_items(user_id,item_key) values(auth.uid(),'crown_gold');raise exception 'Ownership forged';exception when insufficient_privilege then null;end;
 begin update public.game_stats set love_coins=999999 where user_id=auth.uid();raise exception 'Coins forged';exception when insufficient_privilege then null;end;
 begin perform count(*) from public.duo_answers;raise exception 'Private answers readable';exception when insufficient_privilege then null;end;
end $$;
reset role;
select 'PASS: atomic purchases, slot exclusivity, insufficient funds, answer privacy, immutable answers, multiplayer scoring, collisions, currency permissions' as result;
rollback;
