// Zachbox Games: the host-screen lobby every game shares.
// Room code, QR code, the card grid filling in, and the Start button.
//
//   ZBHostLobby.render(el, { state, room, title, tagline, howTo, onStart })

(function () {
  let seated = new Set();

  function render(el, { state, room, title, tagline, howTo, onStart }) {
    const lobby = state.lobby;
    const byCard = new Map(lobby.players.map((p) => [p.cardId, p]));
    const count = lobby.players.length;
    const need = Math.max(0, lobby.minPlayers - count);
    const joinHost = room.joinUrl.replace(/^https?:\/\//, '').replace(/\?.*$/, '');

    const cards = ZB.cardList().map((c) => {
      const p = byCard.get(c.id);
      const isNew = p && !seated.has(c.id);
      const chips = p
        ? `${p.isVip ? '<span class="chip">VIP</span>' : ''}${p.connected ? '' : '<span class="chip red">Away</span>'}`
        : '<span class="chip dim">Open seat</span>';
      return `<div class="lobby-seat ${p ? 'taken' : 'open'} ${isNew ? 'just' : ''}">
        ${ZB.cardHtml(c.id, { html: `<div class="seat-chips">${chips}</div>` })}
      </div>`;
    }).join('');
    seated = new Set(lobby.players.map((p) => p.cardId));

    el.innerHTML = `
      <div class="lobby">
        <div class="lobby-left">
          <div class="eyebrow">Zachbox Games presents</div>
          <h1 class="lobby-title">${ZB.esc(title)}</h1>
          <p class="lobby-tag">${ZB.esc(tagline)}</p>
          <div class="lobby-join panel">
            <div class="lobby-qr"><img src="${room.qr}" alt="QR code to join"></div>
            <div class="lobby-how">
              <div class="eyebrow">On your phone</div>
              <div class="lobby-url">${ZB.esc(joinHost)}</div>
              <div class="eyebrow" style="margin-top:0.8rem">Room code</div>
              <div class="lobby-code">${ZB.esc(state.code)}</div>
            </div>
          </div>
          ${howTo ? `<ol class="lobby-rules">${howTo.map((h) => `<li>${h}</li>`).join('')}</ol>` : ''}
        </div>
        <div class="lobby-right">
          <div class="lobby-head">
            <h2>The guest list</h2>
            <span class="lobby-count">${count} / ${lobby.maxPlayers}</span>
          </div>
          <div class="lobby-grid">${cards}</div>
          <div class="lobby-start">
            <button class="btn" id="lobbyStart" ${lobby.canStart ? '' : 'disabled'}>Start the dinner party</button>
            <span class="muted">${need ? `Need ${need} more guest${need === 1 ? '' : 's'} to start.` : 'Everyone in? The host or the VIP can start.'}</span>
          </div>
        </div>
      </div>`;
    el.querySelector('#lobbyStart').addEventListener('click', onStart);
  }

  window.ZBHostLobby = { render };
})();
