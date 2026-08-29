create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  display_name text,
  bio text,
  avatar_url text,
  created_at timestamptz not null default now()
);

alter table profiles enable row level security;

create policy "profiles are publicly readable"
  on profiles for select using (true);

create policy "users manage own profile"
  on profiles for insert with check (auth.uid() = id);

create policy "users update own profile"
  on profiles for update using (auth.uid() = id);
