-- Run inside BEGIN/ROLLBACK. Synthetic identities never survive this test.
create temporary table social_test_ids(a uuid,b uuid,c uuid,post uuid,anon_post uuid,expired uuid,comment uuid);
insert into social_test_ids(a,b,c) values(gen_random_uuid(),gen_random_uuid(),gen_random_uuid());
insert into auth.users(id,email,raw_user_meta_data) select id,id::text||'@social-test.invalid','{}'::jsonb from social_test_ids cross join lateral (values(a),(b),(c)) x(id);
update public.user_profiles set nickname='Public nickname',full_name='PRIVATE FULL NAME',city='PRIVATE CITY' where id in(select a from social_test_ids union select b from social_test_ids union select c from social_test_ids);
grant select,update on social_test_ids to authenticated;
select set_config('request.jwt.claims',jsonb_build_object('sub',a,'role','authenticated')::text,true) from social_test_ids;
set local role authenticated;
update social_test_ids set post=public.social_create_post('phrase','A real isolated test',false,''),anon_post=public.social_create_post('phrase','Anonymous isolated test',true,'');
do $$ declare denied boolean:=false;begin
 begin update public.social_posts set expires_at=now()+interval '1 year'; exception when insufficient_privilege then denied:=true;end;
 assert denied,'Clients must not extend lifetime or rewrite counts';
 assert (public.social_feed('friends')->'posts') @> '[{"is_mine":true}]'::jsonb,'Own posts must appear without following anyone';
end $$;
reset role;
update social_test_ids set expired=gen_random_uuid();
insert into public.social_posts(id,owner_id,post_type,content,created_at,expires_at) select expired,a,'phrase','Expired',now()-interval '25 hours',now()-interval '1 hour' from social_test_ids;
select set_config('request.jwt.claims',jsonb_build_object('sub',b,'role','authenticated')::text,true) from social_test_ids;
set local role authenticated;
do $$ declare response jsonb; v_post uuid; denied boolean:=false;begin
 select post into v_post from social_test_ids;
 response:=public.social_feed('discover');
 assert jsonb_array_length(response->'posts')>=2,'Discover must show other active posts';
 assert response::text not like '%PRIVATE FULL NAME%' and response::text not like '%PRIVATE CITY%' and response::text not like '%social-test.invalid%','No private profile fields in feed';
 assert exists(select 1 from jsonb_array_elements(response->'posts') p where p->>'is_anonymous'='true' and p->>'author_id' is null),'Anonymous identity must be hidden';
 assert (select count(*) from public.social_posts)=0,'Raw table cannot reveal another author';
 response:=public.social_set_like(v_post,true);assert (response->>'likes_count')::int=1;
 response:=public.social_set_like(v_post,true);assert (response->>'likes_count')::int=1,'Retrying a like must not duplicate it';
 response:=public.social_set_like(v_post,false);assert (response->>'likes_count')::int=0;
 response:=public.social_set_like(v_post,true);assert (response->>'likes_count')::int=1;
 begin perform public.social_set_like((select expired from social_test_ids),true);exception when insufficient_privilege then denied:=true;end;
 assert denied,'Expired posts must reject interaction';
 update social_test_ids set comment=public.social_add_comment(v_post,'A comment from B');
 assert jsonb_array_length(public.social_comments(v_post))=1;
 begin insert into public.post_likes(post_id,user_id) select post,a from social_test_ids;exception when insufficient_privilege then null;end;
 assert not exists(select 1 from public.user_profiles where id=(select a from social_test_ids)),'Private profiles remain restricted';
 perform public.social_set_follow((select a from social_test_ids),true);
 assert exists(select 1 from jsonb_array_elements(public.social_feed('friends')->'posts') p where p->>'id'=v_post::text),'Following must populate Friends';
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',c,'role','authenticated')::text,true) from social_test_ids;
set local role authenticated;
do $$ begin
 perform public.social_delete_comment((select comment from social_test_ids));
 assert jsonb_array_length(public.social_comments((select post from social_test_ids)))=1,'A third user cannot delete another comment';
 assert (select count(*) from public.social_follows)=0,'Following graphs stay private';
 assert (select count(*) from public.post_likes)=0,'Liker identities stay private';
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',b,'role','authenticated')::text,true) from social_test_ids;
set local role authenticated;
do $$ begin
 perform public.social_report_post((select post from social_test_ids),'other');
 perform public.social_block_post_author((select post from social_test_ids));
 assert not exists(select 1 from jsonb_array_elements(public.social_feed('discover')->'posts') p where p->>'id'=(select post::text from social_test_ids)),'Blocking must hide the author';
end $$;
reset role;
select set_config('request.jwt.claims','{}',true);
set local role anon;
do $$ declare denied boolean:=false;begin
 begin perform public.social_feed('discover');exception when insufficient_privilege then denied:=true;end;
 assert denied,'Signed-out requests cannot read feed';
 denied:=false;begin perform 1 from public.social_posts;exception when insufficient_privilege then denied:=true;end;
 assert denied,'Signed-out requests cannot read raw posts';
end $$;
reset role;
do $$ begin
 assert (select not public from storage.buckets where id='social-media'),'Social photos cannot have public URLs';
 assert (select qual like '%allow_any_operation%' and qual not like '%sign%' from pg_policies where schemaname='storage' and policyname='social_media_read'),'Media policy must exclude signed URL creation';
 assert exists(select 1 from cron.job where jobname='social-expired-posts' and active),'Expired row cleanup must be scheduled';
end $$;
