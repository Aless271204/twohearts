begin;
create table public.duo_questions(id integer generated always as identity primary key, category text not null, prompt text not null, options jsonb not null check(jsonb_array_length(options)=3));
alter table public.duo_questions enable row level security;
create policy questions_read on public.duo_questions for select to authenticated using(true);
grant select on public.duo_questions to authenticated;
insert into public.duo_questions(category,prompt,options) values
('Viajes','¿Cuál es mi destino soñado?','["Inglaterra","Francia","Japón"]'),
('Viajes','¿Dónde elegiría una escapada contigo?','["Playa","Montaña","Una ciudad nueva"]'),
('Comida','¿Qué pediría para nuestra cena?','["Pizza","Sushi","Hamburguesa"]'),
('Comida','¿Cuál es mi desayuno favorito?','["Pan y café","Fruta y yogur","Huevos y tostadas"]'),
('Comida','¿Qué sabor de helado elegiría?','["Chocolate","Vainilla","Fresa"]'),
('Comida','¿Qué bebida me apetece más?','["Café","Té","Chocolate caliente"]'),
('Comida','¿Qué picaría viendo una película?','["Palomitas","Dulces","Nachos"]'),
('Comida','¿Qué prefiero de postre?','["Tarta","Helado","Fruta"]'),
('Comida','¿Cómo me gusta la comida?','["Suave","Algo picante","Muy picante"]'),
('Comida','¿Qué comida elegiría repetir toda la semana?','["Pasta","Arroz","Tacos"]'),
('Viajes','¿Qué haría primero en un país nuevo?','["Probar su comida","Visitar un museo","Caminar sin rumbo"]'),
('Viajes','¿Cómo prefiero viajar?','["Avión","Tren","Coche"]'),
('Viajes','¿Qué clima elegiría de vacaciones?','["Calor y sol","Fresco y nublado","Frío y nieve"]'),
('Viajes','¿Qué tipo de alojamiento escogería?','["Cabaña","Hotel","Apartamento"]'),
('Viajes','¿Cuánto me gusta planear un viaje?','["Todo organizado","Solo lo esencial","Improvisar"]'),
('Mascotas','¿Qué mascota tendría además de Pip?','["Perro","Gato","Conejo"]'),
('Mascotas','¿Qué accesorio le pondría a Pip?','["Bufanda","Sombrero","Mochila"]'),
('Mascotas','¿Qué nombre elegiría para una mascota?','["Luna","Coco","Nube"]'),
('Colores','¿Qué color me gusta más?','["Azul","Rosa","Verde"]'),
('Colores','¿Qué tonos escogería para nuestra casa?','["Pasteles","Neutros","Vivos"]'),
('Colores','¿Qué paleta elegiría para una fiesta?','["Dorado y blanco","Lila y rosa","Azul y plata"]'),
('Hobbies','¿Qué plan me relaja más?','["Leer","Escuchar música","Caminar"]'),
('Hobbies','¿Qué me gustaría aprender?','["Un instrumento","Un idioma","Fotografía"]'),
('Hobbies','¿Qué juego elegiría contigo?','["Preguntas","Ping pong","Correr con Pip"]'),
('Hobbies','¿Qué actividad creativa elegiría?','["Pintar","Cocinar","Escribir"]'),
('Hobbies','¿Qué deporte probaría?','["Natación","Baile","Escalada"]'),
('Música','¿Qué pondría de fondo en una tarde juntos?','["Pop","Música instrumental","Rock"]'),
('Música','¿Dónde disfrutaría más de la música?','["Un concierto","En casa","En un viaje"]'),
('Música','¿Qué haría al escuchar mi canción favorita?','["Cantar","Bailar","Escuchar en silencio"]'),
('Planes','¿Cuál sería mi cita ideal?','["Cena romántica","Pícnic","Una aventura"]'),
('Planes','¿Qué prefiero un domingo?','["Quedarme en casa","Salir temprano","Dormir y salir después"]'),
('Planes','¿Qué película elegiría?','["Comedia","Aventura","Romance"]'),
('Planes','¿Qué regalo me haría más ilusión?','["Una experiencia","Algo hecho a mano","Algo que quería"]'),
('Planes','¿Qué estación disfruto más?','["Primavera","Verano","Invierno"]'),
('Planes','¿Qué me gusta más de una celebración?','["La comida","La compañía","La sorpresa"]'),
('Sueños','¿Dónde me gustaría vivir?','["Cerca del mar","En una ciudad","En el campo"]'),
('Sueños','¿Qué aventura elegiría juntos?','["Ver auroras","Un safari","Una ruta por islas"]'),
('Sueños','¿Qué me gustaría tener en nuestra casa?','["Biblioteca","Jardín","Sala de juegos"]'),
('Hábitos','¿En qué momento tengo más energía?','["Mañana","Tarde","Noche"]'),
('Hábitos','¿Cómo prefiero recibir cariño?','["Palabras bonitas","Tiempo juntos","Abrazos"]'),
('Hábitos','¿Qué hago para animarme?','["Hablar contigo","Dar un paseo","Descansar"]'),
('Hábitos','¿Cómo celebro una buena noticia?','["Salir a comer","Llamar a alguien","Un plan tranquilo"]'),
('Comida','¿Qué fruta elegiría?','["Mango","Fresas","Sandía"]'),
('Comida','¿Qué sabor prefiero?','["Dulce","Salado","Ácido"]'),
('Comida','¿Qué comida internacional probaría?','["Italiana","Mexicana","Japonesa"]'),
('Viajes','¿Qué recuerdo traería de un viaje?','["Fotos","Artesanía","Comida local"]'),
('Viajes','¿Qué ciudad visitaría primero?','["Londres","París","Roma"]'),
('Viajes','¿Con qué paisaje me quedaría?','["Cascadas","Bosque","Desierto"]'),
('Hobbies','¿Qué manualidad haría contigo?','["Cerámica","Velas","Un álbum"]'),
('Hobbies','¿Qué baile aprendería?','["Salsa","Bachata","Tango"]'),
('Planes','¿Qué plan elegiría si llueve?','["Película y manta","Cocinar juntos","Un museo"]'),
('Planes','¿Cómo prefiero las sorpresas?','["Pequeñas y frecuentes","Una gran sorpresa","Prefiero saber el plan"]'),
('Mascotas','¿Dónde pasearía con una mascota?','["Parque","Playa","Bosque"]'),
('Colores','¿Qué color llevaría en una mochila?','["Amarillo","Negro","Turquesa"]'),
('Sueños','¿Qué celebraría con nuestro primer ahorro?','["Un viaje","Un hogar bonito","Una cena especial"]'),
('Hábitos','¿Qué parte del día compartiría contigo?','["Desayuno","Atardecer","Antes de dormir"]'),
('Música','¿Qué instrumento me gustaría tocar?','["Piano","Guitarra","Batería"]'),
('Planes','¿Qué elegiría en una feria?','["Atracciones","Juegos","Puestos de comida"]'),
('Hobbies','¿Qué haría con una tarde libre?','["Crear algo","Aprender algo","Salir a explorar"]'),
('Sueños','¿Qué recuerdo quiero guardar más?','["Nuestros viajes","Nuestros pequeños momentos","Nuestros logros"]');
create table public.duo_matches(id uuid primary key default gen_random_uuid(),game text not null check(game in('pong','quiz')),player_a uuid not null references public.user_profiles(id),player_b uuid not null references public.user_profiles(id),status text not null default 'waiting' check(status in('waiting','playing','finished','cancelled')),state jsonb not null,last_tick timestamptz not null default now(),heartbeat_a timestamptz not null default now(),heartbeat_b timestamptz,created_at timestamptz not null default now(),winner uuid);
create unique index duo_active_pair on public.duo_matches(player_a,player_b,game) where status in('waiting','playing');
alter table public.duo_matches enable row level security;
create policy duo_participants on public.duo_matches for select to authenticated using((select auth.uid()) in(player_a,player_b));
grant select on public.duo_matches to authenticated;
create table public.duo_answers(match_id uuid not null references public.duo_matches(id) on delete cascade,question_no integer not null,user_id uuid not null references public.user_profiles(id),self_choice integer check(self_choice between 0 and 2),guess integer check(guess between 0 and 2),primary key(match_id,question_no,user_id));
alter table public.duo_answers enable row level security;
-- No SELECT grant or policy: secret answers only leave the RPC during reveal.
revoke all on public.duo_answers from anon,authenticated;
create table public.duo_rewards(match_id uuid not null references public.duo_matches(id),user_id uuid not null references public.user_profiles(id),coins integer not null,created_at timestamptz not null default now(),primary key(match_id,user_id));
alter table public.duo_rewards enable row level security;
create policy rewards_own on public.duo_rewards for select to authenticated using(user_id=(select auth.uid()));
grant select on public.duo_rewards to authenticated;
create index duo_rewards_user_date on public.duo_rewards(user_id,created_at);
create or replace function public.duo_join(p_game text) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); partner uuid; a uuid;b uuid;m public.duo_matches; st jsonb;qs jsonb;
begin
 if u is null or p_game not in('pong','quiz') then raise exception 'Inicia sesión para jugar';end if;
 select partner_id into partner from public.user_profiles where id=u;
 if partner is null or not exists(select 1 from public.user_profiles where id=partner and partner_id=u) then raise exception 'Vincula primero tu cuenta con tu pareja';end if;
 a:=least(u,partner);b:=greatest(u,partner);
 perform pg_advisory_xact_lock(hashtextextended(a::text||b::text||p_game,0));
 update public.duo_matches set status='cancelled' where player_a=a and player_b=b and game=p_game and status in('waiting','playing') and greatest(heartbeat_a,heartbeat_b)<now()-interval '2 minutes';
 select * into m from public.duo_matches where player_a=a and player_b=b and game=p_game and status in('waiting','playing') for update;
 if not found then
  select jsonb_agg(id) into qs from(select id from public.duo_questions order by random())q;
  st:=jsonb_build_object('ready_a',false,'ready_b',false,'round',1,'wins_a',0,'wins_b',0,'score_a',0,'score_b',0,'phase','countdown','deadline',extract(epoch from now())+3,'question_no',0,'questions',qs,'x',0.5,'y',0.5,'vx',0.35,'vy',0.48,'paddle_a',0.5,'paddle_b',0.5);
  insert into public.duo_matches(game,player_a,player_b,state) values(p_game,a,b,st) returning * into m;
 end if;
 st:=jsonb_set(m.state,array[case when u=a then 'ready_a' else 'ready_b' end],'true');
 if m.status='waiting' and st->>'ready_a'='true' and st->>'ready_b'='true' then m.status:='playing';st:=jsonb_set(st,'{deadline}',to_jsonb(extract(epoch from now())+3));end if;
 update public.duo_matches set state=st,status=m.status,heartbeat_a=case when u=a then now() else heartbeat_a end,heartbeat_b=case when u=b then now() else heartbeat_b end,last_tick=now() where id=m.id;
 return public.duo_tick(m.id);
end $$;
-- Fixed server steps, cosmetics never influence collision size or speed.
create or replace function public.duo_pong_step(st jsonb,dt double precision) returns jsonb language plpgsql immutable set search_path='' as $$
declare x double precision:=(st->>'x')::float8;y double precision:=(st->>'y')::float8;vx double precision:=(st->>'vx')::float8;vy double precision:=(st->>'vy')::float8;old_y double precision;p double precision;hit double precision;sa integer:=(st->>'score_a')::int;sb integer:=(st->>'score_b')::int;steps integer;i integer;step_dt double precision;
begin
 steps:=greatest(1,ceil(least(greatest(dt,0),0.25)/0.01)::int);step_dt:=least(greatest(dt,0),0.25)/steps;
 for i in 1..steps loop
  old_y:=y;x:=x+vx*step_dt;y:=y+vy*step_dt;
  if x<0.025 then x:=0.05-x;vx:=abs(vx);elsif x>0.975 then x:=1.95-x;vx:=-abs(vx);end if;
  if vy>0 and old_y<0.9 and y>=0.9 then p:=(st->>'paddle_a')::float8;hit:=x-p;if abs(hit)<=0.135 then y:=1.8-y;vy:=-least(abs(vy)*1.035,0.85);vx:=greatest(-0.7,least(0.7,hit*4));end if;
  elsif vy<0 and old_y>0.1 and y<=0.1 then p:=(st->>'paddle_b')::float8;hit:=x-p;if abs(hit)<=0.135 then y:=0.2-y;vy:=least(abs(vy)*1.035,0.85);vx:=greatest(-0.7,least(0.7,hit*4));end if;end if;
  if y>1.05 then sb:=sb+1;exit;elsif y< -0.05 then sa:=sa+1;exit;end if;
 end loop;
 return st||jsonb_build_object('x',x,'y',y,'vx',vx,'vy',vy,'score_a',sa,'score_b',sb);
end $$;
create or replace function public.duo_tick(p_match_id uuid,p_paddle double precision default null,p_choice integer default null,p_question_no integer default null,p_phase text default null) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();m public.duo_matches;st jsonb;phase text;ts double precision:=extract(epoch from clock_timestamp());qn integer;qa public.duo_answers;qb public.duo_answers;sa integer;sb integer;wa integer;wb integer;round_n integer;question public.duo_questions;uid uuid;reward integer;earned integer;paused boolean;old_st jsonb;
begin
 select * into m from public.duo_matches where id=p_match_id for update;
 if u is null or not found or u not in(m.player_a,m.player_b) then raise exception 'No tienes acceso a esta partida' using errcode='42501';end if;
 if not exists(select 1 from public.user_profiles a join public.user_profiles b on a.partner_id=b.id and b.partner_id=a.id where a.id=m.player_a and b.id=m.player_b) then raise exception 'La pareja ya no está vinculada';end if;
 if u=m.player_a then m.heartbeat_a:=clock_timestamp();else m.heartbeat_b:=clock_timestamp();end if;
 st:=m.state;phase:=st->>'phase';qn:=(st->>'question_no')::int;
 paused:=m.status='playing' and (m.heartbeat_a<clock_timestamp()-interval '4 seconds' or m.heartbeat_b is null or m.heartbeat_b<clock_timestamp()-interval '4 seconds');
 if paused then st:=st||jsonb_build_object('paused',true,'deadline',ts+15);
 elsif st->>'paused'='true' then st:=st||jsonb_build_object('paused',false,'deadline',ts+case when phase='countdown' then 3 else 15 end);
 elsif m.status='playing' then
  if p_paddle is not null and m.game='pong' and p_paddle::text not in('NaN','Infinity','-Infinity') then st:=jsonb_set(st,array[case when u=m.player_a then 'paddle_a' else 'paddle_b' end],to_jsonb(greatest(0.11,least(0.89,p_paddle))));end if;
  if p_choice is not null and m.game='quiz' and p_choice between 0 and 2 and p_question_no=qn and p_phase=phase and phase in('self','guess') and ts<(st->>'deadline')::float8 then
   insert into public.duo_answers(match_id,question_no,user_id) values(m.id,qn,u) on conflict do nothing;
   if phase='self' then update public.duo_answers set self_choice=p_choice where match_id=m.id and question_no=qn and user_id=u and self_choice is null;
   else update public.duo_answers set guess=p_choice where match_id=m.id and question_no=qn and user_id=u and guess is null;end if;
  end if;
  select * into qa from public.duo_answers where match_id=m.id and question_no=qn and user_id=m.player_a;
  select * into qb from public.duo_answers where match_id=m.id and question_no=qn and user_id=m.player_b;
  if m.game='pong' and phase='play' then
   old_st:=st;st:=public.duo_pong_step(st,extract(epoch from clock_timestamp()-m.last_tick));
   if st->>'score_a'<>old_st->>'score_a' or st->>'score_b'<>old_st->>'score_b' then
    sa:=(st->>'score_a')::int;sb:=(st->>'score_b')::int;
    st:=st||jsonb_build_object('x',0.5,'y',0.5,'vx',case when random()<0.5 then -0.35 else 0.35 end,'vy',case when sa>(old_st->>'score_a')::int then -0.48 else 0.48 end,'phase','countdown','deadline',ts+3);
    if greatest(sa,sb)>=7 then
     wa:=(st->>'wins_a')::int+case when sa>sb then 1 else 0 end;wb:=(st->>'wins_b')::int+case when sb>sa then 1 else 0 end;
     st:=st||jsonb_build_object('wins_a',wa,'wins_b',wb,'round',(st->>'round')::int+1,'score_a',0,'score_b',0);
     if greatest(wa,wb)=2 then m.status:='finished';m.winner:=case when wa>wb then m.player_a else m.player_b end;end if;
    end if;
   end if;
  elsif phase='countdown' and ts>=(st->>'deadline')::float8 then st:=st||jsonb_build_object('phase',case when m.game='pong' then 'play' else 'self' end,'deadline',ts+15);
  elsif m.game='quiz' and phase='self' and (ts>=(st->>'deadline')::float8 or (qa.self_choice is not null and qb.self_choice is not null)) then st:=st||jsonb_build_object('phase','guess','deadline',ts+15);
  elsif m.game='quiz' and phase='guess' and (ts>=(st->>'deadline')::float8 or (qa.guess is not null and qb.guess is not null)) then
   sa:=(st->>'score_a')::int+case when qa.guess=qb.self_choice then 1 else 0 end;sb:=(st->>'score_b')::int+case when qb.guess=qa.self_choice then 1 else 0 end;
   st:=st||jsonb_build_object('score_a',sa,'score_b',sb,'phase','reveal','deadline',ts+4,'answer_a',qa.self_choice,'answer_b',qb.self_choice,'guess_a',qa.guess,'guess_b',qb.guess);
  elsif m.game='quiz' and phase='reveal' and ts>=(st->>'deadline')::float8 then
   sa:=(st->>'score_a')::int;sb:=(st->>'score_b')::int;
   round_n:=coalesce((st->>'round_questions')::int,0)+1;
   if round_n>=5 and sa<>sb then
    wa:=(st->>'wins_a')::int+case when sa>sb then 1 else 0 end;wb:=(st->>'wins_b')::int+case when sb>sa then 1 else 0 end;
    st:=st||jsonb_build_object('wins_a',wa,'wins_b',wb,'round',(st->>'round')::int+1,'score_a',0,'score_b',0);round_n:=0;
    if greatest(wa,wb)=2 then m.status:='finished';m.winner:=case when wa>wb then m.player_a else m.player_b end;end if;
   end if;
   st:=(st-'answer_a'-'answer_b'-'guess_a'-'guess_b')||jsonb_build_object('question_no',qn+1,'round_questions',round_n,'phase','self','deadline',ts+15);qn:=qn+1;
   -- A cap prevents an endless all-AFK or always-tied match from yielding rewards.
   if qn>=60 and m.status<>'finished' then m.status:='cancelled';end if;
  end if;
 end if;
 if m.status='finished' then
  for uid in select v from unnest(array[m.player_a,m.player_b])v order by v loop
   insert into public.game_stats(user_id) values(uid) on conflict(user_id) do nothing;
   perform 1 from public.game_stats where user_id=uid for update;
   if not exists(select 1 from public.duo_rewards where match_id=m.id and user_id=uid) then
    select coalesce(sum(coins),0) into earned from public.duo_rewards where user_id=uid and created_at>=(date_trunc('day',now() at time zone 'UTC') at time zone 'UTC');
    reward:=case when clock_timestamp()-m.created_at>=interval '30 seconds' then least(greatest(300-earned,0),case when uid=m.winner then 20 else 8 end) else 0 end;
    insert into public.duo_rewards(match_id,user_id,coins) values(m.id,uid,reward);
    update public.game_stats set love_coins=love_coins+reward,total_coins_earned=total_coins_earned+reward,total_games_played=total_games_played+1,updated_at=now() where user_id=uid;
   end if;
  end loop;
  select coins into reward from public.duo_rewards where match_id=m.id and user_id=u;
 end if;
 update public.duo_matches set state=st,status=m.status,winner=m.winner,heartbeat_a=m.heartbeat_a,heartbeat_b=m.heartbeat_b,last_tick=clock_timestamp() where id=m.id;
 -- Return my lock status only. Never return the other player's secret selections.
 st:=st-'questions';
 if m.game='quiz' then
  select * into question from public.duo_questions where id=(m.state->'questions'->>(qn%jsonb_array_length(m.state->'questions')))::int;
  st:=st||jsonb_build_object('question',jsonb_build_object('category',question.category,'prompt',question.prompt,'options',question.options),'my_choice',case when st->>'phase'='self' then case when u=m.player_a then qa.self_choice else qb.self_choice end when st->>'phase'='guess' then case when u=m.player_a then qa.guess else qb.guess end else null end);
 end if;
 return jsonb_build_object('id',m.id,'game',m.game,'side',case when u=m.player_a then 'a' else 'b' end,'status',m.status,'winner',m.winner,'server_time',ts,'reward',reward,'state',st);
end $$;
create or replace function public.duo_leave(p_match_id uuid) returns void language plpgsql security definer set search_path='' as $$
begin update public.duo_matches set status='cancelled' where id=p_match_id and auth.uid() in(player_a,player_b) and status in('waiting','playing');end $$;
revoke all on function public.duo_join(text),public.duo_tick(uuid,double precision,integer,integer,text),public.duo_leave(uuid),public.duo_pong_step(jsonb,double precision) from public,anon,authenticated;
grant execute on function public.duo_join(text),public.duo_tick(uuid,double precision,integer,integer,text),public.duo_leave(uuid) to authenticated;
-- Currency can only change through validated runner rewards, duo results, and purchases.
revoke insert,update,delete on public.game_stats from anon,authenticated;
grant select on public.game_stats to authenticated;
commit;
