-- Only the service-role Edge validator submits reconstructed state.
-- Keep ownership, elapsed wall time, 500/run and 1000/day reward caps.
do $$ declare definition text; begin
 select pg_get_functiondef('public.runner_save_checkpoint(uuid,uuid,integer,jsonb,boolean)'::regprocedure) into definition;
 if position('d>t*24+2' in definition)=0 then raise exception 'Unexpected checkpoint validator'; end if;
 execute replace(definition,'d>t*24+2','d>t*48+2');
 select pg_get_functiondef('public.runner_finish_session(uuid,uuid,integer,integer,double precision)'::regprocedure) into definition;
 if position('p_distance > p_elapsed*24+2' in definition)=0 or position('p_distance::bigint*6/18+12' in definition)=0 then raise exception 'Unexpected finish validator'; end if;
 definition:=replace(definition,'p_distance > p_elapsed*24+2','p_distance > p_elapsed*48+2');
 definition:=replace(definition,'p_distance::bigint*6/18+12','p_distance::bigint*12/18+24');
 execute definition;
end $$;
