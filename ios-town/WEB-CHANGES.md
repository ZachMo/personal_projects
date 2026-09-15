# Web changes not yet in the iOS app

The iOS app started from `first-town.html` at commit `67cc7e4`. This log lists every change to the
browser version since then that the app does not have yet, newest first. When a change is ported,
move it to **Ported** at the bottom with the Swift commit that brought it over.

`WebParityTests` still pins the app to `67cc7e4`. When rules are ported, regenerate the fixtures
with `node FirstTownCore/Tools/make-web-fixtures.js` from a web version with the same rules, or the
parity tests will fail.

## Waiting

### `89a5e57` — no zoom on phones, fewer copies, one land rule

**One land rule instead of on and beside.** The rule kinds `on` and `by` merge into one, `land`. A
land bonus counts that land under the building plus the open land next to it, set when the building
goes up, and water under a bridge still counts. `once` still caps it at one.

* `Library.swift`: replace `Rule.Kind.on` and `.by` with `.land`, and `Rule.on`/`Rule.by` with one
  `Rule.land(_:_:once:)`. `isLand` covers `.land` and `.edge`.
* `Game.evaluate`: `n = on[t] + by[t]`, then `once` caps it.
* Every `on` and `by` rule becomes `land` with the same points, except these, which changed:

| Building | Before | Now |
|---|---|---|
| Farm | +3 each square on wild wheat | +2 each wild wheat square on or next to it |
| Ranch | +2 on herd, +1 on open grass | +2 each herd square on or next to it; grass rule gone. Blurb: "Round up a herd and sell to the shops." |
| Lumber Mill | +2 each woods square beside | +1 each woods square on or next to it |
| Mine | +4 each square on ore | +3 each ore square on or next to it |
| Orchard | +1 on open grass, +2 beside water, +1 each home | +2 if on or next to water, +1 each home, **+1 each food building** |
| Vineyard | +1 on open grass, +2 each leisure | **+1 each ore square on or next to it**, +2 each leisure. Blurb: "Grapes like rocky ground. Wine for the saloons and hotels." |
| Stables | +2 each herd square beside | +1 each herd square on or next to it |
| Granary | +2 each square on wild wheat | +1 each wild wheat square on or next to it |
| Gold Sluice | +3 each square on ore | +2 each ore square on or next to it |
| Stamp Mill | +2 each ore square beside | +1 each ore square on or next to it |
| Tannery | +2 each herd square beside | +1 each herd square on or next to it |
| Racetrack | +1 on open grass, +2 each herd square beside, +2 each leisure | +1 each herd square on or next to it, +2 each leisure. Blurb: "Horses from the herds, and a crowd from the saloons." |
| Courthouse | +1 on open grass | **+2 if on or next to water** |
| Bridge, Covered Bridge | +3 each square on water | +1 each water square on or next to it |

No rule scores for open grass any more.

**Words and cards.**

* `Words.rule`: `"each woods square on or next to it"`, or `"if on or next to water"` with `once`.
* `Words.part`: `"3 woods on or next to it"`, `"On or next to water"`, `"Not next to water"`.
* `Words.caresAbout` returns one list, not `on` and `by`.
* `InfoCard.land`: one section, "Scores on it or next to it", with "each square" or "once". Drop
  the note about covered land keeping its points.
* `RuleIcon`: one land icon, the land colour with a white house. Drop the ring icon.
* `HowToPlay`: drop the lines that explain on, beside and next to, and that land bonuses are kept.
  Add: "Land bonuses count that land under a building or next to it."

**Trophies.**

* Add `Trophy.rich`, "Rich land", after `.perfect`: one land bonus counting 5 squares or more.
* Triple, Quadruple and Combo count neighbour bonuses only (`near`, `town`, `variety`), not land.
* Perfect ground: every square of the building sits on a land its `land` rules want.
* Wasted land reads `land` rules for what a building uses.
* Good neighbour needs 3 buildings raised, not 2.

**Fewer copies in a deck.** `DeckMaker`'s fill loop changes. A kind of home can go up to 3 copies;
anything else no further than its `count`. While the deck is short of its target, it draws `r() < 0.4`:
on true it adds a copy of a kind already chosen that is under its cap; otherwise it adds a new kind
(not a bridge, not chosen yet, no bigger than the gap plus one). If the draw finds nothing it tries a
copy, and if that finds nothing too it stops. Copy the web version's order of draws exactly if the
parity tests should keep passing.

**Not needed on iOS.** `touch-action: manipulation`, blocking pinch zoom, and the 16px name field only
fix Safari zooming. `LINK_VERSION` moved to 4, but the app has no challenge links.

## Ported

Nothing yet.
