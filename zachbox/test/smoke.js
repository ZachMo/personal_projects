// Plays whole games of Murder Dinner Party against a real server with fake
// phones, and checks the acceptance list: unique cards, one Detective and one
// killer, no secret on the wrong screen, anonymous entries, saved picks,
// reconnects, the reveal, and rematch rotation.
//
//   npm test

process.env.MDP_TIME_SCALE = '0.05';
const assert = require('assert/strict');
const { io: connect } = require('socket.io-client');
const { server } = require('../server/index');
const mdp = require('../games/murder-dinner-party/game');
const locations = require('../games/murder-dinner-party/content/locations.json');
const weapons = require('../games/murder-dinner-party/content/weapons.json');

const PNG_1x1 = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

let base;
const sockets = [];
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

function client(name) {
  const s = connect(base, { transports: ['websocket'], forceNew: true });
  s.name = name;
  s.states = [];
  s.on('state:update', (st) => { s.state = st; s.states.push(st); });
  sockets.push(s);
  return s;
}
const emit = (s, ev, data) => new Promise((r) => s.emit(ev, data, r));
async function until(fn, label, ms = 8000) {
  const t0 = Date.now();
  while (Date.now() - t0 < ms) {
    if (fn()) return;
    await wait(15);
  }
  throw new Error('Timed out waiting for ' + label);
}

// Every message a client received, as text, for secrecy checks.
const seen = (s) => JSON.stringify(s.states);

async function playGame(host, phones, { round = 1 } = {}) {
  await until(() => phones.every((p) => p.state && p.state.phase === 'ROLE_REVEAL'), 'role reveal');
  const detective = phones.filter((p) => p.state.me.role === 'detective');
  assert.equal(detective.length, 1, 'exactly one Detective');
  const det = detective[0];
  const suspects = phones.filter((p) => p !== det);
  assert.ok(suspects.every((p) => p.state.me.isKiller === false), 'killer is not told at role reveal');

  await until(() => phones.every((p) => p.state.phase === 'R1_ANSWER'), 'round 1');
  const killers = suspects.filter((p) => p.state.me.isKiller);
  assert.equal(killers.length, 1, 'exactly one killer');
  const killer = killers[0];
  assert.notEqual(killer, det, 'killer is never the Detective');
  const location = suspects.find((p) => p !== killer).state.location;
  assert.ok(locations.includes(location), 'witness sees the true location');
  assert.match(killer.state.prompt, /the crime scene/);
  assert.equal(killer.state.location, undefined);

  // Round 1: answers. One suspect stays silent to test the deadline fill.
  const silent = suspects.find((p) => p !== killer);
  for (const p of suspects) {
    if (p === silent) continue;
    const text = p === killer ? 'a very normal fork' : `honest answer from ${p.name}`;
    assert.deepEqual(await emit(p, 'answer:submit', { text }), { ok: true });
  }
  // Too long, wrong role, wrong phase.
  assert.equal((await emit(silent, 'answer:submit', { text: 'x'.repeat(81) })).ok, false);
  assert.equal((await emit(det, 'answer:submit', { text: 'hi' })).ok, false);
  assert.equal((await emit(det, 'pick:submit', { entryLabel: 'A' })).ok, false);

  // A suspect refreshes mid-round and gets their own answer back.
  const refresher = suspects.find((p) => p !== silent);
  const tok = refresher.token;
  refresher.disconnect();
  const back = client(refresher.name + "'");
  const rejoin = await emit(back, 'room:join', { code: host.code, token: tok });
  assert.equal(rejoin.ok, true);
  assert.equal(rejoin.playerId, refresher.playerId, 'token returns the same player');
  await until(() => back.state && back.state.phase === 'R1_ANSWER', 'state after rejoin');
  assert.ok(back.state.mine, 'answer survives a refresh');
  back.token = tok; back.playerId = refresher.playerId;
  phones[phones.indexOf(refresher)] = back;
  suspects[suspects.indexOf(refresher)] = back;
  const killerNow = refresher === killer ? back : killer;

  // Round 1 pick. The silent suspect is still connected, so we wait for the deadline.
  await until(() => det.state.phase === 'R1_PICK', 'R1 pick', 10000);
  assert.equal(det.state.entries.length, suspects.length);
  assert.ok(det.state.entries.some((e) => e.text === '(said nothing)'), 'missed answer becomes (said nothing)');
  assert.deepEqual(det.state.entries.map((e) => e.label), 'ABCDEFGH'.slice(0, suspects.length).split(''));
  assert.deepEqual(host.state.entries, det.state.entries, 'same order on every screen');
  const ids = phones.map((p) => p.playerId);
  for (const id of ids) assert.ok(!JSON.stringify(det.state.entries).includes(id), 'entries carry no ids');
  const killerLabel = det.state.entries.find((e) => e.text === 'a very normal fork').label;
  assert.equal((await emit(det, 'pick:submit', { entryLabel: 'Z' })).ok, false);
  assert.deepEqual(await emit(det, 'pick:submit', { entryLabel: killerLabel }), { ok: true });
  assert.equal((await emit(det, 'pick:submit', { entryLabel: 'A' })).ok, false, 'one pick only');

  // Round 2: drawings.
  await until(() => suspects.every((p) => p.state.phase === 'R2_DRAW'), 'round 2');
  assert.equal(killerNow.state.weapon, '???');
  const weapon = suspects.find((p) => p !== killerNow).state.weapon;
  assert.ok(weapons.includes(weapon));
  assert.equal((await emit(suspects[0], 'answer:submit', { png: 'data:image/png;base64,AAAA' })).ok, false, 'rejects a non-PNG');
  for (const p of suspects) assert.deepEqual(await emit(p, 'answer:submit', { png: PNG_1x1 }), { ok: true });
  await until(() => det.state.phase === 'R2_PICK', 'R2 pick');
  assert.equal(det.state.entries.length, suspects.length);
  assert.ok(det.state.entries.every((e) => e.png && e.png.startsWith('data:image/png')));
  await emit(det, 'pick:submit', { entryLabel: 'A' });

  // Round 3: words.
  await until(() => suspects.every((p) => p.state.phase === 'R3_WORD'), 'round 3');
  assert.ok(suspects.every((p) => p.state.silhouette && p.state.silhouette.startsWith('data:image/')), 'suspects see the silhouette');
  assert.equal(det.state.silhouette, undefined, 'Detective does not');
  assert.equal(host.state.silhouette, undefined, 'host does not');
  assert.equal((await emit(suspects[0], 'answer:submit', { word: 'two words' })).ok, false);
  for (const p of suspects) assert.deepEqual(await emit(p, 'answer:submit', { word: 'Hat' }), { ok: true });

  // Verdict.
  await until(() => det.state.phase === 'VERDICT', 'verdict');
  assert.equal(det.state.dossier.length, suspects.length);
  assert.ok(host.state.words.length === suspects.length);
  assert.equal(suspects[0].state.dossier, undefined);
  const accuse = round === 1 ? killerNow.playerId : suspects.find((p) => p !== killerNow).playerId;
  assert.deepEqual(await emit(det, 'pick:submit', { suspectId: accuse }), { ok: true });

  // Secrecy: nothing secret reached the wrong screen before the reveal.
  await until(() => host.state.phase === 'REVEAL', 'reveal');
  const before = (s) => JSON.stringify(s.states.filter((st) => !['REVEAL', 'END'].includes(st.phase)));
  for (const secret of [location, weapon]) {
    assert.ok(!before(host).includes(secret), `host never sees "${secret}" before the reveal`);
    assert.ok(!before(killerNow).includes(secret), `killer never sees "${secret}"`);
    assert.ok(!before(det).includes(secret), `Detective never sees "${secret}"`);
  }
  assert.ok(!before(host).includes('killerId') && !before(host).includes('detectiveId'));
  assert.ok(!before(host).includes('-sil.'), 'no silhouette file names leak');

  // Reveal.
  const r = host.state.reveal;
  assert.equal(r.killerId, killerNow.playerId);
  assert.equal(r.r1.filter((e) => e.isKiller).length, 1);
  assert.equal(r.r1Pick, killerLabel);
  assert.equal(r.score.r1, true);
  assert.equal(r.score.final, round === 1);
  assert.equal(r.winner, round === 1 ? 'detective' : 'killer');
  assert.equal(r.score.rank, ['Hopeless Clouseau', 'Lucky Guess Larry', 'Competent Inspector', 'Legendary Detective'][r.score.total]);

  // Host can hurry the reveal along.
  while (host.state.phase === 'REVEAL') {
    await emit(host, 'mdp:skip');
    await wait(30);
  }
  await until(() => phones.every((p) => p.state.phase === 'END'), 'end');
  return { det, killer: killerNow, phones };
}

// Detective drops: the pick phase pauses, resumes when they return, and after
// a while the host can deal a fresh game. Then the killer drops and flees.
async function disconnectRules() {
  const host = client('host-dc');
  const created = await emit(host, 'room:create', { gameId: 'murder-dinner-party' });
  let phones = [];
  for (let i = 0; i < 4; i++) {
    const p = client('dc' + i);
    const j = await emit(p, 'room:join', { code: created.code });
    p.token = j.token; p.playerId = j.playerId;
    await emit(p, 'card:pick', { cardId: created.cards[i].id });
    phones.push(p);
  }
  await emit(host, 'game:start');
  await until(() => phones.every((p) => p.state && p.state.phase === 'R1_ANSWER' && p.state.me.role), 'dc round 1');
  const det = phones.find((p) => p.state.me.role === 'detective');
  const suspects = phones.filter((p) => p !== det);
  det.disconnect();
  for (const p of suspects) await emit(p, 'answer:submit', { text: 'a lamp' });
  await until(() => host.state.phase === 'R1_PICK' && host.state.paused, 'pause for the Detective');
  assert.equal(host.state.deadline, null);
  assert.equal(host.state.canReassign, false);
  assert.equal((await emit(host, 'mdp:reassign')).ok, false, 'too soon to reassign');

  // The Detective comes back: the phase resumes.
  const det2 = client('dc-det2');
  await emit(det2, 'room:join', { code: created.code, token: det.token });
  det2.playerId = det.playerId; det2.token = det.token;
  await until(() => host.state.paused === false && host.state.deadline, 'resume');
  assert.ok(det2.state.entries, 'Detective gets their pick screen back');

  // Gone again, long enough this time.
  det2.disconnect();
  await until(() => host.state.paused, 'pause again');
  await until(() => host.state.canReassign, 'reassign unlocks', 10000);
  assert.deepEqual(await emit(host, 'mdp:reassign'), { ok: true });
  await until(() => suspects.every((p) => p.state.phase === 'ROLE_REVEAL'), 'fresh game');
  const newDet = suspects.find((p) => p.state.me.role === 'detective');
  assert.ok(newDet, 'a connected player is the new Detective');

  // The killer flees.
  await until(() => suspects.every((p) => p.state.phase === 'R1_ANSWER'), 'round 1 again', 10000);
  const killer = suspects.find((p) => p.state.me.isKiller);
  killer.disconnect();
  await until(() => host.state.phase === 'END', 'killer fled', 10000);
  assert.equal(host.state.reveal.fled, true);
  assert.equal(host.state.reveal.winner, null);
}

(async () => {
  await new Promise((r) => server.listen(0, r));
  base = `http://localhost:${server.address().port}`;

  // Unit: PNG cleaning keeps the image and drops metadata.
  const clean = mdp._internals.cleanPng(PNG_1x1);
  assert.ok(clean && clean.startsWith('data:image/png;base64,'));
  assert.equal(mdp._internals.cleanPng('data:image/png;base64,' + 'A'.repeat(300000)), null);

  // Pages.
  for (const [p, want] of [['/', 200], ['/join?code=ABCD', 200], ['/host/murder-dinner-party', 200], ['/games/murder-dinner-party/cards/cards.json', 200],
    ['/games/murder-dinner-party/game.js', 404], ['/games/murder-dinner-party/content/locations.json', 404]]) {
    const res = await fetch(base + p, { redirect: 'manual' });
    assert.equal(res.status, want, `${p} → ${res.status}`);
  }

  // Host creates a room.
  const host = client('host');
  const created = await emit(host, 'room:create', { gameId: 'murder-dinner-party' });
  assert.equal(created.ok, true);
  assert.match(created.code, /^[A-HJ-NP-Z]{4}$/);
  assert.ok(created.qr.startsWith('data:image/png;base64,'));
  assert.ok(created.joinUrl.endsWith('/join?code=' + created.code));
  assert.ok(created.cards.every((c) => !c.silhouette), 'public card list has no silhouettes');
  host.code = created.code;
  assert.equal((await fetch(`${base}/play/${created.code}`)).status, 200);

  assert.equal((await emit(client('nobody'), 'room:join', { code: 'ZZZZ' })).ok, false);

  // Five phones join and pick cards.
  const cardIds = created.cards.map((c) => c.id);
  const phones = [];
  for (let i = 0; i < 5; i++) {
    const p = client('p' + i);
    const j = await emit(p, 'room:join', { code: created.code.toLowerCase() });
    assert.equal(j.ok, true);
    p.token = j.token; p.playerId = j.playerId;
    phones.push(p);
  }
  assert.equal((await emit(phones[0], 'game:start')).ok, false, 'start needs 4 carded players');
  assert.deepEqual(await emit(phones[0], 'card:pick', { cardId: cardIds[0] }), { ok: true, cardId: cardIds[0] });
  const clash = await emit(phones[1], 'card:pick', { cardId: cardIds[0] });
  assert.equal(clash.taken, true, 'second claim on a card is refused');
  for (let i = 1; i < 5; i++) assert.equal((await emit(phones[i], 'card:pick', { cardId: cardIds[i] })).ok, true);
  // Swap before start frees the old card.
  assert.equal((await emit(phones[4], 'card:pick', { cardId: cardIds[5] })).ok, true);
  await until(() => host.state && host.state.lobby && host.state.lobby.players.length === 5 && host.state.lobby.canStart && host.state.lobby.taken.includes(cardIds[5]), 'lobby fills');
  assert.ok(!host.state.lobby.taken.includes(cardIds[4]));
  assert.equal(host.state.lobby.vipPlayerId, phones[0].playerId, 'first to join is VIP');
  assert.equal((await emit(phones[1], 'game:start')).ok, false, 'only host or VIP can start');

  assert.deepEqual(await emit(phones[0], 'game:start'), { ok: true });
  assert.equal((await emit(client('late'), 'room:join', { code: created.code })).ok, false, 'late join blocked');

  const g1 = await playGame(host, phones, { round: 1 });
  assert.ok(host.state.reveal.winner === 'detective');

  // Rematch: same players and cards, new Detective.
  assert.equal((await emit(g1.phones[2], 'game:rematch')).ok, false);
  assert.deepEqual(await emit(host, 'game:rematch'), { ok: true });
  const g2 = await playGame(host, g1.phones, { round: 2 });
  assert.notEqual(g2.det.playerId, g1.det.playerId, 'Detective rotates');
  assert.equal(host.state.reveal.winner, 'killer');

  // Host screen refresh: rejoin by code and token.
  const host2 = client('host2');
  const hr = await emit(host2, 'host:rejoin', { code: created.code, hostToken: created.hostToken });
  assert.equal(hr.ok, true);
  await until(() => host2.state && host2.state.phase === 'END', 'host rejoin state');
  assert.equal((await emit(client('thief'), 'host:rejoin', { code: created.code, hostToken: 'nope' })).ok, false);

  // Back to the lobby keeps players and cards.
  assert.deepEqual(await emit(host, 'game:lobby'), { ok: true });
  await until(() => host.state.phase === 'LOBBY', 'lobby again');
  assert.equal(host.state.lobby.players.length, 5);

  await disconnectRules();

  console.log('All checks passed.');
  for (const s of sockets) s.disconnect();
  server.close();
  process.exit(0);
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
