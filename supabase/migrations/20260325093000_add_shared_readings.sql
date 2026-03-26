create table if not exists public.shared_readings (
  id uuid primary key,
  code text not null,
  source text not null default 'manual',
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz null,
  device_id text not null
);

alter table public.shared_readings enable row level security;

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on table public.shared_readings to anon, authenticated;

drop policy if exists "shared_readings_select_all" on public.shared_readings;
create policy "shared_readings_select_all"
on public.shared_readings
for select
to anon, authenticated
using (true);

drop policy if exists "shared_readings_insert_all" on public.shared_readings;
create policy "shared_readings_insert_all"
on public.shared_readings
for insert
to anon, authenticated
with check (true);

drop policy if exists "shared_readings_update_all" on public.shared_readings;
create policy "shared_readings_update_all"
on public.shared_readings
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "shared_readings_delete_all" on public.shared_readings;
create policy "shared_readings_delete_all"
on public.shared_readings
for delete
to anon, authenticated
using (true);

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'shared_readings'
  ) then
    alter publication supabase_realtime add table public.shared_readings;
  end if;
end $$;
