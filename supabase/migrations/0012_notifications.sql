create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  actor_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('like', 'comment', 'follow')),
  post_id uuid references posts(id) on delete cascade,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index notifications_user_idx on notifications (user_id, created_at desc);

alter table notifications enable row level security;

create policy "usuario le suas proprias notificacoes"
  on notifications for select using (auth.uid() = user_id);

create policy "usuario marca como lida a propria notificacao"
  on notifications for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create function notify_on_like() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  post_owner uuid;
begin
  select user_id into post_owner from posts where id = new.post_id;
  if post_owner is not null and post_owner <> new.user_id then
    insert into notifications (user_id, actor_id, kind, post_id)
    values (post_owner, new.user_id, 'like', new.post_id);
  end if;
  return new;
end;
$$;

create trigger likes_notify after insert on likes
  for each row execute function notify_on_like();

create function notify_on_comment() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  post_owner uuid;
begin
  select user_id into post_owner from posts where id = new.post_id;
  if post_owner is not null and post_owner <> new.user_id then
    insert into notifications (user_id, actor_id, kind, post_id)
    values (post_owner, new.user_id, 'comment', new.post_id);
  end if;
  return new;
end;
$$;

create trigger comments_notify after insert on comments
  for each row execute function notify_on_comment();

create function notify_on_follow() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into notifications (user_id, actor_id, kind)
  values (new.following_id, new.follower_id, 'follow');
  return new;
end;
$$;

create trigger follows_notify after insert on follows
  for each row execute function notify_on_follow();
