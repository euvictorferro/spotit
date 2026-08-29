create policy "usuario deleta o proprio post"
  on posts for delete using (auth.uid() = user_id);

create policy "usuario deleta o proprio comentario"
  on comments for delete using (auth.uid() = user_id);
