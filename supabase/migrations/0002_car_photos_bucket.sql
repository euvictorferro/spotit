insert into storage.buckets (id, name, public)
values ('car-photos', 'car-photos', true)
on conflict (id) do nothing;

create policy "leitura publica de fotos de carro"
  on storage.objects for select
  using (bucket_id = 'car-photos');

create policy "usuarios autenticados fazem upload de fotos"
  on storage.objects for insert
  with check (bucket_id = 'car-photos' and auth.role() = 'authenticated');
