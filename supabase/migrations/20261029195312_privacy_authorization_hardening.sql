-- Preserve existing rows. Only restrict client privileges and strengthen ownership.
-- SECURITY DEFINER RPCs keep their existing owner/service privileges.
revoke all on public.user_profiles from public, anon, authenticated;
grant select on public.user_profiles to authenticated;
grant update(full_name,avatar_url,pet_type,city,connection_type,nickname,bio,pet_portrait_style)
 on public.user_profiles to authenticated;

do $$
declare r record;
begin
 for r in select c.oid::regclass rel from pg_class c join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public' and c.relkind in ('r','p')
 loop
  execute format('revoke truncate, references, trigger on table %s from public, anon, authenticated',r.rel);
 end loop;
end $$;

create or replace function public.get_my_partner_id()
returns uuid language sql stable security definer set search_path=''
as $$
 select me.partner_id from public.user_profiles me
 join public.user_profiles partner on partner.id=me.partner_id and partner.partner_id=me.id
 where me.id=(select auth.uid()) limit 1
$$;
revoke all on function public.get_my_partner_id() from public,anon;
grant execute on function public.get_my_partner_id() to authenticated,service_role;

create or replace function public.get_couple_id_for_user(uid uuid)
returns text language plpgsql stable security definer set search_path=''
as $$
declare partner uuid;
begin
 if uid is null then return null; end if;
 -- RPC callers may only ask for their own couple, not enumerate other accounts.
 if auth.uid() is distinct from uid
   and coalesce(auth.role(),'') <> 'service_role' then
  raise exception 'Acceso no autorizado' using errcode='42501';
 end if;
 select me.partner_id into partner from public.user_profiles me
 join public.user_profiles other on other.id=me.partner_id and other.partner_id=me.id
 where me.id=uid;
 if partner is null then return uid::text; end if;
 return least(uid,partner)::text || '_' || greatest(uid,partner)::text;
end $$;
revoke all on function public.get_couple_id_for_user(uuid) from public,anon;
grant execute on function public.get_couple_id_for_user(uuid) to authenticated,service_role;

revoke all on function public.handle_new_user() from public,anon,authenticated;
-- Pin built-ins before any application namespace, including trigger functions.
do $$
declare r record;
begin
 for r in select p.oid::regprocedure signature from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname='public' and p.proname in
 ('generate_invite_code','handle_new_user','update_memory_albums_updated_at',
  'update_nido_memories_updated_at','update_post_interaction_count','update_updated_at_column')
 loop execute format('alter function %s set search_path = pg_catalog, public',r.signature); end loop;
end $$;

drop policy if exists users_read_couple_locations on public.couple_locations;
create policy users_read_couple_locations on public.couple_locations for select to authenticated
using(user_id=(select auth.uid()) or user_id=(select public.get_my_partner_id()));

drop policy if exists users_can_send_messages on public.couple_messages;
create policy users_can_send_messages on public.couple_messages for insert to authenticated
with check(sender_id=(select auth.uid()) and receiver_id=(select public.get_my_partner_id()));
revoke update on public.couple_messages from public,anon,authenticated;
grant update(reply_content,reply_at,is_read) on public.couple_messages to authenticated;

-- Static partner_id must not continue authorizing a former partner after unlink.
do $$
declare t text;
begin
 foreach t in array array['nido_dates','nido_memories','nido_trips'] loop
  execute format('drop policy if exists %I on public.%I','couple_access_'||t,t);
  execute format('create policy %I on public.%I for all to authenticated using (owner_id=(select auth.uid()) or owner_id=(select public.get_my_partner_id())) with check (owner_id=(select auth.uid()))','couple_access_'||t,t);
 end loop;
end $$;
drop policy if exists couple_can_view_memory_albums on public.memory_albums;
create policy couple_can_view_memory_albums on public.memory_albums for select to authenticated
using(user_id=(select auth.uid()) or
 (user_id=(select public.get_my_partner_id()) and couple_id=public.get_couple_id_for_user(auth.uid())));

-- Abort the entire installation if the privilege boundary is not effective.
do $$
begin
 if has_column_privilege('authenticated','public.user_profiles','partner_id','UPDATE')
 or has_column_privilege('authenticated','public.user_profiles','invite_code','UPDATE')
 or has_table_privilege('authenticated','public.user_profiles','INSERT')
 or has_table_privilege('authenticated','public.user_profiles','DELETE')
 or has_table_privilege('authenticated','public.user_profiles','TRUNCATE')
 or has_function_privilege('anon','public.get_couple_id_for_user(uuid)','EXECUTE')
 or has_function_privilege('authenticated','public.handle_new_user()','EXECUTE')
 then raise exception 'Privacy hardening privilege regression'; end if;
 if not has_column_privilege('authenticated','public.user_profiles','nickname','UPDATE')
 or not has_table_privilege('authenticated','public.user_profiles','SELECT')
 or not has_function_privilege('authenticated','public.link_partner_by_invite_code(text,date,text)','EXECUTE')
 then raise exception 'Normal application access regression'; end if;
end $$;
