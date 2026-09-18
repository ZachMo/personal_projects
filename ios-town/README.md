# Hügelland for iOS

A native rebuild of `../hugelland.html` in Swift, for the App Store. It starts from the web
version's rules and is free to grow its own.

The browser version keeps moving. [`WEB-CHANGES.md`](WEB-CHANGES.md) lists every change made there
that the app does not have yet.

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
| `FirstTown/Model` | `Town`: the game in play, the building in hand, the open card, saving |
| `FirstTown/Board` | The map: land and building art, things that move, the renderer and touch |
| `FirstTown/UI` | The SwiftUI screens and pieces: the play screen, colours, shape icons, haptics |

The rules live in a package so they build for macOS too. Their tests run in a few seconds
without a simulator:

```
cd FirstTownCore && swift test
```

## How the board is drawn

The web version draws on a canvas, and so does the app: a SwiftUI `Canvas` inside a
`TimelineView`, running at 60 frames a second. `Canvas` hands over a Core Graphics context, whose
calls match canvas almost one for one, so `LandArt` and `BuildingArt` are close translations of
the web drawing code, and the art stays the same.

Like the web version, the land, the streets and the settled buildings are drawn once into an
image and only redrawn when a building lands. Each frame draws that image, then the things that
move: water, glints, herds, walkers, smoke, dust, confetti, the building in hand and the selection.

`BoardLayout` does the web version's sizing sums. Everything is in points with a top-left origin,
the same as canvas.

Debug builds take launch arguments for simulator screenshots: `-seed 424242 -autoplay 12` starts a
known map with 12 moves made, and `-rules` opens the scoring card.

```
xcrun simctl launch booted com.nicholeroatch.firsttown -seed 424242 -autoplay 12
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
games in Node with the rules from `hugelland.html`, and the test plays the same games in Swift.
Maps, decks, every move's squares, points and trophies, and the final scores must all match.

```
node Tools/make-web-fixtures.js
```

The app is allowed to change its rules. When it does on purpose, drop `WebParityTests` or
regenerate the fixtures from a web version with the same rules.

## State

**Done.** The rules package, with its tests. The board: land and building art, the building in
hand with drag, Turn, Flip and Build, the dashed squares beside it, walkers, herds, smoke, water,
glints, confetti and score numbers over neighbours. The screens: the intro with a name, the town
bar, the slim panel, the scoring card, building and land cards, the score pop-up with trophy
pills, the score sheet, the To come sheet, the menu with How to play and New town, and the end
summary with trophies, best buildings and the best score. Saving, and haptics for turning,
building and trophies.

More debug flags for screenshots: `-intro`, `-select <square>`, `-pop`, `-sheet score|deck|menu`
and `-summary`.

**Next**, in order:

1. **Game Center.** Leaderboards and a daily map that everyone plays.
2. **The App Store.** App icon, iPad layout, privacy details and TestFlight.

## Before the App Store

These need the owner of the Apple Developer account:

* Join the Apple Developer Program, and pick a team in the target's Signing settings.
* Check that the name First Town is free on the App Store, or choose another. The bundle id is
  `com.nicholeroatch.firsttown`.
* Turn on Game Center for the app id in App Store Connect. The entitlement is already in
  `FirstTown.entitlements`.
* Try it on a real iPhone. The simulator has no Taptic Engine and no real Game Center sign-in.
