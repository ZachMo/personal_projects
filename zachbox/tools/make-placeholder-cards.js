// Draws the 8 placeholder cards for Murder Dinner Party.
// Each character is a list of SVG shapes. The avatar draws them in colour;
// the silhouette draws the same shapes in black, minus small face details,
// so the silhouette is always a true outline of the avatar.
//
//   node tools/make-placeholder-cards.js
//
// Writes games/murder-dinner-party/cards/*.svg and cards.json.

const fs = require('fs');
const path = require('path');

const OUT = path.join(__dirname, '..', 'games', 'murder-dinner-party', 'cards');
const URL_BASE = '/games/murder-dinner-party/cards';

// Shared body parts. `skin`, `outfit` are filled in per character.
const head = (skin) => ({ el: 'ellipse', a: { cx: 100, cy: 118, rx: 32, ry: 38, fill: skin } });
const neck = (skin) => ({ el: 'rect', a: { x: 88, y: 146, width: 24, height: 26, fill: skin } });
const body = (outfit) => ({ el: 'path', a: { d: 'M28 240 C28 186 58 166 100 166 C142 166 172 186 172 240 Z', fill: outfit } });
const eyes = [
  { el: 'circle', a: { cx: 88, cy: 114, r: 3.6, fill: '#1b1410' }, detail: true },
  { el: 'circle', a: { cx: 112, cy: 114, r: 3.6, fill: '#1b1410' }, detail: true },
];
const smile = { el: 'path', a: { d: 'M88 136 Q100 144 112 136', fill: 'none', stroke: '#1b1410', 'stroke-width': 3, 'stroke-linecap': 'round' }, detail: true };

const characters = [
  {
    id: 'dolores-vance',
    name: 'Madame Dolores Vance',
    title: 'Retired magician with a lisp',
    traits: ['Enormous feathered hat', 'Pulls scarves from her sleeves when nervous', "Was the victim's secret lover"],
    catchphrase: 'Thith ith a mithunderthtanding.',
    bg: '#3a1838',
    shapes: [
      { el: 'ellipse', a: { cx: 68, cy: 132, rx: 11, ry: 26, fill: '#9b2d1e' } },
      { el: 'ellipse', a: { cx: 132, cy: 132, rx: 11, ry: 26, fill: '#9b2d1e' } },
      body('#6b2d6b'), neck('#f0c9a8'), head('#f0c9a8'), ...eyes,
      { el: 'path', a: { d: 'M90 134 Q100 142 110 134 Q100 138 90 134 Z', fill: '#b0283a' }, detail: true },
      { el: 'path', a: { d: 'M118 62 C136 22 166 6 194 2 C182 22 162 46 134 72 Z', fill: '#f2c4f0' } },
      { el: 'rect', a: { x: 64, y: 46, width: 72, height: 42, rx: 14, fill: '#56205a' } },
      { el: 'rect', a: { x: 64, y: 74, width: 72, height: 8, fill: '#d4af37' } },
      { el: 'ellipse', a: { cx: 100, cy: 88, rx: 76, ry: 12, fill: '#6b2d6b' } },
    ],
  },
  {
    id: 'barnaby-mustardseed',
    name: 'Colonel Barnaby Mustardseed',
    title: 'Hero of a war nobody remembers',
    traits: ['Handlebar mustache wider than his shoulders', 'Salutes the soup before eating it', 'Never actually served'],
    catchphrase: 'In my day, we murdered with RESPECT.',
    bg: '#3a2a12',
    shapes: [
      body('#a3242a'),
      { el: 'ellipse', a: { cx: 46, cy: 184, rx: 20, ry: 7, fill: '#d4af37' } },
      { el: 'ellipse', a: { cx: 154, cy: 184, rx: 20, ry: 7, fill: '#d4af37' } },
      neck('#e8b894'), head('#e8b894'), ...eyes,
      { el: 'path', a: { d: 'M100 134 C80 126 60 142 36 128 C28 122 28 112 36 108 C34 120 46 126 58 124 C74 120 88 122 100 126 C112 122 126 120 142 124 C154 126 166 120 164 108 C172 112 172 122 164 128 C140 142 120 126 100 134 Z', fill: '#d9a441' } },
      { el: 'path', a: { d: 'M56 94 C56 46 144 46 144 94 Z', fill: '#d8c69a' } },
      { el: 'ellipse', a: { cx: 100, cy: 94, rx: 56, ry: 9, fill: '#c4b183' } },
    ],
  },
  {
    id: 'tiffany-sparkle',
    name: 'Tiffany Sparkle-Pants',
    title: 'Influencer, 40 followers',
    traits: ['Beehive hairdo taller than a toddler', 'Hoop earrings you could juggle', 'Livestreamed the soup course'],
    catchphrase: "Don't forget to like and subscribe to my alibi.",
    bg: '#3b1430',
    shapes: [
      { el: 'ellipse', a: { cx: 100, cy: 52, rx: 38, ry: 50, fill: '#f2c94c' } },
      body('#e05aa8'), neck('#f6d3b8'), head('#f6d3b8'),
      { el: 'path', a: { d: 'M68 108 C66 80 134 80 132 108 C120 92 80 92 68 108 Z', fill: '#f2c94c' } },
      { el: 'rect', a: { x: 76, y: 106, width: 20, height: 13, rx: 5, fill: '#ff7ac6' }, detail: true },
      { el: 'rect', a: { x: 104, y: 106, width: 20, height: 13, rx: 5, fill: '#ff7ac6' }, detail: true },
      { el: 'rect', a: { x: 95, y: 110, width: 10, height: 3, fill: '#ff7ac6' }, detail: true },
      smile,
      { el: 'circle', a: { cx: 64, cy: 146, r: 13, fill: 'none', stroke: '#d4af37', 'stroke-width': 4 } },
      { el: 'circle', a: { cx: 136, cy: 146, r: 13, fill: 'none', stroke: '#d4af37', 'stroke-width': 4 } },
    ],
  },
  {
    id: 'mortimer-gloom',
    name: 'Reverend Mortimer Gloom',
    title: 'Undertaker who brings his own coffin to parties',
    traits: ['Absurdly tall top hat', 'Never without his silver-tipped cane', 'Measured everyone for a coffin on arrival'],
    catchphrase: 'I simply had a feeling about tonight.',
    bg: '#1c2230',
    shapes: [
      { el: 'rect', a: { x: 170, y: 118, width: 8, height: 122, fill: '#6b4a2b' } },
      { el: 'path', a: { d: 'M174 122 C174 98 200 98 200 116', fill: 'none', stroke: '#c0c0c0', 'stroke-width': 8, 'stroke-linecap': 'round' } },
      body('#22252c'), neck('#d9d4c7'),
      { el: 'ellipse', a: { cx: 100, cy: 122, rx: 30, ry: 42, fill: '#d9d4c7' } },
      ...eyes,
      { el: 'path', a: { d: 'M90 142 L110 142', stroke: '#1b1410', 'stroke-width': 3, 'stroke-linecap': 'round' }, detail: true },
      { el: 'rect', a: { x: 70, y: 0, width: 60, height: 84, fill: '#16171b' } },
      { el: 'rect', a: { x: 70, y: 66, width: 60, height: 9, fill: '#5a1a1a' } },
      { el: 'ellipse', a: { cx: 100, cy: 84, rx: 50, ry: 8, fill: '#16171b' } },
    ],
  },
  {
    id: 'pierre-crouton',
    name: 'Chef Pierre Croûton',
    title: 'Cooked the dinner, regrets nothing',
    traits: ['Puffy chef hat like a cloud', 'Insults the guests in French', 'Was fired by the victim an hour ago'],
    catchphrase: 'Ze soup was perfect. Ze man was not.',
    bg: '#3a2410',
    shapes: [
      body('#f4f1ea'),
      { el: 'path', a: { d: 'M84 166 L100 186 L116 166 Z', fill: '#c0392b' } },
      neck('#eebd96'), head('#eebd96'), ...eyes,
      { el: 'path', a: { d: 'M100 130 C90 124 80 132 72 126 C70 132 80 138 90 134 C95 132 98 132 100 132 C102 132 105 132 110 134 C120 138 130 132 128 126 C120 132 110 124 100 130 Z', fill: '#3b2416' } },
      { el: 'rect', a: { x: 72, y: 54, width: 56, height: 34, fill: '#ffffff' } },
      { el: 'circle', a: { cx: 76, cy: 52, r: 22, fill: '#ffffff' } },
      { el: 'circle', a: { cx: 100, cy: 38, r: 27, fill: '#ffffff' } },
      { el: 'circle', a: { cx: 124, cy: 52, r: 22, fill: '#ffffff' } },
      { el: 'rect', a: { x: 70, y: 80, width: 60, height: 10, rx: 3, fill: '#e6e1d6' } },
    ],
  },
  {
    id: 'gertrude-barnacle',
    name: 'Captain Gertrude Barnacle',
    title: 'Sea captain with a very opinionated parrot',
    traits: ['Pirate hat and eyepatch', 'A parrot named Lawyer on her shoulder', 'The parrot knows everything'],
    catchphrase: "Lawyer says I'm innocent. SQUAWK.",
    bg: '#10283a',
    shapes: [
      body('#1f3b5c'), neck('#d9a77e'), head('#d9a77e'),
      { el: 'circle', a: { cx: 112, cy: 114, r: 3.6, fill: '#1b1410' }, detail: true },
      { el: 'path', a: { d: 'M70 100 L130 122', stroke: '#111', 'stroke-width': 3 }, detail: true },
      { el: 'ellipse', a: { cx: 88, cy: 114, rx: 9, ry: 8, fill: '#111' }, detail: true },
      smile,
      { el: 'path', a: { d: 'M150 150 C172 172 168 200 158 214 L150 196 Z', fill: '#2e8b3a' } },
      { el: 'ellipse', a: { cx: 152, cy: 156, rx: 15, ry: 24, fill: '#3fbf4f' } },
      { el: 'circle', a: { cx: 154, cy: 128, r: 12, fill: '#e74c3c' } },
      { el: 'path', a: { d: 'M164 124 L178 132 L164 136 Z', fill: '#f1c40f' } },
      { el: 'path', a: { d: 'M40 94 C58 58 80 50 100 48 C120 50 142 58 160 94 C140 82 120 80 100 82 C80 80 60 82 40 94 Z', fill: '#2b2118' } },
      { el: 'circle', a: { cx: 100, cy: 66, r: 7, fill: '#f4f1ea' }, detail: true },
    ],
  },
  {
    id: 'ignatius-quill',
    name: 'Professor Ignatius Quill',
    title: 'Scientist, expelled from 3 universities',
    traits: ['Hair like he licked a socket', 'Enormous round spectacles', 'Has a formula for the perfect murder'],
    catchphrase: 'Statistically, it was one of YOU.',
    bg: '#16301e',
    shapes: [
      { el: 'path', a: { d: 'M60 122 L40 108 L56 96 L34 80 L58 76 L44 50 L72 60 L72 30 L92 52 L100 22 L110 52 L130 28 L130 60 L158 48 L144 76 L168 80 L146 96 L162 108 L140 122 Z', fill: '#e8e8e8' } },
      body('#7a6a4f'), neck('#efc7a4'), head('#efc7a4'),
      { el: 'circle', a: { cx: 82, cy: 116, r: 19, fill: 'rgba(200,230,255,.35)', stroke: '#3a2a1a', 'stroke-width': 5 } },
      { el: 'circle', a: { cx: 118, cy: 116, r: 19, fill: 'rgba(200,230,255,.35)', stroke: '#3a2a1a', 'stroke-width': 5 } },
      { el: 'circle', a: { cx: 82, cy: 116, r: 4, fill: '#1b1410' }, detail: true },
      { el: 'circle', a: { cx: 118, cy: 116, r: 4, fill: '#1b1410' }, detail: true },
      { el: 'path', a: { d: 'M100 172 L78 160 L78 184 Z M100 172 L122 160 L122 184 Z', fill: '#c0392b' } },
    ],
  },
  {
    id: 'valentina-vex',
    name: 'Countess Valentina Vex',
    title: 'Aristocrat, widowed seven times',
    traits: ['Gigantic frilled collar', 'Tiara she claims is "only borrowed"', 'Every husband died at dinner'],
    catchphrase: 'Darling, I was merely holding the knife.',
    bg: '#2a0f1a',
    shapes: [
      { el: 'path', a: { d: 'M40 176 C10 130 26 70 52 72 C60 60 74 64 78 76 L100 160 L122 76 C126 64 140 60 148 72 C174 70 190 130 160 176 Z', fill: '#e8dfd0' } },
      { el: 'path', a: { d: 'M70 110 C60 150 64 190 74 200 L84 120 Z M130 110 C140 150 136 190 126 200 L116 120 Z', fill: '#2b1a10' } },
      body('#7a1030'), neck('#f3d6c1'), head('#f3d6c1'), ...eyes,
      { el: 'path', a: { d: 'M90 136 Q100 141 110 136', fill: 'none', stroke: '#8b0020', 'stroke-width': 3 }, detail: true },
      { el: 'path', a: { d: 'M68 100 C70 72 130 72 132 100 C118 86 82 86 68 100 Z', fill: '#2b1a10' } },
      { el: 'path', a: { d: 'M72 88 L78 62 L88 80 L100 48 L112 80 L122 62 L128 88 Z', fill: '#d4af37' } },
    ],
  },
];

function attrs(a, sil) {
  return Object.entries(a)
    .map(([k, v]) => {
      if (sil && (k === 'fill' || k === 'stroke') && v !== 'none') v = '#111';
      return `${k}="${v}"`;
    })
    .join(' ');
}

function svg(ch, sil) {
  const parts = [];
  parts.push(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 240" width="400" height="480">`);
  if (sil) parts.push(`<rect width="200" height="240" fill="#e9dfc7"/>`);
  else parts.push(`<rect width="200" height="240" fill="${ch.bg}"/><circle cx="100" cy="110" r="96" fill="#ffffff" opacity=".06"/>`);
  for (const s of ch.shapes) {
    if (sil && s.detail) continue;
    parts.push(`<${s.el} ${attrs(s.a, sil)}/>`);
  }
  parts.push('</svg>');
  return parts.join('\n');
}

fs.mkdirSync(OUT, { recursive: true });
const cards = [];
for (const ch of characters) {
  fs.writeFileSync(path.join(OUT, `${ch.id}.svg`), svg(ch, false));
  fs.writeFileSync(path.join(OUT, `${ch.id}-sil.svg`), svg(ch, true));
  cards.push({
    id: ch.id,
    name: ch.name,
    title: ch.title,
    traits: ch.traits,
    catchphrase: ch.catchphrase,
    avatar: `${URL_BASE}/${ch.id}.svg`,
    silhouette: `${URL_BASE}/${ch.id}-sil.svg`,
  });
}
fs.writeFileSync(path.join(OUT, 'cards.json'), JSON.stringify(cards, null, 2) + '\n');
console.log(`Wrote ${cards.length} cards to ${OUT}`);
