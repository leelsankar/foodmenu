-- ============================================================
-- Fix v2: join_family RPC that bypasses RLS safely
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- ============================================================

-- Drop old conflicting policies first
drop policy if exists "users can update own membership"  on public.family_members;
drop policy if exists "users can delete own membership"  on public.family_members;
drop policy if exists "authenticated users can join a family" on public.family_members;

-- Single clean insert policy (for first-time inserts only)
create policy "authenticated users can insert own membership"
    on public.family_members for insert
    with check (auth.uid() = user_id);

-- Allow users to update their own row (family switch)
create policy "users can update own membership"
    on public.family_members for update
    using  (auth.uid() = user_id)
    with check (auth.uid() = user_id);

-- Allow users to delete their own row
create policy "users can delete own membership"
    on public.family_members for delete
    using (auth.uid() = user_id);

-- ============================================================
-- Secure RPC: join_family(invite_code)
-- Runs as SECURITY DEFINER (postgres role) so it bypasses RLS.
-- Validates the invite code, then upserts the membership row.
-- Returns the new family_id on success, raises exception on error.
-- ============================================================
create or replace function public.join_family(p_invite_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
    v_family_id uuid;
    v_user_id   uuid := auth.uid();
begin
    if v_user_id is null then
        raise exception 'Not authenticated';
    end if;

    -- Look up family by invite code (case-insensitive)
    select id into v_family_id
    from public.families
    where invite_code = upper(trim(p_invite_code));

    if v_family_id is null then
        raise exception 'Invite code not found';
    end if;

    -- Upsert membership: insert or update existing row
    insert into public.family_members (user_id, family_id, role)
    values (v_user_id, v_family_id, 'member')
    on conflict (user_id)
    do update set family_id = excluded.family_id,
                  role      = 'member';

    return v_family_id;
end;
$$;

-- Grant execute to authenticated users
grant execute on function public.join_family(text) to authenticated;
