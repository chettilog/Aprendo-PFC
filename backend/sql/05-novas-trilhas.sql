\encoding UTF8
-- Entrega 16/11: datas com fuso horário e duas trilhas novas (História e Geografia)
-- Pode rodar mais de uma vez sem duplicar.
-- Como rodar (na pasta backend):
--   psql $env:DB_URL -f sql/05-novas-trilhas.sql

-- 1) As datas das explicações e do XP passam a guardar o fuso horário.
-- Assim o dashboard consegue calcular "hoje" e os dias seguidos no horário de Brasília,
-- mesmo com o servidor em outro país.
ALTER TABLE producoes ALTER COLUMN enviada_em TYPE TIMESTAMPTZ;
ALTER TABLE movimentacoes_xp ALTER COLUMN criado_em TYPE TIMESTAMPTZ;

-- 2) Trilha de História
INSERT INTO trilhas (nome, materia, descricao)
SELECT 'Revolução Industrial', 'História',
       'Como as máquinas e as fábricas mudaram o trabalho, as cidades e o mundo.'
WHERE NOT EXISTS (SELECT 1 FROM trilhas WHERE nome = 'Revolução Industrial');

INSERT INTO aulas (trilha_id, ordem, titulo, conteudo, palavras_chave, resposta_referencia)
SELECT t.id, v.ordem, v.titulo, v.conteudo, v.palavras_chave, v.resposta_referencia
FROM trilhas t,
(VALUES
  (1, 'O que foi a Revolução Industrial',
   'A Revolução Industrial começou na Inglaterra, por volta de 1760. A produção, que era feita à mão em pequenas oficinas, passou a ser feita por máquinas dentro de fábricas. A máquina a vapor, movida a carvão, permitiu produzir muito mais em menos tempo. Com isso, os produtos ficaram mais baratos e o trabalho mudou de lugar: saiu das casas e do campo e foi para as fábricas.',
   'Inglaterra,máquina,fábrica,vapor,produção',
   'A Revolução Industrial foi a mudança da produção manual, feita em oficinas, para a produção com máquinas em fábricas. Começou na Inglaterra por volta de 1760. A máquina a vapor, movida a carvão, fez a produção aumentar muito, deixou os produtos mais baratos e levou o trabalho para dentro das fábricas.'),
  (2, 'O trabalho e as cidades',
   'Com as fábricas, muitas famílias deixaram o campo e foram morar nas cidades, que cresceram rápido e sem estrutura. Os operários trabalhavam até 16 horas por dia, recebiam salários baixos, e era comum o trabalho de crianças. Para melhorar essas condições, os trabalhadores se organizaram em sindicatos e fizeram greves. Aos poucos, conquistaram leis que limitaram a jornada de trabalho.',
   'cidade,operário,jornada,sindicato,salário',
   'As pessoas saíram do campo para trabalhar nas fábricas, e as cidades cresceram rápido e sem estrutura. Os operários tinham jornadas muito longas, salários baixos, e havia trabalho infantil. Em resposta, os trabalhadores criaram sindicatos e fizeram greves, conquistando leis que reduziram a jornada.'),
  (3, 'As consequências da industrialização',
   'A industrialização aumentou a produção de riquezas e acelerou os transportes, com trens e navios a vapor. Também aprofundou a desigualdade entre os donos das fábricas, chamados de burguesia, e os operários, chamados de proletariado. Outra consequência foi ambiental: a queima de carvão trouxe poluição do ar, um problema que continua até hoje.',
   'burguesia,proletariado,transporte,desigualdade,poluição',
   'A industrialização trouxe mais produção e riqueza e transportes mais rápidos, como trens e navios a vapor. Por outro lado, aumentou a desigualdade entre a burguesia (donos das fábricas) e o proletariado (operários) e causou poluição pela queima de carvão.')
) AS v(ordem, titulo, conteudo, palavras_chave, resposta_referencia)
WHERE t.nome = 'Revolução Industrial'
ON CONFLICT (trilha_id, ordem) DO NOTHING;

-- 3) Trilha de Geografia
INSERT INTO trilhas (nome, materia, descricao)
SELECT 'Clima e Tempo', 'Geografia',
       'A diferença entre tempo e clima, o que influencia o clima e os climas do Brasil.'
WHERE NOT EXISTS (SELECT 1 FROM trilhas WHERE nome = 'Clima e Tempo');

INSERT INTO aulas (trilha_id, ordem, titulo, conteudo, palavras_chave, resposta_referencia)
SELECT t.id, v.ordem, v.titulo, v.conteudo, v.palavras_chave, v.resposta_referencia
FROM trilhas t,
(VALUES
  (1, 'Tempo e clima',
   'Tempo é o estado da atmosfera em um momento e em um lugar: se está chovendo ou fazendo sol agora. Clima é o padrão do tempo de uma região, observado durante muitos anos, em geral 30. Por isso dizemos que o tempo está chuvoso hoje, mas que o clima da Amazônia é quente e úmido.',
   'tempo,clima,atmosfera,momento,anos',
   'Tempo é como a atmosfera está em um momento e lugar específicos, por exemplo se chove ou faz sol hoje. Clima é o comportamento médio do tempo em uma região ao longo de muitos anos, cerca de 30. O tempo muda de um dia para o outro; o clima é o padrão de longo prazo.'),
  (2, 'O que influencia o clima',
   'O clima de um lugar depende de alguns fatores. A latitude: quanto mais perto da linha do Equador, mais quente. A altitude: quanto mais alto o lugar, mais frio. A maritimidade: lugares perto do mar têm temperatura mais estável. Já no interior dos continentes, longe do mar, a diferença de temperatura entre o dia e a noite é maior.',
   'latitude,altitude,maritimidade,Equador,temperatura',
   'Os principais fatores são a latitude (perto do Equador é mais quente), a altitude (lugares mais altos são mais frios) e a distância do mar (perto do mar a temperatura varia menos; no interior do continente varia mais entre o dia e a noite).'),
  (3, 'Os climas do Brasil',
   'O Brasil tem vários climas porque é um país muito extenso. O equatorial, na Amazônia, é quente e chuvoso o ano todo. O tropical, no centro do país, tem verão chuvoso e inverno seco. O semiárido, no sertão nordestino, é quente e com pouca chuva. O subtropical, no Sul, tem as temperaturas mais baixas e as estações do ano mais marcadas.',
   'equatorial,tropical,semiárido,subtropical,chuva',
   'Por ser muito extenso, o Brasil tem vários climas: equatorial na Amazônia (quente e chuvoso o ano todo), tropical no centro (verão chuvoso e inverno seco), semiárido no sertão nordestino (quente e com pouca chuva) e subtropical no Sul (mais frio, com estações bem definidas).')
) AS v(ordem, titulo, conteudo, palavras_chave, resposta_referencia)
WHERE t.nome = 'Clima e Tempo'
ON CONFLICT (trilha_id, ordem) DO NOTHING;
