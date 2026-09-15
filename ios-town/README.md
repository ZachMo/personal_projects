# First Town for iOS

A native rebuild of `../first-town.html` in Swift, for the App Store. It starts from the web
version's rules and is free to grow its own.

Open `FirstTown.xcodeproj`. There is no package manager step and nothing to install.

```
xcodebuild -project FirstTown.xcodeproj -scheme FirstTown \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO build
```

If `xcode-select` points at the Command Line Tools, put
`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` in front of that. No `sudo` needed.

## How it is laid out

| Folder | What lives there |
|---|---|
| `FirstTownCore` | A Swift package with the rules and no UI: the map, the deck, placement, scoring, trophies, saving and the words on the cards |
| `FirstTown/App` | The app entry and the root view |

The rules live in a package so they build for macOS too. Their tests run in a few seconds
without a simulator:

```
cd FirstTownCore && swift test
```

## The rules package

| File | What it does |
|---|---|
| `Board.swift` | The 9 by 12 grid, and Mulberry32, the web version's random number generator |
| `MapMaker.swift` | Water, then patches of woods, ore, wild wheat and herds |
| `DeckMaker.swift` | Draws about 19 kinds of building and sizes the deck to 87% of the open land |
| `Shapes.swift` | Footprints, turning and flipping, and every legal spot for a building |
| `Library.swift` | All 55 buildings and the kinds of rule they score by |
| `Game.swift` | Building, live neighbour scores, kept land bonuses, trophies and saving |
| `Words.swift` | Trophy names, land and category names, rule and score text, town names |

`Game` is a value type. Copy it to try a move without touching the real game.

## Tests

`RuleTests` checks the rules on their own: every building has a land bonus and a neighbour bonus,
covering land takes nothing away, water under a bridge still counts, later neighbours raise
earlier buildings, and a saved game loads back the same.

`WebParityTests` checks the port against the web version. `Tools/make-web-fixtures.js` plays 60
games in Node with the rules from `first-town.html`, and the test plays the same games in Swift.
Maps, decks, every move's squares, points and trophies, and the final scores must all match.

```
node Tools/make-web-fixtures.js
```

The app is allowed to change its rules. When it does on purpose, drop `WebParityTests` or
regenerate the fixtures from a web version with the same rules.

## State

**Done.** The rules package, with its tests, and an app target that links it and builds.

**Next**, in order:

1. **The board.** SpriteKit: the land drawn once into a texture, raised building tiles with roofs,
   the building in hand with drag, Turn, Flip and Build, and the dashed squares beside it.
2. **The panels.** SwiftUI: the intro, the slim panel, the scoring card, the info card, the score
   sheet, the To come list, the score pop-up, trophies and the end summary.
3. **Life.** Walkers, grazing herds, chimney smoke, confetti and haptics.
4. **Game Center.** Leaderboards and a daily map that everyone plays.
5. **The App Store.** App icon, iPad layout, privacy details and TestFlight.

## Before the App Store

These need the owner of the Apple Developer account:

* Join the Apple Developer Program, and pick a team in the target's Signing settings.
* Check that the name First Town is free on the App Store, or choose another. The bundle id is
  `com.nicholeroatch.firsttown`.
* Turn on Game Center for the app id in App Store Connect. The entitlement is already in
  `FirstTown.entitlements`.
* Try it on a real iPhone. The simulator has no Taptic Engine and no real Game Center sign-in.
