/*
  Takes a finished daily town, plays its moves again on that day's map, and writes down the score it really
  earned. The rules come from the game itself: this fetches the deployed hugelland.html and runs the block
  marked <script id="logic">, so the leaderboard can never drift from what players are playing.

  Deploy: supabase functions deploy score --no-verify-jwt
  Needs: GAME_URL (optional, defaults below), SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY (both set for you).
*/

import { createClient } from "jsr:@supabase/supabase-js@2";

const GAME_URL = Deno.env.get("GAME_URL") ?? "https://zachmo.github.io/personal_projects/hugelland.html";
const RULES_TTL = 10 * 60 * 1000;   // how long a copy of the rules is kept before fetching again

type Replay = {
  ok: boolean;
  why?: string;
  score?: number;
  goals?: number;
  away?: number;
};

let rules: { at: number; for: string; replay: (day: string, moves: number[][]) => Replay; par: (day: string) => number } | null = null;

/* The game's own rules, pulled out of the page and made callable. Kept per day, so a change at midnight is read
   straight away rather than waiting for the copy to go stale. */
async function loadRules(day: string) {
  if (rules && rules.for === day && Date.now() - rules.at < RULES_TTL) return rules;
  const page = await fetch(GAME_URL, { cache: "no-store" }).then((r) => r.text());
  const logic = page.split('<script id="logic">')[1]?.split("</script>")[0];
  if (!logic) throw new Error("no rules in the page");
  const make = new Function(logic + `
    return {
      // Plays the moves in order on that day's map. Anything that does not fit the rules stops it.
      replay(day, moves) {
        newGame("board", 0, 0, day);
        for (const cells of moves) {
          if (G.over) return { ok: false, why: "more moves than buildings" };
          const type = current();
          if (!Array.isArray(cells) || !cells.length) return { ok: false, why: "a move with no squares" };
          if (cells.length !== SHAPES[DEF[type].shape].length) return { ok: false, why: "wrong shape for the " + DEF[type].name };
          if (!canPlace(cells, type)) return { ok: false, why: "the " + DEF[type].name + " cannot stand there" };
          build(cells);
        }
        if (!G.over) return { ok: false, why: "the town is not finished" };
        return { ok: true, score: total(), goals: goalsDone(), away: G.away.length };
      },
      par(day) { return parFor(dailySeed(day)); },
    };
  `);
  rules = { at: Date.now(), for: day, ...make() };
  return rules;
}

const bad = (why: string, code = 400) =>
  new Response(JSON.stringify({ ok: false, why }), { status: code, headers: { "content-type": "application/json", ...cors } });

const cors = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
};

/* A day may be sent in only while it is that day, or the day after, in Texas. */
function dayIsOpen(day: string) {
  const now = new Date(new Date().toLocaleString("en-US", { timeZone: "America/Chicago" }));
  const today = now.toISOString().slice(0, 10);
  const yesterday = new Date(now.getTime() - 864e5).toISOString().slice(0, 10);
  return day === today || day === yesterday;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return bad("post only", 405);

  let body: { day?: string; name?: string; device?: string; moves?: number[][] };
  try { body = await req.json(); } catch { return bad("no body"); }

  const day = String(body.day ?? "");
  if (!/^\d{4}-\d{2}-\d{2}$/.test(day)) return bad("no day");
  if (!dayIsOpen(day)) return bad("that day is closed");

  // The town's name, not the player's: "New Zachfels" rather than "Zach".
  const name = String(body.name ?? "").replace(/[\x00-\x1f\x7f]/g, "").trim().slice(0, 24);
  if (!name) return bad("no name");

  const device = String(body.device ?? "").replace(/[^a-z0-9]/gi, "").slice(0, 40);
  if (device.length < 6) return bad("no device");

  const moves = body.moves;
  if (!Array.isArray(moves) || moves.length < 1 || moves.length > 60) return bad("no moves");
  for (const m of moves) {
    if (!Array.isArray(m) || m.length > 6) return bad("a move of the wrong size");
    for (const c of m) if (!Number.isInteger(c) || c < 0 || c >= 108) return bad("a square off the map");
  }

  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  // One town a day for a browser. The first finished one stands, as it does in the game.
  const { data: already } = await db.from("daily_scores").select("id").eq("day", day).eq("device", device).maybeSingle();
  if (already) return bad("this browser has already played that day", 409);

  let out: Replay;
  try {
    const r = await loadRules(day);
    out = r.replay(day, moves);
  } catch (e) {
    return bad("could not read the rules: " + (e as Error).message, 500);
  }
  if (!out.ok) return bad(out.why ?? "that town does not add up");

  // Par is the same for everyone that day, so it is worked out once and kept.
  let par = 0;
  const { data: known } = await db.from("daily_par").select("par").eq("day", day).maybeSingle();
  if (known) par = known.par;
  else {
    try {
      const r = await loadRules(day);
      par = r.par(day);
      await db.from("daily_par").insert({ day, par });
    } catch { par = 0; }
  }

  const { error } = await db.from("daily_scores")
    .insert({ day, name, score: out.score, goals: out.goals, away: out.away, par, device });
  if (error) return bad(error.message, 500);

  return new Response(JSON.stringify({ ok: true, score: out.score, goals: out.goals, par }),
    { headers: { "content-type": "application/json", ...cors } });
});
