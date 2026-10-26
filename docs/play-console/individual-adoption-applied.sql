-- Remote migration 20261026143026; applied with explicit owner approval on 26oct2026.
set local plpgsql.check_asserts=on;
-- Review candidate: preserve individual identities, including equal species.
alter table public.shared_pet_animals add column id uuid not null default gen_random_uuid();
alter table public.shared_pet_animals add column personal_owner uuid references auth.users(id) on delete set null;
alter table public.shared_pet_animals drop constraint shared_pet_animals_pkey;
alter table public.shared_pet_animals add primary key(id);
create index shared_pet_animals_household on public.shared_pet_animals(pair_key,species);
create index shared_pet_animals_personal_owner on public.shared_pet_animals(personal_owner) where personal_owner is not null;
alter table public.shared_pets add column active_pet_id uuid;
update public.shared_pets s set active_pet_id=(select a.id from public.shared_pet_animals a where a.pair_key=s.pair_key and a.species=s.active_species order by a.adopted_at,a.id limit 1);

create or replace function nido_private.pet_family_snapshot() returns jsonb
language plpgsql security definer set search_path='' as $$
declare base jsonb;k text;m uuid[];r public.shared_pets;pet public.shared_pet_animals;roster jsonb;days integer;moved integer;
begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='42501';end if;
 perform nido_private.wallet_lock(auth.uid());
 m:=nido_private.pet_members();k:=array_to_string(m,':');
 -- Personal pets move by identity, never copy. Wallet locks serialize linking,
 -- purchase and refresh; repeated snapshots cannot duplicate an adoption.
 base:=nido_private.pet_snapshot();
 update public.shared_pet_animals a set pair_key=k where a.personal_owner=any(m) and a.pair_key<>k;
 get diagnostics moved=row_count;
 if moved>0 then
  update public.shared_pets set selection_confirmed=true,arrival_revision=arrival_revision+1 where pair_key=k;
 end if;
 select * into r from public.shared_pets where pair_key=k for update;
 if not(auth.uid()=any(r.members)) then raise exception 'Not a member' using errcode='42501';end if;
 if not exists(select 1 from public.shared_pet_animals where pair_key=k) then
  if cardinality(m)=1 then
   update public.shared_pets set selection_confirmed=false,active_pet_id=null where pair_key=k;
   r.selection_confirmed:=false;
  elsif r.selection_confirmed then
   insert into public.shared_pet_animals(pair_key,species,name,care_points)
    values(k,r.active_species,r.name,r.care_points);
  end if;
 end if;
 if not r.selection_confirmed then
  return base||jsonb_build_object('pair_key',k,'members',to_jsonb(m),'pets','[]'::jsonb,
   'selection_confirmed',false,'adoption_required',true,'paired',cardinality(m)=2,'arrival_pending',false);
 end if;
 select * into pet from public.shared_pet_animals where pair_key=k and id=r.active_pet_id;
 if pet.id is null then
  select * into pet from public.shared_pet_animals where pair_key=k order by adopted_at,id limit 1;
  update public.shared_pets set active_pet_id=pet.id,active_species=pet.species,name=pet.name where pair_key=k;
 end if;
 select coalesce(jsonb_agg(jsonb_build_object('id',a.id,'species',a.species,'name',a.name,
  'level',1+a.care_points/20) order by a.adopted_at,a.id),'[]'::jsonb) into roster
  from public.shared_pet_animals a where a.pair_key=k;
 select count(*) into days from public.shared_pet_care_days where pair_key=k;
 return base||jsonb_build_object('pair_key',k,'members',to_jsonb(m),'paired',cardinality(m)=2,
  'active_pet_id',pet.id,'species',pet.species,'name',pet.name,'level',1+pet.care_points/20,
  'family_level',1+r.care_points/20,'care_days',days,'pets',roster,'selection_confirmed',true,
  'adoption_required',false,'arrival_pending',r.arrival_revision>0 and not exists(
   select 1 from nido_private.pet_arrival_receipts a where a.pair_key=k and a.user_id=auth.uid() and a.revision=r.arrival_revision));
end $$;

create function nido_private.pet_change_identity(p_action text,p_species text,p_name text,p_id uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare snapshot jsonb;k text;m uuid[];r public.shared_pets;pet public.shared_pet_animals;n integer;days integer;required_level integer;required_days integer;
begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='42501';end if;
 if p_name is null or char_length(btrim(p_name))>24 or p_name~'[[:cntrl:]]' then raise exception 'Invalid pet name';end if;
 perform nido_private.wallet_lock(auth.uid());
 snapshot:=nido_private.pet_family_snapshot();k:=snapshot->>'pair_key';m:=nido_private.pet_members();
 select * into r from public.shared_pets where pair_key=k for update;
 if p_id is not null then
  if p_action not in ('select','rename') then raise exception 'Invalid pet action';end if;
  select * into pet from public.shared_pet_animals where pair_key=k and id=p_id;
  if pet.id is null then raise exception 'Pet not adopted' using errcode='42501';end if;
  p_species:=pet.species;
 end if;
 if p_species is null or p_species not in ('penguin','bear','pig','chick') then raise exception 'Invalid pet';end if;
 if p_action='choose' then
  if cardinality(m)<>2 then raise exception 'Enlaza las cuentas o adopta por 4.000 de oro' using errcode='42501';end if;
  if r.selection_confirmed then return snapshot;end if;
  select * into pet from public.shared_pet_animals where pair_key=k order by adopted_at,id limit 1;
  if pet.id is null then
   insert into public.shared_pet_animals(pair_key,species,name) values(k,p_species,btrim(p_name)) returning * into pet;
  else
   update public.shared_pet_animals set species=p_species,name=btrim(p_name) where id=pet.id returning * into pet;
  end if;
 elsif p_action in ('adopt','adopt_gold') then
  if r.selection_confirmed and exists(select 1 from public.shared_pet_animals where pair_key=k and species=p_species) then return snapshot;end if;
  if p_action='adopt' and (cardinality(m)<>2 or not r.selection_confirmed) then raise exception 'Adoption locked';end if;
  select count(distinct species) into n from public.shared_pet_animals where pair_key=k and r.selection_confirmed;
  if n>=4 then raise exception 'Family is complete';end if;
  if p_action='adopt_gold' then
   perform nido_private.wallet_spend(auth.uid(),4000);
  else
   required_level:=case n when 1 then 8 when 2 then 16 else 24 end;
   required_days:=case n when 1 then 3 when 2 then 7 else 14 end;
   select count(*) into days from public.shared_pet_care_days where pair_key=k;
   if 1+r.care_points/20<required_level or days<required_days then raise exception 'Adoption locked';end if;
  end if;
  select * into pet from public.shared_pet_animals where pair_key=k and not r.selection_confirmed order by adopted_at,id limit 1;
  if pet.id is null then
   insert into public.shared_pet_animals(pair_key,species,name,personal_owner)
    values(k,p_species,btrim(p_name),case when cardinality(m)=1 then auth.uid() end) returning * into pet;
  else
   update public.shared_pet_animals set species=p_species,name=btrim(p_name),
    personal_owner=case when cardinality(m)=1 then auth.uid() end where id=pet.id returning * into pet;
  end if;
 elsif p_action in ('select','rename') then
  if pet.id is null then
   select * into pet from public.shared_pet_animals where pair_key=k and species=p_species order by adopted_at,id limit 1;
  end if;
  if pet.id is null then raise exception 'Pet not adopted' using errcode='42501';end if;
  if p_action='rename' then
   update public.shared_pet_animals set name=btrim(p_name) where id=pet.id returning * into pet;
   update public.shared_pets set name=pet.name where pair_key=k and active_pet_id=pet.id;
   return nido_private.pet_family_snapshot();
  end if;
 else raise exception 'Invalid action';end if;
 update public.shared_pets set active_pet_id=pet.id,active_species=pet.species,name=pet.name,
  selection_confirmed=true,arrival_revision=arrival_revision+case when not r.selection_confirmed then 1 else 0 end where pair_key=k;
 return nido_private.pet_family_snapshot();
end $$;
revoke all on function nido_private.pet_change_identity(text,text,text,uuid) from public,anon,authenticated;

create or replace function nido_private.pet_family_change(p_action text,p_species text,p_name text)
returns jsonb language sql security definer set search_path='' as $$
 select nido_private.pet_change_identity(p_action,p_species,p_name,null);
$$;

create function public.shared_pet_change_by_id(p_action text,p_pet_id uuid,p_name text)
returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if p_action not in ('select','rename') or p_pet_id is null then raise exception 'Invalid pet action';end if;
 return nido_private.pet_change_identity(p_action,null,p_name,p_pet_id);
end $$;
revoke all on function public.shared_pet_change_by_id(text,uuid,text) from public,anon;
grant execute on function public.shared_pet_change_by_id(text,uuid,text) to authenticated;

create or replace function nido_private.pet_family_progress() returns trigger
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();
begin
 if new.care_points>old.care_points and u=any(new.members) then
  update public.shared_pet_animals set care_points=care_points+(new.care_points-old.care_points)
   where pair_key=new.pair_key and id=new.active_pet_id;
  insert into public.shared_pet_care_days(pair_key,care_date,contributors)
   values(new.pair_key,(now() at time zone 'UTC')::date,array[u])
   on conflict(pair_key,care_date) do update set contributors=(select array_agg(distinct member)
    from unnest(public.shared_pet_care_days.contributors||array[u]) member);
 end if;
 return new;
end $$;

-- Validation uses temporary fake identities and rolls back all fixture data.
do $$
declare a uuid:=gen_random_uuid();b uuid:=gen_random_uuid();poor uuid:=gen_random_uuid();
 snap jsonb;first_id uuid;second_id uuid;initial_rows bigint;expected_failure boolean;
begin
 select count(*) into initial_rows from public.shared_pet_animals;
 begin
  insert into auth.users(id,email,raw_user_meta_data,raw_app_meta_data,aud,role)
   values(a,a::text||'@nido-fixture.invalid','{}','{}','authenticated','authenticated'),
         (b,b::text||'@nido-fixture.invalid','{}','{}','authenticated','authenticated'),
         (poor,poor::text||'@nido-fixture.invalid','{}','{}','authenticated','authenticated');
  insert into public.game_stats(user_id,love_coins) values(a,5000),(b,5000),(poor,3999)
   on conflict(user_id) do update set love_coins=excluded.love_coins;
  perform set_config('request.jwt.claim.sub',a::text,true);
  expected_failure:=false;
  begin perform public.shared_pet_change('choose','chick','A'); exception when insufficient_privilege then expected_failure:=true;end;
  assert expected_failure,'Unpaired free adoption must fail';
  snap:=public.shared_pet_change('adopt_gold','chick','A');first_id:=(snap->>'active_pet_id')::uuid;
  assert (select love_coins=1000 from public.game_stats where user_id=a),'Exact 4000 charge';
  assert (snap->>'selection_confirmed')::boolean and jsonb_array_length(snap->'pets')=1,'Solo pet usable';
  perform public.shared_pet_change('adopt_gold','chick','A');
  assert (select love_coins=1000 from public.game_stats where user_id=a),'Retry charged twice';
  perform set_config('request.jwt.claim.sub',poor::text,true);
  expected_failure:=false;
  begin perform public.shared_pet_change('adopt_gold','pig','No');exception when others then expected_failure:=true;end;
  assert expected_failure and not exists(select 1 from public.shared_pet_animals where personal_owner=poor),'Insufficient balance must not grant';
  assert (select love_coins=3999 from public.game_stats where user_id=poor),'Failure changed balance';
  perform set_config('request.jwt.claim.sub',b::text,true);
  snap:=public.shared_pet_change('adopt_gold','chick','B');second_id:=(snap->>'active_pet_id')::uuid;
  update public.user_profiles set partner_id=b where id=a;
  update public.user_profiles set partner_id=a where id=b;
  perform set_config('request.jwt.claim.sub',a::text,true);
  snap:=public.shared_pet_snapshot();
  assert jsonb_array_length(snap->'pets')=2,'Same species pets lost on linking';
  assert exists(select 1 from jsonb_array_elements(snap->'pets') x where x->>'id'=first_id::text),'First identity lost';
  assert exists(select 1 from jsonb_array_elements(snap->'pets') x where x->>'id'=second_id::text),'Second identity lost';
  snap:=public.shared_pet_change_by_id('select',second_id,'');
  assert snap->>'name'='B','Cannot select second same-species pet';
  perform public.shared_pet_change_by_id('rename',second_id,'B2');
  assert (select name='A' from public.shared_pet_animals where id=first_id),'Renamed both identities';
  assert nido_private.wallet_balance(a)=2000,'Linking charged again';
  perform public.shared_pet_snapshot();
  assert (select count(*)=2 from public.shared_pet_animals where personal_owner in(a,b)),'Refresh duplicated pets';
  perform set_config('request.jwt.claim.sub',poor::text,true);
  expected_failure:=false;
  begin perform public.shared_pet_change_by_id('select',first_id,'');exception when insufficient_privilege then expected_failure:=true;end;
  assert expected_failure,'Another household can select pet';
  -- A paid pet + an empty partner must also join without another charge.
  update public.user_profiles set partner_id=null where id in(a,b);
  update public.user_profiles set partner_id=poor where id=a;
  update public.user_profiles set partner_id=a where id=poor;
  perform set_config('request.jwt.claim.sub',poor::text,true);
  snap:=public.shared_pet_snapshot();
  assert jsonb_array_length(snap->'pets')=1,'One pet plus empty partner did not merge';
  assert nido_private.wallet_balance(a)=4999,'Empty partner link charged gold';
  perform set_config('request.jwt.claim.sub','',true);
  expected_failure:=false;
  begin perform public.shared_pet_change('adopt_gold','pig','No');exception when insufficient_privilege then expected_failure:=true;end;
  assert expected_failure,'Anonymous adoption permitted';
  raise exception using errcode='N1000',message='Rollback fixtures after successful tests';
 exception when sqlstate 'N1000' then null;
 end;
 assert (select count(*)=initial_rows from public.shared_pet_animals),'Test fixtures leaked';
 assert not exists(select 1 from auth.users where id in(a,b,poor)),'Test users leaked';
end $$;
notify pgrst,'reload schema';
