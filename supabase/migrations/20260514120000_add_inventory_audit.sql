create table if not exists public.inventory_audits (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  status text not null default 'active' check (status in ('active', 'archived')),
  imported_at timestamptz not null default timezone('utc', now()),
  item_count integer not null default 0 check (item_count >= 0),
  source_filename text not null default '',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists inventory_audits_one_active_idx
  on public.inventory_audits ((status))
  where status = 'active';

create table if not exists public.inventory_items (
  id uuid primary key default gen_random_uuid(),
  audit_id uuid not null references public.inventory_audits(id) on delete cascade,
  company_name text not null,
  bobbin_code text not null default '',
  item_description text not null default '',
  barcode text not null,
  weight text not null default '',
  warehouse text not null default '',
  row_number integer not null,
  raw_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  unique (audit_id, barcode)
);

create index if not exists inventory_items_audit_barcode_idx
  on public.inventory_items (audit_id, barcode);

create index if not exists inventory_items_audit_company_idx
  on public.inventory_items (audit_id, company_name);

create table if not exists public.inventory_audit_results (
  id uuid primary key default gen_random_uuid(),
  audit_id uuid not null references public.inventory_audits(id) on delete cascade,
  inventory_item_id uuid null references public.inventory_items(id) on delete set null,
  scanned_barcode text not null,
  status text not null check (status in ('correct', 'incorrect', 'not_found')),
  discrepancy_fields jsonb not null default '[]'::jsonb,
  note text null,
  device_id text null,
  scanned_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now()),
  unique (audit_id, scanned_barcode)
);

create index if not exists inventory_audit_results_audit_status_idx
  on public.inventory_audit_results (audit_id, status);

create index if not exists inventory_audit_results_item_idx
  on public.inventory_audit_results (inventory_item_id);

create or replace function public.set_inventory_audit_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists inventory_audits_set_updated_at on public.inventory_audits;
create trigger inventory_audits_set_updated_at
before update on public.inventory_audits
for each row
execute function public.set_inventory_audit_updated_at();

alter table public.inventory_audits enable row level security;
alter table public.inventory_items enable row level security;
alter table public.inventory_audit_results enable row level security;

grant usage on schema public to anon, authenticated;
grant select, insert, update on public.inventory_audits to anon, authenticated;
grant select, insert on public.inventory_items to anon, authenticated;
grant select, insert on public.inventory_audit_results to anon, authenticated;

drop policy if exists inventory_audits_select_all on public.inventory_audits;
create policy inventory_audits_select_all
on public.inventory_audits
for select
to anon, authenticated
using (true);

drop policy if exists inventory_audits_insert_all on public.inventory_audits;
create policy inventory_audits_insert_all
on public.inventory_audits
for insert
to anon, authenticated
with check (true);

drop policy if exists inventory_audits_update_all on public.inventory_audits;
create policy inventory_audits_update_all
on public.inventory_audits
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists inventory_items_select_all on public.inventory_items;
create policy inventory_items_select_all
on public.inventory_items
for select
to anon, authenticated
using (true);

drop policy if exists inventory_items_insert_all on public.inventory_items;
create policy inventory_items_insert_all
on public.inventory_items
for insert
to anon, authenticated
with check (true);

drop policy if exists inventory_audit_results_select_all on public.inventory_audit_results;
create policy inventory_audit_results_select_all
on public.inventory_audit_results
for select
to anon, authenticated
using (true);

drop policy if exists inventory_audit_results_insert_all on public.inventory_audit_results;
create policy inventory_audit_results_insert_all
on public.inventory_audit_results
for insert
to anon, authenticated
with check (true);
