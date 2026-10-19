-- Client/server replay remains authoritative. The rate guard expands only for
-- the new validated v9 state; installed clients retain their original bound.
do $$ declare definition text; begin
 select pg_get_functiondef('public.runner_save_checkpoint(uuid,uuid,integer,jsonb,boolean)'::regprocedure) into definition;
 if position('d>t*48+2' in definition)=0 then raise exception 'Unexpected runner rate guard';end if;
 execute replace(definition,'d>t*48+2','d>t*(case when (p_state->>''version'')::integer in (9,10) then 88 else 48 end)+2');
 select pg_get_functiondef('nido_private.guardian_room(text,uuid,text,text,text,jsonb)'::regprocedure) into definition;
 if position('case when p_packets->>''engine_version''=''3'' then 3 else 2 end' in definition)=0 then raise exception 'Unexpected Guardian version negotiation';end if;
 definition:=replace(definition,'case when p_packets->>''engine_version''=''3'' then 3 else 2 end','case when p_packets->>''engine_version''=''4'' and p_packets->>''chapter''=''river'' then 4 when p_packets->>''engine_version'' in (''3'',''4'') then 3 else 2 end');
 definition:=replace(definition,'if r.id is null or r.host_id=u','if r.engine_version=4 and coalesce(p_packets->>''engine_version'','''')<>''4'' then return jsonb_build_object(''error'',''Actualiza NIDO para jugar este capítulo'');end if; if r.id is null or r.host_id=u');
 execute definition;
end $$;
