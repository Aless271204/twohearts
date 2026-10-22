-- A clothing-prize receipt exists only after a replay-verified hard victory,
-- including victories that had no unowned prize left. Reuse those receipts so
-- existing players retain their progress. No client may grant a receipt.
create or replace function nido_private.guardian_river_unlocked(p_user uuid)
returns boolean language sql stable security invoker set search_path='' as $$
 select exists (
  select 1 from nido_private.guardian_rooms r
  join nido_private.guardian_clothing_prizes v on v.room_id=r.id
  where r.status='finished' and r.mode='partner' and r.difficulty='hard'
   and r.engine_version not in (4,5,7)
   and (r.host_id=p_user or r.guest_id=p_user)
   and r.guest_id is not null
 );
$$;
revoke all on function nido_private.guardian_river_unlocked(uuid) from public,anon,authenticated;

do $change$
declare definition text; marker text;
begin
 select pg_get_functiondef('nido_private.guardian_room(text,uuid,text,text,text,jsonb)'::regprocedure) into definition;
 if position('unlocked_chapters' in definition)>0 then raise exception 'Chapter progress already installed';end if;
 marker:='jsonb_build_object(''species'',pets->>''species''';
 if position(marker in definition)=0 then raise exception 'Unexpected profile implementation';end if;
 definition:=replace(definition,marker,'jsonb_build_object(''unlocked_chapters'',case when nido_private.guardian_river_unlocked(u) then ''["forest","river"]''::jsonb else ''["forest"]''::jsonb end,''species'',pets->>''species''');
 marker:='if p_difficulty not in (''easy'',''medium'',''hard'')';
 if position(marker in definition)=0 then raise exception 'Unexpected room creation implementation';end if;
 definition:=replace(definition,marker,'if p_packets->>''chapter''=''river'' and not nido_private.guardian_river_unlocked(u) then raise exception ''Desbloquea el Río completando el Bosque en Difícil y en pareja'';end if; '||marker);
 marker:='update nido_private.guardian_rooms set guest_id=u,guest_species=p_species,guest_loadout=look';
 if position(marker in definition)=0 then raise exception 'Unexpected room join implementation';end if;
 definition:=replace(definition,marker,'if r.engine_version in (4,5,7) and not nido_private.guardian_river_unlocked(u) then raise exception ''Desbloquea el Río completando el Bosque en Difícil y en pareja'';end if; '||marker);
 execute definition;
end $change$;
