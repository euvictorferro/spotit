-- Exclusão de conta self-service (exigida pela App Store, guideline 5.1.1v).
-- wallet_items não tinha "on delete cascade" — sem isso, apagar o usuário
-- falhava com violação de FK sempre que ele tivesse algum carro salvo.
alter table wallet_items drop constraint wallet_items_user_id_fkey;
alter table wallet_items add constraint wallet_items_user_id_fkey
  foreign key (user_id) references auth.users(id) on delete cascade;

-- Todo o resto (profiles, posts, likes, comments, follows, conversations,
-- messages, notifications, events, event_attendees) já cascade em
-- auth.users(id), então apagar a linha em auth.users limpa tudo.
--
-- security definer: a role "authenticated" não tem permissão de escrever em
-- auth.users diretamente — a função roda com o dono (postgres), que tem.
create or replace function delete_user() returns void
language plpgsql security definer set search_path = public as $$
begin
  delete from auth.users where id = auth.uid();
end;
$$;

grant execute on function delete_user() to authenticated;

-- ponytail: fotos no Storage (car-photos, avatares) ficam órfãs — não
-- bloqueia a review da Apple (o requisito é apagar a conta/dados pessoais
-- identificáveis, que isso já faz), mas vale um cron de limpeza depois.
