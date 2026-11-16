\encoding UTF8
-- Entrega 23/11: texto das aulas em cerca de 100 palavras (ideia, explicação e exemplo)
-- Substitui o texto do script 06, que ficou longo para a tela do aplicativo.
-- Troca apenas o texto que o aluno lê (coluna conteudo). Títulos, palavras-chave,
-- respostas de referência, produções e XP dos alunos continuam como estão.
-- Pode rodar mais de uma vez.
-- Como rodar (na pasta backend):
--   psql $env:DB_URL -f sql/08-aulas-resumidas.sql

-- ===================== MATEMÁTICA: Fundamentos de Funções =====================

UPDATE aulas SET conteudo = $aula$Uma função é uma regra que liga dois conjuntos: para cada valor de entrada, ela devolve exatamente uma saída.

O conjunto dos valores que podem entrar se chama domínio, e o conjunto onde ficam as saídas se chama contradomínio. A mesma entrada sempre gera a mesma saída. Duas entradas diferentes podem ter a mesma saída, mas uma entrada nunca pode ter duas saídas.

Exemplo: em f(x) = 2x + 1, a regra é "multiplique por 2 e some 1". Se a entrada for 3, a saída é f(3) = 7. Pense em uma máquina de suco: colocou laranja, sai sempre suco de laranja.$aula$
WHERE trilha_id = (SELECT id FROM trilhas WHERE nome = 'Fundamentos de Funções') AND ordem = 1;

UPDATE aulas SET conteudo = $aula$Toda função trabalha com três conjuntos: domínio, contradomínio e imagem.

O domínio é o conjunto dos valores que podem entrar na função. O contradomínio é o conjunto onde as saídas podem estar. A imagem é só a parte do contradomínio formada pelas saídas que realmente acontecem. Por isso, a imagem fica dentro do contradomínio, mas pode ser menor que ele.

Exemplo: em f(x) = x², com x real, qualquer número pode entrar. Mas um número ao quadrado nunca é negativo, então a imagem contém apenas os números maiores ou iguais a zero.$aula$
WHERE trilha_id = (SELECT id FROM trilhas WHERE nome = 'Fundamentos de Funções') AND ordem = 2;

UPDATE aulas SET conteudo = $aula$O gráfico é o desenho de uma função no plano cartesiano.

O plano tem dois eixos: o eixo x, na horizontal, para as entradas, e o eixo y, na vertical, para as saídas. Cada par de entrada e saída vira um ponto (x, f(x)). Na função do 1º grau, f(x) = ax + b, os pontos formam uma reta: o coeficiente a define a inclinação, e o número b é onde a reta corta o eixo y.

Exemplo: em f(x) = 2x + 1, os pontos (0, 1), (1, 3) e (2, 5) formam uma reta que sobe, porque o coeficiente 2 é positivo.$aula$
WHERE trilha_id = (SELECT id FROM trilhas WHERE nome = 'Fundamentos de Funções') AND ordem = 3;

-- ===================== HISTÓRIA: Revolução Industrial =====================

UPDATE aulas SET conteudo = $aula$A Revolução Industrial mudou a forma de produzir: o trabalho feito à mão passou a ser feito por máquinas.

Ela começou na Inglaterra, por volta de 1760. Antes, os artesãos produziam pouco, em casa ou em pequenas oficinas. Com a máquina a vapor, movida a carvão, a produção passou para as fábricas, com muitos trabalhadores e cada um cuidando de uma só etapa.

Exemplo: no setor de tecidos, uma única máquina de fiar fazia o trabalho de várias pessoas. A produção aumentou muito, os produtos ficaram mais baratos e o trabalhador passou a receber salário.$aula$
WHERE trilha_id = (SELECT id FROM trilhas WHERE nome = 'Revolução Industrial') AND ordem = 1;

UPDATE aulas SET conteudo = $aula$As fábricas mudaram a vida dos trabalhadores e das cidades, e nem sempre para melhor.

Muitas famílias saíram do campo, e as cidades cresceram rápido, sem moradia, água limpa nem esgoto. Nas fábricas, o operário enfrentava jornada de até 16 horas, salário baixo e nenhum direito. Mulheres e crianças também trabalhavam, e ganhavam ainda menos.

Exemplo de reação: os operários criaram sindicatos, associações para defender seus interesses, e fizeram greves. Com essa pressão, surgiram leis que limitaram a jornada e o trabalho infantil, origem de muitos direitos que existem hoje.$aula$
WHERE trilha_id = (SELECT id FROM trilhas WHERE nome = 'Revolução Industrial') AND ordem = 2;

UPDATE aulas SET conteudo = $aula$A industrialização trouxe mudanças econômicas, sociais e ambientais.

Na economia, a produção e o comércio cresceram, e o transporte ficou mais rápido com trens e navios a vapor. Na sociedade, surgiram dois grupos principais: a burguesia, dona das fábricas, e o proletariado, os operários que vendiam sua força de trabalho. A riqueza cresceu, mas a desigualdade entre eles também.

Exemplo de consequência ambiental: a queima de carvão encheu as cidades de fumaça. Essa poluição continua hoje, pois queimar carvão e petróleo é uma das causas do aquecimento global.$aula$
WHERE trilha_id = (SELECT id FROM trilhas WHERE nome = 'Revolução Industrial') AND ordem = 3;

-- ===================== GEOGRAFIA: Clima e Tempo =====================

UPDATE aulas SET conteudo = $aula$Tempo e clima parecem a mesma coisa, mas na Geografia são ideias diferentes.

Tempo é o estado da atmosfera em um lugar e em um momento: se chove, se faz sol, qual é a temperatura agora. Ele muda rápido. Clima é o padrão do tempo de uma região, descoberto depois de observar a atmosfera por muitos anos, em geral 30. Por isso o clima muda devagar.

Exemplo: "hoje está frio e chuvoso em Manaus" fala do tempo. "Manaus é quente e úmida o ano todo" fala do clima. Um dia frio não muda o clima da cidade.$aula$
WHERE trilha_id = (SELECT id FROM trilhas WHERE nome = 'Clima e Tempo') AND ordem = 1;

UPDATE aulas SET conteudo = $aula$O clima de cada lugar depende de alguns fatores. Os principais são a latitude, a altitude e a distância do mar.

Latitude é a distância até a linha do Equador: quanto mais perto, mais quente, porque o Sol chega mais direto. Altitude é a altura em relação ao mar: quanto mais alto, mais frio. A maritimidade é a influência do mar, que deixa a temperatura do litoral mais estável; longe dele, a diferença entre o dia e a noite é maior.

Exemplo: Quito fica perto do Equador, mas a quase 3.000 metros de altitude, por isso não é quente.$aula$
WHERE trilha_id = (SELECT id FROM trilhas WHERE nome = 'Clima e Tempo') AND ordem = 2;

UPDATE aulas SET conteudo = $aula$O Brasil é muito extenso e, por isso, tem vários climas.

O equatorial, na Amazônia, é quente e com chuva o ano todo. O tropical, no centro do país, tem verão chuvoso e inverno seco. O semiárido, no sertão nordestino, é quente e com pouca chuva, o que causa longas secas. O subtropical, no Sul, tem as temperaturas mais baixas e as estações mais marcadas.

Exemplo: o Sul é mais frio porque fica mais longe do Equador. Já a Amazônia é úmida por causa da floresta e dos muitos rios da região.$aula$
WHERE trilha_id = (SELECT id FROM trilhas WHERE nome = 'Clima e Tempo') AND ordem = 3;
