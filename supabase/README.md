# The daily leaderboard

A top ten for each day's map in `hugelland.html`, on a free Supabase project.

The browser never sends a score. It sends the **moves**, and a function plays them again on that day's map and
works out the score itself. The rules it plays by are read from the deployed `hugelland.html`, so the board can
never drift from the game. A tampered town is refused: a move nudged one square, two moves swapped, a move
dropped or added, or moves from another day all fail to replay.

Until `CLOUD.url` and `CLOUD.key` are filled in, the game makes no network calls at all and shows no board.

## Setting it up

**1. Make the project.** At supabase.com, create a project on the free plan. Pick a region near your players.

**2. Make the tables.** Open the SQL editor, paste `schema.sql` from this folder, and run it. It creates
`daily_scores` and `daily_par`, turns on row level security, and adds read-only policies. There is no insert
policy, so the public key cannot write. That is what keeps invented scores out.

**3. Deploy the function.** With the Supabase CLI:

```sh
supabase login
supabase link --project-ref <your-project-ref>
supabase functions deploy score --no-verify-jwt
```

`--no-verify-jwt` lets players post without signing in. `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are
already set inside functions; the service key never leaves the server.

If the game is not at `https://zachmo.github.io/personal_projects/hugelland.html`, point the function at it:

```sh
supabase secrets set GAME_URL=https://your-site/hugelland.html
```

**4. Switch the game on.** In `hugelland.html`, find `const CLOUD` and fill in two values from
Settings → API in Supabase:

```js
const CLOUD = { url: "https://abcdefgh.supabase.co", key: "<the anon public key>", table: "daily_scores", fn: "score" };
```

The anon key is meant to be public. It can only read the board, because of step 2.

**5. Try it.** Finish today's daily map. The summary gains a "Today's top ten" page. In Supabase, the table
editor should show the row, with the score the function worked out, not the one the browser claimed.

## Where it stands now

The project `hugelland` (`tnaassoaraijvhswevvp`) is live: the tables and policies are in, the `score` function is
deployed, and `CLOUD` in `hugelland.html` is filled in with the project URL and the publishable key. A finished
daily town posts its moves, the function replays it and the summary shows the day's top ten.

Deploying a change to the function later:

```sh
supabase functions deploy score --no-verify-jwt
```

Running SQL against it without leaving the terminal:

```sh
supabase db query --linked -f supabase/schema.sql
```

## What it does and does not stop

- **Stops:** editing the score in the page, posting a town that never happened, replaying a town on the wrong
  day, posting a half-finished town, and posting twice from the same browser for one day.
- **Does not stop:** a person writing a bot that plays well, or clearing their browser to post again. Both are
  real limits. If the board is ever worth gaming, the next steps are a signed-in account per player and a check
  on how long the town took to build.

## Costs

A free project covers this easily: a row is about 60 bytes, and one function call per finished town.
Par is worked out once per day and kept in `daily_par`.
