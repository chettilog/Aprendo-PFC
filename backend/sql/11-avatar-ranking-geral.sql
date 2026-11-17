\encoding UTF8
-- Entrega 23/11: avatar do perfil e ranking geral
-- O avatar é um número de 0 a 11 que escolhe um dos ícones prontos do app.
-- Não guardamos foto: assim não há imagem de rosto de alunos (muitos são menores de idade).
-- O ranking geral não precisa de tabela nova: usa o XP e a opção "aparecer_no_ranking".
-- Pode rodar mais de uma vez sem duplicar.
-- Como rodar (na pasta backend):
--   psql $env:DB_URL -f sql/11-avatar-ranking-geral.sql

ALTER TABLE usuarios
  ADD COLUMN IF NOT EXISTS avatar SMALLINT NOT NULL DEFAULT 0
  CHECK (avatar BETWEEN 0 AND 11);
