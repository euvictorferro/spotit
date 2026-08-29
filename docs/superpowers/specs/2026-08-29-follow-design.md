# Follow (seguidores) — design

## Contexto

`UserProfileView` já tem um botão "Seguir"/"Seguindo" — hoje é um
`@State private var isFollowing = false` puramente local, sem persistência,
sem contagem real (o `ProfileView` já mostra só "posts" desde a limpeza de
mockup anterior; `UserProfileView` ainda mostra "—" fixo em seguidores/
seguindo). Sem spec/plan formal — decisões abaixo são **Ruling**.

## Objetivo

Seguir/deixar de seguir persistido, com contagem real de seguidores/
seguindo nos dois perfis (próprio e de terceiros).

## Escopo

- Tabela `follows` (quem segue quem)
- Seguir/deixar de seguir um usuário
- Contagem de seguidores/seguindo real em `ProfileView` e `UserProfileView`
- Estado inicial correto do botão (já seguindo ou não, ao abrir o perfil)

## Fora de escopo (Ruling)

- Notificação de novo seguidor — fica pra quando notificações forem
  implementadas (próxima frente)
- Lista de "quem me segue"/"quem eu sigo" navegável — só a contagem por
  enquanto, tela dedicada fica pra depois
- Sugestões de quem seguir

## Dados

```sql
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
```

Leitura pública (contagem de seguidores de qualquer perfil precisa ser
visível pra qualquer usuário, igual `profiles`). Sem policy de UPDATE —
seguir é insert, deixar de seguir é delete, não existe "editar" um follow.

## Componentes

### `SupabaseService` (métodos novos)

- `static func follow(userId: UUID) async throws` — insert em `follows`
- `static func unfollow(userId: UUID) async throws` — delete
- `static func isFollowing(userId: UUID) async throws -> Bool` — select
  com `.limit(1)`, retorna se existe linha
- `static func followCounts(userId: UUID) async throws -> (followers: Int, following: Int)`
  — duas contagens (`count` via `.select(..., head: true, count: .exact)`
  ou equivalente do SDK instalado — implementador confirma a API real)

### `UserProfileView`

- `.task` carrega `isFollowing(userId:)` e `followCounts(userId:)` reais,
  populando os `@State` que hoje são fixos
- Botão "Seguir" chama `follow`/`unfollow` de verdade, com tratamento de
  erro inline (mesmo padrão já usado no resto do app)

### `ProfileView`

- Stat de "seguidores"/"seguindo" (removidos na limpeza de mockup) voltam,
  agora com dado real via `followCounts(userId: sessão atual)`

## Erros e edge cases

- Seguir a si mesmo → botão nem deveria aparecer no próprio perfil (já é
  assim hoje, `ProfileView` não tem botão de seguir), mas a constraint
  `no_self_follow` protege se acontecer por engano
- Seguir duas vezes seguidas (double-tap) → `primary key` composta rejeita
  duplicata; UI desabilita o botão durante a chamada pra evitar o caso comum

## Testando

Self-check manual: duas contas, uma segue a outra, confirmar contagem sobe
nos dois perfis, deixar de seguir confirma contagem volta.
