-- Server snapshots only equipped purchases; clients cannot supply cosmetic IDs.
alter table nido_private.guardian_rooms add column if not exists host_loadout jsonb not null default '[]'::jsonb, add column if not exists guest_loadout jsonb not null default '[]'::jsonb;
create or replace function nido_private.guardian_room(p_action text,p_id uuid,p_code text,p_difficulty text,p_species text,p_packets jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); r nido_private.guardian_rooms; item jsonb; n integer; oldmask integer; hash text; pets jsonb; look jsonb;
begin
 if u is null then raise exception 'Inicia sesión para jugar'; end if;
 if p_action='profile' then pets:=nido_private.pet_family_snapshot();return jsonb_build_object('species',pets->>'species','pets',pets->'pets','loadout',(select coalesce(jsonb_agg(jsonb_build_object('item_key',e->>'item_key','color',e->'appearance'->>'garment_color')),'[]'::jsonb) from jsonb_array_elements(public.shared_pet_snapshot()->'equipment') e where e->>'scope'='pet'));end if;
 if p_action in ('create','solo','join') then pets:=nido_private.pet_family_snapshot();if not exists(select 1 from jsonb_array_elements(pets->'pets') x where x->>'species'=p_species) then raise exception 'Adopta esta mascota en NIDO antes de elegirla';end if;end if;
 if p_action in ('create','solo','join') and p_species not in ('penguin','bear','pig','chick') then raise exception 'Mascota inválida'; end if;
 if p_action in ('create','solo','join') then
  select coalesce(jsonb_agg(jsonb_build_object('item_key',e->>'item_key','color',e->'appearance'->>'garment_color')),'[]'::jsonb) into look from jsonb_array_elements(public.shared_pet_snapshot()->'equipment') e where e->>'scope'='pet';
 end if;
 if p_action in ('create','solo') then
  if p_difficulty not in ('easy','medium','hard') then raise exception 'Dificultad inválida'; end if;
  perform pg_advisory_xact_lock(hashtextextended('guardian-create:'||u::text,0));
  if (select count(*) from nido_private.guardian_rooms where host_id=u and created_at>now()-interval '10 minutes')>=15 then raise exception 'Espera un momento antes de crear otra sala'; end if;
  insert into nido_private.guardian_rooms(code,host_id,mode,difficulty,seed,host_species,status,started_at,host_ready,host_loadout)
  values(upper(substr(replace(gen_random_uuid()::text,'-',''),1,8)),u,case when p_action='solo' then 'solo' else 'partner' end,p_difficulty,floor(random()*4294967295)::bigint,p_species,case when p_action='solo' then 'running' else 'waiting' end,case when p_action='solo' then now() else null end,p_action='solo',look) returning * into r;
 elsif p_action='join' then
  insert into nido_private.guardian_join_limits values(u,date_trunc('minute',now()),1) on conflict(user_id) do update set
   attempts=case when guardian_join_limits.bucket=date_trunc('minute',now()) then guardian_join_limits.attempts+1 else 1 end,bucket=date_trunc('minute',now()) returning attempts into n;
  if n>20 then return jsonb_build_object('error','Demasiados intentos; espera un minuto'); end if;
  select * into r from nido_private.guardian_rooms where code=upper(trim(p_code)) and mode='partner' and status='waiting' and created_at>now()-interval '15 minutes' for update;
  if r.id is null or r.host_id=u or (r.guest_id is not null and r.guest_id<>u) then return jsonb_build_object('error','La sala no está disponible'); end if;
  update nido_private.guardian_rooms set guest_id=u,guest_species=p_species,guest_loadout=look where id=r.id returning * into r;
 else
  select * into r from nido_private.guardian_rooms where id=p_id and (host_id=u or guest_id=u) for update;
  if r.id is null then raise exception 'Sala no disponible'; end if;
  if r.created_at<now()-interval '30 minutes' and p_action<>'status' then raise exception 'La sala ha caducado'; end if;
  if p_action='ready' then
   if r.status<>'waiting' then return jsonb_build_object('status',r.status); end if;
   update nido_private.guardian_rooms set host_ready=host_ready or host_id=u,guest_ready=guest_ready or guest_id=u where id=r.id returning * into r;
   if r.host_ready and r.guest_ready then update nido_private.guardian_rooms set status='running',started_at=now()+interval '3 seconds' where id=r.id returning * into r; end if;
  elsif p_action='inputs' then
   if r.status not in ('running','finished') or jsonb_typeof(p_packets)<>'array' or jsonb_array_length(p_packets)>128 then raise exception 'Entradas inválidas'; end if;
   for item in select value from jsonb_array_elements(p_packets) loop
    if jsonb_typeof(item)<>'array' or jsonb_array_length(item)<>2 or (item->>0)!~'^[0-9]{1,5}$' or (item->>1)!~'^[0-9]{1,2}$' then raise exception 'Entrada inválida'; end if;
    select mask into oldmask from nido_private.guardian_inputs where room_id=r.id and user_id=u and seq=(item->>0)::int;
    if found and oldmask<>(item->>1)::int then raise exception 'La entrada ya está registrada'; end if;
    insert into nido_private.guardian_inputs values(r.id,u,(item->>0)::int,(item->>1)::int) on conflict do nothing;
   end loop;
  elsif p_action='confirm' then
   hash:=p_packets->>'hash';
   if r.guest_id<>u or r.mode<>'partner' or r.status<>'running' or hash is null or hash!~'^[a-f0-9]{64}$' then raise exception 'Confirmación inválida'; end if;
   if r.confirmed_hash is not null and r.confirmed_hash<>hash then raise exception 'La confirmación no coincide'; end if;
   update nido_private.guardian_rooms set confirmed_hash=hash where id=r.id returning * into r;
  elsif p_action='cancel' then
   update nido_private.guardian_rooms set status='cancelled' where id=r.id and status in ('waiting','running') returning * into r;
  elsif p_action<>'status' then raise exception 'Acción inválida'; end if;
 end if;
 return jsonb_build_object('id',r.id,'code',r.code,'mode',r.mode,'difficulty',r.difficulty,'seed',r.seed,'role',case when r.host_id=u then 0 else 1 end,'species',jsonb_build_array(r.host_species,coalesce(r.guest_species,'bear')),'loadouts',jsonb_build_array(r.host_loadout,r.guest_loadout),'joined',r.guest_id is not null,'status',r.status,'started_at',r.started_at,'server_time',now(),'confirmed',r.confirmed_hash is not null,'reward',(select amount from nido_private.guardian_rewards where room_id=r.id and user_id=u));
end $$;
