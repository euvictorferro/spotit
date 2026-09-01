-- wallet_items só tinha select/insert — faltava update (usado agora pra
-- completar o item com o perfil rico que chega depois, em background) e
-- delete (o botão de apagar carro da Wallet nunca funcionou por causa disso,
-- falhava fechado/silencioso via try?).
create policy "usuarios atualizam seus proprios itens"
  on wallet_items for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "usuarios apagam seus proprios itens"
  on wallet_items for delete
  using (auth.uid() = user_id);
