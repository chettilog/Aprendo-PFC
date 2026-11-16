\encoding UTF8
-- Entrega 23/11: níveis de trilha
-- Cada trilha passa a ter o nível 1 (as 3 aulas que já existiam) e o nível 2 (2 aulas novas).
-- O nível 2 é liberado quando o aluno conclui todas as aulas do nível 1.
-- Pode rodar mais de uma vez sem duplicar.
-- Como rodar (na pasta backend):
--   psql $env:DB_URL -f sql/10-niveis-trilha.sql

ALTER TABLE aulas ADD COLUMN IF NOT EXISTS nivel SMALLINT NOT NULL DEFAULT 1;

INSERT INTO aulas (trilha_id, ordem, nivel, titulo, conteudo, palavras_chave, resposta_referencia)
SELECT t.id, v.ordem, 2, v.titulo, v.conteudo, v.palavras_chave, v.resposta_referencia
FROM trilhas t
JOIN (VALUES
  -- ===================== MATEMÁTICA: Fundamentos de Funções =====================
  ('Fundamentos de Funções', 4, 'Função do 1º grau: o zero da função',
   $aula$A função do 1º grau tem a forma f(x) = ax + b, com a diferente de zero, e o seu gráfico é uma reta.

O zero da função, ou raiz, é o valor de x que faz f(x) valer zero. Basta resolver ax + b = 0, o que dá x = -b/a. No gráfico, é onde a reta corta o eixo x. Se a for positivo, a função é crescente; se for negativo, decrescente.

Exemplo: em f(x) = 2x - 6, temos x = 3. A reta corta o eixo x em (3, 0) e é crescente.$aula$,
   'zero,raiz,eixo,crescente,decrescente',
   'O zero ou raiz da função do 1º grau f(x) = ax + b é o valor de x que torna f(x) igual a zero. Ele é encontrado resolvendo ax + b = 0, ou seja, x = -b/a, e no gráfico é onde a reta corta o eixo x. Se a for positivo a função é crescente; se for negativo, decrescente. Exemplo: em f(x) = 2x - 6 a raiz é x = 3.'),
  ('Fundamentos de Funções', 5, 'Função do 2º grau: a parábola',
   $aula$A função do 2º grau tem a forma f(x) = ax² + bx + c, com a diferente de zero, e o seu gráfico é uma curva chamada parábola.

O coeficiente a define a concavidade: se a for positivo, a "boca" fica para cima; se for negativo, para baixo. O ponto mais baixo ou mais alto da curva é o vértice, com x = -b/2a. As raízes são os pontos onde a parábola corta o eixo x: podem ser duas, uma ou nenhuma.

Exemplo: em f(x) = x² - 4, a boca é para cima, o vértice é (0, -4) e as raízes são -2 e 2.$aula$,
   'parábola,concavidade,vértice,raízes,coeficiente',
   'A função do 2º grau f(x) = ax² + bx + c tem como gráfico uma parábola. O coeficiente a define a concavidade: para cima quando a é positivo e para baixo quando é negativo. O vértice é o ponto mais baixo ou mais alto da curva, com x = -b/2a, e as raízes são os pontos onde a parábola corta o eixo x. Exemplo: f(x) = x² - 4 tem vértice (0, -4) e raízes -2 e 2.'),

  -- ===================== HISTÓRIA: Revolução Industrial =====================
  ('Revolução Industrial', 4, 'A Segunda Revolução Industrial',
   $aula$A Segunda Revolução Industrial aconteceu a partir de 1850, e a industrialização se espalhou para países como Estados Unidos, Alemanha e Japão.

As novas fontes de energia foram a eletricidade e o petróleo, que substituíram aos poucos o carvão. Surgiram o aço, o motor a combustão, o telefone e a lâmpada elétrica. A produção também mudou: na linha de montagem, o produto passava por uma esteira e cada operário repetia sempre a mesma tarefa.

Exemplo: Henry Ford usou a linha de montagem para fabricar carros em grande quantidade e mais baratos. Esse modelo ficou conhecido como fordismo.$aula$,
   'eletricidade,petróleo,aço,linha de montagem,fordismo',
   'A Segunda Revolução Industrial começou por volta de 1850 e levou a industrialização a países como Estados Unidos, Alemanha e Japão. Teve como novas fontes de energia a eletricidade e o petróleo, além do aço e do motor a combustão. A produção passou a usar a linha de montagem, em que cada operário repete uma tarefa, modelo aplicado por Henry Ford e chamado de fordismo.'),
  ('Revolução Industrial', 5, 'A industrialização no Brasil',
   $aula$No Brasil, a industrialização foi tardia: começou de fato só no século XX, mais de cem anos depois da Inglaterra.

Até então, a economia dependia da exportação de café. Com a crise de 1929, o café perdeu valor e o país passou a investir na indústria. No governo de Getúlio Vargas, o Estado criou a indústria de base, como a Companhia Siderúrgica Nacional, que produzia aço. Depois, Juscelino Kubitschek atraiu fábricas de outros países, principalmente de automóveis.

Exemplo: a Companhia Siderúrgica Nacional, de 1941, fornecia o aço que outras fábricas usavam, por isso é chamada de indústria de base.$aula$,
   'tardia,café,Getúlio Vargas,indústria de base,Juscelino',
   'O Brasil se industrializou de forma tardia, só no século XX. Antes disso o país vivia de vender café para fora, mas com a crise de 1929 esse produto perdeu valor e foi preciso investir em fábricas. Getúlio Vargas usou o Estado para montar a indústria de base, que produz materiais para outras indústrias, como o aço da CSN. Mais tarde, Juscelino trouxe montadoras de carros estrangeiras.'),

  -- ===================== GEOGRAFIA: Clima e Tempo =====================
  ('Clima e Tempo', 4, 'Massas de ar',
   $aula$Massas de ar são grandes porções de ar que ficam com a temperatura e a umidade da região onde se formam e depois se deslocam, mudando o tempo dos lugares por onde passam.

Uma massa formada sobre o oceano é úmida; sobre o continente, é mais seca. Formada perto do Equador, é quente; perto dos polos, é fria. Quando uma massa fria encontra uma massa quente, forma-se uma frente fria, que costuma trazer chuva e queda de temperatura.

Exemplo: a massa Polar Atlântica se forma perto da Antártida e, no inverno, sobe pelo Sul e pelo Sudeste do Brasil, causando frio e até geada.$aula$,
   'massa,umidade,temperatura,frente fria,polar',
   'Massas de ar são grandes porções de ar que adquirem a temperatura e a umidade do lugar onde se formam e se deslocam, alterando o tempo. As formadas sobre o oceano são úmidas e sobre o continente, secas; perto do Equador são quentes e perto dos polos, frias. O encontro de uma massa fria com uma quente forma uma frente fria, com chuva e queda de temperatura, como faz a massa Polar Atlântica no Sul do Brasil.'),
  ('Clima e Tempo', 5, 'Efeito estufa e aquecimento global',
   $aula$O efeito estufa é um fenômeno natural: alguns gases da atmosfera seguram parte do calor do Sol, mantendo a Terra aquecida. Sem ele, o planeta seria frio demais para a vida.

O problema é a intensificação desse efeito. A queima de carvão, petróleo e gás natural e o desmatamento lançam mais gases como o gás carbônico (CO2) e o metano. Com mais gases, a atmosfera segura mais calor e a temperatura média do planeta sobe: é o aquecimento global.

Exemplo de consequências: derretimento das geleiras, aumento do nível do mar e eventos extremos mais frequentes, como secas longas e chuvas muito fortes.$aula$,
   'efeito estufa,gás carbônico,aquecimento global,desmatamento,temperatura',
   'O efeito estufa é natural: gases da atmosfera retêm parte do calor do Sol e mantêm a Terra aquecida. A queima de combustíveis fósseis e o desmatamento aumentam a quantidade de gases como o gás carbônico e o metano, o que intensifica o efeito e eleva a temperatura média do planeta, causando o aquecimento global, com derretimento de geleiras, aumento do nível do mar e eventos extremos.')
) AS v(trilha, ordem, titulo, conteudo, palavras_chave, resposta_referencia) ON v.trilha = t.nome
ON CONFLICT (trilha_id, ordem) DO UPDATE SET
  nivel = EXCLUDED.nivel,
  titulo = EXCLUDED.titulo,
  conteudo = EXCLUDED.conteudo,
  palavras_chave = EXCLUDED.palavras_chave,
  resposta_referencia = EXCLUDED.resposta_referencia;
