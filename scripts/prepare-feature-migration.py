from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
defs=json.loads((root/'outputs/latest-feature-definitions.json').read_text(encoding='utf-8'))
def definition(schema,name):
    return next(d['definition'] for d in defs if d['nspname']==schema and d['proname']==name).rstrip().rstrip(';')+';\n'
wallet=(root/'outputs/shared-wallet-draft.sql').read_text(encoding='utf-8').replace('end $function$','end $function$;')
wallet=wallet.replace('balance integer','balance bigint')
wallet=wallet.replace("insert into public.game_stats(user_id) values(u) on conflict(user_id) do nothing;\n perform nido_private.wallet_lock(u)","perform nido_private.wallet_lock(u)")
wallet=wallet.replace("if p_action='adopt_gold' then perform 1 from public.game_stats where user_id=auth.uid() for update;end if;","perform nido_private.wallet_lock(auth.uid());")
# Membership changes and adoption serialize with spending; balances are never
# rewritten merely by linking or installing this migration.
room=definition('nido_private','guardian_room')
room=room.replace('guest_ready=guest_ready or guest_id=u','guest_ready=guest_ready or coalesce(guest_id=u,false)')
room=room.replace("if r.host_ready and r.guest_ready then", "if r.engine_version=2 and r.host_ready and r.guest_ready then")
room=room.replace("elsif p_action='inputs' then", """elsif p_action='start' then
   if r.host_id<>u or r.status<>'waiting' or r.guest_id is null or not r.host_ready or not r.guest_ready then raise exception 'Ambos deben estar listos y el anfitrión debe iniciar';end if;
   update nido_private.guardian_rooms set status='running',started_at=now()+interval '3 seconds' where id=r.id returning * into r;
  elsif p_action='inputs' then""")
room=room.replace("host_ready,host_loadout)","host_ready,host_loadout,engine_version)")
room=room.replace("p_action='solo',look) returning", "p_action='solo',look,case when p_packets->>'engine_version'='3' then 3 else 2 end) returning")
room=room.replace("'joined',r.guest_id is not null", "'engine_version',r.engine_version,'host_ready',r.host_ready,'guest_ready',r.guest_ready,'joined',r.guest_id is not null")
room=room.replace("'reward',(select amount", "'prize',(select item_key from nido_private.guardian_clothing_prizes where room_id=r.id),'reward',(select amount")
settle=definition('public','guardian_settle')
settle=settle.replace("maxreward integer;", "maxreward integer; prize text; members uuid[];")
settle=settle.replace("return result;", """if r.difficulty='hard' then
  members:=array_remove(array[r.host_id,r.guest_id],null);
  -- One claim per verified victory, even when all eligible pieces are owned.
  if not exists(select 1 from nido_private.guardian_clothing_prizes where room_id=r.id) then
   select s.item_key into prize from public.shop_items s where s.active and s.scope='pet' and s.price_coins between 50 and 60
    and s.item_key in ('bandana_sage','bow_neck','glasses_heart','patch_pirate','shirt_love','mask_sleep','glasses_round')
    and not exists(select 1 from public.owned_items o where o.user_id=any(members) and o.item_key=s.item_key) order by random() limit 1;
   insert into nido_private.guardian_clothing_prizes(room_id,item_key) values(r.id,prize);
   if prize is not null then insert into public.owned_items(user_id,item_key,slot) select x,prize,s.equip_slot from unnest(members) x cross join public.shop_items s where s.item_key=prize on conflict(user_id,item_key) do nothing;end if;
  end if;
 end if;
 return result||jsonb_build_object('prize',(select item_key from nido_private.guardian_clothing_prizes where room_id=r.id));""")
# An idempotent save must return the original prize too.
settle=settle.replace("'saved',true,'reward',(select gr.amount", "'saved',true,'prize',(select item_key from nido_private.guardian_clothing_prizes where room_id=r.id),'reward',(select gr.amount")
art=(root/'outputs/art-mystery-draft.sql').read_text(encoding='utf-8').replace('end $function$','end $function$;')
art=art.replace('alter table nido_private.art_rooms add column if not exists reference_revealed_at', 'alter table nido_private.art_rooms add column if not exists reference_protocol integer not null default 1, add column if not exists reference_revealed_at')
art=art.replace('code,host,guest,difficulty,scene)', 'code,host,guest,difficulty,scene,reference_protocol)')
art=art.replace("floor(random()*12)::int)) returning", "floor(random()*12)::int),case when p_data->>'protocol'='2' then 2 else 1 end) returning")
art=art.replace("if r.host_ready and r.guest_ready and r.reference_revealed_at is null then", "if r.reference_protocol=1 and r.host_ready and r.guest_ready then update nido_private.art_rooms set deadline=now()+interval '5 minutes',reference_revealed_at=now() where id=r.id returning * into r;end if;\n   if r.host_ready and r.guest_ready and r.reference_revealed_at is null then")
art=art.replace("if r.id is not null and r.reference_revealed_at is null then", "if r.id is not null and r.reference_protocol=2 and r.reference_revealed_at is null then")
art=art.replace("token text; result jsonb; art text;", "token text; result jsonb; art text; member uuid; earned integer; amount integer;")
art=art.replace("result:=(to_jsonb(r)", """if r.host_art is not null and r.guest_art is not null and r.deadline is not null and now()>=r.deadline then
  for member in select x from unnest(array[r.host,r.guest]) x order by x loop
   perform pg_advisory_xact_lock(hashtextextended('art-reward:'||member::text,0));
   if not exists(select 1 from nido_private.art_rewards where room_id=r.id and user_id=member) then
    select coalesce(sum(a.amount),0) into earned from nido_private.art_rewards a where a.user_id=member and a.created_at>=date_trunc('day',now());
    amount:=least(10+r.difficulty*5,greatest(0,100-earned));
    insert into nido_private.art_rewards(room_id,user_id,amount) values(r.id,member,amount);
    insert into public.game_stats(user_id,love_coins,total_games_played,total_coins_earned) values(member,amount,1,amount)
     on conflict(user_id) do update set love_coins=game_stats.love_coins+excluded.love_coins,total_games_played=game_stats.total_games_played+1,total_coins_earned=game_stats.total_coins_earned+excluded.total_coins_earned,updated_at=now();
   end if;
  end loop;
 end if;
 result:=(to_jsonb(r)""")
art=art.replace("'server_now',now()", "'reward',(select a.amount from nido_private.art_rewards a where a.room_id=r.id and a.user_id=u),'server_now',now()")
tables="""
alter table nido_private.guardian_rooms add column if not exists engine_version integer not null default 2;
create table if not exists nido_private.guardian_clothing_prizes(room_id uuid primary key references nido_private.guardian_rooms(id) on delete cascade,item_key text references public.shop_items(item_key),created_at timestamptz not null default now());
alter table nido_private.guardian_clothing_prizes enable row level security;
revoke all on nido_private.guardian_clothing_prizes from public,anon,authenticated;
create table if not exists nido_private.art_rewards(room_id uuid references nido_private.art_rooms(id) on delete cascade,user_id uuid references auth.users(id) on delete cascade,amount integer not null check(amount between 0 and 20),created_at timestamptz not null default now(),primary key(room_id,user_id));
alter table nido_private.art_rewards enable row level security;
revoke all on nido_private.art_rewards from public,anon,authenticated;
"""
target=root/'supabase/migrations/20261017225009_shared_wallet_game_rewards_and_mystery_art.sql'
target.write_text(wallet+'\n'+tables+'\n'+room+'\n'+settle+'\n'+art,encoding='utf-8')
print(target.name, target.stat().st_size)
