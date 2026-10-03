-- Add nickname and bio columns to user_profiles for personalization
ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS nickname TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS bio TEXT DEFAULT '';

-- Add social_posts table for 24h expiring posts
CREATE TABLE IF NOT EXISTS public.social_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  couple_id TEXT,
  is_anon BOOLEAN DEFAULT FALSE,
  post_type TEXT NOT NULL DEFAULT 'phrase', -- 'phrase', 'image', 'gif'
  content TEXT NOT NULL,
  caption TEXT,
  tag TEXT,
  tag_color BIGINT,
  likes INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '24 hours'
);

-- Add follows table for couple following
CREATE TABLE IF NOT EXISTS public.social_follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  followed_couple_id TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(follower_id, followed_couple_id)
);

-- RLS for social_posts
ALTER TABLE public.social_posts ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'social_posts' AND policyname = 'social_posts_select'
  ) THEN
    CREATE POLICY social_posts_select ON public.social_posts
      FOR SELECT USING (expires_at > NOW());
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'social_posts' AND policyname = 'social_posts_insert'
  ) THEN
    CREATE POLICY social_posts_insert ON public.social_posts
      FOR INSERT WITH CHECK (auth.uid() = owner_id);
  END IF;
END $$;

-- RLS for social_follows
ALTER TABLE public.social_follows ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'social_follows' AND policyname = 'social_follows_all'
  ) THEN
    CREATE POLICY social_follows_all ON public.social_follows
      USING (auth.uid() = follower_id)
      WITH CHECK (auth.uid() = follower_id);
  END IF;
END $$;
