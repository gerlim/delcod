create or replace function public.set_shared_readings_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists shared_readings_set_updated_at on public.shared_readings;

create trigger shared_readings_set_updated_at
before insert or update on public.shared_readings
for each row
execute function public.set_shared_readings_updated_at();
