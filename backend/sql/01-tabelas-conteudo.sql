-- Entrega 09/11: tabelas de conteudo, producao e XP
-- Pode rodar mais de uma vez (IF NOT EXISTS).
-- Como rodar (na pasta backend):
--   psql -U postgres -d aprendo_db -f sql/01-tabelas-conteudo.sql

CREATE TABLE IF NOT EXISTS trilhas (
  id SERIAL PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  materia VARCHAR(50) NOT NULL,
  descricao VARCHAR(255),
  ativa BOOLEAN NOT NULL DEFAULT true,
  criado_em TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS aulas (
  id SERIAL PRIMARY KEY,
  trilha_id INTEGER NOT NULL REFERENCES trilhas(id) ON DELETE CASCADE,
  titulo VARCHAR(150) NOT NULL,
  conteudo TEXT NOT NULL,
  ordem INTEGER NOT NULL,
  UNIQUE (trilha_id, ordem)
);

-- Producoes do aluno (RF06). Removidas junto com a conta (RF21).
CREATE TABLE IF NOT EXISTS producoes (
  id SERIAL PRIMARY KEY,
  usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  aula_id INTEGER NOT NULL REFERENCES aulas(id) ON DELETE CASCADE,
  tipo VARCHAR(10) NOT NULL DEFAULT 'texto' CHECK (tipo IN ('texto', 'audio')),
  conteudo TEXT NOT NULL,
  enviada_em TIMESTAMP DEFAULT NOW()
);

-- Feedback (RF07): cada producao tem no maximo um feedback.
CREATE TABLE IF NOT EXISTS feedbacks (
  id SERIAL PRIMARY KEY,
  producao_id INTEGER NOT NULL UNIQUE REFERENCES producoes(id) ON DELETE CASCADE,
  resultado VARCHAR(15) NOT NULL CHECK (resultado IN ('suficiente', 'insuficiente')),
  comentario VARCHAR(255),
  criado_em TIMESTAMP DEFAULT NOW()
);

-- Historico de XP (RF08): a mesma aula nao gera XP duas vezes para o mesmo aluno.
CREATE TABLE IF NOT EXISTS movimentacoes_xp (
  id SERIAL PRIMARY KEY,
  usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  aula_id INTEGER REFERENCES aulas(id) ON DELETE SET NULL,
  valor INTEGER NOT NULL,
  motivo VARCHAR(100) NOT NULL,
  criado_em TIMESTAMP DEFAULT NOW(),
  UNIQUE (usuario_id, aula_id)
);