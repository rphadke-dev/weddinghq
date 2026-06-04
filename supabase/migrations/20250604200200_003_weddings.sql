-- WeddingHQ Phase 1: weddings, members, invites, entitlements, preferences

CREATE TABLE public.weddings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text UNIQUE,
  invite_code char(6) NOT NULL UNIQUE,
  title text NOT NULL,
  wedding_date date,
  venue_name text,
  primary_owner_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE RESTRICT,
  subscription_tier public.subscription_tier NOT NULL DEFAULT 'free',
  subscription_status public.subscription_status NOT NULL DEFAULT 'none',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT weddings_invite_code_format CHECK (invite_code ~ '^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$')
);

CREATE TABLE public.wedding_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  wedding_id uuid NOT NULL REFERENCES public.weddings (id) ON DELETE CASCADE,
  profile_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  role public.wedding_member_role NOT NULL,
  can_coordinate boolean NOT NULL DEFAULT false,
  joined_via_invite_code char(6),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (wedding_id, profile_id)
);

CREATE TABLE public.wedding_co_owner_invites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  wedding_id uuid NOT NULL REFERENCES public.weddings (id) ON DELETE CASCADE,
  email text,
  phone text,
  token uuid NOT NULL DEFAULT gen_random_uuid(),
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '7 days'),
  accepted_by uuid REFERENCES public.profiles (id),
  created_by uuid NOT NULL REFERENCES public.profiles (id),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT co_owner_invite_contact CHECK (email IS NOT NULL OR phone IS NOT NULL)
);

CREATE UNIQUE INDEX wedding_co_owner_invites_token_idx ON public.wedding_co_owner_invites (token);

CREATE TABLE public.user_wedding_preferences (
  profile_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  wedding_id uuid NOT NULL REFERENCES public.weddings (id) ON DELETE CASCADE,
  is_pinned boolean NOT NULL DEFAULT false,
  last_accessed_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (profile_id, wedding_id)
);

CREATE TABLE public.subscription_entitlements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid REFERENCES public.profiles (id) ON DELETE CASCADE,
  wedding_id uuid REFERENCES public.weddings (id) ON DELETE CASCADE,
  tier public.subscription_tier NOT NULL,
  status public.subscription_status NOT NULL DEFAULT 'active',
  revenuecat_app_user_id text,
  expires_at timestamptz,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT subscription_entitlements_subject CHECK (
    profile_id IS NOT NULL OR wedding_id IS NOT NULL
  )
);

CREATE TRIGGER weddings_updated_at
  BEFORE UPDATE ON public.weddings
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER subscription_entitlements_updated_at
  BEFORE UPDATE ON public.subscription_entitlements
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- Invite code: ABCDEFGHJKLMNPQRSTUVWXYZ23456789 (no 0/O, 1/I/L)
CREATE OR REPLACE FUNCTION public.generate_invite_code()
RETURNS char(6)
LANGUAGE plpgsql
VOLATILE
SET search_path = public
AS $$
DECLARE
  chars constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result text := '';
  i int;
  attempts int := 0;
  char_len int := length(chars);
BEGIN
  LOOP
    result := '';
    FOR i IN 1..6 LOOP
      result := result || substr(chars, 1 + floor(random() * char_len)::int, 1);
    END LOOP;
    EXIT WHEN NOT EXISTS (
      SELECT 1 FROM public.weddings w WHERE w.invite_code = result
    );
    attempts := attempts + 1;
    IF attempts > 200 THEN
      RAISE EXCEPTION 'Could not generate unique invite code';
    END IF;
  END LOOP;
  RETURN result::char(6);
END;
$$;

-- Stub grant used by Edge Function grant-couple-subscription
CREATE OR REPLACE FUNCTION public.grant_couple_subscription(p_wedding_id uuid)
RETURNS public.weddings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  w public.weddings;
BEGIN
  UPDATE public.weddings
  SET
    subscription_tier = 'couple_lifetime',
    subscription_status = 'active',
    updated_at = now()
  WHERE id = p_wedding_id
  RETURNING * INTO w;

  IF w.id IS NULL THEN
    RAISE EXCEPTION 'Wedding not found';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.subscription_entitlements e
    WHERE e.wedding_id = p_wedding_id
      AND e.tier = 'couple_lifetime'
  ) THEN
    INSERT INTO public.subscription_entitlements (wedding_id, tier, status, metadata)
    VALUES (
      p_wedding_id,
      'couple_lifetime',
      'active',
      jsonb_build_object('source', 'stub_grant')
    );
  END IF;

  RETURN w;
END;
$$;

-- Membership helpers for RLS
CREATE OR REPLACE FUNCTION public.is_wedding_member(p_wedding_id uuid, p_profile_id uuid DEFAULT auth.uid())
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.wedding_members wm
    WHERE wm.wedding_id = p_wedding_id
      AND wm.profile_id = p_profile_id
  );
$$;

CREATE OR REPLACE FUNCTION public.is_wedding_owner_or_co_owner(
  p_wedding_id uuid,
  p_profile_id uuid DEFAULT auth.uid()
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.wedding_members wm
    WHERE wm.wedding_id = p_wedding_id
      AND wm.profile_id = p_profile_id
      AND wm.role IN ('owner', 'co_owner')
  );
$$;

CREATE INDEX wedding_members_profile_id_idx ON public.wedding_members (profile_id);
CREATE INDEX wedding_members_wedding_id_idx ON public.wedding_members (wedding_id);
CREATE INDEX subscription_entitlements_profile_id_idx ON public.subscription_entitlements (profile_id);
CREATE INDEX subscription_entitlements_wedding_id_idx ON public.subscription_entitlements (wedding_id);
