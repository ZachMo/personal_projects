# personal_projects

## mexico-elections.html

An interactive map of Mexican presidential elections, 2000–2024. Open the file in any
browser — it is a single self-contained page with no build step, no dependencies and no
network access required.

Pick an election to see who won it nationally, then select a state on the map for its own
breakdown by candidate and party coalition. Click the sea (or choose *All of Mexico*) to
return to the national total.

### Data

State-level presidential vote counts published by the Instituto Federal Electoral (2000,
2006) and the Instituto Nacional Electoral (2012, 2018, 2024), parsed from the tables in
Spanish Wikipedia's *Elecciones federales de México* articles.

The parsed totals reconcile against the official national counts. 2018 and 2024 match
exactly; 2000, 2006 and 2012 differ only by the out-of-country vote, which is reported
separately and is not included in any state's row. State-winner counts also match the
historical record — Fox 20 / Labastida 11 / Cárdenas 1 in 2000, Calderón 16 – López
Obrador 16 in 2006, López Obrador 31 (losing only Guanajuato) in 2018, Sheinbaum 31
(losing only Aguascalientes) in 2024.

Two caveats worth knowing:

- **Percentage base.** Shares are each candidate's portion of the votes cast for the
  candidates listed in that election, excluding annulled ballots and votes for
  unregistered candidates. That base is available consistently for all five elections, so
  the years stay comparable, but it runs slightly above the figures usually quoted in the
  press, which divide by all ballots cast — Sheinbaum's 2024 result reads 61.3% here and
  59.8% on the wider base. The all-ballots base is not available per-state for 2012.
- **Wikipedia's 2012 percentage table.** The 2012 article carries a second,
  percentage-based table that disagrees with its own vote-count table on 14 states; that
  table is internally inconsistent (some rows fold null ballots into the base, and
  Veracruz has a typo). The vote counts — the ones that reconcile nationally — are what
  this page uses.

Boundaries come from a public-domain Mexico GeoJSON, simplified and drawn on an
equirectangular projection standardised at 23°N.

Chart colours follow party convention but were checked with a colourblind-separation
validator in both light and dark themes; MORENA's dark-mode step is adjusted because the
obvious crimson failed against Movimiento Ciudadano's orange.
