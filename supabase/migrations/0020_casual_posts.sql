-- Posts casuais do novo fluxo de câmera do feed (sem carro/IA, igual
-- Instagram): carrossel de até 10 fotos, legenda, localização, contas
-- marcadas e rascunho. Post de carro (publicado da Wallet) continua
-- funcionando igual — os campos de carro só ficam opcionais agora.

alter table posts alter column modelo drop not null;
alter table posts alter column raridade drop not null;
alter table posts alter column valor_estimado_usd drop not null;
alter table posts add column location text;
alter table posts add column is_draft boolean not null default false;

-- Rascunho só pode ser visto pelo dono — sem isso, a policy antiga
-- ("using (true)") vazaria rascunhos pra qualquer um.
drop policy "posts sao publicamente legiveis" on posts;
create policy "posts publicados sao legiveis (respeitando bloqueio)"
  on posts for select using (
    not is_draft
    and not exists (
      select 1 from blocks
      where (blocker_id = auth.uid() and blocked_id = posts.user_id)
         or (blocker_id = posts.user_id and blocked_id = auth.uid())
    )
  );
create policy "usuario ve os proprios posts, inclusive rascunhos"
  on posts for select using (auth.uid() = user_id);

-- Necessário pra "publicar" um rascunho depois (is_draft true -> false).
create policy "usuario atualiza os proprios posts"
  on posts for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table post_photos (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references posts(id) on delete cascade,
  url text not null,
  position int not null default 0
);
create index post_photos_post_idx on post_photos (post_id, position);

alter table post_photos enable row level security;

create policy "post_photos seguem a visibilidade do post"
  on post_photos for select using (
    exists (
      select 1 from posts p
      where p.id = post_photos.post_id
        and (
          p.user_id = auth.uid()
          or (
            not p.is_draft
            and not exists (
              select 1 from blocks
              where (blocker_id = auth.uid() and blocked_id = p.user_id)
                 or (blocker_id = p.user_id and blocked_id = auth.uid())
            )
          )
        )
    )
  );

create policy "usuario adiciona fotos ao proprio post"
  on post_photos for insert with check (
    exists (select 1 from posts p where p.id = post_photos.post_id and p.user_id = auth.uid())
  );

create table post_mentions (
  post_id uuid not null references posts(id) on delete cascade,
  mentioned_user_id uuid not null references auth.users(id) on delete cascade,
  primary key (post_id, mentioned_user_id)
);

alter table post_mentions enable row level security;

create policy "post_mentions sao publicamente legiveis"
  on post_mentions for select using (true);

create policy "usuario marca contas no proprio post"
  on post_mentions for insert with check (
    exists (select 1 from posts p where p.id = post_mentions.post_id and p.user_id = auth.uid())
  );
