-- Migration: social interactions & follows
-- Adds interaction_count to social_posts and ensures social_follows exists

-- Add interaction_count column if not present
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'social_posts'
      AND column_name  = 'interaction_count'
  ) THEN
    ALTER TABLE public.social_posts ADD COLUMN interaction_count INTEGER NOT NULL DEFAULT 0;
  END IF;
END $$;

-- Add likes_count column if not present
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'social_posts'
      AND column_name  = 'likes_count'
  ) THEN
    ALTER TABLE public.social_posts ADD COLUMN likes_count INTEGER NOT NULL DEFAULT 0;
  END IF;
END $$;

-- Add comments_count column if not present
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'social_posts'
      AND column_name  = 'comments_count'
  ) THEN
    ALTER TABLE public.social_posts ADD COLUMN comments_count INTEGER NOT NULL DEFAULT 0;
  END IF;
END $$;

-- Create social_follows table if not exists
CREATE TABLE IF NOT EXISTS public.social_follows (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id   UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  following_id  UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (follower_id, following_id)
);

-- Enable RLS
ALTER TABLE public.social_follows ENABLE ROW LEVEL SECURITY;

-- RLS policies for social_follows
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename  = 'social_follows'
      AND policyname = 'Users can view follows'
  ) THEN
    CREATE POLICY "Users can view follows"
      ON public.social_follows FOR SELECT
      USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename  = 'social_follows'
      AND policyname = 'Users can manage own follows'
  ) THEN
    CREATE POLICY "Users can manage own follows"
      ON public.social_follows FOR ALL
      USING (auth.uid() = follower_id)
      WITH CHECK (auth.uid() = follower_id);
  END IF;
END $$;

-- Create post_likes table if not exists
CREATE TABLE IF NOT EXISTS public.post_likes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    UUID NOT NULL REFERENCES public.social_posts(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (post_id, user_id)
);

ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename  = 'post_likes'
      AND policyname = 'Users can view likes'
  ) THEN
    CREATE POLICY "Users can view likes"
      ON public.post_likes FOR SELECT
      USING (true);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename  = 'post_likes'
      AND policyname = 'Users can manage own likes'
  ) THEN
    CREATE POLICY "Users can manage own likes"
      ON public.post_likes FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- Function to update interaction_count on like/unlike
CREATE OR REPLACE FUNCTION public.update_post_interaction_count()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.social_posts
    SET likes_count = likes_count + 1,
        interaction_count = interaction_count + 1
    WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.social_posts
    SET likes_count = GREATEST(likes_count - 1, 0),
        interaction_count = GREATEST(interaction_count - 1, 0)
    WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$;

-- Trigger for likes
DROP TRIGGER IF EXISTS trg_post_likes_count ON public.post_likes;
CREATE TRIGGER trg_post_likes_count
  AFTER INSERT OR DELETE ON public.post_likes
  FOR EACH ROW EXECUTE FUNCTION public.update_post_interaction_count();
