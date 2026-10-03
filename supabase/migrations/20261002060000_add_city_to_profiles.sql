-- Add city column to user_profiles for personalized location display
ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS city TEXT DEFAULT '';

-- Update demo users with their cities
DO $$
BEGIN
    UPDATE public.user_profiles
    SET city = 'Quito, Ecuador'
    WHERE email = 'sofia@twohearts.app';

    UPDATE public.user_profiles
    SET city = 'Barcelona, España'
    WHERE email = 'mateo@twohearts.app';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'City update for demo users failed: %', SQLERRM;
END $$;
