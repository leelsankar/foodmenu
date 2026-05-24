-- ============================================================
-- Gatherly — Community Dishes Table
-- Run in: Supabase Dashboard → SQL Editor → New query
-- ============================================================
-- Any user who adds a custom dish contributes it to the
-- community list. All users see dishes added by others.
-- Only the original contributor can delete their own dish.
-- ============================================================

create table if not exists public.community_dishes (
    id          text primary key,          -- e.g. "cus_luCurry_1748123456789"
    list_key    text not null,             -- e.g. "luCurry", "bfSingle"
    name        text not null,
    nonveg      boolean not null default false,
    tags        text[] not null default '{}',
    added_by    uuid references auth.users(id) on delete set null,
    added_at    timestamptz not null default now()
);

-- Index for fast lookup by list_key
create index if not exists community_dishes_list_key_idx
    on public.community_dishes(list_key);

-- RLS
alter table public.community_dishes enable row level security;

-- Anyone (including anonymous) can read all community dishes
create policy "anyone can read community dishes"
    on public.community_dishes for select
    using (true);

-- Authenticated users can insert their own dishes
create policy "authenticated users can add dishes"
    on public.community_dishes for insert
    with check (auth.uid() is not null);

-- Users can only delete dishes they added
create policy "users can delete own dishes"
    on public.community_dishes for delete
    using (auth.uid() = added_by);

-- Enable realtime so new dishes appear instantly for all users
alter publication supabase_realtime add table public.community_dishes;
