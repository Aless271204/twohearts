-- Private counters: no codes, emails, IP addresses or attempt history.
create table nido_private.invite_attempt_limits (
  user_id uuid primary key references auth.users(id) on delete cascade,
  minute_started timestamptz not null,
  minute_count integer not null check (minute_count between 1 and 6),
  day_started timestamptz not null,
  day_count integer not null check (day_count between 1 and 21)
);
alter table nido_private.invite_attempt_limits enable row level security;
revoke all on nido_private.invite_attempt_limits from public, anon, authenticated;

create or replace function nido_private.take_invite_attempt()
returns boolean language plpgsql security invoker
set search_path = pg_catalog
as $fn$
declare
  caller uuid := auth.uid();
  at_time timestamptz := statement_timestamp();
  minute_attempts integer;
  day_attempts integer;
begin
  if caller is null then return false; end if;
  insert into nido_private.invite_attempt_limits as limits
    (user_id, minute_started, minute_count, day_started, day_count)
  values (caller, at_time, 1, at_time, 1)
  on conflict (user_id) do update set
    minute_count = case when limits.minute_started <= at_time - interval '1 minute'
      then 1 else least(limits.minute_count + 1, 6) end,
    minute_started = case when limits.minute_started <= at_time - interval '1 minute'
      then at_time else limits.minute_started end,
    day_count = case when limits.day_started <= at_time - interval '1 day'
      then 1 else least(limits.day_count + 1, 21) end,
    day_started = case when limits.day_started <= at_time - interval '1 day'
      then at_time else limits.day_started end
  returning minute_count, day_count into minute_attempts, day_attempts;
  return minute_attempts <= 5 and day_attempts <= 20;
end;
$fn$;
revoke all on function nido_private.take_invite_attempt() from public, anon, authenticated;

CREATE OR REPLACE FUNCTION public.link_partner_by_invite_code(p_invite_code text, p_relationship_start date DEFAULT NULL::date, p_connection_type text DEFAULT 'pareja'::text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
DECLARE
    caller_id UUID := auth.uid();
    target_id UUID;
    caller_partner_id UUID;
    target_partner_id UUID;
    normalized_code TEXT := upper(trim(p_invite_code));
BEGIN
    IF caller_id IS NULL THEN
        RETURN 'not_authenticated';
    END IF;

    IF p_connection_type IS NULL
       OR p_connection_type NOT IN ('pareja', 'amigo', 'grupo') THEN
        RETURN 'invalid_connection_type';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.user_profiles WHERE id = caller_id) THEN
        RETURN 'profile_not_found';
    END IF;

    -- Return instead of raising: rejected guesses must retain their counters.
    IF NOT nido_private.take_invite_attempt() THEN
        RETURN 'rate_limited';
    END IF;

    SELECT profile.id
    INTO target_id
    FROM public.user_profiles AS profile
    WHERE profile.invite_code = normalized_code;

    IF target_id IS NULL THEN
        RETURN 'not_found';
    END IF;

    IF target_id = caller_id THEN
        RETURN 'self';
    END IF;

    -- Always acquire the two row locks in the same order to avoid deadlocks.
    PERFORM profile.id
    FROM public.user_profiles AS profile
    WHERE profile.id IN (caller_id, target_id)
    ORDER BY profile.id
    FOR UPDATE;

    SELECT profile.partner_id
    INTO caller_partner_id
    FROM public.user_profiles AS profile
    WHERE profile.id = caller_id;

    IF NOT FOUND THEN
        RETURN 'profile_not_found';
    END IF;

    SELECT profile.partner_id
    INTO target_partner_id
    FROM public.user_profiles AS profile
    WHERE profile.id = target_id
      AND profile.invite_code = normalized_code;

    IF NOT FOUND THEN
        RETURN 'not_found';
    END IF;

    IF caller_partner_id IS NOT NULL THEN
        RETURN 'caller_already_linked';
    END IF;

    IF target_partner_id IS NOT NULL THEN
        RETURN 'target_already_linked';
    END IF;

    UPDATE public.user_profiles
    SET partner_id = target_id,
        connection_type = p_connection_type,
        relationship_start = COALESCE(p_relationship_start, relationship_start)
    WHERE id = caller_id;

    UPDATE public.user_profiles
    SET partner_id = caller_id,
        connection_type = p_connection_type,
        relationship_start = COALESCE(p_relationship_start, relationship_start)
    WHERE id = target_id;

    RETURN 'linked';
END;
$function$
;
revoke execute on function public.link_partner_by_invite_code(text,date,text) from public, anon;
grant execute on function public.link_partner_by_invite_code(text,date,text) to authenticated;
