-- WeddingHQ Phase 1: grants for helper functions

GRANT EXECUTE ON FUNCTION public.is_identity_verified(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_invite_code() TO service_role;
GRANT EXECUTE ON FUNCTION public.grant_couple_subscription(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.is_wedding_member(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_wedding_owner_or_co_owner(uuid, uuid) TO authenticated;
