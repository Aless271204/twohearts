-- Unlimited voluntary rewarded videos, three coins; signed SSV and replay protection unchanged.
CREATE OR REPLACE FUNCTION nido_private.ad_status()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid:=auth.uid();
begin
 if u is null then raise exception 'Inicia sesiÃ³n' using errcode='42501';end if;
 return jsonb_build_object('remaining',null,'gold',3,'limit',null,'window_hours',null,'unlimited',true,'next_available_at',now());
end $function$
;
CREATE OR REPLACE FUNCTION nido_private.ad_begin()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid:=auth.uid();t uuid;
begin
 if u is null then raise exception 'Inicia sesiÃ³n' using errcode='42501';end if;
 insert into public.game_stats(user_id) values(u) on conflict do nothing;
 perform 1 from public.game_stats where user_id=u for update;
 insert into public.rewarded_ad_sessions(user_id) values(u) returning ticket into t;
 return jsonb_build_object('ticket',t,'gold',3);
end $function$
;
CREATE OR REPLACE FUNCTION public.admob_credit_verified(p_ticket uuid, p_user_id uuid, p_transaction_id text, p_event_time timestamp with time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare s public.rewarded_ad_sessions;balance integer;
begin
 if length(p_transaction_id)<8 or length(p_transaction_id)>200 then raise exception 'Invalid transaction';end if;
 perform 1 from public.game_stats where user_id=p_user_id for update;
 select * into s from public.rewarded_ad_sessions where ticket=p_ticket and user_id=p_user_id for update;
 if not found then raise exception 'Unknown reward';end if;
 if s.status='completed' then
  if s.transaction_id<>p_transaction_id then raise exception 'Transaction mismatch';end if;
  return jsonb_build_object('credited',false,'already_processed',true);
 end if;
 if s.status<>'reserved' or p_event_time<s.created_at-interval '1 minute' or p_event_time>s.expires_at or now()-p_event_time>interval '24 hours' or p_event_time>now()+interval '1 minute' then raise exception 'Invalid reward window';end if;
 if exists(select 1 from public.rewarded_ad_sessions where transaction_id=p_transaction_id) then raise exception 'Repeated transaction';end if;
 update public.rewarded_ad_sessions set status='completed',completed_at=now(),transaction_id=p_transaction_id where ticket=p_ticket;
 update public.game_stats set love_coins=love_coins+3,updated_at=now() where user_id=p_user_id returning love_coins into balance;
 return jsonb_build_object('credited',true,'gold',3,'coins',balance);
end $function$
;
