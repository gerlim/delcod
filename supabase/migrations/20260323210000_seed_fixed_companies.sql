insert into public.companies (code, name, status)
values
  ('del-papeis', 'Del Papeis', 'active'),
  ('bora-embalagens', 'Bora Embalagens', 'active'),
  ('abn-embalagens', 'ABN Embalagens', 'active')
on conflict (code) do update
set
  name = excluded.name,
  status = excluded.status;
