-- Evita spam de notificação em loop de like/unlike/like ou follow/unfollow/follow
-- rápido. Janela de 1 minuto: suficiente pra frear um toggle nervoso na UI sem
-- impedir uma curtida/follow genuína e independente horas depois.

create or replace function notify_on_like() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  post_owner uuid;
begin
  select user_id into post_owner from posts where id = new.post_id;
  if post_owner is not null and post_owner <> new.user_id
     and not exists (
       select 1 from notifications
       where user_id = post_owner and actor_id = new.user_id
         and kind = 'like' and post_id = new.post_id
         and created_at > now() - interval '1 minute'
     )
  then
    insert into notifications (user_id, actor_id, kind, post_id)
    values (post_owner, new.user_id, 'like', new.post_id);
  end if;
  return new;
end;
$$;

create or replace function notify_on_comment() returns trigger
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
-- comment não precisa de dedupe por janela de tempo (cada comentário é um evento
-- distinto e legítimo, diferente de like/unlike/like que é o mesmo "gosto" repetido)

create or replace function notify_on_follow() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.follower_id <> new.following_id
     and not exists (
       select 1 from notifications
       where user_id = new.following_id and actor_id = new.follower_id
         and kind = 'follow'
         and created_at > now() - interval '1 minute'
     )
  then
    insert into notifications (user_id, actor_id, kind)
    values (new.following_id, new.follower_id, 'follow');
  end if;
  return new;
end;
$$;
