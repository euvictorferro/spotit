-- A policy de UPDATE criada em 0006 não tinha WITH CHECK — o Postgres reusa
-- o USING como CHECK quando não há CHECK explícito, e o USING só valida que
-- EU sou participante da conversa, não que o UPDATE preserva user_a/user_b.
-- Isso deixava qualquer participante trocar o outro lado da conversa e
-- sequestrar o histórico de mensagens de outra pessoa.
--
-- Fix: substitui o UPDATE feito manualmente pelo client (que exigia essa
-- policy) por um trigger security definer que só atualiza last_message_at,
-- disparado no insert de mensagens. Sem policy de UPDATE nenhuma, ninguém
-- mais pode alterar conversations pelo client.
drop policy "participante atualiza last_message_at da propria conversa" on conversations;

create function touch_conversation() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update conversations set last_message_at = new.created_at where id = new.conversation_id;
  return new;
end;
$$;

create trigger messages_touch_conversation
  after insert on messages
  for each row execute function touch_conversation();
