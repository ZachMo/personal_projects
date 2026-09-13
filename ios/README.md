# Fall for iOS

A Swift and SpriteKit rewrite of `../fall.html`. Same games, same feel, native.

Open `Fall.xcodeproj`. There is no package manager and nothing to install.

```
xcodebuild -scheme Fall -destination 'platform=iOS Simulator,name=iPhone 17' build
```

If `xcode-select` points at the Command Line Tools, put `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`
in front of that. No `sudo` needed.

## How it is laid out

| Folder | What lives there |
|---|---|
| `App` | The app entry and the three-screen router |
| `Core` | Storage, settings, best scores, sound, haptics, input |
| `Game` | The SpriteKit host, shared drawing helpers, the game list |
| `Game/Dino` | Dino Fall |
| `UI` | The SwiftUI shell: home, settings, play, overlays |

The split follows the web version. Menus were HTML and CSS, so they are SwiftUI.
Gameplay was a canvas, so it is a `SKScene`.

## The one thing to know before editing a game

SpriteKit puts the origin at the bottom left with y running up. Canvas puts it at
the top left with y running down, and every line of game logic in `fall.html` was
written that way.

Rather than rewrite all of it, `GameScene.canvas` sits at the top of the scene
with `yScale = -1`. Anything added to it uses canvas coordinates unchanged, so a
game's `update` is a near-transcription of the original.

Two rules follow:

* A node carrying a **texture** must cancel the flip with its own `yScale = -1`,
  or the picture arrives upside down. `CanvasSprite` does this for you, so use it.
* `zRotation` still turns clockwise, the same direction `ctx.rotate()` does under
  a y-down axis. Rotation values copy across as they are.

## What replaced what

| Web | Native |
|---|---|
| `localStorage` | `UserDefaults`, same `fall_` key prefix |
| WebAudio oscillators | PCM buffers synthesised on demand, still no audio files |
| `navigator.vibrate` | `UIImpactFeedbackGenerator` |
| `deviceorientation.gamma` | `CMMotionManager` gravity, resolved per interface orientation |
| Immediate-mode canvas | Retained nodes, pooled where they churn |

Drawing is the only part that was rewritten rather than translated. Instead of
clearing and redrawing every frame, each moving thing owns a node and the frame
ends by pushing positions into it. Dust is pooled; the dunes are one periodic
path slid sideways; the ground ticks are a fixed set of nodes moved along.

## State

**Done.** The shell, the settings screen, the shared core, and **Dino Fall** in
full: pickups, shield, slow, mini, bomb, the timer bars, the difficulty ramp,
best scores, pause and the endings.

**Next**, in the order they are worth doing:

1. **Fish Fall** — the largest of the three left, and the one that will show
   whether the pooling approach holds up under a busier scene.
2. **Ski Fall** — shares the island renderer with Golf, so do it before Golf.
3. **Golf Fall** — also needs the club bar, which is the one piece of gameplay
   chrome the shell does not have yet.

Each new game is a `FallGame` in its own folder, plus one row in `Catalogue.swift`
with `soon: false`.

## Not yet checked on hardware

Everything above was verified on the simulator. Two things cannot be:

* **Tilt steering.** The maths is in `Input.lateralDegrees`. Portrait should be
  right; the two landscape cases pick the axis by interface orientation and the
  sign wants confirming on a real phone.
* **Haptics.** The simulator has no Taptic Engine, so the patterns in
  `Haptics.buzz` have never actually been felt.

## Debug flags

`-autostart dino` opens straight into a game. `-autoplay` presses the first Start
once. Both are `#if DEBUG` only, and exist so a simulator run can be photographed
without tapping through the menu.

```
xcrun simctl launch <device> com.nicholeroatch.fall -autostart dino -autoplay
```
