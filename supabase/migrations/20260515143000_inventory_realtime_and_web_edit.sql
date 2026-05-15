grant update on public.inventory_items to anon, authenticated;

drop policy if exists inventory_items_update_all on public.inventory_items;
create policy inventory_items_update_all
on public.inventory_items
for update
to anon, authenticated
using (true)
with check (true);

do $$
begin
  if exists (
    select 1
    from pg_publication
    where pubname = 'supabase_realtime'
  ) then
    begin
      alter publication supabase_realtime add table public.inventory_audits;
    exception
      when duplicate_object then null;
    end;

    begin
      alter publication supabase_realtime add table public.inventory_items;
    exception
      when duplicate_object then null;
    end;

    begin
      alter publication supabase_realtime add table public.inventory_audit_results;
    exception
      when duplicate_object then null;
    end;
  end if;
end $$;
