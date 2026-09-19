# Web changes not yet in the iOS app

The iOS app started from `hugelland.html` (then `first-town.html`) at commit `67cc7e4`. This log lists every change to the
browser version since then that the app does not have yet, newest first. When a change is ported,
move it to **Ported** at the bottom with the Swift commit that brought it over.

`WebParityTests` still pins the app to `67cc7e4`. When rules are ported, regenerate the fixtures
with `node FirstTownCore/Tools/make-web-fixtures.js` from a web version with the same rules, or the
parity tests will fail.

## Waiting

### Building notes: a trader's yard, a truer blurb, and changes waiting

Commit: "Hügelland: building notes, with scoring changes held for go-live", after the drafts.

Live now, words and art only:
- Row Houses blurb: "Town folk who want the shops close and civic services at hand." (It promised a river view it never scored.)
- Trading Post: a TRADE sign on its roof, and its yard (`furs`) is a birch canoe, two pelts laced in drying hoops and a barrel.

Held back with `pending` (the game ignores it; the review page shows it beside today's card):
- Bridge and Covered Bridge: "+1 each building" becomes "+1 each kind of building" (`variety`).
- Doctor: Woods is replaced by +1 Shop; blurb "Close to families and the shops, far from the smoke."

Drafts: the Country House's open squares are +2 each, and Company Houses are replaced by the Duplex (I2, ×2,
+1 Industry, +2 Food), a Cabin that likes the works instead of the woods. Decks and par are unchanged.

### Six draft buildings, and three new ways to score

Commit: "Hügelland: six draft buildings for review", after the livelier buildings.

Not in any game yet. `draft: true` keeps a building out of `makeDeck` (all three of its filters), so every deck,
daily map, goal and par is unchanged. A fingerprint over 5,000 seeds and 60 days matched before and after.
The drafts show on `hugelland-buildings.html` for review. Port them when they go live, not before.

- Homes: Apartments (P5), Country House (L4), Company Houses (I3). Shops: Toll House (I2), Feed Store (V3),
  Department Store (O4).
- New rule `crowd` (`n`, `p`): points if its district has at least `n` buildings. Card: "District of 4 or more".
- New rule `room` (`p`): points for each empty land square next to it, counted live from `look().open`.
  Card: "Each open square".
- `near` takes `bridge: true` to mean either bridge. Card: "Bridge".
- `evalRule` now takes the building's type and squares, and `ruleIcon` takes the type.
- New ground art `tollgate` and `sacks`, and a water tank on the Apartments roof.

### Livelier buildings

Commit: "Hügelland: livelier stables, windmills and mines, clearer signs", after the jigsaw tutorial.

Art only; no rules change. On iOS it lands in the drawing code in `FirstTown/`.

- **Stables:** the paddock horse wanders (`mosey`): a three-second walk to the next of four spots, then a
  while grazing, with a slight head sway.
- **Windmill:** the sails drift slowly, and every 9 seconds a gust spins them one and a half turns, easing in and out.
- **Mine:** a headframe stands over the shaft. A cart of ore rises out of the shaft, rolls down the track, tips
  the ore out, rolls back up empty and sinks out of sight. The headframe's wheel turns with the cable. The dust stays.
- **Gambling Hall:** `sign: "CASINO"` on its roof instead of the diamond emblem, which is gone.
- **Theater:** the emblem is the comedy and tragedy masks, tilted apart.
- **Bank:** the dollar emblem is 1.9 times the usual emblem size, the masks 2.3 (`EMBLEM_SIZE`).
- The building review page now animates the buildings on screen. Web only.

### The tutorial teaches the jigsaw

Commit: "Hügelland: the tutorial teaches the jigsaw", after the tutorial pauses.

Same number of steps. The first coach card says Hügelland is a jigsaw and a building with no room costs −5.
The To come step points at the squares count and says a real deck fills almost every open square. The map is
tighter: a lake fills the right side and the bottom, and a bay cuts into the top. The last building is now a
Church (a plus) instead of a Windmill. After the scripted moves it fits in only two gaps, next to the last ore,
and a careless Mine can take both. Careful play ends on 70, a blocked Church on 50. The tutorial summary says
which building had no room and why that matters.

### The tutorial gives you a moment to look

Commit: "Hügelland: the tutorial lets you look before it talks", after Each water.

After a build, the coach card waits until the score and trophies over the new building have gone (`hold: "pop"`,
from `popTime`). After you open a card, it waits 2.2 seconds. Then it fades in. The card you opened goes to the
side away from the coach from the start, so it never jumps. The longer coach texts are about half as long.

### Free is a new map, Each water, a wheat Tutorial button

Commit: "Hügelland: Free starts a new map, and water says when it counts each square", after the tutorial.

- Free (and Daily) from the menu during a game started the *same* map again, because `startTown` reused the
  seed of the town on screen. It now takes a seed, and the menu and the tutorial's ending pass `null` for a fresh one.
  Check the iOS menu for the same bug.
- A water rule that counts every square (Fishing Dock, Fish Market, both bridges) reads "Each water". Water that
  counts once still reads "Water". How to play says: "Water counts once, unless the card says Each water."
- The Tutorial button is wheat yellow (`#e2bf5c`, dark brown text), not dark.
- New page `hugelland-buildings.html` lists every building for review. Web only; not needed on iOS.

### A tutorial

Commit: "Hügelland: a tutorial, and cards that name what they count", after how to play dropped the daily line.

A Tutorial button sits under Daily and Free, on the start screen and in the menu. It plays a hand-drawn map
(`TUT_MAP`) with eight buildings in a set order (`TUT_DECK`). A coach card walks through 19 steps (`STEPS`):
read a card, turn and flip the Lumber Mill onto a gold outline in the woods, grow a home district, put a Farm
on the Mine's ore to show a trade-off, cross the river with a bridge, open To come, tap a built building, and
place the last two freely. Build stays off until the building covers the outline (`placeOK`). The tutorial is
never saved, so a town under way comes back afterwards. Its own summary (`tutSummary`) explains final scoring
and leads to Daily or Free. On iOS this is new UI in `FirstTown/`. The rules in `FirstTownCore` do not change.

### Cards name what they count

Same commit. A rule on a card is now its points, its icon and a name: "+2 Woods", "+2 Food", "+3 Map edge",
"+1 Any building", "+1 Food in town", "+4 No industry or leisure". It was "+2 each woods", "+2 if water" and so on.
The district row reads "Home district, max +4". A built card says "Water" or "No water", capitalised. How to play
now says a land bonus counts each square, and that most buildings count water once. The iOS words live in
`FirstTownCore/Sources/FirstTownCore/Words.swift`. Web only uses these for display, so the parity fixtures are unaffected.

### How to play drops the daily line

Commit: "Hügelland: how to play stops explaining the two maps", after the par timing fix.

The line "The daily map is the same for everyone, with three goals and a par to beat. A free map has neither."
is gone from `RULES_HTML`. The two buttons say it where the choice is made.

### Par is worked out at the end

Commit: "Hügelland: work out par when the town is done", after the par change.

Par was worked out when a daily town was founded and kept in the save, so a town started before par changed
still showed the old number. `parFor` now runs in `showSummary`, once, when the town is done, and a day
already written down takes the fresh par while keeping its score and goals. Founding a daily town no longer
costs that moment, and the welcome line drops the par it used to name.

### Par comes down to a good game

Commit: "Hügelland: par is a good game, not a perfect one", after the plainer daily card.

Par was the machine's own score, and the machine reads all eighty-odd spots every turn, which no person does.
It came out above a strong player's best: 222 on 18 September against an all-time best of 194. Par is now
`PAR_SHARE = .85` of that score, rounded, so 18 September is 189 and the days after it 127, 135, 140 and 144.
It still rises and falls with how rich the map is.

A bot that samples a dozen spots a turn was the other candidate. It averages 158 but swings between days on
one run (143 on 18 September, 173 on the 21st), so par would have felt arbitrary.

### A plainer daily card

Commit: "Hügelland: the daily card shows the goals alone", after the menu change.

The card during a daily game keeps its heading, the date and the three goals with their progress. The score
so far, the streak and the line about par are gone: the score is already in the header, and par belongs to
the summary.

### The daily map from the menu

Commit: "Hügelland: reach the daily map from the menu", after the daily challenge links.

A town already under way resumes when the page opens, so a player who had a game saved never saw the new
opening screen. Two changes:

* The menu leads with **New town**: a **Daily** button and a **Free** button, above How to play. In a town
  under way, the first tap warns that the town will be lost and the second starts the new one. The name is
  already known, so it starts straight away instead of returning to the opening screen. The Daily button's
  line says whether you are on today's map already, or what you scored on it.
* A finished town no longer greets you on the next visit. `load()` still restores it, but the opening screen
  shows unless the town is still under way.

### A pinned summary header, and daily challenge links

Commit: "Hügelland: keep the score in view, share the daily map", after the swipeable summary.

* The town's name, its score, the day or best line, and the **Challenge a friend** button sit above the pages
  and stay while you swipe. The first page holds the tally, trophies and best buildings; the second the par
  and the goals; a leaderboard would be the third.
* A challenge from a daily town shares `?daily=2026-09-18` instead of `?seed=…`, so a friend gets that day's
  map with its goals and its par. The share text reads "Beat me on today's map" or names the date.
* Opening a `?daily=` link shows who scored what on that map, and **Take the challenge** starts that day.
  `?seed=` links work as before.
* Only today's map is recorded: playing an older day through a link does not touch the streak.

### The opening and the summary

Commit: "Hügelland: a warmer opening, a summary you can swipe", after the daily map.

* **Opening.** The app's icon sits above the name, the two buttons read **Daily** ("Play the daily challenge
  map") and **Free** ("Play a random map"), in orange and green, and the paragraph explaining the daily map is
  gone. The name is remembered in `hugelland.name` and fills the field, so the buttons work at once; an empty
  name puts the cursor in the field instead of blocking the button. When a day is already finished, one line
  reports it.
* **Par waits.** The day's card during a game shows the goals and the score so far, not the par. It says par
  waits until the town is done.
* **A summary you can swipe.** The end screen keeps its old page, and the daily part moves to a second page:
  the date, par against the score, the goals and the streak. Dots under the pages show where you are and move
  you when tapped, and a line reads "Swipe for today's goals" until the last page. A leaderboard becomes a
  third page when one is switched on.

### A daily map, with three goals and a par

Commit: "Hügelland: a daily map with goals and par", after the rename.

* **Two ways to start.** The intro asks for a name, then offers **Daily map** or **Free map**. A free map is the
  game as it was. `newGame(player, pick, seed, daily)` takes a day key; `G` gains `day`, `goals` and `par`, and
  the save version goes to 7 (a version 6 save carries on as a free map).
* **The day's map.** `dayKey()` is today's date in UTC, so everyone gets the same map. `seedFrom(text)` is an
  FNV hash, and the seed is `seedFrom("hugelland/" + day)`.
* **Three goals,** drawn from `seedFrom("goals/" + day)`: one district of 5/6/7, 4 or 5 homes in one district,
  a building worth 14/15/16, every building scores 3 or 4, or win 8/10/12 trophies. Each goal reads the town
  as it stands, so the header shows "Daily 1/3" while you play and the day's card shows each goal's progress.
  Thresholds were picked so a plain player hits about half of them.
* **Par** is what a plain player scores on that map, always taking the best spot for the building in hand and
  never looking ahead. `parFor(seed)` plays the whole game on a scratch board, about 25–60 ms, once, when a
  daily town is founded. The summary shows "Par 222 +8 over par".
* **The day's card** opens by tapping the town's name in the header: the date, the three goals with progress,
  par, the score so far and the streak.
* **Records.** `hugelland.daily` keeps the last finished day: day, score, par, goals hit and the streak of days
  in a row. Only the first finished run of a day counts; later runs are practice. The intro shows the day's
  result when it exists.
* **Leaderboard hook.** `CLOUD = { url, key, table }` is empty, so the game never touches the network. Filled
  in with a Supabase project's URL and public anon key, it posts each day's run and shows the day's top ten
  under the summary.

### The game is called Hügelland

Commit: "Hügelland: the game gets its name and its icon", after the rebalance.

* The name is in one place, `GAME = "Hügelland"`, used by the header, the intro heading and a shared link's
  text. The page title, `apple-mobile-web-app-title` and the card on `index.html` use it too.
* The header's second line now starts with the game's name: "Hügelland · 6 built", or "Hügelland · the town is
  done". The town's own name stays on the first line, and shows the game's name before a town is founded.
* New files: `hugelland-icon.svg` (rounded, for a browser tab), `hugelland-icon-180.png` (the iOS home screen)
  and `hugelland-icon-512.png`. A green hillside with a clay-roofed house and a tree, in the game's colours.
  On iOS the app has its own app icon, so only the name matters there.
* The save keys stay `firsttown.v3` and `firsttown.best`, so a game in progress survives the rename.
* **Web only.** The page moves to `hugelland.html`, and `first-town.html` stays behind as a redirect that
  keeps any `?seed=…` on a challenge link. `index.html` and both READMEs point at the new name, as does
  `FirstTownCore/Tools/make-web-fixtures.js`, which reads the web file.

### Rebalance: herds, water, shops and civic

Commit: "First Town: rebalance herds, water and neighbours", after "less text on the cards".

**Herds pay.** A herd patch was worth about 5 points a game, the weakest land on the map. Ranch +3 each herd
square, Stables, Tannery and Racetrack +2. Town Well, Grocer and Saloon no longer count herd: Town Well gains
+1 each food building, Saloon +1 each wheat square. Herd patches on the map grow from `n(3,4)` plus a 60%
chance of `n(2,3)` to `n(4,5)` plus a certain `n(2,3)`, about 6.8 squares a map instead of 4.8.

**Water on fewer buildings,** 24 down to 15. Dropped from Church (+1 woods instead), Plaza (base 1 → 2), Park
(base 1 → 2), Courthouse (+1 each home instead), Theater (+1 each shop instead), Town Hall (base 3 → 4),
Doctor (+1 woods instead) and Stamp Mill (base 2 → 3).

**Fewer buildings want a shop next door,** 16 down to 13. Lumber Mill +2 each woods square (was +1 woods, +1
shop). Orchard +2 each home (was +1 home, +1 shop), blurb "Apples for the families next door." Freight Yard
+1 each industry building in town (was +2 each shop next to it), blurb "Loads what every mill in town makes."
Gristmill +2 each home (was +2 each shop), blurb "A water wheel grinds flour for the families."

**Civic pulls a little,** wanted by 3 buildings, now 5: Row Houses +1 each civic, Hotel +1 each civic.

**Blurbs:** Town Well "Water for the families and the fields.", Saloon "Whiskey for the miners after a shift."

**Link version** goes to 6, since the map changed.

### Less text: no card for land, shorter scoring rows

Commit: "First Town: less text on the cards", after the signs and sluice change.

* **Tapping land does nothing.** Only a built building opens a card. `InfoCard` drops the land case, and the
  yellow ring that marked a chosen land square goes with it. `TERRAIN` keeps only `short`, the word the
  scoring rows use; its `name`, `on` and `blurb` are gone.
* **Shorter rows.** The icon already says whether a rule is land, a neighbour, the town, the edge or a
  district, so the words carry only what it counts. `Words.rule`: "each woods", "if water", "each home",
  "at the map edge", "each kind next to it", "each shop in town", "if no industry or leisure". `Words.part`:
  "3 woods", "no water", "2 homes", "Map edge", "Not at the edge", "2 kinds", "District of 6", "No district".
  A built building's rows no longer repeat the points as "× +1". The base row reads "Base".
* `CATS` short words: home/homes, food/food, industry/industry, shop/shops, civic/civic, leisure/leisure.
* The district row reads "each other home in its district, max +4".

### Signs on the Hotel and Store, gold in the sluice, a busy mine, land words

Not committed yet. Comes after "First Town: trains, wagons, races, plaza benches, saloon sign".

* **Signs.** General Store gets `sign: "STORE"` on its false front. Hotel gets `sign: "HOTEL"`: a building
  with a sign that is not a false front gets a raised board on the lower slope of its biggest roof,
  .78 of the roof long and up to .3 deep, turned to read bottom to top when the roof stands upright. The board
  drawing moves into one `signBoard(x, y, w, h, words, colours, upright, raised)`.
* **Gold Sluice.** Each trough square draws three white water streaks and four gold flecks running along it.
  Every square uses the same time, so flecks pass from one square to the next.
* **Land words.** A one-time land bonus that misses reads "Not on or next to water", not "Not next to
  water". Blurbs no longer hint at on or beside: Cabin "Timber walls and a porch, close to the food.", Mine
  "Only worth digging for ore.", Stamp Mill "Crushes ore from the diggings.", Windmill "Grinds the wild
  grain.", Granary "Stores wild grain and the harvest of every food building.", Cemetery "Quiet, shady
  ground, away from the noise."
* **Mine.** Tan dust drifts up out of the shaft, and a small ore cart with a gold nugget rolls up and down
  the track below it.
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
