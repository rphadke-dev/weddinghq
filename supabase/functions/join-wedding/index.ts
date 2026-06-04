import { handleCors, jsonResponse } from "../_shared/cors.ts";
import { errorResponse } from "../_shared/errors.ts";
import { getServiceClient, requireUser } from "../_shared/supabase.ts";

type JoinWeddingBody = {
  invite_code: string;
  role_intent?: "guest" | "vendor" | "coordinator" | "couple";
};

function mapRoleIntent(
  intent: string | undefined,
): { role: string; can_coordinate: boolean } {
  switch (intent) {
    case "vendor":
      return { role: "vendor", can_coordinate: false };
    case "coordinator":
      return { role: "guest", can_coordinate: false };
    case "couple":
      return { role: "guest", can_coordinate: false };
    default:
      return { role: "guest", can_coordinate: false };
  }
}

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  if (req.method !== "POST") {
    return errorResponse("VALIDATION_ERROR", "Method not allowed", 405);
  }

  const { error: authError, user } = await requireUser(req);
  if (authError || !user) {
    return errorResponse("UNAUTHORIZED", "Authentication required", 401);
  }

  const service = getServiceClient();

  const { data: verified } = await service.rpc("is_identity_verified", {
    p_user_id: user.id,
  });
  if (!verified) {
    return errorResponse("NOT_VERIFIED", "Identity not verified", 403);
  }

  let body: JoinWeddingBody;
  try {
    body = await req.json();
  } catch {
    return errorResponse("VALIDATION_ERROR", "Invalid JSON body", 400);
  }

  const code = body.invite_code?.trim().toUpperCase();
  if (!code || code.length !== 6) {
    return errorResponse("INVALID_CODE", "Invite code must be 6 characters", 400);
  }

  const { data: wedding, error: weddingErr } = await service
    .from("weddings")
    .select("*")
    .eq("invite_code", code)
    .maybeSingle();

  if (weddingErr || !wedding) {
    return errorResponse("INVALID_CODE", "Wedding not found for this code", 404);
  }

  const { data: existing } = await service
    .from("wedding_members")
    .select("id, role")
    .eq("wedding_id", wedding.id)
    .eq("profile_id", user.id)
    .maybeSingle();

  if (existing) {
    return errorResponse("ALREADY_MEMBER", "You are already a member", 409);
  }

  const { data: onboarding } = await service
    .from("onboarding_progress")
    .select("role_intent, completed_steps")
    .eq("profile_id", user.id)
    .single();

  const intent = body.role_intent ?? onboarding?.role_intent ?? "guest";
  const { role, can_coordinate } = mapRoleIntent(intent);

  const { data: member, error: memberErr } = await service
    .from("wedding_members")
    .insert({
      wedding_id: wedding.id,
      profile_id: user.id,
      role,
      can_coordinate,
      joined_via_invite_code: code,
    })
    .select()
    .single();

  if (memberErr) {
    return errorResponse("VALIDATION_ERROR", memberErr.message, 400);
  }

  await service.from("user_wedding_preferences").upsert({
    profile_id: user.id,
    wedding_id: wedding.id,
    last_accessed_at: new Date().toISOString(),
  });

  const completed = (onboarding?.completed_steps ?? []) as string[];
  const updatedSteps = [...new Set([...completed, "wedding_create_or_join"])];

  await service
    .from("onboarding_progress")
    .update({
      completed_steps: updatedSteps,
      current_step: "completed",
      completed_at: new Date().toISOString(),
    })
    .eq("profile_id", user.id);

  return jsonResponse({ wedding, member });
});
