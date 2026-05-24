-- ============================================================
-- Fix: allow family members to update/delete their own row
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- ============================================================

-- Allow a user to update their own membership row
-- (needed for upsert when switching families)
drop policy if exists "users can update own membership" on public.family_members;
create policy "users can update own membership"
    on public.family_members for update
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

-- Allow a user to delete their own membership row
-- (needed when leaving a family)
drop policy if exists "users can delete own membership" on public.family_members;
create policy "users can delete own membership"
    on public.family_members for delete
    using (auth.uid() = user_id);
