-- WeddingHQ dev seed (runs after migrations on `supabase db reset`)
--
-- Auth users are created via Supabase Auth (Studio, signUp API, or smoke-test curl).
-- This seed documents schema expectations and does not insert into auth.users.
--
-- After creating a couple user and running Edge Functions:
--   1. complete-onboarding-step (role_selected, profile_basics)
--   2. create-wedding
--   3. grant-couple-subscription (stub IAP)
--
-- See docs/smoke-test.md for end-to-end commands.

SELECT 'WeddingHQ seed: use smoke-test.md to create users and weddings via Auth + Edge Functions' AS note;
