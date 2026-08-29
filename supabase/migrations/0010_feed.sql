-- posts: carro compartilhado com legenda
create table posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  wallet_item_id uuid references wallet_items(id) on delete set null,
  modelo text not null,
  raridade int not null check (raridade between 1 and 10),
  valor_estimado_usd numeric not null,
  foto_url text not null,
  caption text,
  created_at timestamptz not null default now()
);

alter table posts enable row level security;

create policy "posts sao publicamente legiveis"
  on posts for select using (true);

create policy "usuario publica por conta propria"
  on posts for insert with check (auth.uid() = user_id);

-- likes: curtida em post
create table likes (
  post_id uuid not null references posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

alter table likes enable row level security;

create policy "likes sao publicamente legiveis"
  on likes for select using (true);

create policy "usuario curte por conta propria"
  on likes for insert with check (auth.uid() = user_id);

create policy "usuario descurte por conta propria"
  on likes for delete using (auth.uid() = user_id);

-- comments: comentário em post
create table comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  text text not null check (char_length(text) between 1 and 500),
  created_at timestamptz not null default now()
);

create index comments_post_idx on comments (post_id, created_at);

alter table comments enable row level security;

create policy "comments sao publicamente legiveis"
  on comments for select using (true);

create policy "usuario comenta por conta propria"
  on comments for insert with check (auth.uid() = user_id);
