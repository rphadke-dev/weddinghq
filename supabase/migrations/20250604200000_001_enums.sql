-- WeddingHQ Phase 1: enums

CREATE TYPE public.user_role_intent AS ENUM (
  'couple',
  'guest',
  'vendor',
  'coordinator'
);

CREATE TYPE public.wedding_member_role AS ENUM (
  'owner',
  'co_owner',
  'coordinator',
  'vendor',
  'guest',
  'wedding_party'
);

CREATE TYPE public.subscription_tier AS ENUM (
  'free',
  'couple_lifetime',
  'coordinator_subscriber'
);

CREATE TYPE public.subscription_status AS ENUM (
  'none',
  'active',
  'expired',
  'pending'
);

CREATE TYPE public.onboarding_step AS ENUM (
  'welcome_seen',
  'role_selected',
  'profile_basics',
  'wedding_create_or_join',
  'subscription_prompt',
  'completed'
);
