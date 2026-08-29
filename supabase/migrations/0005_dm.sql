create table conversations (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references auth.users(id) on delete cascade,
  user_b uuid not null references auth.users(id) on delete cascade,
  last_message_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint distinct_users check (user_a <> user_b),
  constraint ordered_pair check (user_a < user_b)
);

create unique index conversations_pair_idx on conversations (user_a, user_b);

create table messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references conversations(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  text text not null check (char_length(text) between 1 and 2000),
  created_at timestamptz not null default now()
);

create index messages_conversation_idx on messages (conversation_id, created_at);

alter table conversations enable row level security;
alter table messages enable row level security;

create policy "participante le suas conversas"
  on conversations for select
  using (auth.uid() = user_a or auth.uid() = user_b);

create policy "participante cria conversa com outro usuario"
  on conversations for insert
  with check (auth.uid() = user_a or auth.uid() = user_b);

create policy "participante le mensagens da propria conversa"
  on messages for select
  using (
    exists (
      select 1 from conversations c
      where c.id = messages.conversation_id
        and (c.user_a = auth.uid() or c.user_b = auth.uid())
    )
  );

create policy "participante envia mensagem na propria conversa"
  on messages for insert
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from conversations c
      where c.id = messages.conversation_id
        and (c.user_a = auth.uid() or c.user_b = auth.uid())
    )
  );
