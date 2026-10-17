// Murder Dinner Party: the host screen. Shared on the call, so it only ever
// draws what the server sent it, and the server sends it no secrets until
// the reveal.

(function () {
  const GAME_ID = 'murder-dinner-party';
  const stage = ZB.$('#stage');
  const timerEl = ZB.$('#timer');
  const params = new URLSearchParams(location.search);
  const esc = ZB.esc;

  let room = null;
  let state = null;
  let sceneKey = '';
  let lastPhase = null;
  let lastDone = 0;
  let lastSeated = 0;
  let phaseTotal = 0;
  let lastTick = null;
  let lastDeadline = null;

  const HOW_TO = [
    'One of you is the <b>Detective</b>. Everyone else is a <b>suspect</b>.',
    'Every suspect saw the murder, except the <b>killer</b>, who must bluff.',
    'Three rounds: the scene, the weapon, the silhouette.',
    'The Detective sees answers, never names, and must find the liar.',
  ];

  // ---------- connecting ----------

  async function connectRoom() {
    const code = (params.get('code') || '').toUpperCase();
    if (code && ZB.getHostToken(code)) {
      const res = await ZB.emit('host:rejoin', { code, hostToken: ZB.getHostToken(code) });
      if (res.ok) return setRoom(res);
    }
    const res = await ZB.emit('room:create', { gameId: GAME_ID });
    if (!res.ok) {
      stage.innerHTML = `<div class="overlay"><h2>Could not open a room</h2><p>${esc(res.error || '')}</p><a class="btn" href="/">Back to index</a></div>`;
      return;
    }
    ZB.setHostToken(res.code, res.hostToken);
    params.set('code', res.code);
    history.replaceState(null, '', `${location.pathname}?${params}`);
    setRoom(res);
  }

  function setRoom(res) {
    room = res;
    ZB.setCards(res.cards);
    const host = res.joinUrl.replace(/^https?:\/\//, '').replace(/\?.*$/, '');
    ZB.$('#roomtag').innerHTML = `${esc(host)} · <b>${esc(res.code)}</b>`;
  }

  ZB.socket.on('connect', connectRoom);
  ZB.socket.on('room:closed', (m) => {
    stage.innerHTML = `<div class="overlay"><h2>The party is over</h2><p>${esc(m.reason)}</p><a class="btn" href="/host/${GAME_ID}">Host a new game</a></div>`;
  });

  ZB.$('#mute').addEventListener('click', () => {
    ZB.$('#mute').textContent = SFX.toggle() ? '🔇' : '🔊';
  });
  ZB.$('#mute').textContent = SFX.muted ? '🔇' : '🔊';
  document.addEventListener('pointerdown', () => SFX.unlock(), { once: false });

  // ---------- helpers ----------

  const playerCard = (id) => {
    const p = state.players.find((x) => x.id === id);
    return p ? ZB.card(p.cardId) : null;
  };
  const cardIdOf = (id) => (state.players.find((x) => x.id === id) || {}).cardId;
  const nameOf = (id) => (playerCard(id) || { name: 'Someone' }).name;

  function avatarChip(id) {
    const c = playerCard(id);
    if (!c) return '';
    return `<span class="who"><img src="${esc(c.avatar)}" alt="">${esc(c.name)}</span>`;
  }

  function roundHead(no, title, sub) {
    return `<div class="round-head">
      <div class="eyebrow">Round ${no} of 3</div>
      <h1>${esc(title)}</h1>
      ${sub ? `<p class="sub">${sub}</p>` : ''}
    </div>`;
  }

  function progressHtml() {
    const pr = state.progress;
    if (!pr) return '';
    const dots = Array.from({ length: pr.total }, (_, i) => `<span class="dot ${i < pr.done ? 'on' : ''}"></span>`).join('');
    return `<div class="progress"><div class="dots">${dots}</div>
      <div class="ptext">${pr.done} of ${pr.total} suspects done</div></div>`;
  }

  // "the crime scene" appears redacted on the shared screen.
  function redact(prompt) {
    return esc(prompt).replace('the crime scene', '<span class="redacted">the crime scene</span>');
  }

  function drawingImg(png) {
    return png ? `<img class="drawing" src="${png}" alt="">` : '<div class="drawing blank"><span>(drew nothing)</span></div>';
  }

  // ---------- phases ----------

  function render() {
    if (!state || !room) return;
    const key = [state.phase, state.revealStep, state.paused, state.canReassign, state.entries ? state.entries.length : 0].join('|');

    if (state.phase !== lastPhase) onPhaseChange(state.phase, lastPhase);
    if (state.deadline !== lastDeadline) {
      lastDeadline = state.deadline;
      phaseTotal = state.deadline ? state.deadline - ZB.now() : 0;
    }

    if (state.phase === 'LOBBY') {
      const seatedNow = state.lobby.players.length;
      if (seatedNow > lastSeated) SFX.join();
      lastSeated = seatedNow;
      ZBHostLobby.render(stage, {
        state, room,
        title: 'Murder Dinner Party',
        tagline: 'A rich old man is dead. Everyone saw it. One guest is bluffing.',
        howTo: HOW_TO,
        onStart: async () => {
          SFX.unlock();
          const r = await ZB.emit('game:start');
          if (!r.ok) ZB.toast(r.error);
        },
      });
      sceneKey = key;
      return;
    }

    if (key !== sceneKey) {
      sceneKey = key;
      stage.innerHTML = phaseHtml() + pauseHtml();
      wire();
    } else {
      // Small live updates without redrawing the scene.
      const p = stage.querySelector('.progress');
      if (p) p.outerHTML = progressHtml();
      const v = stage.querySelector('#votes');
      if (v) v.textContent = votesText();
    }

    if (state.progress) {
      if (state.progress.done > lastDone) SFX.submit();
      lastDone = state.progress.done;
    }
  }

  function onPhaseChange(phase, prev) {
    lastPhase = phase;
    lastDone = 0;
    if (phase === 'ROLE_REVEAL') SFX.gong();
    if (phase === 'INTRO') SFX.thunder();
    if (['R1_ANSWER', 'R2_DRAW', 'R3_WORD'].includes(phase)) SFX.gong();
    if (phase === 'END' && prev && state.reveal) {
      if (state.reveal.winner === 'detective') SFX.good(); else SFX.bad();
    }
  }

  function phaseHtml() {
    switch (state.phase) {
      case 'ROLE_REVEAL':
        return `<div class="center-stage">
          <div class="envelope" aria-hidden="true">✉️</div>
          <h1 class="huge">Check your phone</h1>
          <p class="sub">Your role is waiting. Keep it to yourself.</p>
        </div>`;

      case 'INTRO':
        return `<div class="intro">
          <div class="scene-wrap">${MDPScene.table(state.players.map((p) => p.cardId))}</div>
          <div class="narration">${state.intro.map((l, i) => `<p style="animation-delay:${0.8 + i * 3.4}s">${esc(l)}</p>`).join('')}</div>
          <button class="btn ghost sm skip" data-act="skip">Skip intro ›</button>
        </div>`;

      case 'R1_ANSWER':
        return `<div class="round">
          ${roundHead(1, 'The Scene', 'Witnesses saw where it happened. The killer did not.')}
          <div class="prompt panel">“${redact(state.prompt)}”</div>
          <p class="hint">Suspects, answer on your phones. The Detective waits.</p>
          ${progressHtml()}
        </div>`;

      case 'R1_PICK':
        return `<div class="pick">
          ${roundHead(1, 'Which answer fits the scene least?', 'The Detective is choosing on their phone.')}
          <div class="entries text n${state.entries.length}">
            ${state.entries.map((e, i) => `<div class="entry fade-up" style="animation-delay:${i * 0.12}s">
              <span class="label">${e.label}</span><p>${esc(e.text)}</p></div>`).join('')}
          </div>
        </div>`;

      case 'R2_DRAW':
        return `<div class="round">
          ${roundHead(2, 'The Weapon', 'Witnesses saw what it was. The killer is guessing.')}
          <div class="prompt panel">“Draw the murder weapon.”</div>
          <p class="hint">Suspects are drawing on their phones.</p>
          ${progressHtml()}
        </div>`;

      case 'R2_PICK':
        return `<div class="pick">
          ${roundHead(2, 'Which drawing is not the weapon?', 'The Detective is choosing on their phone.')}
          <div class="entries draw n${state.entries.length}">
            ${state.entries.map((e, i) => `<div class="entry fade-up" style="animation-delay:${i * 0.12}s">
              <span class="label">${e.label}</span>${drawingImg(e.png)}</div>`).join('')}
          </div>
        </div>`;

      case 'R3_WORD':
        return `<div class="round">
          ${roundHead(3, 'The Silhouette', 'A figure fled the scene. Every suspect saw its outline.')}
          <div class="mystery" aria-hidden="true">${mysteryFigure()}</div>
          <div class="prompt panel">“Describe the figure you saw in ONE word.”</div>
          ${progressHtml()}
        </div>`;

      case 'VERDICT':
        return `<div class="verdict">
          <div class="eyebrow">The verdict</div>
          <h1 class="huge">The Detective is deliberating…</h1>
          <p class="sub">Words the suspects used for the fleeing figure:</p>
          <div class="words">${state.words.map((w, i) => `<span class="word fade-up" style="animation-delay:${i * 0.15}s; --r:${((i * 37) % 9) - 4}deg">${esc(w)}</span>`).join('')}</div>
        </div>`;

      case 'REVEAL':
        return revealHtml(state.revealStep) + `<button class="btn ghost sm next" data-act="skip">Next ›</button>`;

      case 'END':
        return endHtml();

      default:
        return '';
    }
  }

  function pauseHtml() {
    if (!state.paused) return '';
    return `<div class="overlay">
      <h2>Waiting for the Detective…</h2>
      <p>The Detective's phone dropped out. The game carries on as soon as they're back.</p>
      ${state.canReassign ? `<p>Still gone? Deal a fresh game with a new Detective. Same guests, new roles.</p>
        <button class="btn danger" data-act="reassign">Deal a new game</button>` : ''}
    </div>`;
  }

  function mysteryFigure() {
    return `<svg viewBox="0 0 200 240" width="100%" height="100%"><rect width="200" height="240" rx="16" fill="#e9dfc7"/>
      <path d="M28 240 C28 186 58 166 100 166 C142 166 172 186 172 240 Z" fill="#111"/>
      <rect x="88" y="146" width="24" height="26" fill="#111"/><ellipse cx="100" cy="118" rx="32" ry="38" fill="#111"/>
      <text x="100" y="132" text-anchor="middle" font-family="Playfair Display, Georgia, serif" font-weight="900" font-size="54" fill="#d4af37">?</text></svg>`;
  }

  // ---------- reveal ----------

  function revealHtml(step) {
    const r = state.reveal;
    const killer = playerCard(r.killerId);
    if (step === 0) {
      return `<div class="center-stage dark"><h1 class="huge drum">The killer is<span class="dots"><i>.</i><i>.</i><i>.</i></span></h1></div>`;
    }
    if (step === 1) {
      const accused = r.verdictPick ? nameOf(r.verdictPick) : null;
      const right = r.score.final;
      return `<div class="killer-reveal">
        <div class="killer-card">
          <img src="${esc(killer.avatar)}" alt="">
          <div class="kc-body">
            <span class="chip red">The killer</span>
            <h1>${esc(killer.name)}</h1>
            <p class="kc-title">${esc(killer.title)}</p>
            <ul class="traits">${killer.traits.map((t) => `<li>${esc(t)}</li>`).join('')}</ul>
            <p class="catch">“${esc(killer.catchphrase)}”</p>
          </div>
        </div>
        <div class="accusation ${right ? 'right' : 'wrong'}">
          <p>The Detective, ${avatarChip(r.detectiveId)}, ${accused ? `accused <b>${esc(accused)}</b>.` : 'accused nobody in time.'}</p>
          <h2>${right ? 'Correct! Justice is served.' : 'Wrong! The killer walks free.'}</h2>
        </div>
      </div>`;
    }
    if (step === 2) {
      return `<div class="replay">
        <div class="replay-head"><div class="eyebrow">Round 1 replay · The Scene</div>
          <h2>“${esc(r.prompts.r1).replace(esc(r.secret.location), `<span class="gold">${esc(r.secret.location)}</span>`)}”</h2></div>
        <div class="entries text reveal n${r.r1.length}">
          ${r.r1.map((e, i) => replayEntry(e, r.r1Pick, `<p>${esc(e.text)}</p>`, i)).join('')}
        </div>
        ${pickVerdict(r.r1Pick, r.score.r1)}
      </div>`;
    }
    if (step === 3) {
      return `<div class="replay">
        <div class="replay-head"><div class="eyebrow">Round 2 replay · The Weapon</div>
          <h2>The weapon was <span class="gold">${esc(r.secret.weapon)}</span></h2></div>
        <div class="entries draw reveal n${r.r2.length}">
          ${r.r2.map((e, i) => replayEntry(e, r.r2Pick, drawingImg(e.png), i)).join('')}
        </div>
        ${pickVerdict(r.r2Pick, r.score.r2)}
      </div>`;
    }
    if (step === 4) {
      return `<div class="replay r3">
        <div class="replay-head"><div class="eyebrow">Round 3 replay · The Silhouette</div>
          <h2>The figure they all saw</h2></div>
        <div class="r3-body">
          <img class="sil" src="${r.killerSilhouette}" alt="">
          <div class="r3-words">${r.r3.map((e, i) => `<div class="r3-word fade-up ${e.isKiller ? 'killer' : ''}" style="animation-delay:${i * 0.25}s">
            <b>${esc(e.word)}</b>${avatarChip(e.playerId)}${e.isKiller ? '<span class="chip red">Killer</span>' : ''}</div>`).join('')}</div>
        </div>
      </div>`;
    }
    // step 5: the Detective's evaluation
    const s = r.score;
    const det = playerCard(r.detectiveId);
    const row = (label, ok) => `<li class="${ok ? 'ok' : 'no'}"><span>${ok ? '✔' : '✘'}</span>${label}</li>`;
    return `<div class="evaluation">
      <img class="det-avatar" src="${esc(det.avatar)}" alt="">
      <div>
        <div class="eyebrow">Detective evaluation</div>
        <h2>${esc(det.name)}</h2>
        <ul class="score-list">
          ${row('Round 1: found the odd answer', s.r1)}
          ${row('Round 2: found the odd drawing', s.r2)}
          ${row('Final accusation', s.final)}
        </ul>
        <div class="score">${s.total}<small> / 3</small></div>
        <h1 class="rank">${esc(s.rank)}</h1>
      </div>
    </div>`;
  }

  function replayEntry(e, pickLabel, inner, i) {
    const picked = e.label === pickLabel;
    return `<div class="entry fade-up ${e.isKiller ? 'killer' : ''} ${picked ? 'picked' : ''}" style="animation-delay:${i * 0.18}s">
      <span class="label">${e.label}</span>${inner}
      <div class="by">${avatarChip(e.playerId)}</div>
      <div class="tags">${e.isKiller ? '<span class="chip red">Killer</span>' : ''}${picked ? '<span class="chip">🔍 Detective’s pick</span>' : ''}</div>
    </div>`;
  }

  function pickVerdict(label, ok) {
    if (!label) return '<p class="pick-verdict wrong">The Detective ran out of time and picked nothing.</p>';
    return `<p class="pick-verdict ${ok ? 'right' : 'wrong'}">The Detective picked ${label}: ${ok ? 'the killer! ✔' : 'an innocent guest. ✘'}</p>`;
  }

  function votesText() {
    const n = state.rematchVotes || 0;
    return n ? `${n} guest${n === 1 ? '' : 's'} want${n === 1 ? 's' : ''} a rematch` : '';
  }

  function endHtml() {
    const r = state.reveal;
    const killer = playerCard(r.killerId);
    let title;
    let sub;
    if (r.fled) {
      title = 'The killer fled!';
      sub = `${esc(killer.name)} slipped out into the night. Nobody wins this one.`;
    } else if (r.winner === 'detective') {
      title = 'Justice is served';
      sub = 'The Detective and every innocent guest win.';
    } else {
      title = 'The killer got away with it';
      sub = `${esc(killer.name)} wins. Sleep with one eye open.`;
    }
    return `<div class="end ${r.fled ? 'fled' : r.winner}">
      <div class="eyebrow">${esc(r.victim.name)} · ${esc(r.secret.location)} · ${esc(r.secret.weapon)}</div>
      <h1 class="huge">${title}</h1>
      <p class="sub">${sub}</p>
      <div class="end-cards">
        <div><span class="chip red">Killer</span>${ZB.cardHtml(cardIdOf(r.killerId))}</div>
        <div><span class="chip">Detective${r.score ? ' · ' + esc(r.score.rank) : ''}</span>${ZB.cardHtml(cardIdOf(r.detectiveId))}</div>
      </div>
      <div class="end-actions">
        <button class="btn" data-act="rematch">Play again</button>
        <button class="btn ghost" data-act="lobby">Back to lobby</button>
        <a class="btn ghost" href="/">Back to index</a>
      </div>
      <p class="muted" id="votes">${votesText()}</p>
    </div>`;
  }

  // ---------- buttons ----------

  function wire() {
    stage.querySelectorAll('[data-act]').forEach((b) => b.addEventListener('click', async () => {
      SFX.unlock();
      const act = b.dataset.act;
      const ev = { skip: 'mdp:skip', reassign: 'mdp:reassign', rematch: 'game:rematch', lobby: 'game:lobby' }[act];
      const r = await ZB.emit(ev);
      if (!r.ok) ZB.toast(r.error || 'That did not work.');
    }));
  }

  ZB.socket.on('reveal:step', ({ step }) => {
    if (step === 0) SFX.drumroll(3.4);
    if (step === 1) SFX.sting();
  });

  ZB.onState((s) => {
    state = s;
    render();
  });

  // ---------- timer ----------

  const TIMED_INPUT = ['R1_ANSWER', 'R1_PICK', 'R2_DRAW', 'R2_PICK', 'R3_WORD', 'VERDICT'];
  setInterval(() => {
    if (!state || !state.deadline || state.paused || !TIMED_INPUT.includes(state.phase)) {
      timerEl.classList.add('off');
      return;
    }
    const left = Math.max(0, state.deadline - ZB.now());
    const secs = Math.ceil(left / 1000);
    timerEl.classList.remove('off');
    timerEl.classList.toggle('low', secs <= 10);
    timerEl.style.setProperty('--p', phaseTotal ? Math.min(1, left / phaseTotal) : 1);
    timerEl.querySelector('span').textContent = secs;
    if (secs <= 5 && secs > 0 && secs !== lastTick) { SFX.tick(); lastTick = secs; }
  }, 200);
})();
