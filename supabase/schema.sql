-- Adapt: one private account, shared activity catalog, no per-row owner_id.
-- BEFORE RUNNING: replace 00000000-0000-0000-0000-000000000000 below
-- with the Adapt app user's UID from Supabase Authentication > Users.
-- Keep the UUID out of GitHub; replace it only in the SQL Editor.
-- Run once in a new Supabase project, before inserting any data.

create table public.activities (
  id bigint generated always as identity primary key,
  name text not null unique check (length(trim(name)) > 0),
  frequency text,
  created_at timestamptz not null default now()
);

create table public.adaptations (
  id bigint generated always as identity primary key,
  activity_id bigint not null references public.activities(id) on delete cascade,
  limitation text not null check (limitation in ('Mental energy', 'Time', 'Physical ability')),
  capacity text not null check (capacity in ('Full', 'Moderate', 'Low', 'Minimum')),
  suggestion text not null check (length(trim(suggestion)) > 0),
  created_at timestamptz not null default now(),
  unique (activity_id, limitation, capacity)
);

-- This is the one place we identify the only allowed app user.
-- The zero UUID deliberately matches no real account until replaced.
create function public.is_adapt_user()
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select (select auth.uid()) = '8385049a-70a1-44db-8f34-3c1353b58a82'::uuid;
$$;

-- Restrict client roles to the exact operations the app needs.
alter table public.activities enable row level security;
alter table public.adaptations enable row level security;
revoke all on table public.activities, public.adaptations from anon, authenticated;
grant select, insert, update, delete on table public.activities, public.adaptations to authenticated;
revoke all on function public.is_adapt_user() from public;
grant execute on function public.is_adapt_user() to authenticated;
-- Identity sequences may require usage when inserting via the API.
grant usage on sequence public.activities_id_seq, public.adaptations_id_seq to authenticated;

-- Each operation is restricted to the single approved authenticated user.
create policy "Adapt user reads activities" on public.activities
  for select to authenticated using ((select public.is_adapt_user()));
create policy "Adapt user adds activities" on public.activities
  for insert to authenticated with check ((select public.is_adapt_user()));
create policy "Adapt user edits activities" on public.activities
  for update to authenticated using ((select public.is_adapt_user()))
  with check ((select public.is_adapt_user()));
create policy "Adapt user deletes activities" on public.activities
  for delete to authenticated using ((select public.is_adapt_user()));

create policy "Adapt user reads adaptations" on public.adaptations
  for select to authenticated using ((select public.is_adapt_user()));
create policy "Adapt user adds adaptations" on public.adaptations
  for insert to authenticated with check ((select public.is_adapt_user()));
create policy "Adapt user edits adaptations" on public.adaptations
  for update to authenticated using ((select public.is_adapt_user()))
  with check ((select public.is_adapt_user()));
create policy "Adapt user deletes adaptations" on public.adaptations
  for delete to authenticated using ((select public.is_adapt_user()));

-- Before connecting the frontend, verify that an anonymous request and
-- a different authenticated user cannot read or modify either table.
-- The Supabase SQL Editor runs as a privileged role and does not test RLS.
