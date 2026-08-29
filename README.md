# personal_projects

Five pages. Each one is a single HTML file with no build step, no dependencies and no
network calls. Open any of them in a browser.

## fall.html

Three small games for a phone, played with one thumb. The page is a full-screen app
shell: a home list, a settings screen and one canvas the games draw into. Nothing leaves
the browser. Best scores and settings live in localStorage.

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

Not built yet. The card on the home screen is there and locked.

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
