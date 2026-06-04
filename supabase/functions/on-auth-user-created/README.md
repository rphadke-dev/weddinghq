# on-auth-user-created

Provisioning is handled by the Postgres trigger `on_auth_user_created` on `auth.users`
(see migration `20250604200100_002_profiles.sql`).

No Edge Function is required for Phase 1. If you later add a Supabase Auth Hook,
point it here or keep the trigger as the source of truth.
