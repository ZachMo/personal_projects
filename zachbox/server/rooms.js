// Rooms: codes, host screens, joining, reconnect tokens, the shared card
// picker, start / rematch, and cleanup. Shared by every game.
//
// A game module only sees the room through `ctx` (see makeCtx) and answers
// three questions: what happens on an event, what each client may see, and
// what to do when someone's connection drops.

const crypto = require('crypto');
const QRCode = require('qrcode');
const { getGame } = require('./games');

const CODE_LETTERS = 'ABCDEFGHJKLMNPQRSTUVWXYZ'; // no I or O
const ROOM_IDLE_MS = 30 * 60 * 1000; // delete a room 30 min after its last activity
const LOBBY_DROP_MS = 45 * 1000; // a phone gone this long from the lobby frees its card

// Events the room layer handles itself. Anything else goes to the game.
const ROOM_EVENTS = new Set([
  'room:create', 'host:rejoin', 'room:join', 'card:pick', 'card:release',
  'game:start', 'game:rematch', 'game:lobby', 'vote:rematch',
]);

const token = () => crypto.randomBytes(18).toString('base64url');
const newId = () => crypto.randomBytes(6).toString('hex');

class Rooms {
  constructor(io, opts = {}) {
    this.io = io;
    this.rooms = new Map();
    this.publicUrl = opts.publicUrl || null;
    this.sweeper = setInterval(() => this.sweep(), 15 * 1000);
    this.sweeper.unref();
    io.on('connection', (socket) => this.attach(socket));
  }

  // ---------- helpers ----------

  makeCode() {
    for (let tries = 0; tries < 1000; tries++) {
      let code = '';
      for (let i = 0; i < 4; i++) code += CODE_LETTERS[crypto.randomInt(CODE_LETTERS.length)];
      if (!this.rooms.has(code)) return code;
    }
    throw new Error('No free room codes');
  }

  get(code) {
    return this.rooms.get(String(code || '').trim().toUpperCase());
  }

  baseUrl(socket) {
    if (this.publicUrl) return this.publicUrl.replace(/\/$/, '');
    const h = socket.handshake.headers;
    const proto = (h['x-forwarded-proto'] || '').split(',')[0] || (socket.handshake.secure ? 'https' : 'http');
    return `${proto}://${h['x-forwarded-host'] || h.host}`;
  }

  touch(room) {
    room.lastActivity = Date.now();
  }

  cardedPlayers(room) {
    return room.players.filter((p) => p.cardId);
  }

  publicCards(room) {
    // Silhouettes stay off the public list; the game sends one only to the phones that may see it.
    return room.module.cards.map(({ silhouette, ...c }) => c);
  }

  publicPlayers(room) {
    return this.cardedPlayers(room).map((p) => ({
      id: p.id,
      cardId: p.cardId,
      connected: p.connected,
      isVip: p.id === room.vipPlayerId,
    }));
  }

  lobbyInfo(room) {
    const carded = this.cardedPlayers(room).length;
    return {
      players: this.publicPlayers(room),
      taken: this.cardedPlayers(room).map((p) => p.cardId),
      vipPlayerId: room.vipPlayerId,
      minPlayers: room.module.minPlayers,
      maxPlayers: room.module.maxPlayers,
      canStart: !room.game && carded >= room.module.minPlayers,
    };
  }

  // The personalised state for one client. player = null means a host screen.
  viewFor(room, player) {
    const base = {
      code: room.code,
      gameId: room.gameId,
      serverNow: Date.now(),
      isHost: !player,
      me: player ? { id: player.id, cardId: player.cardId, isVip: player.id === room.vipPlayerId } : null,
      players: this.publicPlayers(room),
      rematchVotes: room.rematchVotes.size,
    };
    if (!room.game) {
      return { ...base, phase: 'LOBBY', lobby: this.lobbyInfo(room) };
    }
    const gv = room.game.viewFor(player);
    return { ...base, ...gv, me: base.me && { ...base.me, ...gv.me } };
  }

  // Send every client its own state.
  broadcast(room) {
    for (const sid of room.hostSockets) this.io.to(sid).emit('state:update', this.viewFor(room, null));
    for (const p of room.players) {
      if (p.socketId) this.io.to(p.socketId).emit('state:update', this.viewFor(room, p));
    }
  }

  emitAll(room, event, data) {
    for (const sid of room.hostSockets) this.io.to(sid).emit(event, data);
    for (const p of room.players) if (p.socketId) this.io.to(p.socketId).emit(event, data);
  }

  lobbyUpdate(room) {
    this.emitAll(room, 'lobby:update', this.lobbyInfo(room));
  }

  makeCtx(room) {
    return {
      broadcast: () => this.broadcast(room),
      emitAll: (event, data) => this.emitAll(room, event, data),
      rematch: (opts) => this.startGame(room, opts),
      // Data a game keeps between rematches in the same room (content bags, Detective rotation).
      store: room.store,
    };
  }

  startGame(room, opts = {}) {
    if (room.game) room.game.dispose();
    room.rematchVotes.clear();
    room.game = room.module.createGame(room, this.makeCtx(room), opts);
    room.game.start();
    this.touch(room);
    this.broadcast(room);
    this.lobbyUpdate(room);
  }

  backToLobby(room) {
    if (room.game) room.game.dispose();
    room.game = null;
    room.rematchVotes.clear();
    this.broadcast(room);
    this.lobbyUpdate(room);
  }

  removePlayer(room, player, reason) {
    room.players = room.players.filter((p) => p !== player);
    if (player.socketId) {
      const s = this.io.sockets.sockets.get(player.socketId);
      if (s) {
        s.emit('room:kicked', { reason });
        s.data = {};
      }
    }
    if (room.vipPlayerId === player.id) {
      const next = room.players.find((p) => p.connected && p.cardId) || room.players[0];
      room.vipPlayerId = next ? next.id : null;
    }
  }

  sweep() {
    const now = Date.now();
    for (const room of this.rooms.values()) {
      if (now - room.lastActivity > ROOM_IDLE_MS) {
        if (room.game) room.game.dispose();
        this.emitAll(room, 'room:closed', { reason: 'This room timed out.' });
        this.rooms.delete(room.code);
        continue;
      }
      if (!room.game) {
        const gone = room.players.filter((p) => !p.connected && now - p.disconnectedAt > LOBBY_DROP_MS);
        if (gone.length) {
          for (const p of gone) this.removePlayer(room, p, 'You left the lobby.');
          this.broadcast(room);
          this.lobbyUpdate(room);
        }
      }
    }
  }

  // ---------- socket wiring ----------

  attach(socket) {
    socket.data = {};
    const on = (event, fn) => {
      socket.on(event, (payload, ack) => {
        if (typeof payload === 'function') { ack = payload; payload = undefined; }
        const reply = typeof ack === 'function' ? ack : () => {};
        const fail = (err) => {
          console.error(`[${event}]`, err);
          reply({ ok: false, error: 'Something went wrong.' });
        };
        try {
          Promise.resolve(fn(payload || {}, reply)).catch(fail);
        } catch (err) {
          fail(err);
        }
      });
    };

    on('room:create', (payload, reply) => this.onCreate(socket, payload, reply));
    on('host:rejoin', (payload, reply) => this.onHostRejoin(socket, payload, reply));
    on('room:join', (payload, reply) => this.onJoin(socket, payload, reply));
    on('card:pick', (payload, reply) => this.onCardPick(socket, payload, reply));
    on('card:release', (payload, reply) => this.onCardRelease(socket, payload, reply));
    on('game:start', (payload, reply) => this.onStart(socket, payload, reply));
    on('game:rematch', (payload, reply) => this.onRematch(socket, payload, reply));
    on('game:lobby', (payload, reply) => this.onLobby(socket, payload, reply));
    on('vote:rematch', (payload, reply) => this.onVote(socket, payload, reply));

    // Everything else belongs to the running game.
    socket.onAny((event, payload, ack) => {
      if (ROOM_EVENTS.has(event)) return;
      if (typeof payload === 'function') { ack = payload; payload = undefined; }
      const reply = typeof ack === 'function' ? ack : () => {};
      const { room, player, isHost } = this.whoIs(socket);
      if (!room || !room.game) return reply({ ok: false, error: 'No game running.' });
      this.touch(room);
      try {
        reply(room.game.handle(event, { player, isHost, isVip: !!player && player.id === room.vipPlayerId }, payload || {}) || { ok: true });
      } catch (err) {
        console.error(`[${event}]`, err);
        reply({ ok: false, error: 'Something went wrong.' });
      }
    });

    socket.on('disconnect', () => this.onDisconnect(socket));
  }

  // Identity always comes from what the server stored on this socket, never from the payload.
  whoIs(socket) {
    const room = socket.data.code ? this.rooms.get(socket.data.code) : null;
    if (!room) return {};
    if (socket.data.host) return { room, isHost: room.hostSockets.has(socket.id) };
    const player = room.players.find((p) => p.id === socket.data.playerId && p.socketId === socket.id);
    return { room, player };
  }

  async onCreate(socket, { gameId }, reply) {
    const module = getGame(gameId);
    if (!module) return reply({ ok: false, error: 'Unknown game.' });
    const code = this.makeCode();
    const joinUrl = `${this.baseUrl(socket)}/join?code=${code}`;
    const qr = await QRCode.toDataURL(joinUrl, {
      margin: 1, width: 360, errorCorrectionLevel: 'M',
      color: { dark: '#1a1208', light: '#f3e9d2' },
    });
    const room = {
      code, gameId, module,
      hostToken: token(),
      hostSockets: new Set([socket.id]),
      vipPlayerId: null,
      players: [],
      game: null,
      store: {},
      rematchVotes: new Set(),
      joinUrl, qr,
      lastActivity: Date.now(),
    };
    this.rooms.set(code, room);
    socket.data = { code, host: true };
    reply({ ok: true, code, hostToken: room.hostToken, joinUrl, qr, cards: this.publicCards(room), game: { id: module.id, name: module.name } });
    this.broadcast(room);
  }

  onHostRejoin(socket, { code, hostToken }, reply) {
    const room = this.get(code);
    if (!room || !hostToken || hostToken !== room.hostToken) return reply({ ok: false, error: 'Room not found.' });
    room.hostSockets.add(socket.id);
    socket.data = { code: room.code, host: true };
    this.touch(room);
    reply({ ok: true, code: room.code, joinUrl: room.joinUrl, qr: room.qr, cards: this.publicCards(room), game: { id: room.module.id, name: room.module.name } });
    socket.emit('state:update', this.viewFor(room, null));
  }

  onJoin(socket, { code, token: tok }, reply) {
    const room = this.get(code);
    if (!room) return reply({ ok: false, error: 'No room with that code.' });

    let player = tok ? room.players.find((p) => p.token === tok) : null;
    if (!player) {
      if (room.game) return reply({ ok: false, error: 'Game in progress. Wait for the next one.' });
      if (this.cardedPlayers(room).length >= room.module.maxPlayers) return reply({ ok: false, error: 'This room is full.' });
      player = { id: newId(), token: token(), cardId: null, socketId: null, connected: false, disconnectedAt: 0 };
      room.players.push(player);
      if (!room.vipPlayerId) room.vipPlayerId = player.id;
    }

    // One live socket per player. A refresh or second tab takes over.
    if (player.socketId && player.socketId !== socket.id) {
      const old = this.io.sockets.sockets.get(player.socketId);
      if (old) { old.emit('room:kicked', { reason: 'You opened this game somewhere else.' }); old.data = {}; }
    }
    player.socketId = socket.id;
    player.connected = true;
    socket.data = { code: room.code, playerId: player.id };
    this.touch(room);
    if (room.game) room.game.onConnectionChange(player);

    reply({
      ok: true,
      code: room.code,
      gameId: room.gameId,
      playerId: player.id,
      token: player.token,
      cardId: player.cardId,
      inGame: !!room.game,
      cards: this.publicCards(room),
      lobby: this.lobbyInfo(room),
    });
    this.broadcast(room);
    this.lobbyUpdate(room);
  }

  onCardPick(socket, { cardId }, reply) {
    const { room, player } = this.whoIs(socket);
    if (!room || !player) return reply({ ok: false, error: 'Join a room first.' });
    if (room.game) return reply({ ok: false, error: 'The game has started.' });
    if (!room.module.cards.some((c) => c.id === cardId)) return reply({ ok: false, error: 'Unknown card.' });
    if (player.cardId === cardId) return reply({ ok: true, cardId });
    const holder = room.players.find((p) => p.cardId === cardId);
    if (holder) return reply({ ok: false, error: 'Taken', taken: true });
    if (!player.cardId && this.cardedPlayers(room).length >= room.module.maxPlayers) {
      return reply({ ok: false, error: 'This room is full.' });
    }
    player.cardId = cardId; // swapping frees the old card
    this.touch(room);
    reply({ ok: true, cardId });
    this.broadcast(room);
    this.lobbyUpdate(room);
  }

  onCardRelease(socket, _payload, reply) {
    const { room, player } = this.whoIs(socket);
    if (!room || !player || room.game) return reply({ ok: false });
    player.cardId = null;
    reply({ ok: true });
    this.broadcast(room);
    this.lobbyUpdate(room);
  }

  canControl(socket) {
    const { room, player, isHost } = this.whoIs(socket);
    const ok = !!room && (isHost || (player && player.id === room.vipPlayerId));
    return { room, ok };
  }

  onStart(socket, _payload, reply) {
    const { room, ok } = this.canControl(socket);
    if (!ok) return reply({ ok: false, error: 'Only the host or the VIP can start.' });
    if (room.game) return reply({ ok: false, error: 'Already started.' });
    if (this.cardedPlayers(room).length < room.module.minPlayers) {
      return reply({ ok: false, error: `Need at least ${room.module.minPlayers} players.` });
    }
    // Phones that never picked a card sit this one out.
    for (const p of room.players.filter((p) => !p.cardId)) this.removePlayer(room, p, 'The game started before you picked a card.');
    this.startGame(room);
    reply({ ok: true });
  }

  onRematch(socket, _payload, reply) {
    const { room, ok } = this.canControl(socket);
    if (!ok) return reply({ ok: false, error: 'Only the host or the VIP can start a rematch.' });
    if (!room.game || !room.game.isOver()) return reply({ ok: false, error: 'The game is still going.' });
    if (room.players.length < room.module.minPlayers) return reply({ ok: false, error: 'Not enough players. Go back to the lobby.' });
    this.startGame(room);
    reply({ ok: true });
  }

  onLobby(socket, _payload, reply) {
    const { room, ok } = this.canControl(socket);
    if (!ok) return reply({ ok: false, error: 'Only the host or the VIP can do that.' });
    if (room.game && !room.game.isOver()) return reply({ ok: false, error: 'The game is still going.' });
    this.backToLobby(room);
    reply({ ok: true });
  }

  onVote(socket, _payload, reply) {
    const { room, player } = this.whoIs(socket);
    if (!room || !player || !room.game || !room.game.isOver()) return reply({ ok: false });
    room.rematchVotes.add(player.id);
    this.touch(room);
    reply({ ok: true });
    this.broadcast(room);
  }

  onDisconnect(socket) {
    const { code, host, playerId } = socket.data || {};
    const room = code && this.rooms.get(code);
    if (!room) return;
    if (host) {
      room.hostSockets.delete(socket.id);
      return;
    }
    const player = room.players.find((p) => p.id === playerId);
    if (!player || player.socketId !== socket.id) return;
    player.socketId = null;
    player.connected = false;
    player.disconnectedAt = Date.now();
    if (room.game) room.game.onConnectionChange(player);
    this.broadcast(room);
    this.lobbyUpdate(room);
  }
}

module.exports = { Rooms };
