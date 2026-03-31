alter table if exists public.shared_readings
  add column if not exists code_type text not null default 'unknown',
  add column if not exists classification_status text not null default 'unknown',
  add column if not exists classification_candidates jsonb not null default '[]'::jsonb,
  add column if not exists details_payload jsonb null,
  add column if not exists schema_version integer not null default 1;

update public.shared_readings
set
  code_type = coalesce(code_type, 'unknown'),
  classification_status = coalesce(classification_status, 'unknown'),
  classification_candidates = coalesce(classification_candidates, '[]'::jsonb),
  details_payload = details_payload,
  schema_version = coalesce(schema_version, 1)
where true;
