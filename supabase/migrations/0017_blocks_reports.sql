-- Bloqueio e denúncia — exigidos pela App Store guideline 1.2 (apps com
-- conteúdo gerado por usuário precisam permitir bloquear e denunciar).

create table blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint no_self_block check (blocker_id <> blocked_id)
);

alter table blocks enable row level security;

create policy "usuario ve os proprios bloqueios"
  on blocks for select using (auth.uid() = blocker_id);

create policy "usuario bloqueia por conta propria"
  on blocks for insert with check (auth.uid() = blocker_id);

create policy "usuario desbloqueia por conta propria"
  on blocks for delete using (auth.uid() = blocker_id);

-- Esconde posts de quem bloqueou ou foi bloqueado, nos dois sentidos.
drop policy "posts sao publicamente legiveis" on posts;
create policy "posts sao publicamente legiveis"
  on posts for select using (
    not exists (
      select 1 from blocks
      where (blocker_id = auth.uid() and blocked_id = posts.user_id)
         or (blocker_id = posts.user_id and blocked_id = auth.uid())
    )
  );

-- Impede iniciar conversa com quem bloqueou ou foi bloqueado.
drop policy "participante cria conversa com outro usuario" on conversations;
create policy "participante cria conversa com outro usuario"
  on conversations for insert
  with check (
    (auth.uid() = user_a or auth.uid() = user_b)
    and not exists (
      select 1 from blocks
      where (blocker_id = user_a and blocked_id = user_b)
         or (blocker_id = user_b and blocked_id = user_a)
    )
  );

-- Impede enviar mensagem numa conversa antiga se um bloqueio surgiu depois.
drop policy "participante envia mensagem na propria conversa" on messages;
create policy "participante envia mensagem na propria conversa"
  on messages for insert
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from conversations c
      where c.id = messages.conversation_id
        and (c.user_a = auth.uid() or c.user_b = auth.uid())
        and not exists (
          select 1 from blocks
          where (blocker_id = c.user_a and blocked_id = c.user_b)
             or (blocker_id = c.user_b and blocked_id = c.user_a)
        )
    )
  );

create table reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reported_user_id uuid references auth.users(id) on delete cascade,
  post_id uuid references posts(id) on delete cascade,
  reason text not null check (char_length(reason) between 1 and 500),
  created_at timestamptz not null default now(),
  constraint report_has_target check (reported_user_id is not null or post_id is not null)
);

alter table reports enable row level security;

create policy "usuario cria denuncia por conta propria"
  on reports for insert with check (auth.uid() = reporter_id);

create policy "usuario ve as proprias denuncias"
  on reports for select using (auth.uid() = reporter_id);

-- ponytail: sem policy de moderador/admin ainda — a triagem das denúncias
-- por ora é manual, direto no dashboard do Supabase com a service role key.
-- Isso cobre o requisito da Apple ("mecanismo pra denunciar" + resposta em
-- até 24h), mas exige alguém checando a tabela `reports` com frequência.
