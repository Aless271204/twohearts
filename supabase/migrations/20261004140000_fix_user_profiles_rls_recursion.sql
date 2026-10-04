-- Replace recursive profile policies with a restricted SECURITY DEFINER helper.
CREATE OR REPLACE FUNCTION public.get_my_partner_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
    SELECT profile.partner_id
    FROM public.user_profiles AS profile
    WHERE profile.id = (SELECT auth.uid())
    LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.get_my_partner_id() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_partner_id() TO authenticated;

DROP POLICY IF EXISTS "users_read_partner_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "users_read_by_invite_code" ON public.user_profiles;

CREATE POLICY "users_read_partner_profile"
ON public.user_profiles
FOR SELECT
TO authenticated
USING (
    id = (SELECT auth.uid())
    OR id = public.get_my_partner_id()
);

-- Email lookup returns only the fields needed by the pairing UI, and only for
-- an unpaired target when the caller is also unpaired.
CREATE OR REPLACE FUNCTION public.search_user_by_email(p_email TEXT)
RETURNS TABLE (id UUID, full_name TEXT, invite_code TEXT)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    caller_id UUID := auth.uid();
BEGIN
    IF caller_id IS NULL
       OR public.get_my_partner_id() IS NOT NULL
       OR NOT EXISTS (
           SELECT 1
           FROM public.user_profiles AS caller
           WHERE caller.id = caller_id
       ) THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT profile.id, profile.full_name, profile.invite_code
    FROM public.user_profiles AS profile
    WHERE lower(profile.email) = lower(trim(p_email))
      AND profile.id <> caller_id
      AND profile.partner_id IS NULL
    LIMIT 1;
END;
$$;

REVOKE ALL ON FUNCTION public.search_user_by_email(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.search_user_by_email(TEXT) TO authenticated;

-- Pair both profiles atomically without granting clients write access to a
-- different user's row.
CREATE OR REPLACE FUNCTION public.link_partner_by_invite_code(
    p_invite_code TEXT,
    p_relationship_start DATE DEFAULT NULL,
    p_connection_type TEXT DEFAULT 'pareja'
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
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
$$;

REVOKE ALL ON FUNCTION public.link_partner_by_invite_code(TEXT, DATE, TEXT)
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.link_partner_by_invite_code(TEXT, DATE, TEXT)
TO authenticated;
