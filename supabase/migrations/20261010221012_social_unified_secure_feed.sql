-- One schema shared by the feed, publishing, follows, likes and comments.
-- Private profiles are never made public to satisfy a feed join.
create schema if not exists private;
alter table public.social_posts add column if not exists deleted_at timestamptz;
alter table public.social_follows add column if not exists following_id uuid references auth.users(id) on delete cascade;
alter table public.social_follows alter column followed_couple_id drop not null;
create unique index if not exists social_follows_people_unique on public.social_follows(follower_id,following_id) where following_id is not null;
create index if not exists social_posts_active_date on public.social_posts(created_at desc) where deleted_at is null;
create index if not exists social_posts_expiry on public.social_posts(expires_at);
create table if not exists public.post_comments (
 id uuid primary key default gen_random_uuid(), post_id uuid not null references public.social_posts(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 content text not null check(char_length(btrim(content)) between 1 and 500), created_at timestamptz not null default now()
);
create index if not exists post_comments_post_date on public.post_comments(post_id,created_at);
create table if not exists public.social_blocks (
 user_id uuid not null references auth.users(id) on delete cascade,
 blocked_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(), primary key(user_id,blocked_id), check(user_id<>blocked_id)
);
create table if not exists public.social_reports (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 post_id uuid not null references public.social_posts(id) on delete cascade,
 reason text not null check(reason in ('spam','offensive','privacy','other')),
 created_at timestamptz not null default now(), unique(user_id,post_id)
);

-- Remove the permissive legacy policies, including PUBLIC USING(true).
do $$ declare r record; begin
 for r in select schemaname,tablename,policyname from pg_policies where schemaname='public'
 and tablename in ('social_posts','social_follows','post_likes','post_comments','social_blocks','social_reports') loop
  execute format('drop policy %I on %I.%I',r.policyname,r.schemaname,r.tablename);
 end loop;
end $$;
alter table public.social_posts enable row level security;
alter table public.social_follows enable row level security;
alter table public.post_likes enable row level security;
alter table public.post_comments enable row level security;
alter table public.social_blocks enable row level security;
alter table public.social_reports enable row level security;
revoke all on public.social_posts, public.social_follows, public.post_likes, public.post_comments, public.social_blocks, public.social_reports from anon, authenticated;
-- Mutations are exclusively through guarded RPCs; base rows show only one's own data.
grant select on public.social_posts, public.social_follows, public.post_likes, public.post_comments, public.social_blocks, public.social_reports to authenticated;
create policy social_own_posts on public.social_posts for select to authenticated using(owner_id=(select auth.uid()) and expires_at>now() and deleted_at is null);
create policy social_own_follows on public.social_follows for select to authenticated using(follower_id=(select auth.uid()));
create policy social_own_likes on public.post_likes for select to authenticated using(user_id=(select auth.uid()) and exists(select 1 from public.social_posts p where p.id=post_id and p.expires_at>now()));
create policy social_own_comments on public.post_comments for select to authenticated using(user_id=(select auth.uid()) and exists(select 1 from public.social_posts p where p.id=post_id and p.expires_at>now()));
create policy social_own_blocks on public.social_blocks for select to authenticated using(user_id=(select auth.uid()));
create policy social_own_reports on public.social_reports for select to authenticated using(user_id=(select auth.uid()));

create or replace function private.social_require_user() returns uuid language plpgsql stable set search_path='' as $$
begin
 if auth.uid() is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then
  raise exception 'Inicia sesión para usar Social' using errcode='42501';
 end if;
 return auth.uid();
end $$;
create or replace function private.social_can_read(p_post uuid) returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and not coalesce((auth.jwt()->>'is_anonymous')::boolean,false) and exists(
  select 1 from public.social_posts p where p.id=p_post and p.expires_at>now() and p.deleted_at is null
  and not exists(select 1 from public.social_blocks b where (b.user_id=auth.uid() and b.blocked_id=p.owner_id) or (b.blocked_id=auth.uid() and b.user_id=p.owner_id))
 );
$$;
create or replace function private.social_post_json(p public.social_posts) returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('id',p.id,'author_id',case when p.is_anon then null else p.owner_id end,
  'display_name',case when p.is_anon then 'Anónimo' else coalesce(nullif(btrim(u.nickname),''),'Pareja') end,
  'is_mine',p.owner_id=auth.uid(),'is_anonymous',p.is_anon,'content_type',p.post_type,'content',p.content,'caption',p.caption,
  'created_at',p.created_at,'expires_at',p.expires_at,'likes_count',p.likes_count,'comments_count',p.comments_count,
  'liked',exists(select 1 from public.post_likes l where l.post_id=p.id and l.user_id=auth.uid()),
  'following',exists(select 1 from public.social_follows f where f.follower_id=auth.uid() and f.following_id=p.owner_id))
 from (select 1) dummy left join public.user_profiles u on u.id=p.owner_id;
$$;
create or replace function public.social_feed(p_mode text default 'friends',p_before timestamptz default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=private.social_require_user(); v_posts jsonb;
begin
 if p_mode not in ('friends','discover') then raise exception 'Filtro no válido'; end if;
 select coalesce(jsonb_agg(private.social_post_json(q::public.social_posts) order by q.created_at desc,q.id desc),'[]'::jsonb) into v_posts
 from (select p.* from public.social_posts p where private.social_can_read(p.id)
  and (p_before is null or p.created_at<p_before)
  and (p_mode='discover' or p.owner_id=v_uid or (not p.is_anon and exists(select 1 from public.social_follows f where f.follower_id=v_uid and f.following_id=p.owner_id)))
  order by p.created_at desc,p.id desc limit 30) q;
 return jsonb_build_object('server_now',now(),'posts',v_posts);
end $$;
create or replace function public.social_create_post(p_type text,p_content text,p_anonymous boolean default false,p_caption text default '') returns uuid
language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=private.social_require_user(); v_id uuid;
begin
 perform pg_advisory_xact_lock(hashtextextended(v_uid::text,0));
 if p_type not in ('phrase','emoji','image') or char_length(btrim(p_content)) not between 1 and 2000 or char_length(p_caption)>500 then raise exception 'Revisa el contenido de la publicación'; end if;
 if (select count(*) from public.social_posts where owner_id=v_uid and created_at>now()-interval '1 hour')>=10 then raise exception 'Espera un poco antes de publicar de nuevo'; end if;
 if p_type='image' and (p_content !~ '^[a-zA-Z0-9_-]+\.(jpg|png|webp)$' or not exists(select 1 from storage.objects o where o.bucket_id='social-media' and o.name=p_content and o.owner_id=v_uid::text and o.created_at>now()-interval '1 hour')) then
  raise exception 'Selecciona una imagen subida desde tu cuenta';
 end if;
 insert into public.social_posts(owner_id,post_type,content,caption,is_anon,created_at,expires_at,likes,likes_count,comments_count,interaction_count)
 values(v_uid,p_type,btrim(p_content),btrim(p_caption),coalesce(p_anonymous,false),now(),now()+interval '24 hours',0,0,0,0) returning id into v_id;
 return v_id;
end $$;
create or replace function public.social_set_like(p_post uuid,p_liked boolean) returns jsonb
language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=private.social_require_user(); v_post public.social_posts;
begin
 select * into v_post from public.social_posts where id=p_post for update;
 if not private.social_can_read(p_post) then raise exception 'La publicación ya no está disponible' using errcode='42501'; end if;
 if p_liked then insert into public.post_likes(post_id,user_id) values(p_post,v_uid) on conflict(post_id,user_id) do nothing;
 else delete from public.post_likes where post_id=p_post and user_id=v_uid; end if;
 select * into v_post from public.social_posts where id=p_post;
 return private.social_post_json(v_post);
end $$;
create or replace function private.social_count_interaction() returns trigger language plpgsql security definer set search_path='' as $$
declare v_id uuid:=case when tg_op='DELETE' then old.post_id else new.post_id end; v_delta int:=case when tg_op='DELETE' then -1 else 1 end;
begin
 if tg_table_name='post_likes' then update public.social_posts set likes_count=greatest(0,likes_count+v_delta),likes=greatest(0,likes+v_delta),interaction_count=greatest(0,interaction_count+v_delta) where id=v_id;
 else update public.social_posts set comments_count=greatest(0,comments_count+v_delta),interaction_count=greatest(0,interaction_count+v_delta) where id=v_id; end if;
 return null;
end $$;
drop trigger if exists trg_post_likes_count on public.post_likes;
create trigger trg_post_likes_count after insert or delete on public.post_likes for each row execute function private.social_count_interaction();
create trigger trg_post_comments_count after insert or delete on public.post_comments for each row execute function private.social_count_interaction();
revoke all on function public.update_post_interaction_count() from public,anon,authenticated;
create or replace function public.social_comments(p_post uuid,p_before timestamptz default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=private.social_require_user(); v_result jsonb;
begin
 if not private.social_can_read(p_post) then raise exception 'La publicación ya no está disponible' using errcode='42501'; end if;
 select coalesce(jsonb_agg(jsonb_build_object('id',q.id,'content',q.content,'created_at',q.created_at,'display_name',coalesce(nullif(btrim(u.nickname),''),'Pareja'),'is_mine',q.user_id=v_uid) order by q.created_at desc,q.id desc),'[]'::jsonb) into v_result
 from (select c.* from public.post_comments c where c.post_id=p_post and (p_before is null or c.created_at<p_before)
  and not exists(select 1 from public.social_blocks b where (b.user_id=v_uid and b.blocked_id=c.user_id) or (b.blocked_id=v_uid and b.user_id=c.user_id))
  order by c.created_at desc,c.id desc limit 50) q left join public.user_profiles u on u.id=q.user_id;
 return v_result;
end $$;
create or replace function public.social_add_comment(p_post uuid,p_content text) returns uuid
language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=private.social_require_user(); v_id uuid;
begin
 perform pg_advisory_xact_lock(hashtextextended(v_uid::text,1));
 perform 1 from public.social_posts where id=p_post for update;
 if not private.social_can_read(p_post) then raise exception 'La publicación ya no está disponible' using errcode='42501'; end if;
 if char_length(btrim(p_content)) not between 1 and 500 then raise exception 'Escribe entre 1 y 500 caracteres'; end if;
 if (select count(*) from public.post_comments where user_id=v_uid and created_at>now()-interval '1 minute')>=10 then raise exception 'Espera un poco antes de comentar de nuevo'; end if;
 insert into public.post_comments(post_id,user_id,content) values(p_post,v_uid,btrim(p_content)) returning id into v_id; return v_id;
end $$;
create or replace function public.social_delete_comment(p_comment uuid) returns void
language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=private.social_require_user(); v_post uuid;
begin
 select post_id into v_post from public.post_comments where id=p_comment;
 perform 1 from public.social_posts where id=v_post for update;
 if not private.social_can_read(v_post) then raise exception 'La publicación ya no está disponible' using errcode='42501'; end if;
 delete from public.post_comments c where c.id=p_comment and (c.user_id=v_uid or exists(select 1 from public.social_posts p where p.id=c.post_id and p.owner_id=v_uid));
end $$;
create or replace function public.social_set_follow(p_author uuid,p_follow boolean) returns void
language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=private.social_require_user();
begin
 if p_author=v_uid then raise exception 'No puedes seguirte a ti mismo'; end if;
 if p_follow then
  if not exists(select 1 from public.social_posts p where p.owner_id=p_author and not p.is_anon and private.social_can_read(p.id)) then raise exception 'Este perfil no está disponible'; end if;
  insert into public.social_follows(follower_id,following_id) values(v_uid,p_author) on conflict(follower_id,following_id) where following_id is not null do nothing;
 else delete from public.social_follows where follower_id=v_uid and following_id=p_author; end if;
end $$;
create or replace function public.social_delete_post(p_post uuid) returns void
language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=private.social_require_user();
begin update public.social_posts set deleted_at=now() where id=p_post and owner_id=v_uid; end $$;
create or replace function public.social_report_post(p_post uuid,p_reason text) returns void
language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=private.social_require_user();
begin
 if not private.social_can_read(p_post) then raise exception 'Esta publicación no está disponible'; end if;
 insert into public.social_reports(user_id,post_id,reason) values(v_uid,p_post,p_reason) on conflict(user_id,post_id) do nothing;
end $$;
create or replace function public.social_block_post_author(p_post uuid) returns void
language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=private.social_require_user(); v_author uuid;
begin
 if not private.social_can_read(p_post) then raise exception 'Esta publicación no está disponible'; end if;
 select owner_id into v_author from public.social_posts where id=p_post;
 if v_author=v_uid then raise exception 'No puedes bloquearte a ti mismo'; end if;
 insert into public.social_blocks(user_id,blocked_id) values(v_uid,v_author) on conflict do nothing;
 delete from public.social_follows where (follower_id=v_uid and following_id=v_author) or (follower_id=v_author and following_id=v_uid);
end $$;

do $$ declare r record; begin
 for r in select oid::regprocedure signature from pg_proc where pronamespace='private'::regnamespace and proname like 'social_%' loop
  execute format('revoke all on function %s from public,anon,authenticated',r.signature);
 end loop;
end $$;
grant usage on schema private to authenticated;
grant execute on function private.social_can_read(uuid) to authenticated;
do $$ declare r record; begin
 for r in select oid::regprocedure signature from pg_proc where pronamespace='public'::regnamespace and proname in
 ('social_feed','social_create_post','social_set_like','social_comments','social_add_comment','social_delete_comment','social_set_follow','social_delete_post','social_report_post','social_block_post_author') loop
  execute format('revoke all on function %s from public,anon,authenticated',r.signature);
  execute format('grant execute on function %s to authenticated',r.signature);
 end loop;
end $$;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('social-media','social-media',false,5242880,array['image/jpeg','image/png','image/webp']) on conflict(id) do update set public=false,file_size_limit=5242880,allowed_mime_types=array['image/jpeg','image/png','image/webp'];
create policy social_media_upload on storage.objects for insert to authenticated with check(bucket_id='social-media' and owner_id=auth.uid()::text and name ~ '^[a-zA-Z0-9_-]+\.(jpg|png|webp)$');
create policy social_media_read on storage.objects for select to authenticated using(bucket_id='social-media' and exists(select 1 from public.social_posts p where p.post_type='image' and p.content=name and private.social_can_read(p.id)));
-- The subquery above needs a projection that does not depend on owner-only RLS.
create or replace function private.social_media_read(p_name text) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.social_posts p where p.post_type='image' and p.content=p_name and private.social_can_read(p.id));
$$;
revoke all on function private.social_media_read(text) from public,anon;
grant execute on function private.social_media_read(text) to authenticated;
drop policy social_media_read on storage.objects;
create policy social_media_read on storage.objects for select to authenticated using(bucket_id='social-media' and storage.allow_any_operation(array['object.get_authenticated','object.get_authenticated_info']) and private.social_media_read(name));
create policy social_media_delete_own on storage.objects for delete to authenticated using(bucket_id='social-media' and owner_id=auth.uid()::text);
-- Expired content is denied immediately; row cleanup is separate from visibility.
create extension if not exists pg_cron;
select cron.schedule('social-expired-posts','*/5 * * * *',$job$delete from public.social_posts where expires_at<=now() or deleted_at is not null;$job$);
