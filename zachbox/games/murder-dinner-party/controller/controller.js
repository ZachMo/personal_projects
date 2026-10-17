// Murder Dinner Party: the phone controller. It renders whatever the server
// sends this phone and nothing more; the server already left out anything
// this player should not know.

(function () {
  const code = decodeURIComponent(location.pathname.split('/').pop() || '').toUpperCase();
  const screen = ZB.$('#screen');
  const clock = ZB.$('#clock');
  const esc = ZB.esc;

  let state = null;
  let key = '';
  let ended = null; // a message that replaces the game (kicked, room closed)

  // Local, per-phase UI state.
  let editing = false;
  let draft = '';
  let picked = null; // the Detective's tentative choice before confirming
  let sending = false;
  let autoSent = false;
  const pad = new DrawPad();

  // ---------- connecting ----------

  async function join() {
    const token = ZB.getToken(code);
    if (!token) return location.replace(`/join?code=${code}`);
    const res = await ZB.emit('room:join', { code, token });
    if (!res.ok) {
      return showEnded('Could not rejoin', res.error || 'That room is gone.', `/join?code=${code}`, 'Join a game');
    }
    ZB.setToken(res.code, res.token);
    ZB.setCards(res.cards);
    if (!res.cardId && !res.inGame) return location.replace(`/join?code=${code}&pick=1`);
  }

  function showEnded(title, msg, href, label) {
    ended = { title, msg, href, label };
    screen.innerHTML = `<div class="wait"><h2>${esc(title)}</h2><p>${esc(msg)}</p><a class="btn" href="${href}">${esc(label)}</a></div>`;
    clock.textContent = '';
  }

  ZB.socket.on('connect', join);
  ZB.socket.on('room:kicked', (m) => showEnded('You are out of this room', m.reason, `/join?code=${code}`, 'Join again'));
  ZB.socket.on('room:closed', (m) => showEnded('The party is over', m.reason, '/', 'Back to Zachbox'));

  // Keep the screen on and stop pinch-zoom, from the first tap.
  document.addEventListener('pointerdown', () => { ZB._wantAwake = true; ZB.keepAwake(); }, { once: true });
  document.addEventListener('gesturestart', (e) => e.preventDefault());

  // ---------- helpers ----------

  const cardIdOf = (id) => (state.players.find((p) => p.id === id) || {}).cardId;
  const cardOf = (id) => ZB.card(cardIdOf(id));
  const isDetective = () => state.me && state.me.role === 'detective';

  async function send(event, payload) {
    if (sending) return { ok: false };
    sending = true;
    const r = await ZB.emit(event, payload);
    sending = false;
    if (!r.ok && r.error) ZB.toast(r.error);
    return r;
  }

  function progressLine() {
    const p = state.progress;
    return p ? `<p class="progress-line">${p.done} of ${p.total} suspects done</p>` : '';
  }

  function watch(text) {
    return `<div class="wait"><div class="candle"></div><h2>${text}</h2><p class="muted">Watch the big screen.</p>${progressLine()}</div>`;
  }

  function killerNote(text) {
    return state.me.isKiller ? `<div class="killer-note"><b>🔪 You're the killer.</b> ${text}</div>` : '';
  }

  function header(round, title) {
    return `<div class="phase-head"><div class="eyebrow">Round ${round} of 3 · ${title}</div></div>`;
  }

  // ---------- rendering ----------

  function render() {
    if (ended || !state) return;
    renderBar();
    const k = [state.phase, state.paused, state.canReassign, state.revealStep, state.mine != null, editing,
      state.myPick, state.entries ? state.entries.length : 0, state.lobby ? JSON.stringify(state.lobby) : '', state.me && state.me.cardId, state.rematchVotes].join('|');
    if (k === key) {
      const pl = screen.querySelector('.progress-line');
      if (pl && state.progress) pl.textContent = `${state.progress.done} of ${state.progress.total} suspects done`;
      return;
    }
    key = k;
    screen.innerHTML = (state.paused ? pausedHtml() : '') + screenHtml();
    wire();
  }

  function renderBar() {
    const c = state.me && ZB.card(state.me.cardId);
    const role = state.me && state.me.role
      ? `<span class="chip ${state.me.role === 'detective' ? '' : 'dim'}">${state.me.role === 'detective' ? 'Detective' : 'Suspect'}</span>`
      : '';
    ZB.$('#me').innerHTML = c ? `<img src="${esc(c.avatar)}" alt=""><span class="nm">${esc(c.name)}</span>${role}` : '';
  }

  function pausedHtml() {
    const canAct = state.canReassign && state.me && state.me.isVip;
    return `<div class="paused">Waiting for the Detective to reconnect…
      ${canAct ? '<button class="btn danger sm" data-act="reassign">Deal a new game</button>' : ''}</div>`;
  }

  function screenHtml() {
    switch (state.phase) {
      case 'LOBBY': return lobbyHtml();
      case 'ROLE_REVEAL': return roleHtml();
      case 'INTRO':
        return `<div class="story">${state.intro.map((l) => `<p>${esc(l)}</p>`).join('')}<p class="muted">Watch the big screen.</p></div>`;
      case 'R1_ANSWER': return isDetective() ? detectiveWaiting('Next you pick the answer that fits the scene least.') : r1Html();
      case 'R1_PICK': return isDetective() ? pickHtml('text') : watch('The Detective is choosing…');
      case 'R2_DRAW': return isDetective() ? detectiveWaiting('Next you pick the drawing that is not the weapon.') : r2Html();
      case 'R2_PICK': return isDetective() ? pickHtml('draw') : watch('The Detective is choosing…');
      case 'R3_WORD': return isDetective() ? detectiveWaiting('Then you see every clue, with names, and accuse someone.') : r3Html();
      case 'VERDICT': return isDetective() ? verdictHtml() : watch('The Detective is deliberating…');
      case 'REVEAL': return revealHtml();
      case 'END': return endHtml();
      default: return '';
    }
  }

  function lobbyHtml() {
    const l = state.lobby;
    const need = Math.max(0, l.minPlayers - l.players.length);
    const c = ZB.card(state.me.cardId);
    return `<div class="lobby">
      <h1 class="center">You're in!</h1>
      ${c ? fullCard(c) : ''}
      <a class="btn ghost block" href="/join?code=${code}&pick=1">Change card</a>
      <p class="center muted">${l.players.length} of ${l.maxPlayers} guests seated.${need ? ` Need ${need} more.` : ''}</p>
      ${state.me.isVip
        ? `<button class="btn block" data-act="start" ${l.canStart ? '' : 'disabled'}>Start the dinner party</button><p class="center small muted">You're the VIP: you can start the game.</p>`
        : '<p class="center">Waiting for the host or the VIP to start…</p>'}
    </div>`;
  }

  function fullCard(c) {
    return `<div class="full-card">
      <img src="${esc(c.avatar)}" alt="">
      <div class="fc-body">
        <h2>${esc(c.name)}</h2>
        <p class="fc-title">${esc(c.title)}</p>
        <ul>${c.traits.map((t) => `<li>${esc(t)}</li>`).join('')}</ul>
        <p class="fc-catch">“${esc(c.catchphrase)}”</p>
      </div>
    </div>`;
  }

  function roleHtml() {
    if (isDetective()) {
      return `<div class="role detective">
        <div class="role-icon">🔍</div>
        <div class="eyebrow">Your role</div>
        <h1>You are the DETECTIVE</h1>
        <p>Every suspect saw the murder, except the killer, who saw nothing and must bluff.</p>
        <p>You'll see their answers without names. Find the one that doesn't fit.</p>
      </div>`;
    }
    return `<div class="role suspect">
      <div class="role-icon">🎭</div>
      <div class="eyebrow">Your role</div>
      <h1>You are a SUSPECT</h1>
      <p>You were at the table when it happened. Answer so the Detective can find the liar, and keep it funny.</p>
      <p class="muted">Keep your screen to yourself.</p>
    </div>`;
  }

  function detectiveWaiting(next) {
    const ids = state.suspectIds || [];
    return `<div class="det-wait">
      <div class="wait"><div class="candle"></div><h2>Suspects are answering…</h2>${progressLine()}<p class="muted">${esc(next)}</p></div>
      <div class="eyebrow center">Study the suspects</div>
      <div class="suspect-list">${ids.map((id) => {
        const c = cardOf(id);
        return c ? `<div class="mini"><img src="${esc(c.avatar)}" alt=""><div><b>${esc(c.name)}</b><span>${esc(c.traits[0])}</span></div></div>` : '';
      }).join('')}</div>
    </div>`;
  }

  function submittedHtml(inner) {
    return `<div class="submitted">
      <div class="check">✓</div>
      <h2>Submitted</h2>
      ${inner}
      <button class="btn ghost" data-act="edit">Edit</button>
      ${progressLine()}
    </div>`;
  }

  function r1Html() {
    if (state.mine != null && !editing) return header(1, 'The Scene') + submittedHtml(`<p class="your">“${esc(state.mine)}”</p>`);
    const loc = state.location;
    return `${header(1, 'The Scene')}
      ${loc ? `<p class="saw">You saw it happen in<br><span class="gold big">${esc(loc)}</span></p>` : killerNote("You never saw where it happened. Bluff something that fits anywhere.")}
      <p class="prompt">${esc(state.prompt).replace(esc(loc || 'the crime scene'), `<b>${esc(loc || 'the crime scene')}</b>`)}</p>
      <form class="answer" data-form="text">
        <textarea id="txt" rows="3" maxlength="${state.maxLen}" placeholder="Something normal…" autocomplete="off">${esc(draft || state.mine || '')}</textarea>
        <div class="row"><span class="count" id="count"></span><button class="btn" type="submit">Submit</button></div>
      </form>`;
  }

  function r2Html() {
    if (state.mine != null && !editing) {
      return header(2, 'The Weapon') + submittedHtml(state.mine ? `<img class="your-drawing" src="${state.mine}" alt="">` : '<p class="muted">(blank)</p>');
    }
    return `${header(2, 'The Weapon')}
      ${state.me.isKiller ? killerNote('You never saw the weapon. Draw what you think everyone else is drawing.') : ''}
      <p class="prompt">Draw the murder weapon:<br><span class="gold big">${esc(state.weapon)}</span></p>
      <div id="pad"></div>
      <button class="btn block" data-act="draw-submit">Submit drawing</button>`;
  }

  function r3Html() {
    if (state.mine != null && !editing) return header(3, 'The Silhouette') + submittedHtml(`<p class="your big">${esc(state.mine)}</p>`);
    return `${header(3, 'The Silhouette')}
      ${killerNote("That's you. Describe yourself to blend in, or describe someone else to frame them.")}
      <img class="silhouette" src="${state.silhouette}" alt="The figure you saw">
      <p class="prompt">${esc(state.prompt)}</p>
      <form class="answer" data-form="word">
        <input type="text" id="txt" maxlength="${state.maxLen}" placeholder="One word" autocomplete="off" autocapitalize="off" spellcheck="false" value="${esc(draft || state.mine || '')}">
        <div class="row"><span class="count muted small">No spaces</span><button class="btn" type="submit">Submit</button></div>
      </form>`;
  }

  function pickHtml(kind) {
    const round = kind === 'text' ? 1 : 2;
    if (state.myPick) {
      return `<div class="wait"><div class="check">✓</div><h2>Locked in: ${esc(state.myPick)}</h2><p class="muted">No feedback until the end. Keep a straight face.</p></div>`;
    }
    const q = kind === 'text' ? 'Which answer fits the scene least?' : 'Which drawing is not the weapon?';
    return `${header(round, kind === 'text' ? 'The Scene' : 'The Weapon')}
      <h2 class="q">${q}</h2>
      <div class="choices ${kind}">
        ${state.entries.map((e) => `<button type="button" class="choice ${picked === e.label ? 'on' : ''}" data-pick="${e.label}">
          <span class="label">${e.label}</span>
          ${kind === 'text' ? `<span class="t">${esc(e.text)}</span>` : e.png ? `<img src="${e.png}" alt="">` : '<span class="blank">(blank)</span>'}
        </button>`).join('')}
      </div>
      <div class="sticky"><button class="btn block" data-act="confirm-pick" ${picked ? '' : 'disabled'}>${picked ? `This one doesn't fit: ${picked}` : 'Tap the odd one out'}</button></div>`;
  }

  function verdictHtml() {
    if (state.myPick) {
      const c = cardOf(state.myPick);
      return `<div class="wait"><h2>You accused</h2>${c ? fullCard(c) : ''}<p class="muted">Watch the big screen…</p></div>`;
    }
    return `<div class="phase-head"><div class="eyebrow">The verdict</div></div>
      <h2 class="q">Who did it? Tap a suspect to accuse.</h2>
      <div class="dossier">${state.dossier.map((d) => {
        const c = cardOf(d.playerId);
        if (!c) return '';
        return `<button type="button" class="file ${picked === d.playerId ? 'on' : ''}" data-accuse="${esc(d.playerId)}">
          <div class="file-top"><img src="${esc(c.avatar)}" alt=""><div><b>${esc(c.name)}</b><span>${esc(c.title)}</span>
            <ul>${c.traits.map((t) => `<li>${esc(t)}</li>`).join('')}</ul></div></div>
          <div class="clues">
            <div><span class="eyebrow">Scene</span><p>“${esc(d.r1)}”</p></div>
            <div class="clue-draw">${d.r2 ? `<img src="${d.r2}" alt="">` : '<span class="blank">(blank)</span>'}</div>
            <div><span class="eyebrow">Figure</span><p class="w">${esc(d.r3)}</p></div>
          </div>
        </button>`;
      }).join('')}</div>
      <div class="sticky"><button class="btn danger block" data-act="accuse" ${picked ? '' : 'disabled'}>${picked ? `Accuse ${esc(cardOf(picked).name)}` : 'Tap a suspect'}</button></div>`;
  }

  function myResult(r) {
    if (r.fled) return { win: null, text: 'The killer fled. Nobody wins.' };
    const iAmKiller = state.me.id === r.killerId;
    const win = r.winner === 'killer' ? iAmKiller : !iAmKiller;
    return { win, text: win ? 'You win!' : 'You lose.' };
  }

  function revealHtml() {
    const r = state.reveal;
    const step = state.revealStep;
    if (step === 0) return watch('The killer is…');
    const killer = cardOf(r.killerId);
    const isMe = state.me.id === r.killerId;
    let extra = '';
    if (step >= 5 && r.score) {
      extra = `<div class="mini-score"><div class="eyebrow">Detective score</div><b>${r.score.total} / 3</b><span>${esc(r.score.rank)}</span></div>`;
    }
    return `<div class="reveal">
      <div class="eyebrow center">The killer was</div>
      ${killer ? fullCard(killer) : ''}
      ${isMe ? `<p class="center big gold">That's you!</p>` : ''}
      <p class="center">${r.score && r.score.final ? 'The Detective caught them.' : 'The Detective got it wrong.'}</p>
      ${extra}
      <p class="center muted">Watch the big screen for the replay.</p>
    </div>`;
  }

  function endHtml() {
    const r = state.reveal;
    const res = myResult(r);
    const vip = state.me.isVip;
    return `<div class="end ${res.win === true ? 'win' : res.win === false ? 'lose' : ''}">
      <h1>${esc(res.text)}</h1>
      <p class="center muted">${r.fled ? '' : r.winner === 'detective' ? 'The Detective and the innocent guests won.' : 'The killer got away with it.'}</p>
      ${r.score ? `<p class="center">Detective rank: <b class="gold">${esc(r.score.rank)}</b></p>` : ''}
      ${vip
        ? '<button class="btn block" data-act="rematch">Play again</button><button class="btn ghost block" data-act="lobby">Back to lobby</button>'
        : `<button class="btn block" data-act="vote">I want a rematch</button>`}
      <p class="center small muted">${state.rematchVotes ? `${state.rematchVotes} want a rematch.` : ''}</p>
      <a class="btn ghost block" href="/">Back to index</a>
    </div>`;
  }

  // ---------- actions ----------

  function wire() {
    screen.querySelectorAll('[data-act]').forEach((b) => b.addEventListener('click', () => act(b.dataset.act, b)));

    const form = screen.querySelector('form.answer');
    if (form) {
      const input = form.querySelector('#txt');
      const count = form.querySelector('#count');
      const update = () => {
        if (form.dataset.form === 'word') input.value = input.value.replace(/\s/g, '');
        draft = input.value;
        if (count) count.textContent = `${input.value.length} / ${input.maxLength}`;
      };
      input.addEventListener('input', update);
      update();
      form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const val = input.value.trim();
        if (!val) return ZB.toast(form.dataset.form === 'word' ? 'Write one word.' : 'Write an answer.');
        const r = await send('answer:submit', form.dataset.form === 'word' ? { word: val } : { text: val });
        if (r.ok) { editing = false; key = ''; }
      });
    }

    const padEl = screen.querySelector('#pad');
    if (padEl) {
      pad.mount(padEl);
      if (!pad.ops.length && state.mine && !pad.base) pad.setBase(state.mine);
    }

    screen.querySelectorAll('[data-pick]').forEach((b) => b.addEventListener('click', () => {
      picked = b.dataset.pick;
      screen.querySelectorAll('[data-pick]').forEach((x) => x.classList.toggle('on', x === b));
      const c = screen.querySelector('[data-act="confirm-pick"]');
      c.disabled = false;
      c.textContent = `This one doesn't fit: ${picked}`;
    }));

    screen.querySelectorAll('[data-accuse]').forEach((b) => b.addEventListener('click', () => {
      picked = b.dataset.accuse;
      screen.querySelectorAll('[data-accuse]').forEach((x) => x.classList.toggle('on', x === b));
      const c = screen.querySelector('[data-act="accuse"]');
      c.disabled = false;
      c.textContent = `Accuse ${cardOf(picked).name}`;
    }));
  }

  async function act(name, el) {
    switch (name) {
      case 'start': await send('game:start'); break;
      case 'edit':
        editing = true;
        draft = typeof state.mine === 'string' && !state.mine.startsWith('data:') ? state.mine : '';
        key = '';
        render();
        break;
      case 'draw-submit': {
        if (!pad.hasInk()) return ZB.toast('Draw something first.');
        const r = await send('answer:submit', { png: pad.toPNG() });
        if (r.ok) { pad.dirty = false; editing = false; key = ''; render(); }
        break;
      }
      case 'confirm-pick':
        if (picked) await send('pick:submit', { entryLabel: picked });
        break;
      case 'accuse': {
        if (!picked) return;
        const c = cardOf(picked);
        if (!confirm(`Accuse ${c.name}? This is final.`)) return;
        await send('pick:submit', { suspectId: picked });
        break;
      }
      case 'vote':
        if ((await send('vote:rematch')).ok) { el.disabled = true; el.textContent = 'Vote counted'; }
        break;
      case 'rematch': await send('game:rematch'); break;
      case 'lobby': await send('game:lobby'); break;
      case 'reassign': await send('mdp:reassign'); break;
      default:
    }
  }

  // New phase: reset the per-phase scratch state.
  let lastPhase = null;
  ZB.onState((s) => {
    if (s.phase !== lastPhase) {
      lastPhase = s.phase;
      editing = false;
      draft = '';
      picked = null;
      autoSent = false;
      if (s.phase === 'R2_DRAW') pad.reset();
    }
    state = s;
    render();
  });

  // ---------- clock and auto-submit ----------

  const ANSWER_PHASES = ['R1_ANSWER', 'R2_DRAW', 'R3_WORD'];
  setInterval(() => {
    if (ended || !state) return;
    if (!state.deadline || state.paused) { clock.textContent = ''; return; }
    const left = state.deadline - ZB.now();
    const secs = Math.max(0, Math.ceil(left / 1000));
    clock.textContent = secs;
    clock.classList.toggle('low', secs <= 10);

    // Just before time runs out, send what this suspect has.
    if (left < 1300 && !autoSent && ANSWER_PHASES.includes(state.phase) && !isDetective()) {
      autoSent = true;
      if (state.phase === 'R2_DRAW') {
        if (pad.hasInk() && (state.mine == null || pad.dirty)) ZB.emit('answer:submit', { png: pad.toPNG() });
      } else {
        const val = draft.trim();
        if (val && (state.mine == null || (editing && val !== state.mine))) {
          ZB.emit('answer:submit', state.phase === 'R3_WORD' ? { word: val.replace(/\s/g, '') } : { text: val });
        }
      }
    }
  }, 200);
})();
