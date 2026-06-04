export const STEP_ORDER = [
  "welcome_seen",
  "role_selected",
  "profile_basics",
  "wedding_create_or_join",
  "subscription_prompt",
  "completed",
] as const;

export type OnboardingStep = (typeof STEP_ORDER)[number];

export function nextStep(step: OnboardingStep): OnboardingStep {
  const idx = STEP_ORDER.indexOf(step);
  if (idx < 0 || idx >= STEP_ORDER.length - 1) return "completed";
  return STEP_ORDER[idx + 1];
}

export function appendCompleted(
  completed: string[],
  step: string,
): string[] {
  if (completed.includes(step)) return completed;
  return [...completed, step];
}
