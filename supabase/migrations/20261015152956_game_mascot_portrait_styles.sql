begin;
alter table public.user_profiles add column pet_portrait_style text not null default 'masculine' check(pet_portrait_style in('masculine','feminine'));
grant update(pet_portrait_style) on public.user_profiles to authenticated;
create function nido_private.duo_players(p_match_id uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare m public.duo_matches;r jsonb;
begin
 select * into m from public.duo_matches where id=p_match_id;
 if auth.uid() is null or not found or auth.uid() not in(m.player_a,m.player_b) then raise exception 'Partida no accesible' using errcode='42501';end if;
 select jsonb_agg(jsonb_build_object('side',case when p.id=m.player_a then 'a' else 'b' end,'name',coalesce(nullif(p.nickname,''),'Jugador'),'species',coalesce((select sp.active_species from public.shared_pets sp where p.id=any(sp.members) order by sp.updated_at desc limit 1),case p.pet_type when 'oso' then 'bear' when 'cerdito' then 'pig' when 'pollito' then 'chick' else 'penguin' end),'style',p.pet_portrait_style) order by p.id) into r from public.user_profiles p where p.id in(m.player_a,m.player_b);
 return r;
end $$;
revoke all on function nido_private.duo_players(uuid) from public,anon,authenticated;
do $$declare src text; needle text:='''state'',st);';begin
 select pg_get_functiondef('public.duo_tick(uuid,double precision,integer,integer,text)'::regprocedure) into src;
 if position(needle in src)=0 then raise exception 'Unexpected duo_tick return';end if;
 execute replace(src,needle,'''players'',nido_private.duo_players(m.id),''state'',st);');
end $$;
commit;
