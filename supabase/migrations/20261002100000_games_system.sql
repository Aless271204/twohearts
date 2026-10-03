-- ============================================================
-- GAMES SYSTEM MIGRATION
-- LoveCoins economy, minigames, shop, daily challenges
-- ============================================================

-- 1. Game stats per user (XP, level, coins)
CREATE TABLE IF NOT EXISTS public.game_stats (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  love_coins integer NOT NULL DEFAULT 0,
  xp integer NOT NULL DEFAULT 0,
  level integer NOT NULL DEFAULT 1,
  total_games_played integer NOT NULL DEFAULT 0,
  total_coins_earned integer NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

ALTER TABLE public.game_stats ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='game_stats' AND policyname='game_stats_own') THEN
    CREATE POLICY game_stats_own ON public.game_stats
      USING (user_id = auth.uid())
      WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

-- 2. High scores per game per user
CREATE TABLE IF NOT EXISTS public.game_scores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  game_id text NOT NULL,
  score integer NOT NULL DEFAULT 0,
  coins_earned integer NOT NULL DEFAULT 0,
  played_at timestamptz DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.game_scores ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='game_scores' AND policyname='game_scores_own') THEN
    CREATE POLICY game_scores_own ON public.game_scores
      USING (user_id = auth.uid())
      WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

-- 3. High score records per game (best score)
CREATE TABLE IF NOT EXISTS public.game_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  game_id text NOT NULL,
  best_score integer NOT NULL DEFAULT 0,
  best_coins integer NOT NULL DEFAULT 0,
  times_played integer NOT NULL DEFAULT 0,
  updated_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, game_id)
);

ALTER TABLE public.game_records ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='game_records' AND policyname='game_records_own') THEN
    CREATE POLICY game_records_own ON public.game_records
      USING (user_id = auth.uid())
      WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

-- 4. Daily challenges
CREATE TABLE IF NOT EXISTS public.daily_challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  challenge_date date NOT NULL DEFAULT CURRENT_DATE,
  challenge_key text NOT NULL,
  challenge_label text NOT NULL DEFAULT '',
  reward_coins integer NOT NULL DEFAULT 10,
  completed boolean NOT NULL DEFAULT false,
  completed_at timestamptz,
  UNIQUE(user_id, challenge_date, challenge_key)
);

ALTER TABLE public.daily_challenges ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='daily_challenges' AND policyname='daily_challenges_own') THEN
    CREATE POLICY daily_challenges_own ON public.daily_challenges
      USING (user_id = auth.uid())
      WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

-- 5. Shop items catalog (static seed data)
CREATE TABLE IF NOT EXISTS public.shop_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  item_key text NOT NULL UNIQUE,
  name text NOT NULL,
  emoji text NOT NULL DEFAULT '🎁',
  category text NOT NULL DEFAULT 'Accesorios',
  price_coins integer,
  price_real numeric(8,2),
  currency text NOT NULL DEFAULT 'coins',
  collection text,
  is_premium boolean NOT NULL DEFAULT false,
  is_couple_item boolean NOT NULL DEFAULT false,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.shop_items ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='shop_items' AND policyname='shop_items_read') THEN
    CREATE POLICY shop_items_read ON public.shop_items FOR SELECT USING (true);
  END IF;
END $$;

-- 6. User owned items
CREATE TABLE IF NOT EXISTS public.owned_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  item_key text NOT NULL,
  equipped boolean NOT NULL DEFAULT false,
  slot text,
  purchased_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, item_key)
);

ALTER TABLE public.owned_items ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='owned_items' AND policyname='owned_items_own') THEN
    CREATE POLICY owned_items_own ON public.owned_items
      USING (user_id = auth.uid())
      WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

-- 7. Couple game stats (shared progress)
CREATE TABLE IF NOT EXISTS public.couple_game_stats (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  partner_id uuid REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  games_together integer NOT NULL DEFAULT 0,
  coins_together integer NOT NULL DEFAULT 0,
  best_couple_score integer NOT NULL DEFAULT 0,
  streak_days integer NOT NULL DEFAULT 0,
  last_played_date date,
  updated_at timestamptz DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

ALTER TABLE public.couple_game_stats ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='couple_game_stats' AND policyname='couple_game_stats_own') THEN
    CREATE POLICY couple_game_stats_own ON public.couple_game_stats
      USING (user_id = auth.uid() OR partner_id = auth.uid())
      WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

-- ── Seed shop items ──────────────────────────────────────────────────────────

INSERT INTO public.shop_items (item_key, name, emoji, category, price_coins, currency, collection, is_premium, sort_order) VALUES
  ('bow_basic',       'Moño básico',        '🎀', 'Accesorios', 250,  'coins', 'Básico',     false, 1),
  ('glasses_heart',   'Gafas corazón',      '🕶️', 'Gafas',      400,  'coins', 'Básico',     false, 2),
  ('cap_pink',        'Gorra rosa',         '🧢', 'Sombreros',  500,  'coins', 'Básico',     false, 3),
  ('shirt_love',      'Camiseta amor',      '👕', 'Ropa',       700,  'coins', 'Básico',     false, 4),
  ('backpack_heart',  'Mochila corazón',    '🎒', 'Mochilas',   900,  'coins', 'Básico',     false, 5),
  ('hat_special',     'Sombrero especial',  '🎩', 'Sombreros',  1200, 'coins', 'Básico',     false, 6),
  ('crown_gold',      'Corona dorada',      '👑', 'Coronas',    1500, 'coins', 'Básico',     false, 7),
  ('flower_hat',      'Sombrero flores',    '🌸', 'Sombreros',  800,  'coins', 'Primavera',  false, 8),
  ('sunglasses',      'Gafas de sol',       '😎', 'Gafas',      600,  'coins', 'Verano',     false, 9),
  ('scarf_hearts',    'Bufanda corazones',  '🧣', 'Ropa',       750,  'coins', 'Invierno',   false, 10),
  ('valentines_bow',  'Lazo San Valentín',  '💝', 'Accesorios', 350,  'coins', 'San Valentín', false, 11),
  ('halloween_hat',   'Sombrero Halloween', '🎃', 'Sombreros',  600,  'coins', 'Halloween',  false, 12),
  ('xmas_hat',        'Gorro Navidad',      '🎅', 'Sombreros',  600,  'coins', 'Navidad',    false, 13),
  ('birthday_hat',    'Gorro cumpleaños',   '🎂', 'Sombreros',  400,  'coins', 'Cumpleaños', false, 14),
  ('beach_glasses',   'Gafas playa',        '🏖️', 'Gafas',      500,  'coins', 'Playa',      false, 15)
ON CONFLICT (item_key) DO NOTHING;

INSERT INTO public.shop_items (item_key, name, emoji, category, price_real, currency, collection, is_premium, sort_order) VALUES
  ('premium_suit',    'Traje especial',     '🤵', 'Ropa',       1.99, 'real', 'Premium',    true, 100),
  ('premium_pack',    'Pack accesorios',    '✨', 'Paquetes',   2.99, 'real', 'Premium',    true, 101),
  ('season_pack',     'Pack temporada',     '🌟', 'Paquetes',   4.99, 'real', 'Premium',    true, 102),
  ('special_anim',    'Animación especial', '💫', 'Efectos',    1.49, 'real', 'Premium',    true, 103),
  ('premium_pet',     'Mascota premium',    '🦄', 'Mascotas',   4.99, 'real', 'Premium',    true, 104),
  ('couple_pack',     'Pack de pareja',     '💑', 'Paquetes',   6.99, 'real', 'Premium',    true, 105),
  ('starter_pack',    'Starter Pack',       '🎁', 'Paquetes',   1.99, 'real', 'Premium',    true, 106),
  ('couple_full',     'Couple Pack',        '❤️', 'Paquetes',   4.99, 'real', 'Premium',    true, 107),
  ('season_full',     'Season Pack',        '🌈', 'Paquetes',   6.99, 'real', 'Premium',    true, 108),
  ('premium_coll',    'Premium Collection', '💎', 'Paquetes',   9.99, 'real', 'Premium',    true, 109)
ON CONFLICT (item_key) DO NOTHING;
