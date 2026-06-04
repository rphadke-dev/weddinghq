# WeddingHQ iOS

SwiftUI app for Phase 1: welcome, auth, onboarding, profile — wired to the Supabase backend in the parent repo.

## Requirements

- Xcode 15+ (iOS 17 deployment target)
- Local Supabase running (`supabase start` from repo root)
- Docker Desktop (for local Supabase)

## Open the project

```bash
cd ios
./scripts/generate-xcodeproj.sh   # if WeddingHQ.xcodeproj is missing
open WeddingHQ.xcodeproj
```

Select the **WeddingHQ** scheme and an iPhone simulator, then **Run** (⌘R).

## Configuration

| File | Purpose |
|------|---------|
| `Config/Debug.xcconfig` | Local Supabase URL + anon key (default) |
| `Config/Secrets.xcconfig` | Copy from `Secrets.xcconfig.example` for hosted Supabase (gitignored) |

Simulator uses `http://127.0.0.1:54321` with `NSAllowsLocalNetworking` enabled.

## Auth notes

- **Email/password** works out of the box against local Supabase (confirm via [Inbucket](http://127.0.0.1:54324)).
- **Phone:** test OTP `4152127777` → `123456` (see root `supabase/config.toml`).
- **Apple / Google:** enable providers in Supabase Dashboard; add URL scheme `weddinghq://auth-callback` (already in Info.plist). Google opens Safari and returns via `onOpenURL`.

## App flow

1. **Welcome** — falling hearts (this screen only)
2. **Auth** — sign up / sign in
3. **Onboarding** — role, profile, create or join wedding, dev subscription unlock
4. **Main tabs** — timeline placeholder, chat/alerts placeholders, profile + menu

## Edge Functions (local)

With backend running:

```bash
supabase functions serve
```

## Troubleshooting

- **Build fails resolving Supabase:** File → Packages → Reset Package Caches
- **Network errors on device:** use your Mac’s LAN IP in `Debug.xcconfig`, not `127.0.0.1`
- **NOT_VERIFIED on onboarding:** confirm email or use Google/Apple/phone OTP

See [docs/smoke-test.md](../docs/smoke-test.md) for API-level testing.
