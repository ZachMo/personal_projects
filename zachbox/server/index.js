// Zachbox Games: Express for pages and files, Socket.IO for everything live.
//
//   PORT        port to listen on (default 3000)
//   PUBLIC_URL  base URL for join links and QR codes, e.g. https://zachbox.onrender.com
//               (default: worked out from each host screen's request)
//   MDP_FAST=1  short timers, for testing

const path = require('path');
const fs = require('fs');
const http = require('http');
const express = require('express');
const { Server } = require('socket.io');
const { Rooms } = require('./rooms');
const { getGame, listGames } = require('./games');

const ROOT = path.join(__dirname, '..');
const PUBLIC = path.join(ROOT, 'public');
const GAMES = path.join(ROOT, 'games');

const app = express();
app.disable('x-powered-by');
const server = http.createServer(app);
const io = new Server(server, {
  maxHttpBufferSize: 1e6, // drawings are capped at 150 KB; leave headroom for the envelope
  pingInterval: 10000,
  pingTimeout: 8000,
});
const rooms = new Rooms(io, { publicUrl: process.env.PUBLIC_URL });

const noStore = (res) => res.set('Cache-Control', 'no-store');

app.get('/', (req, res) => { noStore(res); res.sendFile(path.join(PUBLIC, 'index.html')); });
app.get('/join', (req, res) => { noStore(res); res.sendFile(path.join(PUBLIC, 'join.html')); });
app.get('/api/games', (req, res) => res.json(listGames()));
app.get('/healthz', (req, res) => res.send('ok'));

app.use('/shared', express.static(path.join(PUBLIC, 'shared')));
app.use('/favicon.svg', express.static(path.join(PUBLIC, 'favicon.svg')));

// Only these folders of a game are public. game.js and content/ stay on the server.
for (const dir of ['host', 'controller', 'cards']) {
  app.use('/games/:gameId/' + dir, (req, res, next) => {
    if (!getGame(req.params.gameId)) return res.sendStatus(404);
    express.static(path.join(GAMES, req.params.gameId, dir))(req, res, next);
  });
}

// Host screen: the page creates (or rejoins) the room over the socket.
app.get('/host/:gameId', (req, res) => {
  const file = path.join(GAMES, req.params.gameId, 'host', 'index.html');
  if (!getGame(req.params.gameId) || !fs.existsSync(file)) return res.redirect('/');
  noStore(res);
  res.sendFile(file);
});

// Phone controller for whichever game this room is playing.
app.get('/play/:code', (req, res) => {
  const code = String(req.params.code).toUpperCase();
  const room = rooms.get(code);
  if (!room) return res.redirect(`/join?code=${encodeURIComponent(code)}`);
  noStore(res);
  res.sendFile(path.join(GAMES, room.gameId, 'controller', 'index.html'));
});

const PORT = Number(process.env.PORT) || 3000;
if (require.main === module) {
  server.listen(PORT, () => console.log(`Zachbox Games on http://localhost:${PORT}`));
}

module.exports = { app, server, io, rooms };
