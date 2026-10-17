// The intro scene: a long dinner table, the victim face-down at the head,
// and every player's avatar in a chair. Placeholder art until Zach's
// illustration exists; swap in an <image> of the real scene here.

(function () {
  const W = 1600;
  const H = 760;

  function candelabra(x, y) {
    const flames = [-46, 0, 46].map((dx, i) => {
      const cy = y - (i === 1 ? 118 : 92);
      return `<rect x="${x + dx - 6}" y="${cy}" width="12" height="${i === 1 ? 40 : 34}" rx="3" fill="#f3e9d2"/>
        <g class="flame" style="animation-delay:${(x % 7) * 0.13 + i * 0.21}s; transform-origin:${x + dx}px ${cy}px">
          <ellipse cx="${x + dx}" cy="${cy - 12}" rx="7" ry="14" fill="#ffb347"/>
          <ellipse cx="${x + dx}" cy="${cy - 9}" rx="3.5" ry="8" fill="#fff4c2"/>
        </g>`;
    }).join('');
    return `<g>
      <circle cx="${x}" cy="${y - 110}" r="170" fill="url(#glow)"/>
      <ellipse cx="${x}" cy="${y + 4}" rx="34" ry="9" fill="#8a6d1d"/>
      <rect x="${x - 5}" y="${y - 70}" width="10" height="74" fill="#c9a43a"/>
      <path d="M${x - 46} ${y - 56} Q${x - 46} ${y - 30} ${x} ${y - 30} Q${x + 46} ${y - 30} ${x + 46} ${y - 56}" fill="none" stroke="#c9a43a" stroke-width="7"/>
      <rect x="${x - 54}" y="${y - 62}" width="16" height="8" rx="2" fill="#d4af37"/>
      <rect x="${x + 38}" y="${y - 62}" width="16" height="8" rx="2" fill="#d4af37"/>
      <rect x="${x - 8}" y="${y - 82}" width="16" height="8" rx="2" fill="#d4af37"/>
      ${flames}
    </g>`;
  }

  function seat(x, y, cardId, labelBelow, i) {
    const c = ZB.card(cardId);
    if (!c) return '';
    const r = 64;
    const ly = labelBelow ? y + r + 34 : y - r - 18;
    return `<g class="seat" style="animation-delay:${0.25 + i * 0.12}s">
      <rect x="${x - 58}" y="${y - 96}" width="116" height="150" rx="40" fill="#4a1a22" stroke="#2a0d12" stroke-width="4"/>
      <circle cx="${x}" cy="${y}" r="${r + 6}" fill="#d4af37"/>
      <image href="${ZB.esc(c.avatar)}" x="${x - r}" y="${y - r}" width="${2 * r}" height="${2 * r}" clip-path="url(#round)" preserveAspectRatio="xMidYMin slice"/>
      <text x="${x}" y="${ly}" text-anchor="middle" class="seat-name">${ZB.esc(c.name)}</text>
    </g>`;
  }

  function table(cardIds) {
    const n = cardIds.length;
    const top = cardIds.slice(0, Math.ceil(n / 2));
    const bottom = cardIds.slice(Math.ceil(n / 2));
    const xs = (count) => {
      if (count === 1) return [960];
      const a = 600;
      const b = 1360;
      return Array.from({ length: count }, (_, i) => a + ((b - a) * i) / (count - 1));
    };
    const topXs = xs(top.length);
    const botXs = xs(bottom.length);
    // Candelabras stand between the back-row guests so they never cover a face.
    const candleXs = (seats) => (seats.length < 2 ? [800, 1180] : seats.slice(1).map((x, i) => (x + seats[i]) / 2));
    const plates = [...topXs.map((x) => [x, 352]), ...botXs.map((x) => [x, 500])]
      .map(([x, y]) => `<ellipse cx="${x}" cy="${y}" rx="40" ry="14" fill="#fbf7ee" stroke="#cbbf9f" stroke-width="2"/>
        <ellipse cx="${x}" cy="${y}" rx="24" ry="8" fill="#e9dfc7"/>`).join('');

    return `<svg class="scene" viewBox="0 0 ${W} ${H}" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="The victim face-down at the head of the dinner table, with every guest seated around it">
      <defs>
        <radialGradient id="glow"><stop offset="0" stop-color="#ffb347" stop-opacity=".35"/><stop offset="1" stop-color="#ffb347" stop-opacity="0"/></radialGradient>
        <linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1e120c"/><stop offset="1" stop-color="#0d0806"/></linearGradient>
        <linearGradient id="cloth" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f4ecd8"/><stop offset="1" stop-color="#dccfae"/></linearGradient>
        <clipPath id="round" clipPathUnits="objectBoundingBox"><circle cx=".5" cy=".5" r=".5"/></clipPath>
      </defs>
      <rect width="${W}" height="${H}" fill="url(#wall)"/>
      <g opacity=".5">${Array.from({ length: 16 }, (_, i) => `<rect x="${i * 100 + 20}" y="40" width="60" height="150" rx="6" fill="none" stroke="#3a2618" stroke-width="3"/>`).join('')}</g>

      <!-- back row of guests -->
      ${top.map((id, i) => seat(topXs[i], 250, id, false, i)).join('')}

      <!-- the table -->
      <rect x="300" y="318" width="1160" height="210" rx="34" fill="url(#cloth)"/>
      <path d="M300 500 h1160 v58 ${Array.from({ length: 29 }, (_, i) => `q-20 18 -40 0`).join(' ')} z" fill="#d4c7a6"/>
      <rect x="300" y="404" width="1160" height="14" fill="#a3242a" opacity=".85"/>
      ${plates}
      ${candleXs(topXs).map((x) => candelabra(x, 470)).join('')}

      <!-- the victim, slumped at the head of the table -->
      <g class="victim">
        <path d="M140 170 Q150 120 215 118 Q280 120 290 170 L300 640 L130 640 Z" fill="#6b1420" stroke="#d4af37" stroke-width="6"/>
        <path d="M168 560 C170 470 210 430 300 420 L390 418 L392 470 L300 480 C260 490 250 520 252 560 Z" fill="#1d1f26"/>
        <path d="M300 420 C330 400 370 396 400 404 L404 440 L300 460 Z" fill="#1d1f26"/>
        <ellipse cx="420" cy="430" rx="62" ry="22" fill="#fbf7ee" stroke="#cbbf9f" stroke-width="2"/>
        <ellipse cx="420" cy="428" rx="40" ry="13" fill="#d98b3a"/>
        <ellipse cx="408" cy="410" rx="44" ry="36" fill="#f0c9a8"/>
        <path d="M368 400 Q372 432 404 440 Q380 428 376 400 Z" fill="#cfcfcf"/>
        <path d="M448 396 Q446 430 420 440 Q440 426 440 396 Z" fill="#cfcfcf"/>
        <path d="M392 470 C440 474 500 476 560 470 L562 488 C500 494 440 494 392 490 Z" fill="#1d1f26"/>
        <ellipse cx="572" cy="479" rx="14" ry="11" fill="#f0c9a8"/>
        <path d="M600 470 l40 -26 l6 8 l-40 26 z" fill="#c9a43a"/>
        <ellipse cx="650" cy="470" rx="70" ry="16" fill="#7a0f1c" opacity=".85"/>
        <path d="M610 452 l26 -10 l14 18 l-26 10 z" fill="#ffffff" opacity=".7"/>
        <g transform="translate(486 356) rotate(-24)">
          <rect x="-30" y="-56" width="60" height="56" fill="#16171b"/>
          <ellipse cx="0" cy="0" rx="48" ry="10" fill="#16171b"/>
          <rect x="-30" y="-16" width="60" height="9" fill="#5a1a1a"/>
        </g>
      </g>

      <!-- front row of guests -->
      ${bottom.map((id, i) => seat(botXs[i], 640, id, true, i + top.length)).join('')}
    </svg>`;
  }

  window.MDPScene = { table };
})();
