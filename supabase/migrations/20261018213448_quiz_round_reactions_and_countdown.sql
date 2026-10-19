-- Server-authoritative, shared result and next-question clocks. No answers
-- are accepted during either intermission; previous secrets are cleared.
do $$ declare definition text; begin
 select pg_get_functiondef('public.duo_tick(uuid,double precision,integer,integer,text)'::regprocedure) into definition;
 if position('''phase'',''reveal'',''deadline'',ts+4' in definition)=0 then raise exception 'Unexpected quiz reveal duration';end if;
 definition:=replace(definition,'''phase'',''reveal'',''deadline'',ts+4','''phase'',''reveal'',''deadline'',ts+5');
 definition:=replace(definition,'''score_a'',sa,''score_b'',sb,''phase'',''reveal''',
  '''score_a'',sa,''score_b'',sb,''streak_a'',case when qa.guess is not null and qa.guess=qb.self_choice then greatest(coalesce((st->>''streak_a'')::int,0),0)+1 else least(coalesce((st->>''streak_a'')::int,0),0)-1 end,''streak_b'',case when qb.guess is not null and qb.guess=qa.self_choice then greatest(coalesce((st->>''streak_b'')::int,0),0)+1 else least(coalesce((st->>''streak_b'')::int,0),0)-1 end,''phase'',''reveal''');
 if position('''question_no'',qn+1,''round_questions'',round_n,''phase'',''self'',''deadline'',ts+20' in definition)=0 then raise exception 'Unexpected quiz next-question transition';end if;
 definition:=replace(definition,'''question_no'',qn+1,''round_questions'',round_n,''phase'',''self'',''deadline'',ts+20','''question_no'',qn+1,''round_questions'',round_n,''phase'',''question_intro'',''deadline'',ts+2');
 definition:=replace(definition,
  'elsif m.game=''quiz'' and phase=''reveal'' and ts>=(st->>''deadline'')::float8 then',
  'elsif m.game=''quiz'' and phase=''question_intro'' and ts>=(st->>''deadline'')::float8 then st:=st||jsonb_build_object(''phase'',''self'',''deadline'',ts+20); elsif m.game=''quiz'' and phase=''reveal'' and ts>=(st->>''deadline'')::float8 then');
 definition:=replace(definition,'case when phase=''countdown'' then 3 when m.game=''quiz'' then 20 else 15 end',
  'case when phase=''countdown'' then 3 when m.game=''quiz'' and phase=''reveal'' then 5 when m.game=''quiz'' and phase=''question_intro'' then 2 when m.game=''quiz'' then 20 else 15 end');
 execute definition;
end $$;
