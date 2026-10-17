// Murder Dinner Party: the server-side state machine.
//
// The server owns every secret. Each client gets a view built for it alone
// (viewFor), so a phone or the host screen never receives anything it should
// not show. Phases run in a straight line; each ends at its deadline or as
// soon as everyone it waits on has submitted.

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const cards = require('./cards/cards.json');
const locations = require('./content/locations.json');
const weapons = require('./content/weapons.json');
const victims = require('./content/victims.json');
const prompts = require('./content/prompts.json');

const SCALE = process.env.MDP_FAST === '1' ? 0.25 : Number(process.env.MDP_TIME_SCALE) || 1;
const ms = (n) => Math.round(n * SCALE);

const DURATION = {
  ROLE_REVEAL: 5000,
  INTRO: 22000,
  R1_ANSWER: 60000,
  R1_PICK: 45000,
  R2_DRAW: 75000,
  R2_PICK: 45000,
  R3_WORD: 30000,
  VERDICT: 60000,
};
// Reveal sequence: drumroll, killer, round 1, round 2, round 3, Detective's score.
const REVEAL_STEPS = [4000, 7000, 11000, 11000, 9000, 9000];
const GRACE_MS = 1500; // pause after the last submission, so a final edit still lands
const DETECTIVE_GONE_MS = ms(90 * 1000);
const KILLER_FLEE_MS = ms(60 * 1000);

const SUBMIT_PHASES = ['R1_ANSWER', 'R2_DRAW', 'R3_WORD'];
const DETECTIVE_PHASES = ['R1_PICK', 'R2_PICK', 'VERDICT'];
const ORDER = ['ROLE_REVEAL', 'INTRO', 'R1_ANSWER', 'R1_PICK', 'R2_DRAW', 'R2_PICK', 'R3_WORD', 'VERDICT', 'REVEAL', 'END'];
const LABELS = 'ABCDEFGH';
const SAID_NOTHING = '(said nothing)';
const RANKS = ['Hopeless Clouseau', 'Lucky Guess Larry', 'Competent Inspector', 'Legendary Detective'];

const limits = { text: 80, word: 20, pngBytes: 150 * 1024 };

// ---------- small helpers ----------

const pick = (list) => list[crypto.randomInt(list.length)];

function shuffle(list) {
  const a = list.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = crypto.randomInt(i + 1);
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

// Draw from a list with no repeats until the whole list has come up.
function drawFrom(store, key, list) {
  store.bags = store.bags || {};
  if (!store.bags[key] || !store.bags[key].length) store.bags[key] = shuffle(list.map((_, i) => i));
  return list[store.bags[key].pop()];
}

const fill = (template, vars) => template.replace(/\{(\w+)\}/g, (_, k) => (k in vars ? vars[k] : `{${k}}`));

const cardById = new Map(cards.map((c) => [c.id, c]));

// Silhouettes go to phones inline, so the file name (which names the character) never travels.
const silCache = new Map();
function silhouetteData(card) {
  if (silCache.has(card.id)) return silCache.get(card.id);
  let out = card.silhouette;
  try {
    const file = path.join(__dirname, 'cards', path.basename(card.silhouette));
    const ext = path.extname(file).slice(1).toLowerCase();
    const mime = ext === 'svg' ? 'image/svg+xml' : ext === 'jpg' ? 'image/jpeg' : `image/${ext}`;
    out = `data:${mime};base64,${fs.readFileSync(file).toString('base64')}`;
  } catch (err) {
    console.warn(`Silhouette for ${card.id} not found; sending its path instead.`);
  }
  silCache.set(card.id, out);
  return out;
}

// Check a drawing and rebuild it with only the image chunks, so no text or
// metadata rides along. Returns a clean data URL, or null if it isn't a PNG.
function cleanPng(dataUrl) {
  const prefix = 'data:image/png;base64,';
  if (typeof dataUrl !== 'string' || !dataUrl.startsWith(prefix)) return null;
  const b64 = dataUrl.slice(prefix.length);
  if (!/^[A-Za-z0-9+/]+=*$/.test(b64)) return null;
  const buf = Buffer.from(b64, 'base64');
  if (buf.length > limits.pngBytes || buf.length < 8) return null;
  if (!buf.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) return null;
  const keep = new Set(['IHDR', 'PLTE', 'tRNS', 'IDAT', 'IEND']);
  const parts = [buf.subarray(0, 8)];
  let off = 8;
  let sawEnd = false;
  while (off + 12 <= buf.length) {
    const len = buf.readUInt32BE(off);
    const type = buf.toString('latin1', off + 4, off + 8);
    const end = off + 12 + len;
    if (end > buf.length) return null;
    if (keep.has(type)) parts.push(buf.subarray(off, end));
    off = end;
    if (type === 'IEND') { sawEnd = true; break; }
  }
  if (!sawEnd) return null;
  return prefix + Buffer.concat(parts).toString('base64');
}

// ---------- the game ----------

class MurderGame {
  constructor(room, ctx, opts = {}) {
    this.room = room;
    this.ctx = ctx;
    this.opts = opts;
    this.timer = null;
    this.timers = new Set();
    this.disposed = false;
  }

  // -- setup --

  start() {
    const store = this.ctx.store;
    const players = this.room.players.filter((p) => p.cardId);
    this.playerIds = players.map((p) => p.id);

    // Detective: everyone gets a turn before anyone goes twice.
    const avoid = new Set([this.opts.avoidDetective, store.lastDetective].filter(Boolean));
    store.detectiveHistory = (store.detectiveHistory || []).filter((id) => this.playerIds.includes(id));
    let pool = players.filter((p) => !store.detectiveHistory.includes(p.id) && !avoid.has(p.id));
    if (!pool.length) {
      store.detectiveHistory = [];
      pool = players.filter((p) => !avoid.has(p.id));
    }
    if (!pool.length) pool = players;
    const live = pool.filter((p) => p.connected);
    this.detectiveId = pick(live.length ? live : pool).id;
    store.detectiveHistory.push(this.detectiveId);
    store.lastDetective = this.detectiveId;

    this.suspectIds = this.playerIds.filter((id) => id !== this.detectiveId);
    const liveSuspects = players.filter((p) => p.connected && p.id !== this.detectiveId).map((p) => p.id);
    this.killerId = pick(liveSuspects.length ? liveSuspects : this.suspectIds);

    const victim = drawFrom(store, 'victims', victims);
    this.secret = {
      location: drawFrom(store, 'locations', locations),
      weapon: drawFrom(store, 'weapons', weapons),
      victimId: victim.id,
    };
    this.victim = victim;
    this.verb = pick(prompts.r1.verbs);

    this.rounds = {
      r1: { answers: {}, order: [], pick: null },
      r2: { drawings: {}, order: [], pick: null },
      r3: { words: {}, order: [] },
    };
    this.verdictPick = null;
    this.score = null;
    this.winner = null;
    this.fled = false;
    this.revealStep = 0;
    this.paused = false;
    this.remaining = 0;
    this.detectiveGoneSince = this.isConnected(this.detectiveId) ? null : Date.now();
    this.fleeTimer = null;

    this.setPhase('ROLE_REVEAL');
  }

  // -- timers --

  later(fn, delay) {
    const t = setTimeout(() => {
      this.timers.delete(t);
      if (!this.disposed) fn();
    }, delay);
    this.timers.add(t);
    return t;
  }

  cancel(t) {
    if (t) { clearTimeout(t); this.timers.delete(t); }
  }

  schedule(delay) {
    this.cancel(this.timer);
    this.timer = this.later(() => this.advance(), Math.max(0, delay));
  }

  setPhase(phase, duration = DURATION[phase]) {
    this.phase = phase;
    this.paused = false;
    this.deadline = duration ? Date.now() + ms(duration) : null;
    this.cancel(this.timer);
    this.timer = null;
    if (this.deadline) this.schedule(this.deadline - Date.now());
    this.checkDetective();
    this.ctx.broadcast();
  }

  // -- flow --

  advance() {
    switch (this.phase) {
      case 'ROLE_REVEAL':
        return this.setPhase('INTRO');
      case 'INTRO':
        return this.setPhase('R1_ANSWER');
      case 'R1_ANSWER': {
        const { r1 } = this.rounds;
        for (const id of this.suspectIds) if (!(id in r1.answers)) r1.answers[id] = SAID_NOTHING;
        r1.order = shuffle(this.suspectIds);
        return this.setPhase('R1_PICK');
      }
      case 'R1_PICK':
        return this.setPhase('R2_DRAW');
      case 'R2_DRAW': {
        const { r2 } = this.rounds;
        for (const id of this.suspectIds) if (!(id in r2.drawings)) r2.drawings[id] = null; // blank
        r2.order = shuffle(this.suspectIds);
        return this.setPhase('R2_PICK');
      }
      case 'R2_PICK':
        return this.setPhase('R3_WORD');
      case 'R3_WORD': {
        const { r3 } = this.rounds;
        for (const id of this.suspectIds) if (!(id in r3.words)) r3.words[id] = SAID_NOTHING;
        r3.order = shuffle(this.suspectIds);
        return this.setPhase('VERDICT');
      }
      case 'VERDICT':
        this.finishScore();
        this.revealStep = 0;
        this.setPhase('REVEAL', REVEAL_STEPS[0]);
        this.emitRevealStep();
        return;
      case 'REVEAL':
        if (this.revealStep < REVEAL_STEPS.length - 1) {
          this.revealStep++;
          this.setPhase('REVEAL', REVEAL_STEPS[this.revealStep]);
          this.emitRevealStep();
          return;
        }
        return this.setPhase('END', 0);
      default:
    }
  }

  emitRevealStep() {
    this.ctx.emitAll('reveal:step', { step: this.revealStep, steps: REVEAL_STEPS.length, data: this.revealData() });
  }

  finishScore() {
    const k = this.killerId;
    const r1 = this.rounds.r1.pick === k;
    const r2 = this.rounds.r2.pick === k;
    const final = this.verdictPick === k;
    const total = (r1 ? 1 : 0) + (r2 ? 1 : 0) + (final ? 1 : 0);
    this.score = { r1, r2, final, total, rank: RANKS[total] };
    this.winner = final ? 'detective' : 'killer';
  }

  // -- who has to act --

  isConnected(id) {
    const p = this.room.players.find((x) => x.id === id);
    return !!(p && p.connected);
  }

  submissions() {
    if (this.phase === 'R1_ANSWER') return this.rounds.r1.answers;
    if (this.phase === 'R2_DRAW') return this.rounds.r2.drawings;
    if (this.phase === 'R3_WORD') return this.rounds.r3.words;
    return null;
  }

  progress() {
    const subs = this.submissions();
    if (!subs) return null;
    return { done: this.suspectIds.filter((id) => id in subs).length, total: this.suspectIds.length };
  }

  // A suspect who has dropped counts as a missed deadline, so nobody waits on them.
  checkAllDone() {
    const subs = this.submissions();
    if (!subs || this.paused) return;
    const waiting = this.suspectIds.filter((id) => !(id in subs) && this.isConnected(id));
    if (!waiting.length) {
      const until = Math.min(this.deadline - Date.now(), ms(GRACE_MS));
      this.schedule(until);
    }
  }

  // Pause a Detective phase while the Detective is away; resume when they're back.
  checkDetective() {
    if (!DETECTIVE_PHASES.includes(this.phase)) return;
    const here = this.isConnected(this.detectiveId);
    if (!here && !this.paused) {
      this.paused = true;
      this.remaining = Math.max(0, (this.deadline || Date.now()) - Date.now());
      this.deadline = null;
      this.cancel(this.timer);
      this.timer = null;
      const since = this.detectiveGoneSince || Date.now();
      this.later(() => this.ctx.broadcast(), Math.max(0, since + DETECTIVE_GONE_MS - Date.now()) + 50);
    } else if (here && this.paused) {
      this.paused = false;
      this.deadline = Date.now() + Math.max(this.remaining, ms(15000));
      this.schedule(this.deadline - Date.now());
    }
  }

  canReassign() {
    return this.paused && this.detectiveGoneSince != null && Date.now() - this.detectiveGoneSince >= DETECTIVE_GONE_MS;
  }

  onConnectionChange(player) {
    if (this.disposed || !this.playerIds.includes(player.id)) return;
    if (player.id === this.detectiveId) {
      this.detectiveGoneSince = player.connected ? null : Date.now();
      this.checkDetective();
    }
    if (player.id === this.killerId && !this.isOver() && this.phase !== 'REVEAL') {
      this.cancel(this.fleeTimer);
      this.fleeTimer = null;
      if (!player.connected) this.fleeTimer = this.later(() => this.killerFled(), KILLER_FLEE_MS);
    }
    if (!player.connected) this.checkAllDone();
  }

  killerFled() {
    if (this.isConnected(this.killerId) || this.phase === 'REVEAL' || this.phase === 'END') return;
    this.fled = true;
    this.winner = null;
    this.setPhase('END', 0);
  }

  isOver() {
    return this.phase === 'END';
  }

  // -- events from clients --

  handle(event, actor, payload) {
    const { player } = actor;
    switch (event) {
      case 'answer:submit': {
        if (!player || !this.suspectIds.includes(player.id)) return { ok: false, error: 'Only suspects answer.' };
        const result = this.acceptAnswer(player.id, payload);
        if (!result.ok) return result;
        this.checkAllDone();
        this.ctx.broadcast();
        return result;
      }
      case 'pick:submit': {
        if (!player || player.id !== this.detectiveId) return { ok: false, error: 'Only the Detective picks.' };
        const result = this.acceptPick(payload);
        if (!result.ok) return result;
        this.schedule(ms(600));
        this.ctx.broadcast();
        return result;
      }
      case 'mdp:skip': {
        // Host or VIP can hurry along the story beats, never a phase someone is working in.
        if (!actor.isHost && !actor.isVip) return { ok: false, error: 'Only the host or VIP can skip.' };
        if (!['ROLE_REVEAL', 'INTRO', 'REVEAL'].includes(this.phase)) return { ok: false, error: 'Nothing to skip.' };
        this.schedule(0);
        return { ok: true };
      }
      case 'mdp:reassign': {
        if (!actor.isHost && !actor.isVip) return { ok: false, error: 'Only the host or VIP can do that.' };
        if (!this.canReassign()) return { ok: false, error: 'Give the Detective a little longer.' };
        // A new Detective would already know the secrets, so deal a fresh game instead.
        this.ctx.rematch({ avoidDetective: this.detectiveId });
        return { ok: true };
      }
      default:
        return { ok: false, error: 'Unknown action.' };
    }
  }

  acceptAnswer(id, payload) {
    if (this.phase === 'R1_ANSWER') {
      if (typeof payload.text !== 'string') return { ok: false, error: 'Write an answer.' };
      const text = payload.text.replace(/\s+/g, ' ').trim();
      if (!text) return { ok: false, error: 'Write an answer.' };
      if (text.length > limits.text) return { ok: false, error: `Keep it under ${limits.text} characters.` };
      this.rounds.r1.answers[id] = text;
      return { ok: true };
    }
    if (this.phase === 'R2_DRAW') {
      const png = cleanPng(payload.png);
      if (!png) return { ok: false, error: 'That drawing could not be read.' };
      this.rounds.r2.drawings[id] = png;
      return { ok: true };
    }
    if (this.phase === 'R3_WORD') {
      if (typeof payload.word !== 'string') return { ok: false, error: 'Write one word.' };
      const word = payload.word.trim();
      if (!word) return { ok: false, error: 'Write one word.' };
      if (/\s/.test(word)) return { ok: false, error: 'Just one word, no spaces.' };
      if (word.length > limits.word) return { ok: false, error: `Keep it under ${limits.word} letters.` };
      this.rounds.r3.words[id] = word;
      return { ok: true };
    }
    return { ok: false, error: 'Not answering right now.' };
  }

  acceptPick(payload) {
    if (this.phase === 'R1_PICK' || this.phase === 'R2_PICK') {
      const round = this.phase === 'R1_PICK' ? this.rounds.r1 : this.rounds.r2;
      if (round.pick) return { ok: false, error: 'Already picked.' };
      const i = LABELS.indexOf(String(payload.entryLabel || ''));
      if (i < 0 || i >= round.order.length) return { ok: false, error: 'Pick one of the entries.' };
      round.pick = round.order[i];
      return { ok: true };
    }
    if (this.phase === 'VERDICT') {
      if (this.verdictPick) return { ok: false, error: 'Already accused.' };
      if (!this.suspectIds.includes(payload.suspectId)) return { ok: false, error: 'Pick one of the suspects.' };
      this.verdictPick = payload.suspectId;
      return { ok: true };
    }
    return { ok: false, error: 'Not picking right now.' };
  }

  // -- what each client may see --

  r1Prompt(forKiller) {
    return fill(prompts.r1.template, { verb: this.verb, location: forKiller ? prompts.r1.killerLocation : this.secret.location });
  }

  r2Prompt(forKiller) {
    return fill(prompts.r2.template, { weapon: forKiller ? prompts.r2.killerWeapon : this.secret.weapon });
  }

  // Shuffled, labelled, nameless. The same order for every client.
  anonEntries(round) {
    if (round === 'r1') return this.rounds.r1.order.map((id, i) => ({ label: LABELS[i], text: this.rounds.r1.answers[id] }));
    return this.rounds.r2.order.map((id, i) => ({ label: LABELS[i], png: this.rounds.r2.drawings[id] }));
  }

  labelOf(round, id) {
    const i = this.rounds[round].order.indexOf(id);
    return i < 0 ? null : LABELS[i];
  }

  revealData() {
    const k = this.killerId;
    const { r1, r2, r3 } = this.rounds;
    return {
      killerId: k,
      detectiveId: this.detectiveId,
      fled: this.fled,
      killerSilhouette: silhouetteData(cardById.get(this.cardOf(k))),
      secret: { location: this.secret.location, weapon: this.secret.weapon },
      victim: { name: this.victim.name, bio: this.victim.bio },
      prompts: { r1: this.r1Prompt(false), r2: this.r2Prompt(false), r3: prompts.r3.template },
      r1: r1.order.map((id, i) => ({ label: LABELS[i], playerId: id, text: r1.answers[id], isKiller: id === k })),
      r1Pick: this.labelOf('r1', r1.pick),
      r2: r2.order.map((id, i) => ({ label: LABELS[i], playerId: id, png: r2.drawings[id], isKiller: id === k })),
      r2Pick: this.labelOf('r2', r2.pick),
      r3: r3.order.map((id) => ({ playerId: id, word: r3.words[id], isKiller: id === k })),
      verdictPick: this.verdictPick,
      score: this.score,
      winner: this.winner,
    };
  }

  viewFor(player) {
    const phase = this.phase;
    const idx = ORDER.indexOf(phase);
    const v = {
      phase,
      deadline: this.deadline,
      paused: this.paused,
      canReassign: this.canReassign(),
      progress: this.progress(),
      victim: { name: this.victim.name, bio: this.victim.bio },
      intro: prompts.intro.map((line) => fill(line, { victim: this.victim.name, bio: this.victim.bio })),
      suspectCount: this.suspectIds.length,
    };

    // After the verdict there are no secrets left.
    if (phase === 'REVEAL' || phase === 'END') {
      v.reveal = this.revealData();
      v.revealStep = phase === 'END' ? REVEAL_STEPS.length : this.revealStep;
      v.revealSteps = REVEAL_STEPS.length;
      if (player) v.me = { role: player.id === this.detectiveId ? 'detective' : 'suspect', isKiller: player.id === this.killerId };
      return v;
    }

    if (!player) return { ...v, ...this.hostView() };
    if (!this.playerIds.includes(player.id)) return { ...v, spectator: true };

    const isDetective = player.id === this.detectiveId;
    const isKiller = player.id === this.killerId;
    const role = isDetective ? 'detective' : 'suspect';
    // The killer learns the truth about themselves in round 1, not at role reveal.
    v.me = { role, isKiller: isKiller && idx >= ORDER.indexOf('R1_ANSWER') };
    return { ...v, ...(isDetective ? this.detectiveView() : this.suspectView(player.id, isKiller)) };
  }

  hostView() {
    const v = {};
    switch (this.phase) {
      case 'R1_ANSWER':
        v.prompt = this.r1Prompt(true); // the crime scene, never the location
        break;
      case 'R1_PICK':
        v.entries = this.anonEntries('r1');
        break;
      case 'R2_PICK':
        v.entries = this.anonEntries('r2');
        break;
      case 'R3_WORD':
        v.prompt = prompts.r3.template;
        break;
      case 'VERDICT':
        v.words = this.rounds.r3.order.map((id) => this.rounds.r3.words[id]);
        break;
      default:
    }
    return v;
  }

  detectiveView() {
    const v = { suspectIds: this.suspectIds };
    switch (this.phase) {
      case 'R1_PICK':
        v.entries = this.anonEntries('r1');
        v.myPick = this.labelOf('r1', this.rounds.r1.pick);
        break;
      case 'R2_PICK':
        v.entries = this.anonEntries('r2');
        v.myPick = this.labelOf('r2', this.rounds.r2.pick);
        break;
      case 'VERDICT':
        v.dossier = this.suspectIds.map((id) => ({
          playerId: id,
          r1: this.rounds.r1.answers[id],
          r2: this.rounds.r2.drawings[id],
          r3: this.rounds.r3.words[id],
        }));
        v.myPick = this.verdictPick;
        break;
      default:
    }
    return v;
  }

  suspectView(id, isKiller) {
    const v = {};
    switch (this.phase) {
      case 'R1_ANSWER':
        v.prompt = this.r1Prompt(isKiller);
        if (!isKiller) v.location = this.secret.location;
        v.mine = this.rounds.r1.answers[id] ?? null;
        v.maxLen = limits.text;
        break;
      case 'R2_DRAW':
        v.prompt = this.r2Prompt(isKiller);
        v.weapon = isKiller ? prompts.r2.killerWeapon : this.secret.weapon;
        v.mine = this.rounds.r2.drawings[id] ?? null;
        break;
      case 'R3_WORD':
        v.prompt = prompts.r3.template;
        v.silhouette = silhouetteData(cardById.get(this.cardOf(this.killerId)));
        v.mine = this.rounds.r3.words[id] ?? null;
        v.maxLen = limits.word;
        break;
      default:
    }
    return v;
  }

  cardOf(id) {
    const p = this.room.players.find((x) => x.id === id);
    return p && p.cardId;
  }

  dispose() {
    this.disposed = true;
    for (const t of this.timers) clearTimeout(t);
    this.timers.clear();
  }
}

module.exports = {
  id: 'murder-dinner-party',
  name: 'Murder Dinner Party',
  pitch: 'A rich old man is dead. Everyone saw it. One guest is bluffing.',
  minPlayers: 4,
  maxPlayers: 8,
  minutes: '10–12',
  cards,
  createGame: (room, ctx, opts) => new MurderGame(room, ctx, opts),
  // For tests.
  _internals: { cleanPng, shuffle, drawFrom, DURATION, REVEAL_STEPS },
};
