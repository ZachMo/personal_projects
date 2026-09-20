-- The daily leaderboard for hugelland.html.
-- Run this once in the Supabase SQL editor. See README.md next to this file.

create table if not exists public.daily_scores (
  id          bigint generated always as identity primary key,
  day         date        not null,
  name        text        not null,
  score       int         not null,
  goals       int         not null default 0,
  par         int         not null default 0,
  away        int         not null default 0,
  device      text        not null,
  made_at     timestamptz not null default now(),
  constraint name_length  check (char_length(name) between 1 and 14),
  constraint score_sane   check (score between -200 and 400),
  constraint goals_sane   check (goals between 0 and 3)
);

-- A day counts once for a browser: the first finished town is the one that stands.
create unique index if not exists daily_scores_one_a_day on public.daily_scores (day, device);
create index if not exists daily_scores_board on public.daily_scores (day, score desc);

-- Par is the same for everybody on a day, and costs a second to work out, so it is worked out once.
create table if not exists public.daily_par (
  day     date primary key,
  par     int  not null,
  made_at timestamptz not null default now()
);

-- Everyone may read the board. Nobody may write to it from a browser: only the
-- score function, which holds the service key, can insert.
alter table public.daily_scores enable row level security;
alter table public.daily_par    enable row level security;

drop policy if exists "read the board" on public.daily_scores;
create policy "read the board" on public.daily_scores for select using (true);

drop policy if exists "read par" on public.daily_par;
create policy "read par" on public.daily_par for select using (true);

-- No insert, update or delete policies exist, so with row level security on,
-- the anon key cannot write. That is the point: scores arrive only through the function.
