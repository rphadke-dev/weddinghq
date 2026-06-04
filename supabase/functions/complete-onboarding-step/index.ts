import { handleCors, jsonResponse } from "../_shared/cors.ts";
import { errorResponse } from "../_shared/errors.ts";
import {
  appendCompleted,
  nextStep,
  type OnboardingStep,
} from "../_shared/onboarding.ts";
import { getServiceClient, requireUser } from "../_shared/supabase.ts";

type StepPayload = {
  step: OnboardingStep;
  role_intent?: "couple" | "guest" | "vendor" | "coordinator";
  display_name?: string;
  bio?: string;
};

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  if (req.method !== "POST") {
    return errorResponse("VALIDATION_ERROR", "Method not allowed", 405);
  }

  const { error: authError, user, client } = await requireUser(req);
  if (authError || !user || !client) {
    return errorResponse("UNAUTHORIZED", "Authentication required", 401);
  }

  const service = getServiceClient();
  const { data: verified, error: verifyErr } = await service.rpc(
    "is_identity_verified",
    { p_user_id: user.id },
  );
  if (verifyErr || !verified) {
    return errorResponse(
      "NOT_VERIFIED",
      "Confirm your email or phone before continuing onboarding",
      403,
    );
  }

  let body: StepPayload;
  try {
    body = await req.json();
  } catch {
    return errorResponse("VALIDATION_ERROR", "Invalid JSON body", 400);
  }

  if (!body.step) {
    return errorResponse("VALIDATION_ERROR", "step is required", 400);
  }

  const { data: progress, error: progressErr } = await client
    .from("onboarding_progress")
    .select("*")
    .eq("profile_id", user.id)
    .single();

  if (progressErr || !progress) {
    return errorResponse("NOT_FOUND", "Onboarding progress not found", 404);
  }

  const completed = (progress.completed_steps ?? []) as string[];
  const updatedCompleted = appendCompleted(completed, body.step);

  const updates: Record<string, unknown> = {
    completed_steps: updatedCompleted,
    current_step: nextStep(body.step),
  };

  if (body.step === "role_selected" && body.role_intent) {
    updates.role_intent = body.role_intent;
  }

  if (body.step === "profile_basics") {
    if (body.display_name || body.bio !== undefined) {
      await client.from("profiles").update({
        display_name: body.display_name ?? undefined,
        bio: body.bio ?? undefined,
      }).eq("id", user.id);
    }
  }

  if (body.step === "completed") {
    updates.completed_at = new Date().toISOString();
    updates.current_step = "completed";
  }

  const { data: updated, error: updateErr } = await client
    .from("onboarding_progress")
    .update(updates)
    .eq("profile_id", user.id)
    .select()
    .single();

  if (updateErr) {
    return errorResponse("VALIDATION_ERROR", updateErr.message, 400);
  }

  return jsonResponse({ onboarding: updated });
});
