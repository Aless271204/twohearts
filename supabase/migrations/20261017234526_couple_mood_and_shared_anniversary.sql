create table nido_private.couple_moods(user_id uuid primary key references auth.users(id) on delete cascade,mood text not null check(mood in ('happy','calm','tired','sad','stressed','affectionate')),sharing boolean not null default false,updated_at timestamptz not null default now());
alter table nido_private.couple_moods enable row level security;
revoke all on nido_private.couple_moods from public,anon,authenticated;
create or replace function public.couple_state(p_action text default 'snapshot',p_data jsonb default '{}') returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();ids uuid[];partner uuid;start_date date;new_date date;
begin
 if u is null then raise exception 'Inicia sesión' using errcode='42501';end if;
 ids:=nido_private.wallet_members(u);select x into partner from unnest(ids)x where x<>u;
 if p_action='mood' then
  if p_data->>'mood' is null or p_data->>'mood' not in ('happy','calm','tired','sad','stressed','affectionate') then raise exception 'Estado no válido';end if;
  insert into nido_private.couple_moods(user_id,mood,sharing) values(u,p_data->>'mood',coalesce((p_data->>'sharing')::boolean,false))
  on conflict(user_id) do update set mood=excluded.mood,sharing=excluded.sharing,updated_at=now();
 elsif p_action='anniversary' then
  new_date:=(p_data->>'start')::date;
  if new_date is null or new_date>current_date or new_date<date '1900-01-01' then raise exception 'Fecha no válida';end if;
  perform 1 from public.user_profiles where id=any(ids) order by id for update;
  if ids is distinct from nido_private.wallet_members(u) then raise exception 'La pareja cambió. Vuelve a intentar';end if;
  update public.user_profiles set relationship_start=new_date where id=any(ids);
 elsif p_action<>'snapshot' then raise exception 'Acción no válida';end if;
 select min(relationship_start) into start_date from public.user_profiles where id=any(ids);
 return jsonb_build_object('start',start_date,'paired',partner is not null,
  'mine',(select to_jsonb(m)-'user_id' from nido_private.couple_moods m where m.user_id=u),
  'partner',(select to_jsonb(m)-'user_id' from nido_private.couple_moods m where m.user_id=partner and m.sharing));
end $$;
revoke all on function public.couple_state(text,jsonb) from public,anon;
grant execute on function public.couple_state(text,jsonb) to authenticated;

-- Existing private widget capabilities may read a derived distance and a
-- deliberately shared mood, never a session, raw coordinates or account data.
create or replace function nido_private.art_widget_note(p_token text) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare u uuid;partner uuid;note jsonb;stats jsonb;d double precision;
begin
 select p.id,q.id into u,partner from nido_private.art_widget_tokens t join public.user_profiles p on p.id=t.user_id join public.user_profiles q on q.id=p.partner_id and q.partner_id=p.id
 where length(p_token)=64 and t.token_hash=extensions.digest(p_token,'sha256') and t.expires_at>now();
 if u is null then return '{}';end if;
 select to_jsonb(n)-'recipient'-'sender' into note from nido_private.partner_art_notes n where n.sender=partner and n.recipient=u;
 select jsonb_build_object('start',min(relationship_start)) into stats from public.user_profiles where id in(u,partner);
 select 6371*2*asin(sqrt(least(1.0,greatest(0.0,power(sin(radians(b.lat-a.lat)/2),2)+cos(radians(a.lat))*cos(radians(b.lat))*power(sin(radians(b.lon-a.lon)/2),2))))) into d
 from nido_private.couple_locations a join nido_private.couple_locations b on b.user_id=partner where a.user_id=u and a.located_at is not null and b.located_at is not null;
 if d is not null then stats:=stats||jsonb_build_object('km',d,'located_at',(select min(located_at) from nido_private.couple_locations where user_id in(u,partner)));end if;
 return coalesce(note,'{}')||jsonb_build_object('couple_stats',stats,'partner_mood',(select to_jsonb(m)-'user_id' from nido_private.couple_moods m where user_id=partner and sharing));
end $$;
