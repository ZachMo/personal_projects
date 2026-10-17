// Registry of games. Each game module exports:
//   { id, name, pitch, minPlayers, maxPlayers, minutes, cards, createGame(room, ctx) }
// To add a game, write its module under games/<id>/game.js and list it here.

const murderDinnerParty = require('../games/murder-dinner-party/game');

const GAMES = [murderDinnerParty];

const byId = new Map(GAMES.map((g) => [g.id, g]));

function getGame(id) {
  return byId.get(id);
}

// Public info for the index page. No cards, no content.
function listGames() {
  return GAMES.map((g) => ({
    id: g.id,
    name: g.name,
    pitch: g.pitch,
    minPlayers: g.minPlayers,
    maxPlayers: g.maxPlayers,
    minutes: g.minutes,
  }));
}

module.exports = { getGame, listGames };
