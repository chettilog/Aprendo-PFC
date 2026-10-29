\encoding UTF8
-- Dados de exemplo para a entrega 09/11 (trilha de Matematica).
-- Pode rodar mais de uma vez sem duplicar.
-- Como rodar (na pasta backend):
--   psql -U postgres -d aprendo_db -f sql/02-dados-exemplo.sql

INSERT INTO trilhas (nome, materia, descricao)
SELECT 'Fundamentos de Funções', 'Matemática',
       'Introdução ao conceito de função e às suas representações.'
WHERE NOT EXISTS (SELECT 1 FROM trilhas WHERE nome = 'Fundamentos de Funções');

INSERT INTO aulas (trilha_id, titulo, conteudo, ordem)
SELECT t.id, v.titulo, v.conteudo, v.ordem
FROM trilhas t,
(VALUES
  (1, 'O que é uma função',
   'Uma função relaciona cada valor de um conjunto (domínio) a exatamente um valor de outro conjunto (contradomínio). Exemplo: f(x) = 2x + 1 associa x = 3 ao valor 7. Pense em uma máquina: você entrega uma entrada e recebe sempre a mesma saída para aquela entrada.'),
  (2, 'Domínio, contradomínio e imagem',
   'O domínio é o conjunto dos valores que podem entrar na função. O contradomínio é o conjunto onde as saídas podem estar. A imagem é o conjunto das saídas que realmente acontecem. Em f(x) = x², com x real, a imagem contém apenas números maiores ou iguais a zero.'),
  (3, 'Gráfico de uma função',
   'O gráfico de uma função é o conjunto dos pontos (x, f(x)) no plano cartesiano. Em uma função do 1º grau, como f(x) = 2x + 1, o gráfico é uma reta: o coeficiente 2 indica a inclinação, e o 1 indica onde a reta cruza o eixo y.')
) AS v(ordem, titulo, conteudo)
WHERE t.nome = 'Fundamentos de Funções'
ON CONFLICT (trilha_id, ordem) DO NOTHING;