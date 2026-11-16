\encoding UTF8
-- Entrega 23/11: código de perfil e ranking entre colegas
-- Cada aluno ganha um código de 4 dígitos, mostrado como "PrimeiroNome#1234".
-- Um aluno só aparece no ranking de quem digitar o seu código (nome + número).
-- Pode rodar mais de uma vez.
-- Como rodar (na pasta backend):
--   psql $env:DB_URL -f sql/09-ranking.sql

-- 1) Sorteia um código de 1000 a 9999 que ainda não esteja em uso
CREATE OR REPLACE FUNCTION gerar_codigo_ranking() RETURNS SMALLINT AS $$
DECLARE
  sorteado SMALLINT;
  tentativas INT := 0;
BEGIN
  LOOP
    sorteado := (1000 + floor(random() * 9000))::SMALLINT;
    EXIT WHEN NOT EXISTS (SELECT 1 FROM usuarios u WHERE u.codigo = sorteado);
    tentativas := tentativas + 1;
    IF tentativas > 500 THEN
      RAISE EXCEPTION 'Não há códigos de ranking livres';
    END IF;
  END LOOP;
  RETURN sorteado;
END;
$$ LANGUAGE plpgsql VOLATILE;

-- 2) Código e opção de aparecer no ranking (ligada por padrão; o aluno pode desligar)
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS codigo SMALLINT;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS aparecer_no_ranking BOOLEAN NOT NULL DEFAULT true;

-- Contas que já existiam recebem um código, uma de cada vez (para não repetir)
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT id FROM usuarios WHERE codigo IS NULL ORDER BY id LOOP
    UPDATE usuarios SET codigo = gerar_codigo_ranking() WHERE id = r.id;
  END LOOP;
END;
$$;

-- Contas novas recebem o código automaticamente
ALTER TABLE usuarios ALTER COLUMN codigo SET DEFAULT gerar_codigo_ranking();
ALTER TABLE usuarios ALTER COLUMN codigo SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS usuarios_codigo_unico ON usuarios (codigo);

-- 3) Colegas que cada aluno adicionou ao seu ranking
--    Se qualquer uma das contas for excluída, a ligação some junto (CASCADE)
CREATE TABLE IF NOT EXISTS colegas (
  usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  colega_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  adicionado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (usuario_id, colega_id),
  CHECK (usuario_id <> colega_id)
);
