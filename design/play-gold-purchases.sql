-- Only the authenticated Google verification service can credit purchased gold.
create table nido_private.play_purchase_receipts(
 token_hash text primary key check(token_hash~'^[a-f0-9]{64}$'),
 user_id uuid not null references auth.users(id),
 product text not null check(product in ('nido_gold_500','nido_gold_2500','nido_gold_10000')),
 gold integer not null check(gold>0),order_id text,is_test boolean not null,
 created_at timestamptz not null default now()
);
alter table nido_private.play_purchase_receipts enable row level security;
revoke all on nido_private.play_purchase_receipts from public,anon,authenticated;
create function public.play_credit_verified(p_user uuid,p_product text,p_token_hash text,p_order text,p_consumed boolean,p_test boolean)
returns jsonb language plpgsql security definer set search_path='' as $$
declare amount integer; previous nido_private.play_purchase_receipts;
begin
 amount:=case p_product when 'nido_gold_500' then 500 when 'nido_gold_2500' then 2500 when 'nido_gold_10000' then 10000 end;
 if p_user is null or amount is null or p_token_hash is null or p_token_hash!~'^[a-f0-9]{64}$' or p_consumed is null or p_test is null then raise exception 'Invalid verified purchase';end if;
 perform pg_advisory_xact_lock(hashtextextended('play-purchase:'||p_token_hash,0));
 select * into previous from nido_private.play_purchase_receipts where token_hash=p_token_hash;
 if found then
  if previous.user_id<>p_user or previous.product<>p_product then raise exception 'Purchase owner mismatch';end if;
  return jsonb_build_object('gold',previous.gold,'already_credited',true);
 end if;
 if p_consumed then raise exception 'Consumed purchase without receipt';end if;
 insert into nido_private.play_purchase_receipts values(p_token_hash,p_user,p_product,amount,left(p_order,200),p_test,now());
 insert into public.game_stats(user_id,love_coins) values(p_user,amount)
 on conflict(user_id) do update set love_coins=game_stats.love_coins+excluded.love_coins,updated_at=now();
 return jsonb_build_object('gold',amount,'already_credited',false);
end $$;
revoke all on function public.play_credit_verified(uuid,text,text,text,boolean,boolean) from public,anon,authenticated;
grant execute on function public.play_credit_verified(uuid,text,text,text,boolean,boolean) to service_role;
