-- Replays retain the rules with which their room was created. New clients
-- support both aerial forest6 and river7; old rooms keep versions2-5.
do $$ declare definition text; old_case text; old_guard text; begin
 select pg_get_functiondef('nido_private.guardian_room(text,uuid,text,text,text,jsonb)'::regprocedure) into definition;
 old_case:=$case$case when p_packets->>'engine_version'='5' and p_packets->>'chapter'='river' then 5 when p_packets->>'engine_version'='4' and p_packets->>'chapter'='river' then 4 when p_packets->>'engine_version' in ('3','4','5') then 3 else 2 end$case$;
 old_guard:=$guard$if (r.engine_version=5 and coalesce(p_packets->>'engine_version','')<>'5') or (r.engine_version=4 and coalesce(p_packets->>'engine_version','') not in ('4','5'))$guard$;
 if position(old_case in definition)=0 or position(old_guard in definition)=0 then raise exception 'Unexpected Guardian version negotiation';end if;
 definition:=replace(definition,old_case,$case$case when p_packets->>'engine_version' in ('6','7') and p_packets->>'chapter'='river' then 7 when p_packets->>'engine_version' in ('6','7') then 6 when p_packets->>'engine_version'='5' and p_packets->>'chapter'='river' then 5 when p_packets->>'engine_version'='4' and p_packets->>'chapter'='river' then 4 when p_packets->>'engine_version' in ('3','4','5') then 3 else 2 end$case$);
 definition:=replace(definition,old_guard,$guard$if (r.engine_version in (6,7) and coalesce(p_packets->>'engine_version','') not in ('6','7')) or (r.engine_version=5 and coalesce(p_packets->>'engine_version','') not in ('5','6','7')) or (r.engine_version=4 and coalesce(p_packets->>'engine_version','') not in ('4','5','6','7'))$guard$);
 execute definition;
end $$;
