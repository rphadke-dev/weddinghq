-- WeddingHQ Phase 1: Row Level Security

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.onboarding_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weddings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wedding_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wedding_co_owner_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_wedding_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_entitlements ENABLE ROW LEVEL SECURITY;

-- profiles
CREATE POLICY profiles_select_own ON public.profiles
  FOR SELECT TO authenticated
  USING (id = auth.uid());

CREATE POLICY profiles_update_own ON public.profiles
  FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- profile_settings
CREATE POLICY profile_settings_select_own ON public.profile_settings
  FOR SELECT TO authenticated
  USING (profile_id = auth.uid());

CREATE POLICY profile_settings_update_own ON public.profile_settings
  FOR UPDATE TO authenticated
  USING (profile_id = auth.uid())
  WITH CHECK (profile_id = auth.uid());

-- onboarding_progress
CREATE POLICY onboarding_progress_select_own ON public.onboarding_progress
  FOR SELECT TO authenticated
  USING (profile_id = auth.uid());

CREATE POLICY onboarding_progress_update_own ON public.onboarding_progress
  FOR UPDATE TO authenticated
  USING (profile_id = auth.uid())
  WITH CHECK (profile_id = auth.uid());

-- weddings
CREATE POLICY weddings_select_member ON public.weddings
  FOR SELECT TO authenticated
  USING (public.is_wedding_member(id));

CREATE POLICY weddings_update_owner ON public.weddings
  FOR UPDATE TO authenticated
  USING (public.is_wedding_owner_or_co_owner(id))
  WITH CHECK (public.is_wedding_owner_or_co_owner(id));

-- wedding_members
CREATE POLICY wedding_members_select_same_wedding ON public.wedding_members
  FOR SELECT TO authenticated
  USING (public.is_wedding_member(wedding_id));

-- co_owner invites: owners/co_owners of wedding can read; create via service role / edge functions
CREATE POLICY co_owner_invites_select_owner ON public.wedding_co_owner_invites
  FOR SELECT TO authenticated
  USING (public.is_wedding_owner_or_co_owner(wedding_id));

-- user_wedding_preferences
CREATE POLICY user_wedding_preferences_select_own ON public.user_wedding_preferences
  FOR SELECT TO authenticated
  USING (profile_id = auth.uid());

CREATE POLICY user_wedding_preferences_insert_own ON public.user_wedding_preferences
  FOR INSERT TO authenticated
  WITH CHECK (
    profile_id = auth.uid()
    AND public.is_wedding_member(wedding_id)
  );

CREATE POLICY user_wedding_preferences_update_own ON public.user_wedding_preferences
  FOR UPDATE TO authenticated
  USING (profile_id = auth.uid())
  WITH CHECK (profile_id = auth.uid());

CREATE POLICY user_wedding_preferences_delete_own ON public.user_wedding_preferences
  FOR DELETE TO authenticated
  USING (profile_id = auth.uid());

-- subscription_entitlements: read own profile or weddings you belong to
CREATE POLICY subscription_entitlements_select ON public.subscription_entitlements
  FOR SELECT TO authenticated
  USING (
    profile_id = auth.uid()
    OR (
      wedding_id IS NOT NULL
      AND public.is_wedding_member(wedding_id)
    )
  );

-- No INSERT/UPDATE/DELETE policies on entitlements for authenticated (Edge Functions use service role)

GRANT SELECT ON public.weddings TO authenticated;
GRANT SELECT ON public.wedding_members TO authenticated;
GRANT SELECT ON public.wedding_co_owner_invites TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_wedding_preferences TO authenticated;
GRANT SELECT ON public.subscription_entitlements TO authenticated;
