create index if not exists shared_readings_active_updated_at_idx
  on public.shared_readings (updated_at desc)
  where deleted_at is null;

create index if not exists shared_readings_deleted_at_idx
  on public.shared_readings (deleted_at);
