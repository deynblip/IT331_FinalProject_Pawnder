import { createClient } from "npm:@supabase/supabase-js@2";

const sa = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT")!);
const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

function b64url(input: ArrayBuffer | string) {
  const bytes = typeof input === "string"
    ? new TextEncoder().encode(input)
    : new Uint8Array(input);
  let s = "";
  bytes.forEach((b) => (s += String.fromCharCode(b)));
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const pem = sa.private_key
    .replace(/-----[^-]+-----/g, "")
    .replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(`${header}.${claim}`),
  );
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${header}.${claim}.${b64url(sig)}`,
    }),
  });
  const json = await res.json();
  if (!json.access_token) throw new Error(JSON.stringify(json));
  return json.access_token;
}

Deno.serve(async (req) => {
  if (req.headers.get("x-webhook-secret") !== Deno.env.get("WEBHOOK_SECRET")) {
    return new Response("Unauthorized", { status: 401 });
  }

  const payload = await req.json();
  if (payload.type !== "INSERT" || !payload.record) {
    return new Response("Ignored");
  }
  const n = payload.record;

  const { data: rows, error } = await supabase
    .from("device_tokens")
    .select("token")
    .eq("user_id", n.recipient_id);
  if (error) {
    console.error("DB ERROR", error.message);
    return new Response(error.message, { status: 500 });
  }
  if (!rows || rows.length === 0) return new Response("No tokens");

  let accessToken: string;
  try {
    accessToken = await getAccessToken();
  } catch (e) {
    console.error("TOKEN ERROR", String(e));
    return new Response("Token error", { status: 500 });
  }

  const url =
    `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;
  const results: string[] = [];

  for (const { token } of rows) {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title: n.title, body: n.message },
          data: { type: String(n.type), target_id: String(n.target_id ?? "") },
          android: {
            priority: "HIGH",
            notification: { channel_id: "pawnder_high" },
          },
        },
      }),
    });
    results.push(`${res.status}`);
    if (res.status === 404 || res.status === 400) {
      const text = await res.text();
      if (text.includes("UNREGISTERED") || text.includes("INVALID_ARGUMENT")) {
        await supabase.from("device_tokens").delete().eq("token", token);
      }
    }
  }
  return new Response(`Sent: ${results.join(",")}`);
});
