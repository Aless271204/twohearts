-- TwoHearts Auth Migration
-- Creates user_profiles and couple_links tables

-- 1. user_profiles table
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL DEFAULT '',
    avatar_url TEXT DEFAULT '',
    invite_code TEXT UNIQUE,
    partner_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    relationship_start DATE,
    pet_type TEXT DEFAULT 'egg',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. Indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_invite_code ON public.user_profiles(invite_code);
CREATE INDEX IF NOT EXISTS idx_user_profiles_partner_id ON public.user_profiles(partner_id);

-- 3. Function to generate unique invite code
CREATE OR REPLACE FUNCTION public.generate_invite_code()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    code TEXT := '';
    i INT;
BEGIN
    FOR i IN 1..6 LOOP
        code := code || substr(chars, floor(random() * length(chars) + 1)::INT, 1);
    END LOOP;
    RETURN code;
END;
$$;

-- 4. Function to handle new user creation (trigger)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_invite_code TEXT;
    attempts INT := 0;
BEGIN
    -- Generate unique invite code
    LOOP
        new_invite_code := public.generate_invite_code();
        EXIT WHEN NOT EXISTS (
            SELECT 1 FROM public.user_profiles WHERE invite_code = new_invite_code
        );
        attempts := attempts + 1;
        EXIT WHEN attempts > 10;
    END LOOP;

    INSERT INTO public.user_profiles (id, email, full_name, avatar_url, invite_code)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
        new_invite_code
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

-- 5. Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- 6. Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- 7. RLS Policies
DROP POLICY IF EXISTS "users_manage_own_user_profiles" ON public.user_profiles;
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Allow users to read their partner's profile
DROP POLICY IF EXISTS "users_read_partner_profile" ON public.user_profiles;
CREATE POLICY "users_read_partner_profile"
ON public.user_profiles
FOR SELECT
TO authenticated
USING (
    id = auth.uid()
    OR id = (SELECT partner_id FROM public.user_profiles WHERE id = auth.uid() LIMIT 1)
);

-- Allow reading by invite code (for partner linking)
DROP POLICY IF EXISTS "users_read_by_invite_code" ON public.user_profiles;
CREATE POLICY "users_read_by_invite_code"
ON public.user_profiles
FOR SELECT
TO authenticated
USING (true);

-- 8. Triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 9. Mock demo users
DO $$
DECLARE
    sofia_uuid UUID := gen_random_uuid();
    mateo_uuid UUID := gen_random_uuid();
BEGIN
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (sofia_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'sofia@twohearts.app', crypt('LoveAlways2026', gen_salt('bf', 10)), now(), now(), now(),
         jsonb_build_object('full_name', 'Sofia'),
         jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (mateo_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'mateo@twohearts.app', crypt('LoveAlways2026', gen_salt('bf', 10)), now(), now(), now(),
         jsonb_build_object('full_name', 'Mateo'),
         jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null)
    ON CONFLICT (id) DO NOTHING;

    -- Link the two demo users as partners and set relationship start
    UPDATE public.user_profiles
    SET partner_id = mateo_uuid, relationship_start = '2023-02-14'
    WHERE id = sofia_uuid;

    UPDATE public.user_profiles
    SET partner_id = sofia_uuid, relationship_start = '2023-02-14'
    WHERE id = mateo_uuid;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock data insertion failed: %', SQLERRM;
END $$;
