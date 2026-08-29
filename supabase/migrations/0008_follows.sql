create table follows (
  follower_id uuid not null references auth.users(id) on delete cascade,
  following_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  constraint no_self_follow check (follower_id <> following_id)
);

alter table follows enable row level security;

create policy "follows sao publicamente legiveis"
  on follows for select using (true);

create policy "usuario segue por conta propria"
  on follows for insert with check (auth.uid() = follower_id);

create policy "usuario deixa de seguir por conta propria"
  on follows for delete using (auth.uid() = follower_id);
