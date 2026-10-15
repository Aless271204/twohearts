do $$declare src text;begin
 select pg_get_functiondef('nido_private.duo_players(uuid)'::regprocedure) into src;
 if position('case p.pet_type when ''oso'' then ''bear''' in src)=0 then raise exception 'Unexpected portrait lookup';end if;
 execute replace(src,'case p.pet_type when ''oso'' then ''bear''','case p.pet_type when ''bear'' then ''bear'' when ''pig'' then ''pig'' when ''chick'' then ''chick'' when ''oso'' then ''bear''');
end $$;
