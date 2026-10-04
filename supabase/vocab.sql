-- Shared word list for spanish-vocab/spanish-vocab.html.
-- Run once: supabase db query --linked -f supabase/vocab.sql   (safe to run again)

create table if not exists public.vocab_words (
  id           bigint generated always as identity primary key,
  list         text        not null,
  es           text        not null,
  en           text        not null,
  -- the page's own normal form of "es=en", so the same pair is never stored twice
  key          text        not null,
  -- sha-256 of the adding browser's random id: lets that browser delete its own words,
  -- without the public table showing the id itself
  device_hash  text        not null,
  made_at      timestamptz not null default now(),
  constraint list_length check (char_length(list) between 1 and 60),
  constraint es_length   check (char_length(es)   between 1 and 120),
  constraint en_length   check (char_length(en)   between 1 and 160)
);

create unique index if not exists vocab_words_one_pair on public.vocab_words (key);
create index if not exists vocab_words_by_device on public.vocab_words (device_hash, made_at);

-- Everyone may read the list. Nobody may write to it from a browser: the vocab
-- function, which holds the service key, checks every word before it goes in.
alter table public.vocab_words enable row level security;

drop policy if exists "read the words" on public.vocab_words;
create policy "read the words" on public.vocab_words for select using (true);
