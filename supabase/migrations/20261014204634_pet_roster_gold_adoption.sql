create or replace function nido_private.pet_family_change(p_action text,p_species text,p_name text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare snapshot jsonb;k text;r public.shared_pets%rowtype;n integer;required_level integer;required_days integer;days integer;balance integer;
begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='42501';end if;
 if p_species is null or p_species not in ('penguin','bear','pig','chick') or p_name is null or char_length(btrim(p_name))>24 or p_name~'[[:cntrl:]]' then raise exception 'Invalid pet';end if;
 -- Wallet before pair: a colour purchase and adoption use the same lock order.
 if p_action='adopt_gold' then perform 1 from public.game_stats where user_id=auth.uid() for update;end if;
 snapshot:=nido_private.pet_family_snapshot();k:=snapshot->>'pair_key';
 select * into r from public.shared_pets where pair_key=k for update;
 if p_action='choose' then
  if r.selection_confirmed then return snapshot;end if;
  update public.shared_pet_animals set species=p_species,name=btrim(p_name) where pair_key=k and species=r.active_species;
  update public.shared_pets set active_species=p_species,name=btrim(p_name),selection_confirmed=true where pair_key=k;
 elsif p_action in ('adopt','adopt_gold') then
  if not r.selection_confirmed then raise exception 'Choose first pet';end if;
  -- Retrying an already completed adoption never charges or switches again.
  if exists(select 1 from public.shared_pet_animals where pair_key=k and species=p_species) then return snapshot;end if;
  select count(*) into n from public.shared_pet_animals where pair_key=k;
  if n>=4 then raise exception 'Family is complete';end if;
  if p_action='adopt_gold' then
   update public.game_stats set love_coins=love_coins-4000,updated_at=now()
    where user_id=auth.uid() and love_coins>=4000 returning love_coins into balance;
   if not found then raise exception 'Insufficient gold';end if;
  else
   required_level:=case n when 1 then 8 when 2 then 16 else 24 end;
   required_days:=case n when 1 then 3 when 2 then 7 else 14 end;
   select count(*) into days from public.shared_pet_care_days where pair_key=k;
   if 1+r.care_points/20<required_level or days<required_days then raise exception 'Adoption locked';end if;
  end if;
  insert into public.shared_pet_animals(pair_key,species,name) values(k,p_species,btrim(p_name));
  update public.shared_pets set active_species=p_species,name=btrim(p_name) where pair_key=k;
 elsif p_action='select' then
  if not exists(select 1 from public.shared_pet_animals where pair_key=k and species=p_species) then raise exception 'Pet not adopted';end if;
  update public.shared_pets set active_species=p_species,name=(select name from public.shared_pet_animals where pair_key=k and species=p_species) where pair_key=k;
 elsif p_action='rename' then
  if not exists(select 1 from public.shared_pet_animals where pair_key=k and species=p_species) then raise exception 'Pet not adopted';end if;
  update public.shared_pet_animals set name=btrim(p_name) where pair_key=k and species=p_species;
  -- Renaming a different member must not change the active character.
  update public.shared_pets set name=btrim(p_name) where pair_key=k and active_species=p_species;
 else raise exception 'Invalid action';end if;
 return nido_private.pet_family_snapshot();
end $$;
revoke all on function nido_private.pet_family_change(text,text,text) from public,anon;
grant execute on function nido_private.pet_family_change(text,text,text) to authenticated;
