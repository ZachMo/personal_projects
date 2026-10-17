# Zachbox Games

Party games for one shared screen and everyone's phones, in the style of Jackbox. One person
opens a game on a computer and shares that screen on Zoom or Discord. Everyone else joins on
their phone with a 4-letter room code or the QR code.

Unlike the rest of this repo, this is a small Node app, not a single HTML page. It needs a
server because the phones and the host screen talk to each other live.

## Run it

```
cd zachbox
npm install
npm start            # http://localhost:3000
```

Open `http://localhost:3000`, pick **Host a game**, and join from phones on the same network at
the address shown on the host screen. To test alone, open the join link in four or more
browser tabs.

`npm run dev` runs every timer at a quarter of its length. `npm test` plays whole games with
fake phones and checks the rules below.

| Variable | Use |
| --- | --- |
| `PORT` | Port to listen on. Default 3000. |
| `PUBLIC_URL` | Base URL for join links and QR codes, such as `https://zachbox.onrender.com`. By default it comes from the host screen's own address. |
| `MDP_FAST=1` | Short timers, for testing. |

## Deploy

Any Node 20+ host with HTTPS and WebSockets works. On Render: new **Web Service** from this
repo, root directory `zachbox`, build command `npm install`, start command `npm start`. Rooms
live in memory, so run one instance; a restart ends any games in progress.

## Murder Dinner Party

A bluffing game for 4 to 8 players, about 10 to 12 minutes. A rich old man was murdered at his
own dinner party. Every guest saw it happen except the killer. One player is the Detective and
sees only anonymous answers.

1. **Lobby.** Phones join and pick a character card. Taken cards grey out. The host screen or
   the first phone to join (the VIP) starts the game at 4 players.
2. **Roles.** Each phone says Detective or suspect. The killer is told nothing yet.
3. **Intro.** The table, the victim face-down, every guest in a chair.
4. **Round 1, the scene.** "What is a normal thing you'd *decorate* in *the greenhouse*?" The
   killer sees "the crime scene" instead. The Detective picks the answer that fits least.
5. **Round 2, the weapon.** Witnesses draw the weapon; the killer sees "???" and guesses. The
   Detective picks the drawing that doesn't match.
6. **Round 3, the silhouette.** Every suspect, killer included, sees the killer's silhouette
   and describes it in one word.
7. **Verdict.** The Detective sees every suspect's card with their three clues, now with
   names, and accuses one.
8. **Reveal.** The killer, a replay of each round showing who wrote what, and the Detective's
   score out of 3: Legendary Detective, Competent Inspector, Lucky Guess Larry, or Hopeless
   Clouseau.

If the Detective names the killer, the Detective and the innocent suspects win. Otherwise the
killer wins. The score is for bragging only.

### Secrets

The host screen is on everyone's call, so it never receives a secret. The server builds a
separate state for each phone and for the host screen, and leaves out anything that client
should not have. Nothing is hidden with CSS. The location and weapon go only to witnesses. The
silhouette goes to suspects as inline image data, so its file name can't give away whose it
is. Round 1 and 2 entries are shuffled once, labelled A, B, C, sent with no names, and shown in
the same order everywhere. Drawings are rebuilt on the server with only their image data. The
Detective's picks get no feedback until the reveal. The host screen never says who the
Detective is.

### When someone drops

- A suspect who drops counts as missing the deadline. Their answer becomes "(said nothing)",
  or a blank drawing. They can rejoin and keep playing.
- If the Detective drops during a pick, the game pauses. After 90 seconds the host or VIP can
  deal a new game with a new Detective. (A new Detective chosen mid-game would already know
  the secrets, so it starts fresh with the same guests.)
- If the killer is gone for 60 seconds, the game ends: "The killer fled."
- A phone or host screen that refreshes picks up where it was. Phones keep a reconnect token
  in localStorage; the host keeps the room code in its URL.

### Adding a friend's card

Cards live in `games/murder-dinner-party/cards/`. Add an entry to `cards.json` and two
images:

```json
{
  "id": "dolores-vance",
  "name": "Madame Dolores Vance",
  "title": "Retired magician with a lisp",
  "traits": ["Enormous feathered hat", "Pulls scarves from her sleeves when nervous", "Was the victim's secret lover"],
  "catchphrase": "Thith ith a mithunderthtanding.",
  "avatar": "/games/murder-dinner-party/cards/dolores-vance.png",
  "silhouette": "/games/murder-dinner-party/cards/dolores-vance-sil.png"
}
```

The silhouette should be a true black outline of the avatar, same pose, showing the most
visible features (a huge hat, a tall hairdo, a cane). That is what makes round 3 solvable.
PNG, JPG or SVG all work. The 8 placeholder cards were drawn by
`node tools/make-placeholder-cards.js`; running it again overwrites `cards.json`, so stop using
it once real cards are in.

### Adding content

Locations, weapons, victims and prompt wording are JSON files in
`games/murder-dinner-party/content/`. Each game draws one location, one weapon and one victim,
with no repeats in a room until the list runs out.

## How it's built

```
server/index.js      Express routes and Socket.IO
server/rooms.js      Room codes, QR, joining, reconnect tokens, card picker, start, rematch, cleanup
server/games.js      The list of games
public/              Index page, join page, shared CSS, socket helper, sounds, host lobby
games/<id>/game.js   A game's server-side state machine
games/<id>/host/     Its host screen
games/<id>/controller/  Its phone screen
```

A game module exports `{ id, name, pitch, minPlayers, maxPlayers, cards, createGame(room, ctx) }`.
The game object it returns answers `handle(event, actor, payload)`, `viewFor(player)`,
`onConnectionChange(player)`, `isOver()` and `dispose()`. The room layer handles everything
else, so a second game reuses the lobby, codes, QR, reconnects and card picker as they are.
Only a game's `host/`, `controller/` and `cards/` folders are served; `game.js` and `content/`
stay on the server.

Room codes are 4 letters without I or O. A room is deleted 30 minutes after its last activity.
Sound effects are synthesised in the browser, so there are no audio files.
