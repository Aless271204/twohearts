-- Nido: Shared sync tables for couple/group memories
-- Adds connection_type to user_profiles and creates shared content tables

-- 1. Add connection_type to user_profiles
ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS connection_type TEXT DEFAULT 'pareja';

-- 2. nido_memories table (shared photos/memories)
CREATE TABLE IF NOT EXISTS public.nido_memories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    partner_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    image_url TEXT DEFAULT '',
    caption TEXT DEFAULT '',
    memory_date DATE DEFAULT CURRENT_DATE,
    likes INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_nido_memories_owner ON public.nido_memories(owner_id);
CREATE INDEX IF NOT EXISTS idx_nido_memories_partner ON public.nido_memories(partner_id);

-- 3. nido_trips table (shared trips/viajes)
CREATE TABLE IF NOT EXISTS public.nido_trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    partner_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    city TEXT NOT NULL DEFAULT '',
    country_emoji TEXT DEFAULT '🌍',
    trip_date TEXT DEFAULT '',
    rating INT DEFAULT 5,
    hotel TEXT DEFAULT '',
    note TEXT DEFAULT '',
    image_url TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_nido_trips_owner ON public.nido_trips(owner_id);
CREATE INDEX IF NOT EXISTS idx_nido_trips_partner ON public.nido_trips(partner_id);

-- 4. nido_dates table (shared citas/dates)
CREATE TABLE IF NOT EXISTS public.nido_dates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    partner_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    title TEXT NOT NULL DEFAULT '',
    description TEXT DEFAULT '',
    date_on DATE DEFAULT CURRENT_DATE,
    photos TEXT[] DEFAULT ARRAY[]::TEXT[],
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_nido_dates_owner ON public.nido_dates(owner_id);
CREATE INDEX IF NOT EXISTS idx_nido_dates_partner ON public.nido_dates(partner_id);

-- 5. Enable RLS
ALTER TABLE public.nido_memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nido_trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nido_dates ENABLE ROW LEVEL SECURITY;

-- 6. Helper function: get partner id for current user (SECURITY DEFINER to avoid recursion)
CREATE OR REPLACE FUNCTION public.get_my_partner_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT partner_id FROM public.user_profiles WHERE id = auth.uid() LIMIT 1;
$$;

-- 7. RLS Policies for nido_memories
DROP POLICY IF EXISTS "couple_access_nido_memories" ON public.nido_memories;
CREATE POLICY "couple_access_nido_memories"
ON public.nido_memories
FOR ALL
TO authenticated
USING (
    owner_id = auth.uid()
    OR partner_id = auth.uid()
    OR owner_id = public.get_my_partner_id()
)
WITH CHECK (
    owner_id = auth.uid()
);

-- 8. RLS Policies for nido_trips
DROP POLICY IF EXISTS "couple_access_nido_trips" ON public.nido_trips;
CREATE POLICY "couple_access_nido_trips"
ON public.nido_trips
FOR ALL
TO authenticated
USING (
    owner_id = auth.uid()
    OR partner_id = auth.uid()
    OR owner_id = public.get_my_partner_id()
)
WITH CHECK (
    owner_id = auth.uid()
);

-- 9. RLS Policies for nido_dates
DROP POLICY IF EXISTS "couple_access_nido_dates" ON public.nido_dates;
CREATE POLICY "couple_access_nido_dates"
ON public.nido_dates
FOR ALL
TO authenticated
USING (
    owner_id = auth.uid()
    OR partner_id = auth.uid()
    OR owner_id = public.get_my_partner_id()
)
WITH CHECK (
    owner_id = auth.uid()
);

-- 10. Update trigger for nido_memories
CREATE OR REPLACE FUNCTION public.update_nido_memories_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS update_nido_memories_updated_at ON public.nido_memories;
CREATE TRIGGER update_nido_memories_updated_at
    BEFORE UPDATE ON public.nido_memories
    FOR EACH ROW EXECUTE FUNCTION public.update_nido_memories_updated_at();
