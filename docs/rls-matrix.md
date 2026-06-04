# WeddingHQ RLS Matrix (Phase 1)

All policies use `auth.uid()` unless noted. Edge Functions use the **service role** and bypass RLS for inserts that clients cannot perform directly.

| Table | SELECT | INSERT | UPDATE | DELETE |
|-------|--------|--------|--------|--------|
| `profiles` | Own row | Trigger on signup | Own row | — |
| `profile_settings` | Own row | Trigger on signup | Own row | — |
| `onboarding_progress` | Own row | Trigger on signup | Own row | — |
| `weddings` | Wedding members | Service role / Edge | Owner or co-owner | — |
| `wedding_members` | Same-wedding members | Service role / Edge | — | — |
| `wedding_co_owner_invites` | Owner/co-owner of wedding | Service role / Edge | Service role / Edge | — |
| `user_wedding_preferences` | Own rows | Own + must be member | Own | Own |
| `subscription_entitlements` | Own profile or member of wedding | Service role / Edge | Service role / Edge | — |

## Helper functions (SECURITY DEFINER)

| Function | Purpose |
|----------|---------|
| `is_identity_verified(uuid)` | Email/phone confirmed or Google/Apple identity |
| `is_wedding_member(wedding_id, profile_id?)` | Membership check for RLS |
| `is_wedding_owner_or_co_owner(wedding_id, profile_id?)` | Owner/co-owner check |
| `generate_invite_code()` | Service role only |
| `grant_couple_subscription(wedding_id)` | Service role only (stub IAP) |

## Intentional restrictions

- Authenticated users **cannot** insert `wedding_members` or `weddings` directly; use Edge Functions.
- Authenticated users **cannot** write `subscription_entitlements`; use `grant-couple-subscription` (stub) or future RevenueCat webhook.
