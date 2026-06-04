import { handleCors, jsonResponse } from "../_shared/cors.ts";
import { errorResponse } from "../_shared/errors.ts";
import { getServiceClient, requireUser } from "../_shared/supabase.ts";

type InviteBody =
  | { action: "create"; wedding_id: string; email?: string; phone?: string }
  | { action: "accept"; token: string };

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

  let body: InviteBody;
  try {
    body = await req.json();
  } catch {
    return errorResponse("VALIDATION_ERROR", "Invalid JSON body", 400);
  }

  if (body.action === "create") {
    if (!body.wedding_id || (!body.email && !body.phone)) {
      return errorResponse(
        "VALIDATION_ERROR",
        "wedding_id and email or phone required",
        400,
      );
    }

    const { data: isOwner } = await service
      .from("wedding_members")
      .select("role")
      .eq("wedding_id", body.wedding_id)
      .eq("profile_id", user.id)
      .eq("role", "owner")
      .maybeSingle();

    if (!isOwner) {
      return errorResponse(
        "FORBIDDEN",
        "Only the primary owner can invite a co-owner",
        403,
      );
    }

    const { data: invite, error: inviteErr } = await service
      .from("wedding_co_owner_invites")
      .insert({
        wedding_id: body.wedding_id,
        email: body.email?.trim().toLowerCase() ?? null,
        phone: body.phone?.trim() ?? null,
        created_by: user.id,
      })
      .select("id, token, expires_at, wedding_id")
      .single();

    if (inviteErr) {
      return errorResponse("VALIDATION_ERROR", inviteErr.message, 400);
    }

    return jsonResponse({ invite });
  }

  if (body.action === "accept") {
    if (!body.token) {
      return errorResponse("VALIDATION_ERROR", "token is required", 400);
    }

    const { data: invite, error: inviteErr } = await service
      .from("wedding_co_owner_invites")
      .select("*")
      .eq("token", body.token)
      .maybeSingle();

    if (inviteErr || !invite) {
      return errorResponse("NOT_FOUND", "Invite not found", 404);
    }

    if (invite.accepted_by) {
      return errorResponse("VALIDATION_ERROR", "Invite already accepted", 400);
    }

    if (new Date(invite.expires_at) < new Date()) {
      return errorResponse("VALIDATION_ERROR", "Invite expired", 400);
    }

    const userEmail = user.email?.toLowerCase();
    const userPhone = user.phone;
    const emailMatch = invite.email && userEmail === invite.email;
    const phoneMatch = invite.phone && userPhone === invite.phone;

    if (!emailMatch && !phoneMatch) {
      return errorResponse(
        "FORBIDDEN",
        "Sign in with the email or phone that received the invite",
        403,
      );
    }

    const { data: existing } = await service
      .from("wedding_members")
      .select("id")
      .eq("wedding_id", invite.wedding_id)
      .eq("profile_id", user.id)
      .maybeSingle();

    if (existing) {
      return errorResponse("ALREADY_MEMBER", "Already a member of this wedding", 409);
    }

    await service.from("wedding_members").insert({
      wedding_id: invite.wedding_id,
      profile_id: user.id,
      role: "co_owner",
      can_coordinate: true,
    });

    await service
      .from("wedding_co_owner_invites")
      .update({ accepted_by: user.id })
      .eq("id", invite.id);

    await service.from("user_wedding_preferences").upsert({
      profile_id: user.id,
      wedding_id: invite.wedding_id,
      is_pinned: true,
      last_accessed_at: new Date().toISOString(),
    });

    const { data: wedding } = await service
      .from("weddings")
      .select("*")
      .eq("id", invite.wedding_id)
      .single();

    return jsonResponse({ wedding, role: "co_owner" });
  }

  return errorResponse("VALIDATION_ERROR", "action must be create or accept", 400);
});
