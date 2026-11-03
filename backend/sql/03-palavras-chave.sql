\encoding UTF8
-- Entrega 09/11: palavras-chave usadas na avaliacao da producao (RF07)
-- Como rodar (na pasta backend):
--   psql -U postgres -d aprendo_db -f sql/03-palavras-chave.sql

ALTER TABLE aulas ADD COLUMN IF NOT EXISTS palavras_chave VARCHAR(255);

UPDATE aulas SET palavras_chave = 'função,domínio,contradomínio,entrada,saída'
WHERE titulo = 'O que é uma função';

UPDATE aulas SET palavras_chave = 'domínio,contradomínio,imagem,conjunto'
WHERE titulo = 'Domínio, contradomínio e imagem';

UPDATE aulas SET palavras_chave = 'gráfico,plano cartesiano,reta,coeficiente,eixo'
WHERE titulo = 'Gráfico de uma função';