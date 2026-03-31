alter table if exists public.shared_readings
  add column if not exists metadata_payload jsonb null;
