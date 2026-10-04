/*
  Keeps a learner's spanish-vocab.html progress in step between their devices, with no account. The page makes a
  random sync code; whoever has the code can read and write that progress. The table stores only the code's hash.
  The page does the merging; this function just keeps the latest copy.

  Deploy: supabase functions deploy progress --no-verify-jwt
  Needs: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY (both set for you).

  POST { action: "pull", code }        ->  { ok, data | null, updated_at }
  POST { action: "push", code, data }  ->  { ok, updated_at }
*/

import { createClient } from "jsr:@supabase/supabase-js@2";

const MAX_BYTES = 600_000;   // about 3,000 practiced words with their history
const MAX_ROWS = 5000;       // sync codes in total; past this, new codes are refused

const cors = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
};
const reply = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json", ...cors } });
const bad = (why: string, status = 400) => reply({ ok: false, why }, status);

async function sha256(s: string) {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return bad("POST only", 405);
  let body: any;
  try { body = await req.json(); } catch { return bad("not JSON"); }

  // Codes look like "k7pm-x2qd-9fhr": 12 letters and digits, with the look-alikes (0 o 1 l i) left out.
  const code = String(body?.code ?? "").toLowerCase().replace(/[^a-z0-9]/g, "");
  if (!/^[a-hj-km-np-z2-9]{12}$/.test(code)) return bad("that is not a sync code");
  const hash = await sha256("vocab-progress:" + code);
  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  if (body.action === "pull") {
    const { data, error } = await db.from("vocab_progress").select("data, updated_at").eq("code_hash", hash).maybeSingle();
    if (error) return bad(error.message, 500);
    return reply({ ok: true, data: data?.data ?? null, updated_at: data?.updated_at ?? null });
  }

  if (body.action === "push") {
    const data = body.data;
    if (!data || typeof data !== "object" || Array.isArray(data)) return bad("no progress");
    if (JSON.stringify(data).length > MAX_BYTES) return bad("progress is too large", 413);
    const known = await db.from("vocab_progress").select("code_hash", { head: true, count: "exact" }).eq("code_hash", hash);
    if (!known.count) {
      const all = await db.from("vocab_progress").select("code_hash", { head: true, count: "exact" });
      if ((all.count ?? 0) >= MAX_ROWS) return bad("sync is full", 507);
    }
    const updated_at = new Date().toISOString();
    const { error } = await db.from("vocab_progress").upsert({ code_hash: hash, data, updated_at });
    if (error) return bad(error.message, 500);
    return reply({ ok: true, updated_at });
  }

  return bad("unknown action");
});
