create table wallet_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  modelo text not null,
  ano int,
  motor text,
  raridade int not null check (raridade between 1 and 10),
  valor_estimado_usd numeric not null,
  fato_interessante text,
  foto_url text not null,
  lat numeric,
  lng numeric,
  created_at timestamptz not null default now()
);

alter table wallet_items enable row level security;

create policy "usuarios leem seus proprios itens"
  on wallet_items for select
  using (auth.uid() = user_id);

create policy "usuarios inserem seus proprios itens"
  on wallet_items for insert
  with check (auth.uid() = user_id);
