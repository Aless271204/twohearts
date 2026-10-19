-- New river terrain has a distinct replay version. Existing rooms retain
-- their old layout and rewards; clients must understand the room's version.
do $$ declare definition text; begin
 select pg_get_functiondef('nido_private.guardian_room(text,uuid,text,text,text,jsonb)'::regprocedure) into definition;
 if position('case when p_packets->>''engine_version''=''4'' and p_packets->>''chapter''=''river'' then 4' in definition)=0 then raise exception 'Unexpected Guardian version negotiation';end if;
 definition:=replace(definition,
  'case when p_packets->>''engine_version''=''4'' and p_packets->>''chapter''=''river'' then 4 when p_packets->>''engine_version'' in (''3'',''4'') then 3 else 2 end',
  'case when p_packets->>''engine_version''=''5'' and p_packets->>''chapter''=''river'' then 5 when p_packets->>''engine_version''=''4'' and p_packets->>''chapter''=''river'' then 4 when p_packets->>''engine_version'' in (''3'',''4'',''5'') then 3 else 2 end');
 if position('if r.engine_version=4 and coalesce(p_packets->>''engine_version'','''')<>''4''' in definition)=0 then raise exception 'Unexpected Guardian join guard';end if;
 definition:=replace(definition,
  'if r.engine_version=4 and coalesce(p_packets->>''engine_version'','''')<>''4''',
  'if (r.engine_version=5 and coalesce(p_packets->>''engine_version'','''')<>''5'') or (r.engine_version=4 and coalesce(p_packets->>''engine_version'','''') not in (''4'',''5''))');
 execute definition;
end $$;
