-- One shared family, named by its members. No purchases or client-awarded XP.
alter table public.shared_pets add column active_species text not null default 'penguin' check(active_species in ('penguin','bear','pig','chick'));
alter table public.shared_pets add column selection_confirmed boolean not null default false;
alter table public.shared_pets drop constraint shared_pets_name_check;
alter table public.shared_pets alter column name set default '';
alter table public.shared_pets add constraint shared_pets_name_check check(char_length(name)<=24);
update public.shared_pets set name='' where name='Pip';

create table public.shared_pet_animals (
 pair_key text not null references public.shared_pets(pair_key) on delete cascade,
 species text not null check(species in ('penguin','bear','pig','chick')),
 name text not null default '' check(char_length(name)<=24),
 care_points integer not null default 0 check(care_points>=0),
 adopted_at timestamptz not null default now(),primary key(pair_key,species)
);
create table public.shared_pet_care_days (
 pair_key text not null references public.shared_pets(pair_key) on delete cascade,
 care_date date not null,contributors uuid[] not null,primary key(pair_key,care_date)
);
alter table public.shared_pet_animals enable row level security;
alter table public.shared_pet_care_days enable row level security;
revoke all on public.shared_pet_animals,public.shared_pet_care_days from public,anon,authenticated;
grant all on public.shared_pet_animals,public.shared_pet_care_days to service_role;

create function nido_private.pet_family_snapshot() returns jsonb language plpgsql security definer set search_path='' as $$
declare base jsonb; k text; r public.shared_pets%rowtype; pet public.shared_pet_animals%rowtype; roster jsonb; days integer;
begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='42501';end if;
 base:=nido_private.pet_snapshot();k:=base->>'pair_key';
 select * into r from public.shared_pets where pair_key=k for update;
 if not(auth.uid()=any(r.members)) then raise exception 'Not a member' using errcode='42501';end if;
 if not exists(select 1 from public.shared_pet_animals where pair_key=k) then
  select case lower(p.pet_type) when 'bear' then 'bear' when 'oso' then 'bear' when 'pig' then 'pig' when 'cerdito' then 'pig' when 'chick' then 'chick' when 'pollito' then 'chick' else 'penguin' end
   into r.active_species from public.user_profiles p where p.id=any(r.members) order by p.id limit 1;
  update public.shared_pets set active_species=r.active_species where pair_key=k;
  insert into public.shared_pet_animals(pair_key,species,name,care_points) values(k,r.active_species,r.name,r.care_points);
 end if;
 select * into pet from public.shared_pet_animals where pair_key=k and species=r.active_species;
 select coalesce(jsonb_agg(jsonb_build_object('species',a.species,'name',a.name,'level',1+a.care_points/20) order by a.adopted_at,a.species),'[]'::jsonb) into roster from public.shared_pet_animals a where a.pair_key=k;
 select count(*) into days from public.shared_pet_care_days d where d.pair_key=k;
 return base||jsonb_build_object('species',r.active_species,'name',pet.name,'level',1+pet.care_points/20,'family_level',1+r.care_points/20,'care_days',days,'pets',roster,'selection_confirmed',r.selection_confirmed);
end $$;

create function nido_private.pet_family_progress() returns trigger language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();
begin
 if new.care_points>old.care_points and u=any(new.members) then
  update public.shared_pet_animals set care_points=care_points+(new.care_points-old.care_points) where pair_key=new.pair_key and species=new.active_species;
  insert into public.shared_pet_care_days(pair_key,care_date,contributors) values(new.pair_key,(now() at time zone 'UTC')::date,array[u])
   on conflict(pair_key,care_date) do update set contributors=(select array_agg(distinct member) from unnest(public.shared_pet_care_days.contributors||array[u]) member);
 end if;
 return new;
end $$;
create trigger pet_family_progress after update of care_points on public.shared_pets for each row execute function nido_private.pet_family_progress();

create function nido_private.pet_family_change(p_action text,p_species text,p_name text) returns jsonb language plpgsql security definer set search_path='' as $$
declare snapshot jsonb; k text; r public.shared_pets%rowtype; n integer; required_level integer; required_days integer; days integer;
begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='42501';end if;
 if p_species is null or p_species not in ('penguin','bear','pig','chick') or p_name is null or char_length(btrim(p_name))>24 or p_name~'[[:cntrl:]]' then raise exception 'Invalid pet';end if;
 snapshot:=nido_private.pet_family_snapshot();k:=snapshot->>'pair_key';
 select * into r from public.shared_pets where pair_key=k for update;
 if p_action='choose' then
  if r.selection_confirmed then return snapshot;end if;
  update public.shared_pet_animals set species=p_species,name=btrim(p_name) where pair_key=k and species=r.active_species;
  update public.shared_pets set active_species=p_species,name=btrim(p_name),selection_confirmed=true where pair_key=k;
 elsif p_action='adopt' then
  if not r.selection_confirmed then raise exception 'Choose first pet';end if;
  select count(*) into n from public.shared_pet_animals where pair_key=k;
  if n>=4 or exists(select 1 from public.shared_pet_animals where pair_key=k and species=p_species) then raise exception 'Already adopted';end if;
  required_level:=case n when 1 then 8 when 2 then 16 else 24 end;
  required_days:=case n when 1 then 3 when 2 then 7 else 14 end;
  select count(*) into days from public.shared_pet_care_days where pair_key=k;
  if 1+r.care_points/20<required_level or days<required_days then raise exception 'Adoption locked';end if;
  insert into public.shared_pet_animals(pair_key,species,name) values(k,p_species,btrim(p_name));
  update public.shared_pets set active_species=p_species,name=btrim(p_name) where pair_key=k;
 elsif p_action in ('select','rename') then
  if not exists(select 1 from public.shared_pet_animals where pair_key=k and species=p_species) then raise exception 'Pet not adopted';end if;
  if p_action='rename' then update public.shared_pet_animals set name=btrim(p_name) where pair_key=k and species=p_species;end if;
  update public.shared_pets set active_species=p_species,name=(select name from public.shared_pet_animals where pair_key=k and species=p_species) where pair_key=k;
 else raise exception 'Invalid action';end if;
 return nido_private.pet_family_snapshot();
end $$;
create or replace function public.shared_pet_snapshot() returns jsonb language sql security invoker set search_path='' as $$ select nido_private.pet_family_snapshot(); $$;
create or replace function public.shared_pet_care(p_action text) returns jsonb language plpgsql security invoker set search_path='' as $$
begin perform nido_private.pet_family_snapshot();perform nido_private.pet_care(p_action);return nido_private.pet_family_snapshot();end $$;
create function public.shared_pet_change(p_action text,p_species text,p_name text) returns jsonb language sql security invoker set search_path='' as $$ select nido_private.pet_family_change(p_action,p_species,p_name); $$;
revoke all on function nido_private.pet_family_snapshot(),nido_private.pet_family_change(text,text,text),nido_private.pet_family_progress() from public,anon,authenticated;
grant execute on function nido_private.pet_family_snapshot(),nido_private.pet_family_change(text,text,text) to authenticated;
revoke all on function public.shared_pet_change(text,text,text) from public,anon;
grant execute on function public.shared_pet_change(text,text,text) to authenticated;
