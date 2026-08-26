# personal_projects

Three pages. Each one is a single HTML file with no build step, no dependencies and no
network calls. Open any of them in a browser.

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
