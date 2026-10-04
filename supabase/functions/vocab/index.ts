/*
  Adds words to the shared list for spanish-vocab.html, and deletes them again for the browser that added them.
  Anyone may add, so every word is checked here: length, a cap per request, a cap per browser per hour, and no
  pair that is already in the list.

  Deploy: supabase functions deploy vocab --no-verify-jwt
  Needs: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY (both set for you).

  POST { action: "add", device, list, words: [{ es, en }] }  ->  { ok, added: [rows], skipped }
  POST { action: "delete", device, id }                      ->  { ok, deleted }
*/

import { createClient } from "jsr:@supabase/supabase-js@2";

const PER_REQUEST = 100;     // words in one paste
const PER_HOUR = 300;        // words one browser may add in an hour
const TOTAL = 20000;         // the whole list; past this, adding stops until someone looks

const cors = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
};
const reply = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json", ...cors } });
const bad = (why: string, status = 400) => reply({ ok: false, why }, status);

// Must match norm() in spanish-vocab.html, so the page and the table agree on what a duplicate is.
const norm = (s: string) => s.toLowerCase()
  .replace(/[¡!¿?.,;:"“”«»…]/g, " ").replace(/[’‘`´']/g, "")
  .replace(/\s+/g, " ").trim();
// Strips control characters and runs of spaces from what people paste.
const clean = (s: unknown) => String(s ?? "").replace(/[\u0000-\u001f\u007f]/g, " ").replace(/\s+/g, " ").trim();

async function sha256(s: string) {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return bad("POST only", 405);

  let body: any;
  try { body = await req.json(); } catch { return bad("not JSON"); }
  const device = clean(body?.device);
  if (!/^[a-z0-9]{16,64}$/i.test(device)) return bad("no device id");
  const hash = await sha256(device);
  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  if (body.action === "delete") {
    const id = Number(body.id);
    if (!Number.isInteger(id)) return bad("no word id");
    const { data, error } = await db.from("vocab_words").delete().eq("id", id).eq("device_hash", hash).select("id");
    if (error) return bad(error.message, 500);
    return data.length ? reply({ ok: true, deleted: id }) : bad("only the browser that added a word can delete it", 403);
  }

  if (body.action !== "add") return bad("unknown action");
  const list = clean(body.list).slice(0, 60) || "Shared words";
  if (!Array.isArray(body.words) || !body.words.length) return bad("no words");
  if (body.words.length > PER_REQUEST) return bad(`at most ${PER_REQUEST} words at a time`);

  const since = new Date(Date.now() - 3600e3).toISOString();
  const recent = await db.from("vocab_words").select("id", { count: "exact", head: true }).eq("device_hash", hash).gte("made_at", since);
  if ((recent.count ?? 0) + body.words.length > PER_HOUR) return bad("that is a lot of words for one hour; try again later", 429);
  const all = await db.from("vocab_words").select("id", { count: "exact", head: true });
  if ((all.count ?? 0) >= TOTAL) return bad("the shared list is full", 507);

  const rows = [];
  const seen = new Set<string>();
  let skipped = 0;
  for (const w of body.words) {
    const es = clean(w?.es), en = clean(w?.en);
    const key = norm(es) + "=" + norm(en);
    if (!es || !en || es.length > 120 || en.length > 160 || seen.has(key)) { skipped++; continue; }
    seen.add(key);
    rows.push({ list, es, en, key, device_hash: hash });
  }
  if (!rows.length) return reply({ ok: true, added: [], skipped });

  // A pair someone else already added is skipped, not an error.
  const { data, error } = await db.from("vocab_words")
    .upsert(rows, { onConflict: "key", ignoreDuplicates: true })
    .select("id, list, es, en, device_hash, made_at");
  if (error) return bad(error.message, 500);
  return reply({ ok: true, added: data, skipped: skipped + rows.length - data.length });
});
