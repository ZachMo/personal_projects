# Web changes not yet in the iOS app

The iOS app started from `first-town.html` at commit `67cc7e4`. This log lists every change to the
browser version since then that the app does not have yet, newest first. When a change is ported,
move it to **Ported** at the bottom with the Swift commit that brought it over.

`WebParityTests` still pins the app to `67cc7e4`. When rules are ported, regenerate the fixtures
with `node FirstTownCore/Tools/make-web-fixtures.js` from a web version with the same rules, or the
parity tests will fail.

## Waiting

### Trains, wagons, races, plaza benches and a saloon sign

Commit: "First Town: trains, wagons, races, plaza benches, saloon sign", after "First Town: districts, coloured lots, distinct buildings".

All drawn every frame, like the other moving parts, with a per-building phase from a hash.

* **Trains.** The Train Station and Freight Yard run a route along their `rail` squares: the straight line
  through them, the length of the building. A train shows only on `rail` squares, inset .09, so it slips under
  the station hall. On a 16-second cycle it pulls in (3.5 s, slowing), waits (6.5 s), pulls out (3.5 s,
  speeding up), and is gone for 2.5 s. The next train comes the other way. The station gets an engine and 4
  green coaches, so the ends show at the platforms while it waits. The freight yard gets an engine and 2
  boxcars. The engine puffs steam where it can be seen, more while moving. The static boxcar is gone
  (`extra: "boxcar"` removed).
* **Wagons.** Bridge and Covered Bridge run the same route along their `deck` squares. A covered wagon
  pulled by a dark horse crosses in 6 s, then the deck is empty for 5 s, and the next one comes the other way.
  The Covered Bridge's roof hides it in the middle.
* **Races.** The racetrack's two dots become a checkered finish line on the right of the track. On an
  18-second cycle, three horses with red, blue and yellow jockeys run two laps in 11 s, in lanes .1 apart,
  easing in and out, with a small lead that changes each race and closes at the line. Dust kicks up behind them.
  Then they rest at the line.
* `horse()` takes a size.
* **Plaza.** Four benches face the fountain, one on each side at .6 from its middle, with a lamp post on each
  corner between them.
* **Saloon sign.** `sign: "SALOON"`. A `front` roof with a sign gets a taller false front (up to .34, or .55 of
  the roof) with a cream board and the word in dark red, `900` Rockwell or a serif, shrunk to fit. When the
  building stands upright, the board runs up the roof and the word reads bottom to top.
### Districts, coloured lots and more distinct buildings

Commit: "First Town: districts, coloured lots, distinct buildings", after "Tapping land only names it".

**Districts.** Buildings of one category that share a side form a district, and so do the buildings those
touch. Bridges belong to no district. Each building scores +1 for every other building in its district, up
to `DISTRICT_MAX = 4`. Scores stay live, so every building in a district gains when it grows.

* `Game`: add `touching(cells, self)` and `districtOf(type, cells, self)` (a flood fill over same-category,
  non-bridge buildings). `scoreParts` puts a district part right after base: `r: "district"`, `n` is the
  district size counting itself, `v = min(n - 1, 4)`. Bridges get no district part.
* `Words`: the card row reads "+1 each other home in its district, up to +4". A built building's row reads
  "District of 5 homes", or "Not in a district". `HowToPlay` gets: "Districts: buildings of one kind that
  touch share a lot. Each gains +1 for every other building on it, up to +4."
* `RuleIcon`: a district icon, three squares in the category colour on one pale lot.

**Same-category neighbour rules are gone,** because the district now rewards them:

| Building | Before | Now |
|---|---|---|
| Lumber Mill | +1 each industry next to it | +1 each shop next to it |
| Mine | base 1, +1 each industry next to it | base 2, rule gone |
| Blacksmith | +2 each industry next to it | +2 each food building next to it. Blurb: "Tools for the farms, shoes for the herds." |
| Saloon | +1 each leisure next to it | rule gone |
| Hotel | +2 each leisure, +1 each shop | +2 each shop. Blurb: "Travellers want a view and a store." |
| Orchard | +1 each food building | +1 each shop. Blurb: "Apples for the homes and the shops." |
| Gristmill | +2 each food building | +2 each shop. Blurb: "A water wheel grinds flour for the shops." |
| Windmill | base 1, +2 each food building | base 2, rule gone |
| Gold Sluice | +1 each industry | rule gone |
| Stamp Mill | +1 each ore square, +2 each industry | +2 each ore square, industry rule gone |
| Charcoal Kiln | base 1, +1 each industry | base 2, rule gone |
| Freight Yard | +2 each industry | +2 each shop. Blurb: "Loads goods for the shops at the edge of town." |
| Bank | +2 each shop, +1 each civic | +2 each civic, +1 each home. Blurb: "Holds the town's gold. Wants the law and rich families close by." |
| Library | +2 each civic | +1 each home. Blurb: "Needs quiet, trees and families to read." |
| Jail | +3 each civic | +2 each leisure. Blurb: "Close to the saloons, at the edge of town." |
| Cemetery | +2 each civic | +2 if no leisure or industry next to it. Blurb: "Quiet ground by the trees, away from the noise." |
| Courthouse | +2 each civic, +1 each shop | +2 each shop |
| Theater | +1 each leisure | rule gone |
| Bathhouse | +1 each leisure | rule gone |
| Gambling Hall | +2 each leisure or shop | +2 each shop |
| Racetrack | +2 each leisure | +2 each food building. Blurb: "Horses from the herds and the stables." |

**Trophies.**

* Add `Trophy.district`, "Full district", after `.jackpot`: the new building's district has 5 or more buildings.
* Good neighbour counts only buildings that touch the new one and gained, still 3 or more.
* `GREAT` goes from 8 to 9 and `JACKPOT` from 13 to 15, since districts lift whole groups at once.

**Looks.**

* Tiles take their colour from the category: top `shade(c, .77)`, side `shade(c, .2)`, with
  `CAT_HEX` as the base colours. Each district is drawn as one lot under its buildings, over the streets:
  `shade(c, .25)` at inset .02, then `shade(c, .5)` at inset .05, so the lot bridges the gaps between its buildings.
* While you hold a building, the district it would join breathes a deeper shade: the lot of that district plus
  the building's own squares, filled with `shade(c, .15)`, with the joined buildings' tiles cut out, drawn at
  alpha `.3 + .25 * sin(t * 2.6)`. No outline.
* Small moving parts, drawn every frame instead of baked: windmill sails and the gristmill wheel turn, the
  Lumber Mill saw spins, the Blacksmith's coals glow and throw sparks, the Miners' campfire flickers and sparks,
  kiln and brick kiln mouths glow, hens wander and peck by the Farmhouse coop, rings spread on the Town Well,
  the Plaza fountain and the Bathhouse pools, the Town Hall flag waves, and three birds circle over the Park
  (`extra: "birds"`). Each gets its own phase from a hash, so neighbours don't move in step.
* New roof styles (`style`): `logs` (Cabin, Log House, Trading Post), `metal` (Miners' Shacks, Lumber Mill,
  Stamp Mill, Freight Yard), `stone` (Blacksmith, Jail), `front`, a false front with a sign (General Store,
  Saloon, Assay Office), and `dormer` (Boarding House, Hotel).
* New roof roles: `silo` (Granary) and `beehive` kilns (Brickworks).
* Extras on the biggest roof (`extra`): `stack` (Stamp Mill), `cupola` (Stables), `bell` (Schoolhouse),
  `saw` (Lumber Mill), `boxcar` (Freight Yard). New emblems: `scale` (Assay Office), `loaf` (Bakery).
* New yard roles: woodpile (Cabin), veg (Homestead), hedge (Manor), laundry (Boarding House), coop
  (Farmhouse), fire (Miners' Shacks), hides (Tannery), anvil (Blacksmith), cart (Stamp Mill), bricks
  (Brickworks), bread (Bakery), fish (Fish Market), furs (Trading Post), hitch (Sheriff), pen (Jail),
  paddock (Stables). Stamp Mill and Hotel roofs change from `big` to `hall`; General Store and Assay Office from `shop` to `hall`.

**Not needed on iOS.** `LINK_VERSION` moved to 5.

### Tapping land only names it

Commit: "First Town: tapping land only names it", after `89a5e57`.

Tapping an unbuilt square shows the card's kind ("Open land" or "Bridges only"), the land's name and
its one-line blurb, and nothing else. The list of buildings that score for that land is gone: each
building's own scoring card already says which land it wants.

* `InfoCard.land`: show `kind`, `title(t.name)` and `t.blurb`. Drop the "Build on it" and "Build beside
  it" sections, the note about covered land, and the "No building scores for this land" line.
* `Words.caresAbout` is no longer used. Remove it.

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
* The land card no longer lists buildings at all. See "Tapping land only names it" above.
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
