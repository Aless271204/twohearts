-- Run in the migration rehearsal transaction; every test account is rolled back.
create temp table pet_test_users(a uuid,b uuid,c uuid,message uuid);
insert into pet_test_users(a,b,c) values(gen_random_uuid(),gen_random_uuid(),gen_random_uuid());
grant all on pet_test_users to authenticated;
insert into auth.users(id,email,raw_user_meta_data) select a,a::text||'@test.invalid','{}'::jsonb from pet_test_users union all select b,b::text||'@test.invalid','{}'::jsonb from pet_test_users union all select c,c::text||'@test.invalid','{}'::jsonb from pet_test_users;
update public.user_profiles set partner_id=(select b from pet_test_users) where id=(select a from pet_test_users);
update public.user_profiles set partner_id=(select a from pet_test_users) where id=(select b from pet_test_users);
-- A forged one-sided link must not grant access to somebody else's pet.
update public.user_profiles set partner_id=(select a from pet_test_users) where id=(select c from pet_test_users);

set local role authenticated;
do $$ declare a uuid; b uuid; c uuid; first_pet jsonb; second_pet jsonb; mid uuid; result jsonb; begin
 select t.a,t.b,t.c into a,b,c from pet_test_users t;
 perform set_config('request.jwt.claim.sub',a::text,true);
 first_pet:=public.shared_pet_snapshot();
 perform public.shared_pet_care('feed');
 mid:=public.pet_message_send('Mensaje de prueba de Pip');
 update pet_test_users set message=mid;
 begin perform public.pet_message_play(mid); raise exception 'Sender replay was permitted';exception when others then if sqlerrm<>'Mensaje no disponible' then raise;end if;end;
 perform set_config('request.jwt.claim.sub',c::text,true);
 if public.shared_pet_snapshot()->>'pair_key'=first_pet->>'pair_key' then raise exception 'Forged link accessed shared pet';end if;
 begin perform public.pet_message_play(mid);raise exception 'Stranger replay was permitted';exception when others then if sqlerrm<>'Mensaje no disponible' then raise;end if;end;
 perform set_config('request.jwt.claim.sub',b::text,true);
 second_pet:=public.shared_pet_care('rest');
 if second_pet->>'pair_key'<>first_pet->>'pair_key' or (second_pet->>'hunger')::integer<>95 or (second_pet->>'energy')::integer<>95 then raise exception 'Care was not shared';end if;
 if (second_pet->'contributions'->>a::text)::integer<>1 or (second_pet->'contributions'->>b::text)::integer<>1 then raise exception 'Both contributions were not stored';end if;
 if jsonb_array_length(public.pet_message_list())<>1 then raise exception 'Recipient inbox is empty';end if;
 for i in 1..5 loop
  result:=public.pet_message_play(mid);
  if result->>'content'<>'Mensaje de prueba de Pip' or (result->>'remaining')::integer<>5-i then raise exception 'Incorrect playback quota';end if;
 end loop;
 if jsonb_array_length(public.pet_message_list())<>0 then raise exception 'Fifth playback did not delete';end if;
 begin perform public.pet_message_play(mid);raise exception 'Sixth playback permitted';exception when others then if sqlerrm<>'Mensaje no disponible' then raise;end if;end;
 begin perform 1 from public.pet_messages;raise exception 'Raw content can bypass quota';exception when insufficient_privilege then null;end;
 begin perform public.runner_save_checkpoint(a,gen_random_uuid(),1,'{}',false);raise exception 'Client checkpoint write permitted';exception when insufficient_privilege then null;end;
end $$;
reset role;
do $$begin
 if exists(select 1 from public.pet_messages where id=(select message from pet_test_users)) then raise exception 'Consumed message still exists';end if;
 if has_function_privilege('anon','public.shared_pet_snapshot()','execute') then raise exception 'Anonymous pet access';end if;
end $$;
select 'PASS: mutual pairing, care from both, stranger denial, five atomic playbacks, deletion and no raw content access' as audit;
