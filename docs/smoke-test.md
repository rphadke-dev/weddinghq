# WeddingHQ Phase 1 Smoke Test

Prerequisites: `supabase start`, `supabase db reset`, `supabase functions serve`

Export keys from `supabase status`:

```bash
export SUPABASE_URL=http://127.0.0.1:54321
export ANON_KEY=<anon key>
export SERVICE_KEY=<service_role key>
```

## 1. Sign up couple (email)

```bash
curl -s "$SUPABASE_URL/auth/v1/signup" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email":"couple@example.com","password":"testpass123"}' | jq .
```

Confirm email via Inbucket (http://127.0.0.1:54324), then sign in:

```bash
TOKEN=$(curl -s "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email":"couple@example.com","password":"testpass123"}' | jq -r .access_token)
```

## 2. Onboarding steps

```bash
curl -s "$SUPABASE_URL/functions/v1/complete-onboarding-step" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"step":"welcome_seen"}' | jq .

curl -s "$SUPABASE_URL/functions/v1/complete-onboarding-step" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"step":"role_selected","role_intent":"couple"}' | jq .

curl -s "$SUPABASE_URL/functions/v1/complete-onboarding-step" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"step":"profile_basics","display_name":"Alex"}' | jq .
```

## 3. Create wedding

```bash
CREATE=$(curl -s "$SUPABASE_URL/functions/v1/create-wedding" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Priya & Alex","wedding_date":"2026-09-20"}')
echo "$CREATE" | jq .
WEDDING_ID=$(echo "$CREATE" | jq -r .wedding.id)
INVITE=$(echo "$CREATE" | jq -r .wedding.invite_code)
```

## 4. Grant stub subscription

```bash
curl -s "$SUPABASE_URL/functions/v1/grant-couple-subscription" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"wedding_id\":\"$WEDDING_ID\"}" | jq .
```

## 5. Co-owner invite

```bash
curl -s "$SUPABASE_URL/functions/v1/invite-co-owner" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"action\":\"create\",\"wedding_id\":\"$WEDDING_ID\",\"email\":\"partner@example.com\"}" | jq .
```

Sign up `partner@example.com`, confirm, sign in as `PARTNER_TOKEN`, accept with token from previous response.

## 6. Guest join

Sign up `guest@example.com`, onboard as guest, then:

```bash
curl -s "$SUPABASE_URL/functions/v1/join-wedding" \
  -H "Authorization: Bearer $GUEST_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"invite_code\":\"$INVITE\",\"role_intent\":\"guest\"}" | jq .
```

## 7. Verify RLS

```bash
curl -s "$SUPABASE_URL/rest/v1/weddings?select=*" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $TOKEN" | jq .
```

Expect only weddings the user is a member of.

## Checklist

- [ ] Signup creates profile + onboarding rows
- [ ] Unverified user gets `NOT_VERIFIED` on onboarding
- [ ] Couple creates wedding with 6-char invite code
- [ ] `requires_subscription: true` until grant
- [ ] Co-owner accept adds `co_owner` member
- [ ] Guest joins with invite code
- [ ] RLS hides other users' weddings
