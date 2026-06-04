import { handleCors, jsonResponse } from "../_shared/cors.ts";
import { errorResponse } from "../_shared/errors.ts";
import { getServiceClient, requireUser } from "../_shared/supabase.ts";

type CreateWeddingBody = {
  title: string;
  wedding_date?: string;
  venue_name?: string;
};

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

  const { data: onboarding } = await service
    .from("onboarding_progress")
    .select("role_intent, completed_steps")
    .eq("profile_id", user.id)
    .single();

  if (onboarding?.role_intent !== "couple") {
    return errorResponse(
      "FORBIDDEN",
      "Only couples can create a wedding",
      403,
    );
  }

  const completed = (onboarding?.completed_steps ?? []) as string[];
  if (
    !completed.includes("role_selected") ||
    !completed.includes("profile_basics")
  ) {
    return errorResponse(
      "INVALID_STEP",
      "Complete role and profile onboarding first",
      400,
    );
  }

  let body: CreateWeddingBody;
  try {
    body = await req.json();
  } catch {
    return errorResponse("VALIDATION_ERROR", "Invalid JSON body", 400);
  }

  if (!body.title?.trim()) {
    return errorResponse("VALIDATION_ERROR", "title is required", 400);
  }

  const { data: existingMember } = await service
    .from("wedding_members")
    .select("wedding_id")
    .eq("profile_id", user.id)
    .eq("role", "owner")
    .maybeSingle();

  if (existingMember) {
    const { data: wedding } = await service
      .from("weddings")
      .select("*")
      .eq("id", existingMember.wedding_id)
      .single();

    return jsonResponse({
      wedding,
      requires_subscription: wedding?.subscription_status === "none",
    });
  }

  const { data: inviteCode, error: codeErr } = await service.rpc(
    "generate_invite_code",
  );
  if (codeErr || !inviteCode) {
    return errorResponse("VALIDATION_ERROR", codeErr?.message ?? "Code error", 500);
  }

  const { data: wedding, error: weddingErr } = await service
    .from("weddings")
    .insert({
      invite_code: inviteCode,
      title: body.title.trim(),
      wedding_date: body.wedding_date ?? null,
      venue_name: body.venue_name ?? null,
      primary_owner_id: user.id,
      subscription_tier: "free",
      subscription_status: "none",
    })
    .select()
    .single();

  if (weddingErr || !wedding) {
    return errorResponse("VALIDATION_ERROR", weddingErr?.message ?? "Insert failed", 400);
  }

  await service.from("wedding_members").insert({
    wedding_id: wedding.id,
    profile_id: user.id,
    role: "owner",
    can_coordinate: true,
  });

  await service.from("user_wedding_preferences").upsert({
    profile_id: user.id,
    wedding_id: wedding.id,
    is_pinned: true,
    last_accessed_at: new Date().toISOString(),
  });

  const completedSteps = appendSteps(completed, [
    "wedding_create_or_join",
    "subscription_prompt",
  ]);
  await service
    .from("onboarding_progress")
    .update({
      completed_steps: completedSteps,
      current_step: "subscription_prompt",
    })
    .eq("profile_id", user.id);

  return jsonResponse({
    wedding,
    requires_subscription: true,
  });
});

function appendSteps(existing: string[], steps: string[]): string[] {
  const set = new Set(existing);
  for (const s of steps) set.add(s);
  return [...set];
}
