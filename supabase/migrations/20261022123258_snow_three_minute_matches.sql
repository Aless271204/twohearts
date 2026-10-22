-- Keep already-started short matches valid; allow new three-minute matches.
do $change$
declare definition text;
begin
 select pg_get_functiondef('public.snow_commit(uuid,uuid,bigint,jsonb,timestamptz)'::regprocedure) into definition;
 if position('>90.001' in definition)=0 then raise exception 'Unexpected snow time guard';end if;
 execute replace(definition,'>90.001','>180.001');
end $change$;
