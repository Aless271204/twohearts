begin;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('profile-avatars','profile-avatars',false,3145728,array['image/png']) on conflict(id) do nothing;
create policy avatar_owner_insert on storage.objects for insert to authenticated with check(bucket_id='profile-avatars' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy avatar_owner_delete on storage.objects for delete to authenticated using(bucket_id='profile-avatars' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy avatar_owner_select on storage.objects for select to authenticated using(bucket_id='profile-avatars' and ((storage.foldername(name))[1]=(select auth.uid())::text or exists(select 1 from public.user_profiles me join public.user_profiles partner on me.partner_id=partner.id and partner.partner_id=me.id where me.id=(select auth.uid()) and partner.id::text=(storage.foldername(name))[1])));
create table nido_private.couple_locations(user_id uuid primary key references public.user_profiles(id) on delete cascade,sharing boolean not null default false,lat double precision,lon double precision,located_at timestamptz,check(lat between -90 and 90),check(lon between -180 and 180));
alter table nido_private.couple_locations enable row level security;
revoke all on nido_private.couple_locations from public,anon,authenticated;
create function nido_private.couple_location(p_action text default 'snapshot',p_lat double precision default null,p_lon double precision default null) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); partner uuid;mine jsonb;other jsonb;
begin
 if u is null then raise exception 'Inicia sesión' using errcode='42501';end if;
 if p_action not in('snapshot','enable','disable','publish') then raise exception 'Acción no válida';end if;
 if p_action in('enable','disable') then
  insert into nido_private.couple_locations(user_id,sharing) values(u,p_action='enable') on conflict(user_id) do update set sharing=excluded.sharing;
 elsif p_action='publish' then
  if p_lat is null or p_lon is null or p_lat::text in('NaN','Infinity','-Infinity') or p_lon::text in('NaN','Infinity','-Infinity') or abs(p_lat)>90 or abs(p_lon)>180 then raise exception 'Coordenadas no válidas';end if;
  update nido_private.couple_locations set lat=p_lat,lon=p_lon,located_at=clock_timestamp() where user_id=u and sharing;
 end if;
 select partner_id into partner from public.user_profiles where id=u;
 select jsonb_build_object('sharing',sharing,'lat',lat,'lon',lon,'located_at',located_at) into mine from nido_private.couple_locations where user_id=u;
 if partner is not null and exists(select 1 from public.user_profiles where id=partner and partner_id=u) then
  select jsonb_build_object('sharing',sharing,'lat',lat,'lon',lon,'located_at',located_at) into other from nido_private.couple_locations where user_id=partner;
 end if;
 return jsonb_build_object('mine',mine,'partner',other);
end $$;
create function public.couple_location(p_action text default 'snapshot',p_lat double precision default null,p_lon double precision default null) returns jsonb language sql security invoker set search_path='' as $$select nido_private.couple_location(p_action,p_lat,p_lon)$$;
revoke all on function public.couple_location(text,double precision,double precision),nido_private.couple_location(text,double precision,double precision) from public,anon;
grant execute on function public.couple_location(text,double precision,double precision),nido_private.couple_location(text,double precision,double precision) to authenticated;
commit;
