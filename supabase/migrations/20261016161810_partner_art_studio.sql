-- Private drawing matches and the latest Noteit-style note. No public artwork URLs.
create table nido_private.art_rooms (
 id uuid primary key default gen_random_uuid(), code text unique not null,
 host uuid not null references auth.users on delete cascade,
 guest uuid not null references auth.users on delete cascade,
 difficulty int not null check(difficulty between 0 and 2), scene int not null check(scene between 0 and 11),
 host_ready boolean not null default false, guest_ready boolean not null default false,
 deadline timestamptz, created_at timestamptz not null default now(),
 host_art text, guest_art text, host_vote uuid, guest_vote uuid,
 check(host<>guest)
);
alter table nido_private.art_rooms enable row level security;
revoke all on nido_private.art_rooms from public,anon,authenticated;
create index art_rooms_host_time on nido_private.art_rooms(host,created_at desc);
create index art_rooms_guest_time on nido_private.art_rooms(guest,created_at desc);
create table nido_private.partner_art_notes (
 sender uuid primary key references auth.users on delete cascade,
 recipient uuid not null references auth.users on delete cascade,
 kind text not null check(kind in ('text','image')), content text not null,
 sent_at timestamptz not null default now(), check(sender<>recipient)
);
alter table nido_private.partner_art_notes enable row level security;
revoke all on nido_private.partner_art_notes from public,anon,authenticated;
create index partner_art_recipient on nido_private.partner_art_notes(recipient);
create table nido_private.art_widget_tokens (
 user_id uuid primary key references auth.users on delete cascade,
 token_hash bytea not null unique, expires_at timestamptz not null
);
alter table nido_private.art_widget_tokens enable row level security;
revoke all on nido_private.art_widget_tokens from public,anon,authenticated;

-- Fixed search path, authenticated identity and reciprocal pairing checked on every operation.
create function nido_private.art_action(p_action text,p_data jsonb default '{}') returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); partner uuid; r nido_private.art_rooms; token text; result jsonb; art text;
begin
 if u is null then raise exception 'Inicia sesión'; end if;
 select p.partner_id into partner from public.user_profiles p
 join public.user_profiles q on q.id=p.partner_id and q.partner_id=p.id where p.id=u;
 if p_action='revoke_widget' then delete from nido_private.art_widget_tokens where user_id=u; return '{}'; end if;
 if partner is null then raise exception 'Vincula primero tu cuenta con tu pareja'; end if;
 if p_action='widget_token' then
  token:=encode(extensions.gen_random_bytes(32),'hex');
  insert into nido_private.art_widget_tokens values(u,extensions.digest(token,'sha256'),now()+interval '30 days')
  on conflict(user_id) do update set token_hash=excluded.token_hash,expires_at=excluded.expires_at;
  return jsonb_build_object('token',token);
 elsif p_action='note' then
  if exists(select 1 from nido_private.partner_art_notes where sender=u and sent_at>now()-interval '5 seconds') then raise exception 'Espera unos segundos'; end if;
  art:=p_data->>'content';
  if p_data->>'kind'='text' then
   if length(trim(art)) not between 1 and 500 then raise exception 'Escribe hasta 500 caracteres'; end if;
  elsif p_data->>'kind'='image' then
   if length(art) not between 16 and 1400000 or art !~ '^[A-Za-z0-9+/=]+$' or left(art,11)<>'iVBORw0KGgo' then raise exception 'Imagen PNG no válida o demasiado grande'; end if;
  else raise exception 'Tipo no válido'; end if;
  insert into nido_private.partner_art_notes values(u,partner,p_data->>'kind',art,now())
  on conflict(sender) do update set recipient=excluded.recipient,kind=excluded.kind,content=excluded.content,sent_at=now();
  return jsonb_build_object('sent',true);
 elsif p_action='inbox' then
  select to_jsonb(n)-'recipient' into result from nido_private.partner_art_notes n where sender=partner and recipient=u;
  return coalesce(result,'{}');
 elsif p_action='create' then
  if (select count(*) from nido_private.art_rooms where host=u and created_at>now()-interval '1 day')>=20 then raise exception 'Máximo 20 partidas al día'; end if;
  insert into nido_private.art_rooms(code,host,guest,difficulty,scene)
  values(upper(left(replace(gen_random_uuid()::text,'-',''),8)),u,partner,(p_data->>'difficulty')::int,floor(random()*12)::int) returning * into r;
 elsif p_action='join' then
  select * into r from nido_private.art_rooms where guest=u and host=partner and deadline is null and created_at>now()-interval '30 minutes' order by created_at desc limit 1;
  if r.id is null then raise exception 'Tu pareja debe crear una partida primero'; end if;
 else
  select * into r from nido_private.art_rooms where id=(p_data->>'id')::uuid and ((host=u and guest=partner) or (guest=u and host=partner)) and created_at>now()-interval '30 days' for update;
  if r.id is null then raise exception 'Partida no disponible'; end if;
  if p_action='ready' and r.deadline is null then
   update nido_private.art_rooms set host_ready=host_ready or host=u,guest_ready=guest_ready or guest=u where id=r.id returning * into r;
   if r.host_ready and r.guest_ready then update nido_private.art_rooms set deadline=now()+interval '5 minutes 3 seconds' where id=r.id returning * into r; end if;
  elsif p_action='submit' then
   if r.deadline is null or now()<r.deadline then raise exception 'Aún quedan minutos para dibujar'; end if;
   if now()>r.deadline+interval '10 minutes' then raise exception 'El plazo para enviar terminó. Puedes guardar tu dibujo'; end if;
   art:=p_data->>'content';
   if length(art) not between 16 and 1400000 or art !~ '^[A-Za-z0-9+/=]+$' or left(art,11)<>'iVBORw0KGgo' then raise exception 'PNG no válido'; end if;
   update nido_private.art_rooms set host_art=case when host=u then coalesce(host_art,art) else host_art end,
    guest_art=case when guest=u then coalesce(guest_art,art) else guest_art end where id=r.id returning * into r;
  elsif p_action='vote' then
   if r.host_art is null or r.guest_art is null then raise exception 'Esperen los dos dibujos'; end if;
   if (p_data->>'winner')::uuid not in(r.host,r.guest) then raise exception 'Voto no válido'; end if;
   update nido_private.art_rooms set host_vote=case when host=u then coalesce(host_vote,(p_data->>'winner')::uuid) else host_vote end,
    guest_vote=case when guest=u then coalesce(guest_vote,(p_data->>'winner')::uuid) else guest_vote end where id=r.id returning * into r;
  elsif p_action<>'status' then raise exception 'Acción no válida'; end if;
 end if;
 result:=to_jsonb(r)-'host_art'-'guest_art';
 -- No peeking: opponent art only revealed after both submissions; own art is recoverable.
 if r.host_art is not null and r.guest_art is not null then result:=result||jsonb_build_object('host_art',r.host_art,'guest_art',r.guest_art);
 elsif u=r.host then result:=result||jsonb_build_object('host_art',r.host_art);
 else result:=result||jsonb_build_object('guest_art',r.guest_art); end if;
 return result||jsonb_build_object('server_now',now());
end $$;
revoke all on function nido_private.art_action(text,jsonb) from public,anon;
grant execute on function nido_private.art_action(text,jsonb) to authenticated;
create function public.art_action(p_action text,p_data jsonb default '{}') returns jsonb
language sql security invoker set search_path='' as $$select nido_private.art_action(p_action,p_data)$$;
revoke all on function public.art_action(text,jsonb) from public,anon;
grant execute on function public.art_action(text,jsonb) to authenticated;

-- Read-only capability, revocable, latest partner note only. Never grants account access.
create function nido_private.art_widget_note(p_token text) returns jsonb
language sql stable security definer set search_path='' as $$
 select coalesce((select to_jsonb(n)-'recipient'-'sender'
 from nido_private.art_widget_tokens t join public.user_profiles p on p.id=t.user_id
 join public.user_profiles q on q.id=p.partner_id and q.partner_id=p.id
 join nido_private.partner_art_notes n on n.sender=q.id and n.recipient=p.id
 where length(p_token)=64 and t.token_hash=extensions.digest(p_token,'sha256') and t.expires_at>now()),'{}'::jsonb)
$$;
revoke all on function nido_private.art_widget_note(text) from public;
grant usage on schema nido_private to anon;
grant execute on function nido_private.art_widget_note(text) to anon,authenticated;
create function public.art_widget_note(p_token text) returns jsonb language sql security invoker set search_path=''
as $$select nido_private.art_widget_note(p_token)$$;
revoke all on function public.art_widget_note(text) from public;
grant execute on function public.art_widget_note(text) to anon,authenticated;
