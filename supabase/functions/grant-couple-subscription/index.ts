import { handleCors, jsonResponse } from "../_shared/cors.ts";
import { errorResponse } from "../_shared/errors.ts";
import { getServiceClient, requireUser } from "../_shared/supabase.ts";

type GrantBody = { wedding_id: string };

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

  let body: GrantBody;
  try {
    body = await req.json();
  } catch {
    return errorResponse("VALIDATION_ERROR", "Invalid JSON body", 400);
  }

  if (!body.wedding_id) {
    return errorResponse("VALIDATION_ERROR", "wedding_id is required", 400);
  }

  const service = getServiceClient();

  const { data: member } = await service
    .from("wedding_members")
    .select("role")
    .eq("wedding_id", body.wedding_id)
    .eq("profile_id", user.id)
    .maybeSingle();

  if (!member || !["owner", "co_owner"].includes(member.role)) {
    return errorResponse(
      "FORBIDDEN",
      "Only wedding owners can grant subscription (dev stub)",
      403,
    );
  }

  const { data: wedding, error: grantErr } = await service.rpc(
    "grant_couple_subscription",
    { p_wedding_id: body.wedding_id },
  );

  if (grantErr) {
    return errorResponse("VALIDATION_ERROR", grantErr.message, 400);
  }

  await service
    .from("onboarding_progress")
    .update({
      current_step: "completed",
      completed_at: new Date().toISOString(),
    })
    .eq("profile_id", user.id);

  return jsonResponse({
    wedding,
    message: "Stub couple lifetime subscription granted",
  });
});
