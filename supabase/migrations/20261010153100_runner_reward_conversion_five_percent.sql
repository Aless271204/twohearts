-- Requested conversion: 20 collected points = 1 store coin, floor per run.
do $$ declare definition text; begin
 select pg_get_functiondef('public.runner_finish_session(uuid,uuid,integer,integer,double precision)'::regprocedure) into definition;
 if position('v_awarded:=least(p_coins,500,greatest(0,1000-v_today))' in definition)=0 then raise exception 'Unexpected reward calculation'; end if;
 definition:=replace(definition,'v_awarded:=least(p_coins,500,greatest(0,1000-v_today))','v_awarded:=least(p_coins/20,500,greatest(0,1000-v_today))');
 definition:=replace(definition,'''coins_awarded'',v_awarded,','''coins_awarded'',v_awarded,''points_per_coin'',20,');
 execute definition;
end $$;
