-- Tabelas base: usuarios e logs de auditoria
-- Pode rodar mais de uma vez (IF NOT EXISTS).
-- Como rodar (na pasta backend):
--   psql -U postgres -d aprendo_db -f sql/00-tabelas-base.sql

CREATE TABLE IF NOT EXISTS usuarios (
  id SERIAL PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  senha VARCHAR(255) NOT NULL,
  criado_em TIMESTAMP DEFAULT NOW(),
  termos_aceitos_em TIMESTAMP,
  termos_versao VARCHAR(10),
  perfil VARCHAR(20) NOT NULL DEFAULT 'aluno'
);

CREATE TABLE IF NOT EXISTS logs (
  id SERIAL PRIMARY KEY,
  usuario_id INTEGER REFERENCES usuarios(id) ON DELETE SET NULL,
  acao VARCHAR(50) NOT NULL,
  detalhes VARCHAR(255),
  ip VARCHAR(45),
  sucesso BOOLEAN DEFAULT true,
  criado_em TIMESTAMP DEFAULT NOW()
);