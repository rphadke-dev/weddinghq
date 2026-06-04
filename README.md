# WeddingHQ

iOS-first, day-of wedding coordination backend (Phase 1: Supabase schema, RLS, Edge Functions).

## Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) (`npm install -g supabase`)
- Docker (for `supabase start`)

## Quick start

```bash
cd ~/Projects/weddinghq
cp .env.example .env
supabase start
supabase db reset   # applies migrations + seed.sql
supabase functions serve
```

- **Studio:** http://127.0.0.1:54323
- **API:** http://127.0.0.1:54321
- **Inbucket (email):** http://127.0.0.1:54324

## Project layout

| Path | Purpose |
|------|---------|
| `supabase/migrations/` | Postgres schema, RLS, helpers |
| `supabase/functions/` | Edge Functions (onboarding, weddings, subscriptions) |
| `supabase/seed.sql` | Dev reference data (run after migrations) |
| `docs/` | API contract, auth setup, RLS matrix |

## Phase 1 scope

- Auth-ready config (Google, Apple, email magic link, phone OTP — verification required)
- Profiles, settings, onboarding state
- Weddings, members, co-owner invites, stub subscriptions
- Edge Functions for gated flows

Timeline, chat, vendors, photo book, and payments (RevenueCat) are Phase 2+.

## Documentation

- [Phase 1 API](docs/phase1-api.md)
- [Auth flows](docs/auth-flows.md)
- [RLS matrix](docs/rls-matrix.md)
- [Smoke test checklist](docs/smoke-test.md)
