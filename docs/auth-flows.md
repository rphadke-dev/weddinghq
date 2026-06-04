# WeddingHQ Auth Flows (Phase 1)

## Supported providers

| Provider | Local config | Verification |
|----------|--------------|--------------|
| Google | `[auth.external.google]` in `supabase/config.toml` | Provider-verified (counts as verified via `auth.identities`) |
| Apple | `[auth.external.apple]` | Provider-verified |
| Email (magic link / OTP) | `[auth.email]` with `enable_confirmations = true` | `email_confirmed_at` required |
| Phone OTP | `[auth.sms]` with `enable_signup = true`, `enable_confirmations = true` | `phone_confirmed_at` required |

Server gate: `public.is_identity_verified(user_id)` and Edge Functions return `NOT_VERIFIED` until satisfied.

## Local development

1. Start stack: `supabase start`
2. View test emails: http://127.0.0.1:54324 (Inbucket)
3. Phone OTP testing: uncomment `[auth.sms.test_otp]` in `config.toml`, e.g. `4152127777 = "123456"`

## Hosted project setup

In [Supabase Dashboard](https://supabase.com/dashboard) → Authentication:

1. **Providers:** Enable Google, Apple, Email, Phone
2. **URL configuration:** Add iOS redirect URLs and web origins
3. **Email:** Enable confirm email / magic link
4. **Phone:** Configure Twilio (or provider) secrets as env vars

### Environment variables

```bash
SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID=
SUPABASE_AUTH_EXTERNAL_GOOGLE_SECRET=
SUPABASE_AUTH_EXTERNAL_APPLE_SECRET=
SUPABASE_AUTH_SMS_TWILIO_AUTH_TOKEN=
```

Copy from `.env.example` for local CLI; set secrets in Dashboard for production.

## Post-signup (automatic)

`AFTER INSERT ON auth.users` trigger `handle_new_user` creates:

- `profiles`
- `profile_settings` (defaults)
- `onboarding_progress` (`current_step = welcome_seen`)

No Edge Function call required for provisioning.

## Recommended client order

1. Welcome screen (client-only, no API)
2. Sign up / sign in (Supabase Auth SDK)
3. Confirm email or phone if prompted
4. `complete-onboarding-step` for each onboarding step
5. `create-wedding` or `join-wedding`
6. `grant-couple-subscription` (dev stub) when `requires_subscription` is true

## Sign out

Client calls `supabase.auth.signOut()` only; no backend endpoint.
