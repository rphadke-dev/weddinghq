import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

export function getServiceClient(): SupabaseClient {
  return createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    { auth: { persistSession: false, autoRefreshToken: false } },
  );
}

export function getUserClient(authHeader: string): SupabaseClient {
  return createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false, autoRefreshToken: false },
    },
  );
}

export async function requireUser(req: Request) {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return { error: "UNAUTHORIZED" as const, user: null, client: null };
  }
  const client = getUserClient(authHeader);
  const { data: { user }, error } = await client.auth.getUser();
  if (error || !user) {
    return { error: "UNAUTHORIZED" as const, user: null, client: null };
  }
  return { error: null, user, client };
}
