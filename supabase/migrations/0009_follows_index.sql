-- Índice pra acelerar followCounts/isFollowing filtrando por following_id
-- (o lookup mais comum: "quem segue esse usuário").
create index if not exists follows_following_id_idx on follows (following_id);
