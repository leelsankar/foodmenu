-- ============================================================
-- Family Menu — Supabase Schema
-- Run this entire file in: Supabase Dashboard → SQL Editor → New query
-- ============================================================

-- 1. Families table
--    One row per household. Members share one family_id.
create table if not exists public.families (
    id            uuid primary key default gen_random_uuid(),
    invite_code   text unique not null default upper(substring(replace(gen_random_uuid()::text,'-',''),1,6)),
    created_at    timestamptz not null default now()
);

-- 2. Family members (links auth users → a family)
create table if not exists public.family_members (
    id            uuid primary key default gen_random_uuid(),
    user_id       uuid not null references auth.users(id) on delete cascade,
    family_id     uuid not null references public.families(id) on delete cascade,
    role          text not null default 'member', -- 'owner' | 'member'
    display_name  text,
    joined_at     timestamptz not null default now(),
    unique(user_id)   -- one user can only belong to one family
);

-- 3. Family data blob
--    Stores the entire app state as a JSON blob per family.
--    This mirrors what was in localStorage, now shared across all family members.
create table if not exists public.family_data (
    family_id     uuid primary key references public.families(id) on delete cascade,
    data          jsonb not null default '{}'::jsonb,
    updated_at    timestamptz not null default now(),
    updated_by    uuid references auth.users(id)
);

-- Auto-update updated_at on every write
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists family_data_updated_at on public.family_data;
create trigger family_data_updated_at
    before update on public.family_data
    for each row execute function public.touch_updated_at();

-- ============================================================
-- Row Level Security (RLS)
-- Only family members can read/write their family's data.
-- ============================================================

alter table public.families       enable row level security;
alter table public.family_members enable row level security;
alter table public.family_data    enable row level security;

-- Helper: get the family_id for the current user
create or replace function public.my_family_id()
returns uuid language sql security definer stable as $$
    select family_id from public.family_members where user_id = auth.uid() limit 1;
$$;

-- families: readable by members, creatable by anyone authenticated
create policy "members can read own family"
    on public.families for select
    using (id = public.my_family_id());

create policy "authenticated users can create family"
    on public.families for insert
    with check (auth.uid() is not null);

-- families: allow reading by invite_code (for joining)
create policy "anyone can lookup family by invite code"
    on public.families for select
    using (true);  -- we gate in app logic; invite_code is a secret

-- family_members: members can see their family's members
create policy "members can read own family members"
    on public.family_members for select
    using (family_id = public.my_family_id());

-- insert: user can only insert their own row
create policy "authenticated users can join a family"
    on public.family_members for insert
    with check (auth.uid() = user_id);

-- update: user can update their own row (needed for upsert / switching families)
create policy "users can update own membership"
    on public.family_members for update
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

-- delete: user can remove their own row (needed when leaving a family)
create policy "users can delete own membership"
    on public.family_members for delete
    using (auth.uid() = user_id);

-- family_data: only family members can read/write
create policy "members can read family data"
    on public.family_data for select
    using (family_id = public.my_family_id());

create policy "members can insert family data"
    on public.family_data for insert
    with check (family_id = public.my_family_id());

create policy "members can update family data"
    on public.family_data for update
    using (family_id = public.my_family_id());

-- ============================================================
-- Realtime: enable broadcasting for family_data changes
-- ============================================================
alter publication supabase_realtime add table public.family_data;

-- ============================================================
-- Done. Copy your invite_code from the families table after
-- your first sign-in and share it with your family members.
-- ============================================================
