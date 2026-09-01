-- Mapa "você + quem você segue" precisa enxergar spots de outros usuários,
-- mas wallet_items só era visível pro próprio dono. Policy adicional (RLS
-- combina policies do mesmo comando com OR) liberando só as linhas COM
-- localização de gente que você segue — sem isso, o resto da coleção de
-- quem você segue continua privado.
create policy "seguidores veem spots com localizacao de quem seguem"
  on wallet_items for select
  using (
    lat is not null and lng is not null
    and exists (
      select 1 from follows
      where follower_id = auth.uid() and following_id = wallet_items.user_id
    )
  );
