// Zachbox Games: the socket and small helpers every page shares.
// Exposes window.ZB.

(function () {
  const socket = window.io ? window.io({ transports: ['websocket', 'polling'] }) : null;
  let offset = 0;
  const cards = new Map();
  const stateHandlers = [];

  const ZB = {
    socket,

    // Emit and wait for the server's reply. Resolves { ok:false } on timeout.
    emit(event, data) {
      return new Promise((resolve) => {
        if (!socket) return resolve({ ok: false, error: 'Not connected.' });
        socket.timeout(8000).emit(event, data || {}, (err, res) => {
          resolve(err ? { ok: false, error: 'The server did not answer. Check your connection.' } : res || { ok: false });
        });
      });
    },

    // Server time, so every screen counts down to the same deadline.
    now: () => Date.now() + offset,
    secondsLeft(deadline) {
      if (!deadline) return null;
      return Math.max(0, Math.ceil((deadline - ZB.now()) / 1000));
    },

    onState(fn) { stateHandlers.push(fn); },

    // Reconnect tokens live in this browser only.
    getToken(code) { try { return localStorage.getItem('zb:token:' + code); } catch { return null; } },
    setToken(code, token) { try { localStorage.setItem('zb:token:' + code, token); } catch {} },
    getHostToken(code) { try { return localStorage.getItem('zb:host:' + code); } catch { return null; } },
    setHostToken(code, token) { try { localStorage.setItem('zb:host:' + code, token); } catch {} },

    setCards(list) { cards.clear(); for (const c of list || []) cards.set(c.id, c); },
    card(id) { return cards.get(id); },
    cardList() { return [...cards.values()]; },

    esc(s) {
      return String(s == null ? '' : s).replace(/[&<>"']/g, (ch) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch]));
    },

    $(sel, root) { return (root || document).querySelector(sel); },

    toast(msg, ms) {
      document.querySelectorAll('.toast').forEach((t) => t.remove());
      const t = document.createElement('div');
      t.className = 'toast';
      t.textContent = msg;
      document.body.appendChild(t);
      setTimeout(() => t.remove(), ms || 3200);
    },

    // Keep a phone's screen on during the game, where the browser allows it.
    async keepAwake() {
      if (!('wakeLock' in navigator)) return;
      try {
        if (ZB._lock && !ZB._lock.released) return;
        ZB._lock = await navigator.wakeLock.request('screen');
      } catch {}
    },

    cardHtml(cardId, extra) {
      const c = cards.get(cardId);
      if (!c) return '';
      return `<div class="pcard ${extra && extra.cls ? extra.cls : ''}">
        <img class="avatar" src="${ZB.esc(c.avatar)}" alt="">
        <div class="pname">${ZB.esc(c.name)}</div>
        <div class="ptitle">${ZB.esc(c.title)}</div>
        ${extra && extra.html ? extra.html : ''}
      </div>`;
    },
  };

  if (socket) {
    socket.on('state:update', (state) => {
      if (state.serverNow) offset = state.serverNow - Date.now();
      for (const fn of stateHandlers) fn(state);
    });
  }

  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible' && ZB._wantAwake) ZB.keepAwake();
  });

  window.ZB = ZB;
})();
