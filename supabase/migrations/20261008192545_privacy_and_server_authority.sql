begin;

-- Trigger helpers are not public API endpoints. Pin every application function.
alter function public.generate_invite_code() set search_path=pg_catalog,public;
alter function public.handle_new_user() set search_path=pg_catalog,public;
alter function public.update_updated_at_column() set search_path=pg_catalog,public;
alter function public.update_nido_memories_updated_at() set search_path=pg_catalog,public;
alter function public.update_post_interaction_count() set search_path=pg_catalog,public;
alter function public.update_memory_albums_updated_at() set search_path=pg_catalog,public;
revoke execute on function public.handle_new_user(), public.update_post_interaction_count() from public,anon,authenticated;
revoke execute on function public.get_couple_id_for_user(uuid) from public,anon;

create or replace function public.get_couple_id_for_user(uid uuid)
returns text language plpgsql stable security definer
set search_path=pg_catalog,public as $$
declare partner uuid; caller uuid:=auth.uid();
begin
 if caller is null or caller<>uid then raise exception 'Not authorized' using errcode='42501'; end if;
 select up.partner_id into partner from public.user_profiles up where up.id=caller;
 if partner is null then return caller::text; end if;
 return least(caller,partner)::text||'_'||greatest(caller,partner)::text;
end $$;
grant execute on function public.get_couple_id_for_user(uuid) to authenticated;

-- RLS does not govern TRUNCATE. Clients must never manage table structure.
revoke truncate,references,trigger on all tables in schema public from anon,authenticated;
revoke insert,update,delete on public.user_profiles from anon,authenticated;
grant update(full_name,avatar_url,relationship_start,pet_type,city,connection_type,nickname,bio)
 on public.user_profiles to authenticated;
revoke insert,update,delete on public.game_stats,public.game_scores,public.game_records,
 public.owned_items,public.runner_sessions,public.duo_rewards from anon,authenticated;

update storage.buckets set public=false where id='memory-photos';
drop policy if exists public_can_view_memory_photos on storage.objects;
drop policy if exists authenticated_can_upload_memory_photos on storage.objects;
drop policy if exists users_can_delete_own_memory_photos on storage.objects;
create policy memory_photos_owner_upload on storage.objects for insert to authenticated
with check(bucket_id='memory-photos' and (storage.foldername(name))[1]='albums'
 and (storage.foldername(name))[2]=(select auth.uid())::text);
create policy memory_photos_couple_read on storage.objects for select to authenticated
using(bucket_id='memory-photos' and (storage.foldername(name))[1]='albums'
 and ((storage.foldername(name))[2]=(select auth.uid())::text
 or (storage.foldername(name))[2]=(select public.get_my_partner_id())::text));
create policy memory_photos_owner_delete on storage.objects for delete to authenticated
using(bucket_id='memory-photos' and (storage.foldername(name))[1]='albums'
 and (storage.foldername(name))[2]=(select auth.uid())::text);
commit;
