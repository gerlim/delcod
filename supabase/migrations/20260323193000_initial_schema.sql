create extension if not exists pgcrypto;

create table if not exists public.companies (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  status text not null default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  matricula text not null unique,
  nome text not null,
  status text not null default 'active' check (status in ('active', 'inactive', 'blocked')),
  cargo_global text null check (cargo_global in ('admin_global', 'gestor_global')),
  ultimo_login timestamptz null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.company_memberships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  company_id uuid not null references public.companies(id) on delete cascade,
  role text not null check (role in ('reader', 'operator', 'manager', 'admin')),
  status text not null default 'active' check (status in ('active', 'inactive')),
  granted_by uuid null references public.profiles(id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (user_id, company_id)
);

create table if not exists public.collections (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete restrict,
  title text not null,
  status text not null default 'open' check (status in ('open', 'closed')),
  created_by uuid not null references public.profiles(id),
  closed_by uuid null references public.profiles(id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  closed_at timestamptz null
);

create table if not exists public.readings (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete restrict,
  collection_id uuid not null references public.collections(id) on delete cascade,
  code text not null,
  code_type text not null default 'unknown',
  source text not null default 'manual' check (source in ('camera', 'manual', 'pdf')),
  operator_id uuid null references public.profiles(id),
  operator_name text null,
  duplicate_confirmed boolean not null default false,
  device_id text null,
  recorded_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid null references public.profiles(id),
  company_id uuid null references public.companies(id),
  collection_id uuid null references public.collections(id),
  target_table text not null,
  target_id uuid null,
  action text not null check (action in ('create', 'edit', 'delete', 'close_collection', 'create_user', 'update_role', 'login', 'export')),
  origin text not null default 'server',
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists companies_code_idx on public.companies (code);
create index if not exists profiles_matricula_idx on public.profiles (matricula);
create index if not exists company_memberships_user_company_idx on public.company_memberships (user_id, company_id);
create index if not exists collections_company_status_idx on public.collections (company_id, status);
create index if not exists readings_collection_recorded_idx on public.readings (collection_id, recorded_at desc);
create index if not exists readings_company_code_idx on public.readings (company_id, code);
create index if not exists audit_logs_company_created_idx on public.audit_logs (company_id, created_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create or replace function public.current_user_is_global_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.status = 'active'
      and p.cargo_global = 'admin_global'
  );
$$;

create or replace function public.current_user_is_global_manager()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.status = 'active'
      and p.cargo_global in ('admin_global', 'gestor_global')
  );
$$;

create or replace function public.current_user_role_for_company(target_company_id uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select cm.role
  from public.company_memberships cm
  where cm.user_id = auth.uid()
    and cm.company_id = target_company_id
    and cm.status = 'active'
  order by
    case cm.role
      when 'admin' then 4
      when 'manager' then 3
      when 'operator' then 2
      when 'reader' then 1
      else 0
    end desc
  limit 1;
$$;

create or replace function public.current_user_has_company_access(target_company_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public.current_user_is_global_manager()
    or exists (
      select 1
      from public.company_memberships cm
      where cm.user_id = auth.uid()
        and cm.company_id = target_company_id
        and cm.status = 'active'
    );
$$;

create or replace function public.current_user_can_manage_readings(target_company_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public.current_user_is_global_manager()
    or coalesce(public.current_user_role_for_company(target_company_id), '') in ('operator', 'manager', 'admin');
$$;

create or replace function public.current_user_can_manage_collections(target_company_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public.current_user_is_global_manager()
    or coalesce(public.current_user_role_for_company(target_company_id), '') in ('manager', 'admin');
$$;

create or replace function public.current_user_can_admin_company(target_company_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public.current_user_is_global_admin()
    or coalesce(public.current_user_role_for_company(target_company_id), '') = 'admin';
$$;

create or replace function public.current_user_can_view_profile(target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    auth.uid() = target_user_id
    or public.current_user_is_global_manager()
    or exists (
      select 1
      from public.company_memberships viewer
      join public.company_memberships target
        on target.company_id = viewer.company_id
      where viewer.user_id = auth.uid()
        and viewer.status = 'active'
        and viewer.role in ('manager', 'admin')
        and target.user_id = target_user_id
        and target.status = 'active'
    );
$$;

create or replace function public.current_user_can_view_membership(target_user_id uuid, target_company_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    auth.uid() = target_user_id
    or public.current_user_is_global_manager()
    or public.current_user_can_admin_company(target_company_id);
$$;

create or replace function public.current_user_can_view_audit(target_company_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public.current_user_is_global_manager()
    or coalesce(public.current_user_role_for_company(target_company_id), '') in ('manager', 'admin');
$$;

create or replace function public.audit_readings_changes()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  action_name text;
  company_ref uuid;
  collection_ref uuid;
  target_ref uuid;
  payload_ref jsonb;
begin
  if tg_op = 'INSERT' then
    action_name := 'create';
    company_ref := new.company_id;
    collection_ref := new.collection_id;
    target_ref := new.id;
    payload_ref := jsonb_build_object(
      'code', new.code,
      'source', new.source,
      'code_type', new.code_type
    );
  elsif tg_op = 'UPDATE' then
    action_name := 'edit';
    company_ref := new.company_id;
    collection_ref := new.collection_id;
    target_ref := new.id;
    payload_ref := jsonb_build_object(
      'before', jsonb_build_object('code', old.code, 'source', old.source, 'code_type', old.code_type),
      'after', jsonb_build_object('code', new.code, 'source', new.source, 'code_type', new.code_type)
    );
  else
    action_name := 'delete';
    company_ref := old.company_id;
    collection_ref := old.collection_id;
    target_ref := old.id;
    payload_ref := jsonb_build_object(
      'code', old.code,
      'source', old.source,
      'code_type', old.code_type
    );
  end if;

  insert into public.audit_logs (
    actor_id,
    company_id,
    collection_id,
    target_table,
    target_id,
    action,
    origin,
    payload
  ) values (
    auth.uid(),
    company_ref,
    collection_ref,
    'readings',
    target_ref,
    action_name,
    'db_trigger',
    payload_ref
  );

  if tg_op = 'DELETE' then
    return old;
  end if;

  return new;
end;
$$;

create or replace function public.audit_collection_close()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.status is distinct from new.status and new.status = 'closed' then
    insert into public.audit_logs (
      actor_id,
      company_id,
      collection_id,
      target_table,
      target_id,
      action,
      origin,
      payload
    ) values (
      auth.uid(),
      new.company_id,
      new.id,
      'collections',
      new.id,
      'close_collection',
      'db_trigger',
      jsonb_build_object('title', new.title)
    );
  end if;

  return new;
end;
$$;

drop trigger if exists set_companies_updated_at on public.companies;
create trigger set_companies_updated_at
before update on public.companies
for each row
execute function public.set_updated_at();

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

drop trigger if exists set_company_memberships_updated_at on public.company_memberships;
create trigger set_company_memberships_updated_at
before update on public.company_memberships
for each row
execute function public.set_updated_at();

drop trigger if exists set_collections_updated_at on public.collections;
create trigger set_collections_updated_at
before update on public.collections
for each row
execute function public.set_updated_at();

drop trigger if exists set_readings_updated_at on public.readings;
create trigger set_readings_updated_at
before update on public.readings
for each row
execute function public.set_updated_at();

drop trigger if exists audit_readings_changes_trigger on public.readings;
create trigger audit_readings_changes_trigger
after insert or update or delete on public.readings
for each row
execute function public.audit_readings_changes();

drop trigger if exists audit_collection_close_trigger on public.collections;
create trigger audit_collection_close_trigger
after update on public.collections
for each row
execute function public.audit_collection_close();

alter table public.companies enable row level security;
alter table public.profiles enable row level security;
alter table public.company_memberships enable row level security;
alter table public.collections enable row level security;
alter table public.readings enable row level security;
alter table public.audit_logs enable row level security;

grant usage on schema public to authenticated;

grant select on public.companies to authenticated;
grant select on public.profiles to authenticated;
grant select on public.company_memberships to authenticated;
grant select, insert, update on public.collections to authenticated;
grant select, insert, update, delete on public.readings to authenticated;
grant select on public.audit_logs to authenticated;

drop policy if exists companies_select_accessible on public.companies;
create policy companies_select_accessible
on public.companies
for select
to authenticated
using (public.current_user_has_company_access(id));

drop policy if exists profiles_select_visible on public.profiles;
create policy profiles_select_visible
on public.profiles
for select
to authenticated
using (public.current_user_can_view_profile(id));

drop policy if exists company_memberships_select_visible on public.company_memberships;
create policy company_memberships_select_visible
on public.company_memberships
for select
to authenticated
using (public.current_user_can_view_membership(user_id, company_id));

drop policy if exists collections_select_accessible on public.collections;
create policy collections_select_accessible
on public.collections
for select
to authenticated
using (public.current_user_has_company_access(company_id));

drop policy if exists collections_insert_allowed on public.collections;
create policy collections_insert_allowed
on public.collections
for insert
to authenticated
with check (public.current_user_can_manage_readings(company_id));

drop policy if exists collections_update_allowed on public.collections;
create policy collections_update_allowed
on public.collections
for update
to authenticated
using (public.current_user_can_manage_collections(company_id))
with check (public.current_user_can_manage_collections(company_id));

drop policy if exists readings_select_accessible on public.readings;
create policy readings_select_accessible
on public.readings
for select
to authenticated
using (public.current_user_has_company_access(company_id));

drop policy if exists readings_insert_allowed on public.readings;
create policy readings_insert_allowed
on public.readings
for insert
to authenticated
with check (public.current_user_has_company_access(company_id));

drop policy if exists readings_update_allowed on public.readings;
create policy readings_update_allowed
on public.readings
for update
to authenticated
using (public.current_user_can_manage_readings(company_id))
with check (public.current_user_can_manage_readings(company_id));

drop policy if exists readings_delete_allowed on public.readings;
create policy readings_delete_allowed
on public.readings
for delete
to authenticated
using (public.current_user_can_manage_readings(company_id));

drop policy if exists audit_logs_select_allowed on public.audit_logs;
create policy audit_logs_select_allowed
on public.audit_logs
for select
to authenticated
using (
  company_id is not null
  and public.current_user_can_view_audit(company_id)
);
