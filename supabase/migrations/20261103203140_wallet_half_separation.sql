-- Restore the approved 50/50 rule. Installing this migration changes no
-- balances, relationships or inventory. It only affects future confirmations.
-- An odd coin goes to the first member in the existing stable UUID order.
alter table nido_private.wallet_separations
  add column if not exists rounding_member uuid;

create or replace function public.wallet_snapshot() returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); ids uuid[]; amount bigint; half bigint;
  own_share bigint; other_share bigint;
begin
 if u is null then raise exception 'Inicia sesión' using errcode='42501';end if;
 ids:=nido_private.wallet_members(u);amount:=nido_private.wallet_balance(u);
 if amount<0 then raise exception 'El saldo requiere revisión';end if;
 half:=amount/2;
 own_share:=half+case when u=ids[1] then mod(amount,2) else 0 end;
 other_share:=amount-own_share;
 return jsonb_build_object('coins',amount,'shared',cardinality(ids)=2,
   'separation_share',half,'separation_percent',50,
   'separation_own_share',own_share,'separation_partner_share',other_share,
   'separation_discarded',0,'separation_policy','half_v1');
end $$;

create or replace function public.wallet_unlink(
 p_expected_balance bigint,p_confirm boolean default false) returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();ids uuid[]; amount bigint; half bigint;
  remainder bigint; own_share bigint;
begin
 if u is null or p_confirm is distinct from true then
   raise exception 'Confirma la separación y su reparto de oro' using errcode='42501';
 end if;
 perform nido_private.wallet_lock(u);ids:=nido_private.wallet_members(u);
 if cardinality(ids)<>2 then raise exception 'No hay una pareja enlazada';end if;
 amount:=nido_private.wallet_balance(u);
 if amount is distinct from p_expected_balance then
   raise exception 'El saldo cambió. Revisa de nuevo el reparto antes de confirmar';
 end if;
 if amount<0 then raise exception 'El saldo requiere revisión';end if;
 half:=amount/2;remainder:=mod(amount,2);
 insert into nido_private.wallet_separations(
   member_a,member_b,balance_before,each_receives,discarded,rounding_member)
 values(ids[1],ids[2],amount,half,0,case when remainder=1 then ids[1] else null end);
 update public.game_stats
 set love_coins=half+case when user_id=ids[1] then remainder else 0 end,
     updated_at=now()
 where user_id=any(ids);
 update public.user_profiles set partner_id=null where id=any(ids);
 own_share:=half+case when u=ids[1] then remainder else 0 end;
 return jsonb_build_object('unlinked',true,'coins',own_share,
   'partner_coins',amount-own_share,'discarded',0,'separation_policy','half_v1');
end $$;
revoke all on function public.wallet_snapshot(),public.wallet_unlink(bigint,boolean)
 from public,anon;
grant execute on function public.wallet_snapshot(),public.wallet_unlink(bigint,boolean)
 to authenticated;
