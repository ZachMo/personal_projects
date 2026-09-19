# personal_projects

Seven pages. Each one is a single HTML file with no build step, no dependencies and no
network calls. Open any of them in a browser.

## fall.html

Four small games for a phone, played with one thumb. The page is a full-screen app
shell: a home list, a settings screen and one canvas the games draw into. Nothing leaves
the browser. Best scores and settings live in localStorage.

There are almost no instructions anywhere on the page, on purpose. A game names itself,
gives you a Start button and then gets out of the way. Working out that the low fish
splash first, or that the driver keeps rolling, is the game.

Steering is one setting shared by every game. **Drag** moves whatever you are steering by
the distance your thumb travels, so your thumb never has to cover the thing you are
watching. **Buttons** puts two pads at the bottom, and they swap sides for left-handers.
**Tilt** reads `deviceorientation`, with a sensitivity choice and a recentre button that
makes however you are holding the phone count as straight ahead. iOS needs motion access,
so there is a button in settings that asks for it.

### Dino Fall

Blocks drop out of a dusk sky and you dodge along the ground. They fall faster and closer
together the longer you last. The score is the number of seconds you stay on your feet.

Four things fall that are not blocks, and they are the only colour in the game apart from
the sky. A **clay diamond** shields one hit. A **green dino** shrinks you to just over half
size for eight seconds, and a small dino is a fast one. A **blue hourglass** drops the sky
to 42% speed for five and a half seconds — you keep your own speed, which is the whole
point of it. An **amber bomb** clears every block on screen and whites out the frame.

Under the score, the two timed pickups get a countdown bar. The shield gets a small
diamond instead — it runs until something hits you, so a draining bar would be a lie.

It started as an easter egg in a page margin, moved with the arrow keys, and had only the
shield. This version is built for a screen you hold.

### Fish Fall

Five casts. Tap to drop the line.

Going down, the first thing you touch stops the descent and starts the reel, so a deep
cast means threading past every fish in the shallows. Coming back up, you hook everything
you can reach.

There is no end to the line. What stops you is the water: five animals per 100 m at the
top, twenty-eight per 100 m near the floor, and they grow as they thin the space between
them. The line also speeds up as it drops, so a deep cast is not a long wait. The sea
floor is at 900 m and is there for completeness — a good run reaches about 180 m, and 390 m
is a very good one. The animals get rarer and worth more the deeper you go: sardines and
perch near the top, tuna and jellyfish in the middle, squid, anglerfish and gulper eels in
the dark.

At the surface the whole catch is thrown clear of the water and falls back into it in slow
motion, scattered across the sky. Tap a fish and the fisherman shoots it for its points.
Anything that reaches the water again is gone.

There is no clock on screen because there does not need to be one. How high a fish is *is*
how long you have. The low ones splash first, so those are the ones to shoot first, and
you can read the whole queue at a glance. Shooting lowest-first instead of at random is
worth about 22% more points at a fast tap rate.

Everything is drawn from shapes on a canvas — no images, no sprite sheets. The water and
the sky carry all the colour. Every animal, the boat and the fisherman are solid ink
silhouettes, so you tell a sardine from a gulper eel by its shape, the way you tell the
blocks apart in Dino Fall. The only other colour is the gold on an anglerfish lure, a shot
and the points it pays.

Which means the water can never go black, or the silhouettes in it would disappear. It
bottoms out at a deep blue instead, and the dark of the deep comes from a vignette closing
in at the edges.

### Golf Fall

One island of course hanging in the sky: a hub with five arms reaching out of it and a cup
on the head of each, in no order. You keep playing from wherever the last ball dropped, so
which cup you take next, and in what order, is most of the game. Some arms are cut through
part way along, so getting out to the head is a carry.

The cups sit 20 to 27 units from the tee and up to 49 apart, which is more than one drive.

Drag back off the ball and let go, the way you would pull a catapult. Drag anywhere else
to turn the course, pinch to zoom. Turning is not decoration — the shot arc is drawn in
world space, so from behind the ball it collapses into a line and from the side you can
see exactly how high the ball goes and what it clears. The round opens zoomed out far
enough to plan a route across the whole island.

The camera sits on the ball and leans toward the cups you have left, but only by
what that lean is worth on the screen — so zooming in walks it back onto the
ball, and the course turns about the ball instead of about a point beside it.
Under all of that the ball is held inside a box on the screen, so no amount of
spinning and pinching can put it in a corner.

**The clubs**, measured on flat ground from a good lie:

| | carry | roll | total | apex | hang |
|---|---|---|---|---|---|
| **Driver** | 25.9 | 7.2 | 33.0 | 5.2 | 2.2s |
| **Wedge** | 11.1 | 1.3 | 12.4 | 4.5 | 2.1s |
| **Putter** | — | 13.8 | 13.8 | 0 | — |

A shot hangs for over two seconds and takes four to finish. That is on purpose.
Gravity is a quarter of what it was and the clubs are half as quick, which
leaves every distance exactly where it was and gives you time to watch the ball
instead of the number. It bounces three or four times and runs out about a third
of its carry, the way a ball does.

**The lie decides which one is any use.** Same club, same power, different
ground:

| | driver | wedge | putter |
|---|---|---|---|
| fairway | 33.0 | 12.4 | 2.4 |
| green | 27.7 | 11.5 | **13.8** |
| rough | 12.1 | 9.2 | 0.5 |
| sand | 3.0 | **9.8** | 0.1 |

Sand is a wedge shot and nothing else. Rough costs a driver two thirds of its
length. The putter is a green club: it rolls 13.8 on a green, 2.4 on fairway and
nowhere at all out of sand.

**The cup is a hole, not a target.** The ball has to fall its own depth in the
time it takes to cross the opening, and that one rule does the rest. Straight
through the middle is the longest crossing, so it takes the most pace — up to
2.39 units a second. Clip the edge and the crossing is short, so only a crawl
stays down. A shade too quick and the ball rides the lip, comes out the side and
loses two thirds of its pace. Quicker again and it crosses, dips, and leaves
14% of its pace in the hole on the way over.

From two units that is a quarter of the power range, from four units a fifth,
from nine a little over a tenth. The putter asks for nearly twice the drag of
the other clubs for the same power, so on the screen the window is about twice
as wide as those numbers suggest — a putt is decided by a fraction of a pull,
and it is worth having the room to find it. Holing out from across the course is
still close to luck: a driver aimed at a cup 21 units away went in 61 times in
2400.

**The aim line runs the real physics to the point the ball stops.** Dashed while
it is in the air, solid once it is running, a faint ring where it first touches
down and a bright one where it comes to rest. That ring goes gold when the shot
holes. Nothing about the shot is hidden and nothing about it is random, so a
missed putt is a misread, not bad luck.

**Height is the colour.** Low ground is grass, high ground is bare dirt, and
there is one band between them rather than a long gradient, so a rise is a
different colour and not a slightly different one. Every wall is earth with a
sunlit lip along the top. Height is worth a quarter more on screen than it used
to be.

One step of terrain is ground and anything more is a face. A ball flies over a
step and lands on it, and rolls up it by trading pace for height; a ball that
meets a face hits it, in the air or on the ground. So a lie tucked under a ledge
is still playable with a lofted club, and no hollow on the island is walled in
on every side — the ground is smoothed until each one has a way out. Bunkers are
levelled at the low point of the ground they sit in with their lips cut back to
one step, and they are kept off the green and off the flat collar round it. Sand
you cannot be played out of is not a hazard, it is a dead end.

A bot that plans each shot the way the aim line lets you plan it goes round in
10.9 shots, and finished all 16 rounds it was given.

It runs on a fixed 120 Hz step and the aim preview runs the same physics on the
same step, so the line you are shown is the line the ball takes — exactly, on
any frame rate.

### Ski Fall

Straight down a mountain that never ends. Steer left and right. The score is how
far you get.

You are looking down at the slope from behind your own skis. Down the mountain
is down the screen, so the snow scrolls up, your tracks run away uphill behind
you, and everything in front of you comes in at the bottom edge and rises to
meet you out of the haze. There is no horizon, on purpose: a ridge of peaks
across the top would put the summit in front of you and make the whole thing
read as a climb.

The trees come at you in ranks with one gap in each, and the gap narrows the
longer you last. Between the ranks there are loose trees and rocks to pick your
way through.

**It gets faster as you go.** Half again as fast by 200 m and near enough double
by 430 m, and the ranks close up behind it. A run ends because the mountain got
quick, not because it was ever going to be the same speed twice.

Everything that pays, pays in speed. Thread a tree close enough to hear it and
you get a push. Take one of the ramps and you fly, over anything in the way, and
the landing gives you another push. Speed is the score, so speed is what you
want, and speed is also what brings the next rank of trees on sooner. Nothing on
the screen says any of this. The number climbing faster after a near miss says
it.

A skier cuts across the hill about as fast as they are going down it, so the
sideways move is capped against the speed and not against the screen. Going
faster does not make you nimbler.

A bot that steers for the widest opening gets about 180 m and has reached 570.
Mashing the controls gets about 60.

## hugelland.html

A town-building board game for a phone. It is a jigsaw puzzle: buildings come in odd shapes,
and you fit them onto one map.

Each new town asks for your name. When the game starts, the town takes a name made from it:
Fort Zach, St. Zach, New Zach, Port Zach, Zachville, Zachburg, Zachton or Zachfield.

**The map.** Every game has a new map, 9 squares by 12. Water crosses it as a river, a lake
with a creek or two ponds. Woods, ore veins, wild wheat and grazing herds grow on it in
patches. The cattle and sheep wander their patch until something is built on it. You can build
on any square that is not water.

**One building at a time.** The library holds 69 kinds of building (55 until the daily map of 20 September 2026), and each game draws about
20 of them, so no two decks are alike. The draw takes a few kinds from each category: homes,
food, industry, shops, civic buildings and leisure. A town gets up to three of one kind of home,
and no more of anything else than that building usually comes in, which is one for most of them.
When the deck needs more buildings to fill the land, it adds new kinds, not copies. The To come
button shows what this game's deck holds, so you can plan where the next shop or farm will pay off.

A deck has about 24 buildings. A well or a windmill is one square, a cabin is two, a farm is a
2 by 2 square, a church is a plus sign, a racetrack is 2 by 3 and a train station is a straight
line of five. You can see the next building. Drag the building onto the map, press Turn or Flip,
then press Build. Small and simple buildings come early, and big civic buildings come late, so
leave room for them.

**Bridges.** A Bridge (three squares) and a Covered Bridge (four) are the only buildings that can
sit on water. Both ends must be on land. They score for each square on water and for each
building next to them. Any map with water to cross gets one of them early in the deck, so
leave a crossing open.

**Fit them all.** The deck covers 87% of the open land. A building that fits nowhere costs
5 points. Place every building and you get 10 points. The To come button lists what is left,
how many squares it needs and how many squares you have.

**Scoring you can count.** Every building has base points and a few modifiers. Tap the
building in hand, on the map or in the panel, to see them. A cabin is +2 base, +1 for each woods
square on or next to it, +2 for each food building next to it and −2 for each industry building
next to it. The game never works out a score before you build.

A land bonus counts that land both under the building and next to it, so you can build right on
a resource or around it. Next to means sharing a side; corners don't count. Modifiers name a kind
of land or a kind of building, never one particular building, so when a shop turns up, any home
can use it, and most buildings have two or three ways to score. Every building has at least one
land bonus and one neighbour bonus: early buildings score for the land they claim, later
buildings score for the town around them, and a well-placed early building scores twice.

Two more rules reach further. **In town** counts buildings anywhere on the map, so a Granary
scores for every food building. **If no** gives a bonus for keeping something away, so a
Library wants no industry and no leisure building next to it.

Land bonuses are set when you build. If you later build over the woods next to a lumber mill,
the mill keeps its points. Water never runs out: a bridge over it doesn't stop new buildings from
counting it. Neighbour bonuses stay live, so a grocer goes up when you later build a farm next to
it, and small +N numbers rise from any building whose score changed.

While you drag a building, or while its scoring is open, the squares next to it get a dashed
outline. Tap an empty square to see what kind of land it is.

**Celebration.** After each build only the score pops up, big, over the new building. A move
that earns 8 or more turns it green, and 13 or more turns it gold with confetti. Trophies show
as small badges under it:

- Triple, Quadruple and Combo: one neighbour bonus counted 3, 4, or 5 or more times;
- Rich land: one land bonus counting 5 squares or more;
- Jackpot: a move that earns 13 points or more;
- Perfect ground: every square on the land the building wants;
- Good neighbour: three or more buildings next door go up;
- Snug fit: no open land left around it;
- On a roll: three great moves in a row;
- Ouch, Bad neighbours, Spoiler and Wasted land: a score of 0 or less, two or more disliked
  neighbours, neighbours losing 3 points or more, or a building over ore or wheat it can't use.

Tap the score for every building's score, part by part. Tap a building in that list to find it
on the map. The summary at the end lists your trophies and your three best buildings.

**How it looks.** Open land is flat grass, trees, wheat and rock, with a faint outline on every
square you can still use. A building is a raised tile with a shadow and a roof. Some roofs carry
a sign: a star for the sheriff, bars for the jail, a dollar for the bank, a mask for the theater.
Streets appear between buildings, and people walk them. Chimneys and kilns smoke, water shimmers
and ore glints. Everything is drawn with vector shapes on a canvas at the screen's full
resolution. The game saves to localStorage after every move.

**Challenge a friend.** At the end of a game, Challenge a friend opens the phone's share sheet
with a link, or copies the link where there is no share sheet. The link holds the map's seed,
your score and your name. Your friend sees "Zach scored 145 on this map", plays the same land
and the same buildings in the same order, and gets a win or a loss at the end, with a button to
challenge you back. There is no server: the seed builds the same map and deck on any phone. If
a later change to the game changes what a seed builds, the link says it may not match.

**Reviewing buildings.** `hugelland-buildings.html` shows all 55 buildings with their art, category,
shape, era, deck count and scoring card, with a note box on each. It loads the game in a hidden frame and draws
each building with the game's own code, so it always matches. It needs a web server, not a file opened from disk.
Notes stay in the browser, and **Copy notes** puts them on the clipboard.

**The daily map.** One map a day, the same for everyone, seeded from the date in Texas. The day turns over at
midnight Central, not UTC, because that is where the players and the town are. A finished daily town also gets a
page of its local paper: see below.

**The Herald-Zeitung.** When a daily town is done, the summary carries a page of the town's newspaper, dated 1922.
Stories are read off the finished town: what ended up beside what, how big the districts grew, what was turned
away. Each story that fits is weighed, the day's own seed picks the wording from a library of headlines, German
Texan surnames and street names, and the photograph is a crop of the board itself.

**On a phone.** Taps are plain taps, so pressing Turn quickly never zooms the page, and pinch zoom
is off. The name field uses 16px text, because Safari zooms into smaller text fields when they get
focus.

**Balance.** I tested with bots over 40 maps. A bot that weighs points against packing scores
about 167 and fits every building about four games in five. A bot that only packs scores about
126. A bot that only chases points scores about 149 and loses about two buildings. A bot that
plays at random scores about 76. Over 300 decks every deck got a bridge, no building went past
its limit on copies, and the only pairs were wells, mines, farms, lumber mills and windmills.

## mexico-elections.html

A map of Mexican presidential elections, 2000–2024.

Pick an election to see who won the country. Then pick a state on the map to see how it
voted, candidate by candidate and coalition by coalition. Click the sea, or choose *All of
Mexico*, to go back to the national total.

### Data

The vote counts are the state-level presidential results published by the Instituto
Federal Electoral (2000, 2006) and the Instituto Nacional Electoral (2012, 2018, 2024). I
parsed them from the tables in Spanish Wikipedia's *Elecciones federales de México*
articles.

They reconcile with the official national counts. 2018 and 2024 match exactly. 2000, 2006
and 2012 differ only by the out-of-country vote, which is reported on its own and belongs
to no state. The state-winner counts match the record too: Fox 20, Labastida 11 and
Cárdenas 1 in 2000; Calderón 16 to López Obrador 16 in 2006; López Obrador 31 in 2018,
losing only Guanajuato; Sheinbaum 31 in 2024, losing only Aguascalientes.

Two things to know about the numbers.

**How the shares are figured.** Each share is a candidate's portion of the votes cast for
the candidates listed in that election. Annulled ballots and votes for unregistered
candidates stay out of the base. That base exists for all five elections, so the years
compare cleanly. It also runs a little high next to the figures the press quotes, which
divide by every ballot cast: Sheinbaum's 2024 result reads 61.3% here and 59.8% on the
wider base. The wider base is not available per state for 2012.

**Wikipedia's 2012 percentage table.** The 2012 article carries a second table, built on
percentages, that disagrees with its own vote counts in 14 states. That table also
contradicts itself. Some rows fold null ballots into the base, and Veracruz has a typo.
This page uses the vote counts, which reconcile nationally.

The boundaries come from a public-domain Mexico GeoJSON, simplified and drawn on an
equirectangular projection standardised at 23°N.

The chart colours follow party convention, but I ran them through a colourblind
separation check in both light and dark themes. MORENA's dark-mode colour is shifted,
because the obvious crimson sat too close to Movimiento Ciudadano's orange.

## map-trivia.html

Five maps to name from memory: the 32 Mexican states, the 50 US states, 44 European
countries, 54 African countries, and India's 36 states and union territories.

Easy mode gives you four choices. Hard mode makes you type the name. Miss five and you
start over. Each map keeps its own best score in the browser. Pinch to zoom, drag to pan.

## metro_city.html

A transit sim that runs in real time.

Place stations, join them into lines, and run trains. Demand follows a daily curve and
turns around between the morning and evening rush, so a platform fills while you watch and
you add trains to clear it. A block of houses holds 150 people. A tower holds twenty times
that. Density grows along the lines you build, so a well-served city climbs toward a
million people. A neglected one thins out.

There is no score and no way to lose. Pause it, speed it up, and it saves as you go.

## manor.html

A daily game. One run, two or three minutes.

You get an empty blueprint, fourteen steps, and an Antechamber that is sealed. Placing a
room costs a step, and so does walking through the seal at the end. Each step offers three
rooms and you keep one. Rooms have doors, and you can only build where a door already
points, so the shape of what you have built decides what you can build next.

Every room does something, and no two do the same thing. Some pay gems. Some score off
their neighbours, or their row, or the corner they sit in. One of them is worth a lot and
hates company. Working out which rooms are worth taking, and when, is the game.

The seal has a price in gems. Gems are not worth points — they only buy the door. So a run
that chases points never gets in, and a run that only mines gems gets in with an empty
manor. You have to do both, in the right proportion, before the steps run out.

The page carries no instructions on purpose. It shows you the price on the door, what you
hold, and what each room does. The rest is yours to work out, and most of it only becomes
obvious after a few days.

The deck is seeded by the date, so everyone gets the same shuffle and the same three cards
off the top. Each day also leans towards a different kind of room.

Simulated over 50 seeded days: a player who takes the highest-scoring room every time
builds a manor worth 38 and gets in **0%** of the time. A player who works out that gems
are the gate gets in 36% of the time but only scores 21. A player doing both scores 45 and
gets in 68%.

## lineup-card.html

A lineup builder for youth baseball coaches. The chart puts the innings across the top and
the positions down the side, with a bench row for each player who sits. Print it and take it
to the dugout.

Enter the team once. The list is the batting order, and a player moves by dragging the dots
beside their name. A player can be marked out for the day, or kept off the mound, out from
behind the plate or off the bench. **All** and **None** set pitching, catching or the bench for
the whole team at once. Even bench time counts only the players who can sit. A
pasted list works too, in the form `1. #99 Maverick`.

Pick any spot by hand and it turns yellow. **Build lineup** keeps those spots and fills the
rest, so a coach can set the first inning or two and let the tool do the others. **Keep** at
the top of an inning holds the whole inning. Press Build again for a different lineup.

Build follows these rules, in order of weight:

1. Every player plays an infield position in the first four innings. The inning is a setting,
   and so is whether pitcher and catcher count as infield.
2. Nobody sits two innings in a row, and nobody sits twice before everyone sits once.
3. Infield innings spread evenly across the team.
4. No player repeats a position if it can be avoided.

It runs simulated annealing over the open spots. That takes about a tenth of a second. **Check**
lists anything in the lineup that breaks a rule. It runs only when pressed, so setting spots
by hand stays quiet, and the list hides again at the next edit.

There is no backend. The team and the lineup live in the browser's localStorage. **Copy team
link** puts the roster in the URL fragment, so a coach can send the team to a phone or to an
assistant coach. The fragment never reaches the server, and the page removes it from the
address bar once it loads the team.

## ios-town/

A native rebuild of `hugelland.html` in Swift, for the App Store. The rules live in a Swift
package, `FirstTownCore`, with tests that play 60 games against the web version's rules and
require the same maps, decks, moves and scores. The app will add SpriteKit for the board,
SwiftUI for the panels, and Game Center leaderboards with a daily map. See `ios-town/README.md`.
