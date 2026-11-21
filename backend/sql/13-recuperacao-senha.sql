\encoding UTF8
-- Entrega 23/11: recuperação de senha por código enviado ao e-mail
-- Cada pedido gera um código de 6 dígitos. O banco guarda só o hash do código (nunca o código),
-- com validade de 15 minutos, uso único e no máximo 5 tentativas.
-- Os pedidos são apagados junto com a conta (ON DELETE CASCADE).
-- Pode rodar mais de uma vez sem duplicar.
-- Como rodar (na pasta backend):
--   psql $env:DB_URL -f sql/13-recuperacao-senha.sql

CREATE TABLE IF NOT EXISTS recuperacoes_senha (
  id SERIAL PRIMARY KEY,
  usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  codigo_hash VARCHAR(255) NOT NULL,
  expira_em TIMESTAMPTZ NOT NULL,
  tentativas SMALLINT NOT NULL DEFAULT 0,
  usado_em TIMESTAMPTZ,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS recuperacoes_senha_usuario ON recuperacoes_senha (usuario_id, criado_em DESC);
