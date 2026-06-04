-- WeddingHQ Phase 1: profiles, settings, onboarding, auth trigger

CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  display_name text,
  avatar_url text,
  bio text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.profile_settings (
  profile_id uuid PRIMARY KEY REFERENCES public.profiles (id) ON DELETE CASCADE,
  animations_enabled boolean NOT NULL DEFAULT true,
  theme text NOT NULL DEFAULT 'system',
  push_notifications_enabled boolean NOT NULL DEFAULT true,
  widgets_enabled boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.onboarding_progress (
  profile_id uuid PRIMARY KEY REFERENCES public.profiles (id) ON DELETE CASCADE,
  role_intent public.user_role_intent,
  current_step public.onboarding_step NOT NULL DEFAULT 'welcome_seen',
  completed_steps jsonb NOT NULL DEFAULT '[]'::jsonb,
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER profile_settings_updated_at
  BEFORE UPDATE ON public.profile_settings
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER onboarding_progress_updated_at
  BEFORE UPDATE ON public.onboarding_progress
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- True when email/phone confirmed or OAuth (google/apple) identity exists
CREATE OR REPLACE FUNCTION public.is_identity_verified(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM auth.users u
    WHERE u.id = p_user_id
      AND (
        u.email_confirmed_at IS NOT NULL
        OR u.phone_confirmed_at IS NOT NULL
        OR EXISTS (
          SELECT 1
          FROM auth.identities i
          WHERE i.user_id = u.id
            AND i.provider IN ('google', 'apple')
        )
      )
  );
$$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id)
  VALUES (NEW.id);

  INSERT INTO public.profile_settings (profile_id)
  VALUES (NEW.id);

  INSERT INTO public.onboarding_progress (profile_id, current_step, completed_steps)
  VALUES (NEW.id, 'welcome_seen', '[]'::jsonb);

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, UPDATE ON public.profiles TO authenticated;
GRANT SELECT, UPDATE ON public.profile_settings TO authenticated;
GRANT SELECT, UPDATE ON public.onboarding_progress TO authenticated;
