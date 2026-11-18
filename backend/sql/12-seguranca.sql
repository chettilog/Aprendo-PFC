\encoding UTF8
-- Entrega 23/11: correções de segurança
-- senha_alterada_em: quando a senha é trocada, os tokens emitidos antes disso deixam de valer
-- (quem tinha roubado uma sessão perde o acesso). Fica vazia até a primeira troca.
-- Pode rodar mais de uma vez sem duplicar.
-- Como rodar (na pasta backend):
--   psql $env:DB_URL -f sql/12-seguranca.sql

ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS senha_alterada_em TIMESTAMPTZ;
