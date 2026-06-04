# WeddingHQ Phase 1 API Contract

Base URL (local): `http://127.0.0.1:54321`

All Edge Functions require header: `Authorization: Bearer <access_token>`

## Welcome screen

- **Client-only.** No API.
- Falling hearts animation only on the welcome/start screen (iOS).

## Onboarding

### Read progress (PostgREST)

```
GET /rest/v1/onboarding_progress?profile_id=eq.<uuid>&select=*
```

Headers: `apikey: <anon>`, `Authorization: Bearer <token>`

### Advance step

```
POST /functions/v1/complete-onboarding-step
Content-Type: application/json

{
  "step": "welcome_seen" | "role_selected" | "profile_basics" | "wedding_create_or_join" | "subscription_prompt" | "completed",
  "role_intent": "couple" | "guest" | "vendor" | "coordinator",  // when step = role_selected
  "display_name": "Alex",  // when step = profile_basics
  "bio": "Optional bio"
}
```

**Response:** `{ "onboarding": { ... } }`

**Errors:** `NOT_VERIFIED`, `UNAUTHORIZED`, `VALIDATION_ERROR`

## Weddings

### Create (couple)

```
POST /functions/v1/create-wedding

{
  "title": "Priya & Alex",
  "wedding_date": "2026-09-20",
  "venue_name": "The Garden Estate"
}
```

**Response:**

```json
{
  "wedding": { "id", "invite_code", "subscription_status", ... },
  "requires_subscription": true
}
```

### Join (guest / vendor / coordinator)

```
POST /functions/v1/join-wedding

{
  "invite_code": "ABC234",
  "role_intent": "guest"
}
```

**Response:** `{ "wedding": { ... }, "member": { ... } }`

**Errors:** `INVALID_CODE`, `ALREADY_MEMBER`, `NOT_VERIFIED`

### Stub subscription (dev)

```
POST /functions/v1/grant-couple-subscription

{ "wedding_id": "<uuid>" }
```

Owner/co-owner only. Sets `couple_lifetime` + `active`.

## Co-owner (two logins)

### Send invite (primary owner)

```
POST /functions/v1/invite-co-owner

{
  "action": "create",
  "wedding_id": "<uuid>",
  "email": "partner@example.com"
}
```

**Response:** `{ "invite": { "token", "expires_at", ... } }`

### Accept invite (partner account)

```
POST /functions/v1/invite-co-owner

{
  "action": "accept",
  "token": "<uuid>"
}
```

Partner must sign in with the invited email or phone.

## Profile screen

### Profile

```
GET /rest/v1/profiles?id=eq.<uid>&select=*
PATCH /rest/v1/profiles?id=eq.<uid>
```

### Settings

```
GET /rest/v1/profile_settings?profile_id=eq.<uid>&select=*
PATCH /rest/v1/profile_settings?profile_id=eq.<uid>
```

Fields: `animations_enabled`, `theme`, `push_notifications_enabled`, `widgets_enabled`

### Weddings list

```
GET /rest/v1/wedding_members?profile_id=eq.<uid>&select=*,weddings(*)
```

### Entitlements (read-only)

```
GET /rest/v1/subscription_entitlements?select=*
```

### Multi-wedding preferences (coordinators)

```
GET /rest/v1/user_wedding_preferences?profile_id=eq.<uid>&select=*,weddings(*)
PATCH /rest/v1/user_wedding_preferences?profile_id=eq.<uid>&wedding_id=eq.<wid>
```

## Error shape (Edge Functions)

```json
{
  "error": {
    "code": "NOT_VERIFIED" | "INVALID_CODE" | "SUBSCRIPTION_REQUIRED" | ...,
    "message": "Human-readable message"
  }
}
```

## Phase 2 (not in API yet)

- Timeline, vendors directory, chat, alerts
- Photo book (menu; vendors blocked)
- Tasks/checklists, guest list upload, event feed
- Coordinator geo directory
- RevenueCat webhooks
