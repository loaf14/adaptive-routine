-- Adapt: private, single-user routine data.
-- Run in the Supabase SQL Editor. Replace the placeholder UUID with the
-- authenticated app user's UUID from Authentication > Users.
create table public.activities (
  id bigint generated always as identity primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (length(trim(name)) > 0),
  frequency text,
  created_at timestamptz not null default now(),
  unique (owner_id, name),
  unique (id, owner_id)
);
create table public.adaptations (
  id bigint generated always as identity primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  activity_id bigint not null,
  limitation text not null check (limitation in ('Mental energy','Time','Physical ability')),
  capacity text not null check (capacity in ('Full','Moderate','Low','Minimum')),
  suggestion text not null check (length(trim(suggestion)) > 0),
  created_at timestamptz not null default now(),
  unique (activity_id, limitation, capacity),
  foreign key (activity_id, owner_id) references public.activities(id, owner_id) on delete cascade
);
create index adaptations_owner_idx on public.adaptations(owner_id);
alter table public.activities enable row level security;
alter table public.adaptations enable row level security;
create policy "Owner manages activities" on public.activities
  for all to authenticated using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));
create policy "Owner manages adaptations" on public.adaptations
  for all to authenticated using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));
-- Do not add public/anon policies. No records are visible without login.
