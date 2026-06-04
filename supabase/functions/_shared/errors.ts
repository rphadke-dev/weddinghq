export type ErrorCode =
  | "NOT_VERIFIED"
  | "INVALID_CODE"
  | "SUBSCRIPTION_REQUIRED"
  | "FORBIDDEN"
  | "NOT_FOUND"
  | "ALREADY_MEMBER"
  | "INVALID_STEP"
  | "VALIDATION_ERROR"
  | "UNAUTHORIZED";

export function errorResponse(
  code: ErrorCode,
  message: string,
  status: number,
): Response {
  return new Response(
    JSON.stringify({ error: { code, message } }),
    {
      status,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers":
          "authorization, x-client-info, apikey, content-type",
        "Content-Type": "application/json",
      },
    },
  );
}
