/*
  Plays First Town in Node with the web version's own rules and writes the results as a Swift test fixture.

    node Tools/make-web-fixtures.js

  The app is free to grow its own rules. These fixtures pin the port to the web version at the time it was made:
  when the app's rules change on purpose, regenerate them from a web version with the same rules, or drop the test.
*/
const fs = require("fs");
const path = require("path");

const html = fs.readFileSync(path.join(__dirname, "../../../hugelland.html"), "utf8");
const logic = html.split('<script id="logic">')[1].split("</script>")[0];

const out = eval(logic + `
(() => {
  const LETTER = { grass: "g", forest: "f", ore: "o", wheat: "w", herd: "h", water: "~" };
  const seeds = [0, 1, 7, 42, 424242, 2147483647];
  for (let i = 1; seeds.length < 60; i++) seeds.push(Math.imul(i, 2654435761) >>> 1);
  return seeds.map(seed => {
    newGame("bot", 0, seed);
    const map = MAP.map(t => LETTER[t]).join("");
    const deck = G.deck.slice();
    const moves = [];
    // The bot takes the spot where the building scores most on its own, and the first such spot on a tie.
    while (!G.over) {
      let best = null, bv = -1e9;
      for (const o of placements(current())) {
        const v = sumParts(scoreParts(current(), o.cells));
        if (v > bv) { bv = v; best = o; }
      }
      const r = build(best.cells);
      moves.push({ t: r.type, c: best.cells, p: r.pts, g: r.gain, tr: r.trophies });
    }
    return { seed, map, deck, moves, total: total(), away: G.away, scores: G.pieces.map((_, k) => pieceScore(k)) };
  });
})()`);

const swift = `// Made by Tools/make-web-fixtures.js from hugelland.html. Don't edit by hand.

enum WebFixtures {
    static let json = #"""
${JSON.stringify(out)}
"""#
}
`;
fs.writeFileSync(path.join(__dirname, "../Tests/FirstTownCoreTests/WebFixtures.swift"), swift);
console.log("wrote", out.length, "games,", out.reduce((s, g) => s + g.moves.length, 0), "moves");
