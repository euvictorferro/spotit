create policy "participante atualiza last_message_at da propria conversa"
  on conversations for update
  using (auth.uid() = user_a or auth.uid() = user_b);
