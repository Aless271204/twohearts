"""Build the reviewed migration from saved, current server function definitions."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
definitions = {(f['schema'], f['name']): f['definition'].replace('\r', '') for f in json.loads((root/'outputs/reward-functions-before.json').read_text(encoding='utf-8'))}
def replace(text, old, new):
    assert text.count(old) == 1, f'Expected exactly one settlement anchor: {old[:100]}'
    return text.replace(old, new)

header = '''-- Verified game settlements only. Existing balances/receipts are not rewritten.
-- A first result establishes the baseline. Ties and repeated saves never earn a bonus.
create table nido_private.game_record_scores (
 user_id uuid not null references auth.users(id) on delete cascade,
 game text not null, scope text not null, best_score bigint,
 current_streak integer not null default 0, attempts integer not null default 0,
 updated_at timestamptz not null default now(), primary key(user_id,game,scope)
);
create table nido_private.game_record_receipts (
 user_id uuid not null references auth.users(id) on delete cascade,
 game text not null, scope text not null, run text not null,
 score bigint not null, base_reward integer not null, bonus integer not null,
 is_record boolean not null, created_at timestamptz not null default now(),
 primary key(user_id,game,scope,run)
);
alter table nido_private.game_record_scores enable row level security;
alter table nido_private.game_record_receipts enable row level security;
revoke all on nido_private.game_record_scores,nido_private.game_record_receipts from public,anon,authenticated;

-- Invoked only inside already-authorized, locked settlement functions.
create function nido_private.record_bonus(p_user uuid,p_game text,p_scope text,p_run text,p_score bigint,p_base integer,p_capacity integer,p_win boolean default null)
returns integer language plpgsql set search_path='' as $$
declare previous nido_private.game_record_scores; score bigint; extra integer; beaten boolean;
begin
 if p_user is null or p_game not in ('pebble_runner','guardian','pong','quiz','penalties','maze','art') or p_scope is null or p_run is null or p_base<0 or p_capacity<0 then raise exception 'Invalid record settlement';end if;
 insert into nido_private.game_record_scores(user_id,game,scope) values(p_user,p_game,p_scope) on conflict do nothing;
 select * into previous from nido_private.game_record_scores where user_id=p_user and game=p_game and scope=p_scope for update;
 if exists(select 1 from nido_private.game_record_receipts where user_id=p_user and game=p_game and scope=p_scope and run=p_run) then return 0;end if;
 score:=case when p_win is null then greatest(0,p_score) when p_win then previous.current_streak+1 else 0 end;
 beaten:=previous.attempts>0 and previous.best_score is not null and score>previous.best_score;
 -- Currency is integral: round up the extra, while preserving each game's daily cap.
 extra:=case when beaten then least(ceil(p_base::numeric/10)::int,greatest(0,p_capacity-p_base)) else 0 end;
 insert into nido_private.game_record_receipts(user_id,game,scope,run,score,base_reward,bonus,is_record) values(p_user,p_game,p_scope,p_run,score,p_base,extra,beaten);
 update nido_private.game_record_scores set best_score=greatest(best_score,score),current_streak=case when p_win is null then current_streak else score::int end,attempts=attempts+1,updated_at=now() where user_id=p_user and game=p_game and scope=p_scope;
 return extra;
end $$;
revoke all on function nido_private.record_bonus(uuid,text,text,text,bigint,integer,integer,boolean) from public,anon,authenticated;

create function nido_private.record_receipt(p_user uuid,p_game text,p_scope text,p_run text) returns jsonb language sql set search_path='' as $$
 select coalesce((select jsonb_build_object('base_reward',base_reward,'record_bonus',bonus,'new_record',is_record) from nido_private.game_record_receipts where user_id=p_user and game=p_game and scope=p_scope and run=p_run),'{}'::jsonb)
$$;
revoke all on function nido_private.record_receipt(uuid,text,text,text) from public,anon,authenticated;

-- Preserve the runner's existing distance record as its baseline.
insert into nido_private.game_record_scores(user_id,game,scope,best_score,attempts)
 select user_id,'pebble_runner','distance',greatest(0,best_score),greatest(1,times_played) from public.game_records where game_id='pebble_runner' on conflict do nothing;
'''

runner = definitions['public','runner_finish_session']
runner = replace(runner, '  v_xp:=least(1000,p_distance/10+v_awarded);', "  v_awarded:=v_awarded+nido_private.record_bonus(p_user_id,'pebble_runner','distance',p_session_id::text,p_distance,v_awarded,least(500,greatest(0,1000-v_today)));\n  v_xp:=least(1000,p_distance/10+v_awarded);")
runner = replace(runner, "'best_distance',v_best,'love_coins',v_stats.love_coins,'xp',v_stats.xp,'level',v_stats.level);", "'best_distance',v_best,'love_coins',v_stats.love_coins,'xp',v_stats.xp,'level',v_stats.level)||nido_private.record_receipt(p_user_id,'pebble_runner','distance',p_session_id::text);")

guardian = definitions['public','guardian_settle']
guardian = replace(guardian, ' maxreward:=100;', ' maxreward:=200;')
guardian = replace(guardian, '  insert into nido_private.guardian_rewards values(r.id,u,amount,now());', "  amount:=amount+nido_private.record_bonus(u,'guardian',r.difficulty||':'||r.mode||':'||case when r.engine_version in (4,5,7) then 'river' else 'forest' end,r.id::text,21601-p_frames,amount,greatest(0,200-earned));\n  insert into nido_private.guardian_rewards values(r.id,u,amount,now());")
guardian = replace(guardian, "jsonb_build_object('saved',true,'reward',amount)", "jsonb_build_object('saved',true,'reward',amount)||nido_private.record_receipt(u,'guardian',r.difficulty||':'||r.mode||':'||case when r.engine_version in (4,5,7) then 'river' else 'forest' end,r.id::text)")

duo = definitions['public','duo_tick']
duo = replace(duo, '    insert into public.duo_rewards(match_id,user_id,coins) values(m.id,uid,reward);', "    if clock_timestamp()-m.created_at>=interval '30 seconds' then reward:=reward+nido_private.record_bonus(uid,m.game,'wins',m.id::text,0,reward,greatest(300-earned,0),uid=m.winner);end if;\n    insert into public.duo_rewards(match_id,user_id,coins) values(m.id,uid,reward);")
duo = replace(duo, "'state',st);\nend $function$", "'state',st)||nido_private.record_receipt(u,m.game,'wins',m.id::text);\nend $function$")

penalty = definitions['nido_private','penalty_room']
penalty = replace(penalty, '     insert into nido_private.penalty_rewards(room_id,generation,user_id,amount) values(r.id,r.generation,member,award) on conflict do nothing;', "     award:=award+nido_private.record_bonus(member,'penalties','wins',r.id::text||':'||r.generation,0,award,greatest(0,100-daily),idx=win);\n     insert into nido_private.penalty_rewards(room_id,generation,user_id,amount) values(r.id,r.generation,member,award) on conflict do nothing;")
penalty = replace(penalty, "'species',jsonb_build_array(r.host_species,r.guest_species));", "'species',jsonb_build_array(r.host_species,r.guest_species),'reward',(select amount from nido_private.penalty_rewards where room_id=r.id and generation=r.generation and user_id=u))||nido_private.record_receipt(u,'penalties','wins',r.id::text||':'||r.generation);")

maze = definitions['public','maze_room_service']
maze = replace(maze, '     insert into nido_private.maze_rewards values(r.id,r.generation,member,amount,now()) on conflict do nothing;', "     amount:=amount+nido_private.record_bonus(member,'maze',r.difficulty||':'||r.mode,r.id::text||':'||r.generation,greatest(0,1000000-coalesce((r.state->>'moves')::int,1000000)),amount,greatest(0,100-daily));\n     insert into nido_private.maze_rewards values(r.id,r.generation,member,amount,now()) on conflict do nothing;")
maze = replace(maze, "'joined',r.guest_id is not null);", "'joined',r.guest_id is not null,'reward',(select rw.amount from nido_private.maze_rewards rw where rw.room_id=r.id and rw.generation=r.generation and rw.user_id=p_user))||nido_private.record_receipt(p_user,'maze',r.difficulty||':'||r.mode,r.id::text||':'||r.generation);")

art = definitions['nido_private','art_action']
art = replace(art, 'amount integer;', 'amount integer; extra integer;')
art = replace(art, " result:=(to_jsonb(r)-'host_art'-'guest_art'-'reference_image')", """ -- Only a mutually agreed vote counts as a drawing victory; never trust a client visual score.
 if r.host_vote is not null and r.host_vote=r.guest_vote and r.deadline is not null and now()>=r.deadline then
  for member in select x from unnest(array[r.host,r.guest]) x order by x loop
   perform pg_advisory_xact_lock(hashtextextended('art-reward:'||member::text,0));
   select amount into amount from nido_private.art_rewards a where a.room_id=r.id and a.user_id=member;
   select coalesce(sum(a.amount),0) into earned from nido_private.art_rewards a where a.user_id=member and a.created_at>=date_trunc('day',now());
   if amount is not null then
    extra:=nido_private.record_bonus(member,'art','wins:'||r.difficulty,r.id::text,0,amount,amount+greatest(0,100-earned),member=r.host_vote);
    if extra>0 then
     update nido_private.art_rewards a set amount=a.amount+extra where a.room_id=r.id and a.user_id=member;
     update public.game_stats set love_coins=love_coins+extra,total_coins_earned=total_coins_earned+extra,updated_at=now() where user_id=member;
    end if;
   end if;
  end loop;
 end if;
 result:=(to_jsonb(r)-'host_art'-'guest_art'-'reference_image')""")
art = art.replace('select amount into amount from nido_private.art_rewards a', 'select a.amount into amount from nido_private.art_rewards a')
art = replace(art, "'server_now',now());", "'server_now',now())||nido_private.record_receipt(u,'art','wins:'||r.difficulty,r.id::text);")

parts = [header, runner, guardian, duo, penalty, maze, art]
target = next((root/'supabase/migrations').glob('*_guardian_ten_points_and_record_bonus.sql'))
target.write_text('\n\n'.join(p.rstrip(';\n')+';' for p in parts)+'\n', encoding='utf-8')
print(target.name)
