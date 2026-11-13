\encoding UTF8
-- Entrega 16/11: avaliação por nota (0 a 100) com rubrica e XP proporcional (RF07 e RF08)
-- Pode rodar mais de uma vez.
-- Como rodar (na pasta backend):
--   psql $env:DB_URL -f sql/04-avaliacao-por-nota.sql

-- 1) Resposta de referência de cada aula: o "gabarito" usado pela rubrica
ALTER TABLE aulas ADD COLUMN IF NOT EXISTS resposta_referencia TEXT;

UPDATE aulas SET resposta_referencia =
  'Função é uma regra que liga cada elemento de um conjunto de entrada (domínio) a um único elemento de um conjunto de saída (contradomínio). A mesma entrada sempre gera a mesma saída. Exemplo: em f(x) = 2x + 1, a entrada 3 gera a saída 7.'
WHERE titulo = 'O que é uma função';

UPDATE aulas SET resposta_referencia =
  'Domínio é o conjunto dos valores que podem entrar na função. Contradomínio é o conjunto onde as saídas podem estar. Imagem é a parte do contradomínio formada pelas saídas que realmente acontecem. Exemplo: em f(x) = x² com x real, a imagem são os números maiores ou iguais a zero.'
WHERE titulo = 'Domínio, contradomínio e imagem';

UPDATE aulas SET resposta_referencia =
  'O gráfico de uma função é o conjunto dos pontos (x, f(x)) desenhados no plano cartesiano. Na função do 1º grau, como f(x) = 2x + 1, o gráfico é uma reta: o coeficiente que multiplica x (2) define a inclinação e o termo independente (1) é onde a reta corta o eixo y.'
WHERE titulo = 'Gráfico de uma função';

-- 2) Feedback guarda a nota, quem avaliou (ia ou regras) e a nota de cada critério
ALTER TABLE feedbacks ADD COLUMN IF NOT EXISTS nota SMALLINT CHECK (nota BETWEEN 0 AND 100);
ALTER TABLE feedbacks ADD COLUMN IF NOT EXISTS avaliador VARCHAR(10);
ALTER TABLE feedbacks ADD COLUMN IF NOT EXISTS criterios JSONB;

-- Novo resultado possível: 'parcial' (acertou parte, ganha metade do XP)
ALTER TABLE feedbacks DROP CONSTRAINT IF EXISTS feedbacks_resultado_check;
ALTER TABLE feedbacks ADD CONSTRAINT feedbacks_resultado_check
  CHECK (resultado IN ('suficiente', 'parcial', 'insuficiente'));

-- 3) XP em etapas: quem tirou parcial (25 XP) e depois acerta tudo recebe só a diferença (+25).
-- Por isso a mesma aula pode ter mais de uma movimentação; o limite de 50 XP por aula
-- passa a ser garantido no código (servicos/xp.js) e não mais pela UNIQUE.
ALTER TABLE movimentacoes_xp DROP CONSTRAINT IF EXISTS movimentacoes_xp_usuario_id_aula_id_key;
CREATE INDEX IF NOT EXISTS idx_movimentacoes_xp_usuario_aula ON movimentacoes_xp (usuario_id, aula_id);
