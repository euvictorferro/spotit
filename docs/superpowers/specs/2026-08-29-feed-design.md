# Feed — design

## Contexto

`FeedView`/`FeedPostCard`/`CommentsSheet` já têm UI completa (curtir, comentar,
compartilhar, ver detalhes) rodando 100% sobre `FeedPost.sample`/
`Comment.sampleFor` — hoje `posts = []` fixo. Sem spec/plan formal — decisões
abaixo são **Ruling**.

## Objetivo

Feed público real: qualquer usuário pode publicar um carro flagrado (com
legenda), curtir e comentar posts de qualquer pessoa.

## Escopo

- Tabela `posts` (um post = um carro compartilhado, com legenda)
- Tabela `likes` (curtida em post)
- Tabela `comments` (comentário em post)
- Feed = linha do tempo global pública, mais recentes primeiro (Ruling já
  tomada antes: sem sistema de "seguir" gating o feed — fica só pra
  personalizar o botão Seguir/Seguindo já visível no card)
- Publicar um post a partir de um item já salvo na Wallet (não é uma foto
  nova — reusa a foto/dados já reconhecidos)

## Fora de escopo (Ruling)

- **Localização legível ("Naples, FL")**: não existe geocoding reverso no
  app — o card real não mostra cidade, só tempo relativo ("há 2h")
- **"Curtido por fulano e outros"**: vira só contagem ("42 curtidas") —
  descobrir quem curtiu primeiro é complexidade desnecessária agora
- **Editar/deletar post ou comentário**: fora de escopo (mesmo padrão do DM)
- **Feed personalizado por "seguindo"**: fora de escopo, feed é global
- **Notificação de curtida/comentário**: fica pra próxima frente
  (Notificações)

## Dados

### Tabela `posts`

Campos denormalizados a partir do `wallet_item` de origem no momento da
publicação — **não** faz join com `wallet_items` de outro usuário (a RLS de
`wallet_items` só libera o dono ler a própria linha; denormalizar evita ter
que relaxar essa RLS só pro Feed funcionar).

```sql
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
```

`wallet_item_id` é só referência solta (`on delete set null` — apagar o item
da Wallet não deve apagar o post, só perde o vínculo). Sem policy de
update/delete — publicar é definitivo (fora de escopo editar/deletar).

### Tabela `likes`

```sql
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
```

Igual ao `follows` — sem policy de UPDATE (curtir é insert, descurtir é
delete; não existe "editar" uma curtida). **Isso é deliberado**: a policy de
UPDATE sem `WITH CHECK` foi o bug de segurança real encontrado na revisão
final do DM — não repetir o padrão aqui.

### Tabela `comments`

```sql
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
```

Mensagens imutáveis (mesmo padrão do DM) — sem update/delete.

## Componentes

### `SupabaseService` (métodos novos)

- `static func createPost(walletItemId: UUID?, modelo: String, raridade: Int, valorEstimadoUsd: Double, fotoUrl: String, caption: String?) async throws`
- `static func fetchFeedPosts() async throws -> [DBPost]` — todos os posts,
  mais recentes primeiro, com contagem de curtidas/comentários e se o
  usuário atual curtiu (3 queries: posts, depois curtidas/comentários
  agregados — implementador escolhe a forma mais direta com o SDK
  instalado; N+1 é aceitável pro volume esperado agora, mesmo padrão já
  aceito em `fetchConversations`)
- `static func toggleLike(postId: UUID) async throws -> Bool` — insere se
  não existe, remove se existe (curtir/descurtir); retorna o novo estado
- `static func fetchComments(postId: UUID) async throws -> [DBComment]`
- `static func addComment(postId: UUID, text: String) async throws`

### Modelos novos

- `DBPost`: `id, userId, username, avatarUrl, modelo, raridade, valorEstimadoUsd, fotoUrl, caption, createdAt, likeCount, commentCount, likedByMe`
  (username/avatarUrl resolvidos via join com `profiles`, igual ao padrão
  já usado em `ConversationSummary`)
- `DBComment`: `id, postId, userId, username, text, createdAt`

### Publicar um post (a partir da Wallet)

**Ruling**: adiciona um botão "Publicar no Feed" na `CarDetailPageView`
(tela que já mostra o detalhe de um item da Wallet) — abre um sheet simples
pedindo a legenda (campo de texto opcional) e confirma. Chama
`createPost(walletItemId: item.id, modelo: item.modelo, raridade: item.raridade, valorEstimadoUsd: item.valorEstimadoUsd, fotoUrl: item.fotoUrl, caption: ...)`.

### `FeedView`

- `.task`/`.refreshable` chamando `fetchFeedPosts()`

### `FeedPostCard`

- Recebe `DBPost` no lugar de `FeedPost`
- Curtir chama `toggleLike(postId:)` de verdade, contagem real
- "Curtido por X e outros" vira `Text("\(post.likeCount) curtidas")`
  (omitido se 0)
- Sem chip de localização (fora de escopo)
- Botão Seguir/Seguindo usa o sistema de Follow já real (`SupabaseService.isFollowing`/`follow`/`unfollow`, da frente anterior) em vez do `@State` local fake — mostra/esconde baseado em `post.userId != usuário atual`

### `CommentsSheet`

- Carrega `fetchComments(postId:)` real, `addComment` real ao enviar

## Erros e edge cases

- Curtir duas vezes rápido (double-tap) → mesmo padrão de tratamento de
  duplicata já usado em Follow (`follow()` engolindo "duplicate key")
- Post cujo `wallet_item_id` foi deletado da Wallet → o post continua
  existindo no Feed normalmente (dados denormalizados, não depende do
  item original sobreviver)

## Testando

Self-check manual: publicar um item da Wallet no Feed, confirmar que
aparece pra outra conta, curtir/descurtir, comentar, confirmar contagens.
