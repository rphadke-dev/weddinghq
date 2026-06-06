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
| `WeddingHQ/Info.plist` | Local Supabase URL + anon key (default for simulator) |
| `Config/Debug.xcconfig` | Build flags only (`PRODUCT_NAME`, `ALWAYS_SEARCH_USER_PATHS`) |
| `Config/Secrets.xcconfig` | Optional overrides (gitignored) |

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

- **`Multiple commands produce .../.app`:** Fixed in `Config/Debug.xcconfig` (xcconfig treats `//` as a comment) and `PRODUCT_NAME` in `project.yml`. Close Xcode, run `./scripts/generate-xcodeproj.sh`, then **Product → Clean Build Folder** (⇧⌘K).
- **`Unable to resolve module dependency: Supabase`:** Usually a **stale or half-downloaded** Swift package cache (often after deleting DerivedData while Xcode is open, or building before packages finish resolving). The product name `Supabase` is correct — run the steps below; do not rename imports.
- **Missing package product `Supabase` / No such module `Supabase`:**
  1. **Quit Xcode** (⌘Q) — close any running build
  2. Terminal:
     ```bash
     rm -rf ~/Library/Developer/Xcode/DerivedData/WeddingHQ-*
     cd ~/Projects/weddinghq/ios
     ./scripts/generate-xcodeproj.sh
     xcodebuild -resolvePackageDependencies -scheme WeddingHQ
     ```
  3. Reopen `WeddingHQ.xcodeproj`
  4. **File → Packages → Resolve Package Versions** (wait until finished)
  5. **Product → Clean Build Folder** (⇧⌘K), then **Run** (⌘R)
- **Build database locked:** Only one build at a time — quit Xcode or stop the other `xcodebuild`, then clean DerivedData.
- **Network errors on device:** use your Mac’s LAN IP in `Debug.xcconfig`, not `127.0.0.1`
- **NOT_VERIFIED on onboarding:** confirm email or use Google/Apple/phone OTP

See [docs/smoke-test.md](../docs/smoke-test.md) for API-level testing.
