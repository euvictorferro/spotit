-- Tokens de push (APNs) por usuário/dispositivo — usado pela Edge Function
-- que dispara push de verdade em like/comment/follow/mensagem.
create table device_tokens (
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  platform text not null default 'ios',
  updated_at timestamptz not null default now(),
  primary key (token)
);

create index device_tokens_user_idx on device_tokens (user_id);

alter table device_tokens enable row level security;

create policy "usuario gerencia os proprios tokens"
  on device_tokens for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
