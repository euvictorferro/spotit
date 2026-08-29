# Notificações — design

## Contexto

`NotificationsView` já tem UI completa (lista por seção, marcar como lida,
abrir post/perfil) rodando sobre `AppNotification` local — hoje
`notifications = []` fixo. Sem spec/plan formal — decisões abaixo são
**Ruling**.

## Objetivo

Notificar o usuário quando alguém curte/comenta um post seu ou passa a
seguir você, gerado automaticamente no banco (não pelo client) — mais
confiável e não perdível se o app estiver fechado no momento da ação.

## Escopo

- Tabela `notifications`
- Gerada via trigger (`security definer`) no insert de `likes`, `comments`,
  `follows` — o client nunca insere notificação diretamente
- Listar notificações do usuário logado, marcar como lida
- Abrir o post (curtida/comentário) ou o perfil (novo seguidor) ao tocar

## Fora de escopo (Ruling)

- **"Sugestões pra seguir de volta"**: a UI existente tem essa seção —
  fica com `suggestions: []` fixo por enquanto (like antes), é uma
  feature própria (cross-referenciar `follows` pra achar quem te segue e
  você não segue de volta), não faz parte desta frente
- **Push notification de verdade (APNs)**: fora de escopo, é só a lista
  dentro do app
- **Notificação de menção/reply em comentário**: fora de escopo

## Dados

```sql
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
```

**Sem policy de INSERT pro client** — só os triggers (`security definer`)
escrevem nesta tabela. **A policy de UPDATE aqui tem `WITH CHECK` explícito
e idêntico ao `USING`** (lição do bug de segurança do DM: nunca deixar
`UPDATE` sem `WITH CHECK` — aqui o dado que pode mudar é só `is_read`, e o
`WITH CHECK` impede qualquer tentativa de reatribuir a notificação pra
outro `user_id`).

### Triggers

```sql
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
```

`post_owner <> new.user_id`/checagem equivalente em `follows` (que já tem
`no_self_follow`) evita notificar a si mesmo.

## Componentes

### `SupabaseService` (métodos novos)

- `static func fetchNotifications() async throws -> [DBNotification]` —
  join com `profiles` (autor da ação) e `posts` (pra abrir o post certo),
  mais recentes primeiro
- `static func markNotificationRead(id: UUID) async throws`

### Modelo novo

- `DBNotification`: `id, actorId, actorUsername, actorAvatarUrl, kind: NotificationKind, postId: UUID?, isRead, createdAt`
  (`NotificationKind` já existe como enum no projeto — reuse)

### `NotificationsView`

- `.task`/`.refreshable` chamando `fetchNotifications()`
- Tocar numa notificação chama `markNotificationRead(id:)` e navega:
  `.follow` → perfil do ator (agora com `userId` real, um dos call sites
  mock sinalizados nas revisões anteriores); `.like`/`.comment` → abre o
  post (precisa buscar o `DBPost` completo por id, ou o suficiente pra
  abrir `CarDetailPageView` — reuse `SupabaseService.fetchFeedPosts()`
  filtrado, ou adicione um fetch por id se for mais direto)

## Erros e edge cases

- Curtir/comentar/seguir a si mesmo nunca gera notificação (trigger já
  filtra) — não que isso seja possível hoje (`no_self_follow`,
  `FollowButton` só aparece pra outros), mas o trigger não confia só na
  UI
- Post deletado depois da notificação existir → a notificação some junto
  (`post_id references posts(id) on delete cascade`, já definido acima) —
  mais simples que `set null`, e uma notificação de curtida num post que
  não existe mais não faz sentido nenhum de qualquer forma

## Testando

Self-check manual: conta A curte um post da conta B → B vê a notificação;
conta A segue B → B vê a notificação; tocar marca como lida e navega
certo.
