-- The Edge Function reconstructs v4/v5 physics; only it can submit rewards.
-- Keep ownership, elapsed time, daily coins and per-run reward caps unchanged.
do $$ declare definition text; begin
 select pg_get_functiondef('public.runner_save_checkpoint(uuid,uuid,integer,jsonb,boolean)'::regprocedure) into definition;
 if position('d>t*14+2' in definition)=0 then raise exception 'Unexpected checkpoint validator';end if;
 execute replace(definition,'d>t*14+2','d>t*24+2');
 select pg_get_functiondef('public.runner_finish_session(uuid,uuid,integer,integer,double precision)'::regprocedure) into definition;
 if position('p_distance > p_elapsed*14+2' in definition)=0 then raise exception 'Unexpected finish validator';end if;
 execute replace(definition,'p_distance > p_elapsed*14+2','p_distance > p_elapsed*24+2');
end $$;
