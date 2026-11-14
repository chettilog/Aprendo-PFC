\encoding UTF8
-- Entrega 16/11: texto das aulas mais explicado (mesmo nível do ensino médio)
-- Troca apenas o texto que o aluno lê (coluna conteudo). Títulos, palavras-chave,
-- respostas de referência, produções e XP dos alunos continuam como estão.
-- Pode rodar mais de uma vez.
-- Como rodar (na pasta backend):
--   psql $env:DB_URL -f sql/06-aulas-detalhadas.sql

-- ===================== MATEMÁTICA: Fundamentos de Funções =====================

UPDATE aulas SET conteudo = $aula$Uma função é uma regra que liga dois conjuntos: para cada valor que entra, ela devolve exatamente um valor de saída. O conjunto dos valores que podem entrar se chama domínio, e o conjunto onde as saídas ficam se chama contradomínio.

Pense em uma máquina de suco: você coloca uma fruta (a entrada) e sai um suco (a saída). Se colocar laranja, sempre sai suco de laranja. É isso que define uma função: a mesma entrada dá sempre a mesma saída, e nenhuma entrada fica sem resposta.

Na matemática, a regra costuma ser escrita como uma fórmula. Em f(x) = 2x + 1, a regra é "multiplique a entrada por 2 e some 1". Se x = 3, então f(3) = 2 · 3 + 1 = 7. Se x = 0, então f(0) = 1.

Atenção: duas entradas diferentes podem dar a mesma saída, e isso não é problema. Em f(x) = x², tanto 2 quanto -2 dão 4. O que não pode acontecer é uma única entrada ter duas saídas diferentes. Quando isso acontece, a relação não é uma função.$aula$
WHERE trilha_id = (SELECT id FROM trilhas WHERE nome = 'Fundamentos de Funções') AND ordem = 1;

UPDATE aulas SET conteudo = $aula$Toda função trabalha com três conjuntos, e é comum confundir os dois últimos.

O domínio é o conjunto de todos os valores que podem entrar na função. O contradomínio é o conjunto onde as saídas podem estar: ele é escolhido quando a função é definida. A imagem é o conjunto das saídas que realmente aparecem quando a regra é aplicada a todos os valores do domínio. Por isso, a imagem está sempre dentro do contradomínio, mas pode ser menor que ele.

Exemplo: considere f(x) = x², com domínio e contradomínio iguais a todos os números reais. Qualquer número pode entrar, então o domínio são os reais. Mas um número elevado ao quadrado nunca dá resultado negativo. Então a imagem são apenas os números maiores ou iguais a zero, mesmo que o contradomínio inclua os negativos.

Uma comparação: em uma turma, o domínio são os alunos, o contradomínio são todas as notas possíveis (de 0 a 10) e a imagem são só as notas que alguém de fato tirou. Se ninguém tirou 3, o 3 está no contradomínio, mas não está na imagem.

Às vezes o domínio precisa ser limitado. Em f(x) = 1/x, o zero não pode entrar, porque não existe divisão por zero.$aula$
WHERE trilha_id = (SELECT id FROM trilhas WHERE nome = 'Fundamentos de Funções') AND ordem = 2;

UPDATE aulas SET conteudo = $aula$O gráfico é o desenho de uma função. Ele mostra, de uma só vez, o que acontece com a saída quando a entrada muda.

Para construir o gráfico usamos o plano cartesiano, formado por dois eixos: o eixo x (horizontal), onde ficam as entradas, e o eixo y (vertical), onde ficam as saídas. Cada par de entrada e saída vira um ponto (x, f(x)). O gráfico é o conjunto de todos esses pontos.

Exemplo: em f(x) = 2x + 1, se x = 0, a saída é 1, o que dá o ponto (0, 1). Se x = 1, a saída é 3, o que dá o ponto (1, 3). Se x = 2, a saída é 5, o que dá o ponto (2, 5). Ligando os pontos, aparece uma reta. Toda função do 1º grau, do tipo f(x) = ax + b, tem uma reta como gráfico.

Os dois números da fórmula dizem como é a reta. O coeficiente a (aqui, o 2) indica a inclinação: cada vez que x aumenta 1, y aumenta 2. Se a for positivo, a reta sobe; se for negativo, a reta desce. O número b (aqui, o 1) indica o ponto onde a reta corta o eixo y.

Ler um gráfico é fazer o caminho contrário: escolher um valor no eixo x, ir até a linha e ver no eixo y qual é a saída.$aula$
WHERE trilha_id = (SELECT id FROM trilhas WHERE nome = 'Fundamentos de Funções') AND ordem = 3;

-- ===================== HISTÓRIA: Revolução Industrial =====================

UPDATE aulas SET conteudo = $aula$A Revolução Industrial foi uma mudança profunda na forma de produzir mercadorias. Ela começou na Inglaterra, por volta de 1760, e depois se espalhou por outros países.

Antes dela, quase tudo era feito à mão, por artesãos, em casa ou em pequenas oficinas. O artesão era dono das ferramentas, conhecia todas as etapas do trabalho e produzia pouco, no seu próprio ritmo. Com a Revolução Industrial, a produção passou a ser feita por máquinas, dentro de fábricas, com muitos trabalhadores, cada um cuidando de uma só etapa.

A invenção mais importante foi a máquina a vapor, movida pela queima de carvão. Ela fornecia uma força muito maior que a de pessoas ou animais e podia funcionar o dia inteiro. O primeiro setor a mudar foi o de tecidos: uma única máquina de fiar fazia o trabalho de várias pessoas.

Por que na Inglaterra? O país tinha muito carvão e ferro, dinheiro acumulado com o comércio e muita gente que tinha saído do campo e precisava de trabalho.

O resultado foi produzir muito mais, em menos tempo e por um preço menor. Em troca, o trabalho mudou de lugar e de dono: saiu das casas e foi para as fábricas, e o trabalhador deixou de ser dono das ferramentas e passou a receber salário.$aula$
WHERE trilha_id = (SELECT id FROM trilhas WHERE nome = 'Revolução Industrial') AND ordem = 1;

UPDATE aulas SET conteudo = $aula$Com as fábricas, o trabalho e a vida nas cidades mudaram muito, e nem sempre para melhor.

Muitas famílias deixaram o campo para trabalhar nas fábricas. As cidades cresceram rápido demais e sem planejamento: faltavam moradia, água limpa e esgoto, e as doenças se espalhavam com facilidade nos bairros dos operários.

Dentro das fábricas, as condições eram duras. A jornada chegava a 14 ou 16 horas por dia, os salários eram baixos e não havia férias, descanso pago nem proteção contra acidentes. Mulheres e crianças também trabalhavam, e recebiam ainda menos que os homens. O ritmo era ditado pela máquina e pelo relógio, e não mais pelo trabalhador.

Diante disso, os operários começaram a se organizar. No início, alguns grupos chegaram a quebrar máquinas, por acreditar que elas tiravam empregos. Depois, os trabalhadores formaram sindicatos, que são associações criadas para defender os seus interesses, e passaram a fazer greves, parando o trabalho para pressionar os patrões.

Aos poucos, essa pressão deu resultado: surgiram leis que limitaram a jornada, restringiram o trabalho de crianças e melhoraram a segurança. Muitos direitos dos trabalhadores de hoje nasceram dessas lutas.$aula$
WHERE trilha_id = (SELECT id FROM trilhas WHERE nome = 'Revolução Industrial') AND ordem = 2;

UPDATE aulas SET conteudo = $aula$A industrialização mudou o mundo de várias formas, com resultados bons e ruins. Dá para organizar as consequências em três grupos.

Econômicas: a produção de mercadorias cresceu como nunca, e os preços caíram. Os transportes ficaram muito mais rápidos com os trens e os navios a vapor, o que facilitou o comércio entre regiões distantes. Os países industrializados passaram a buscar matérias-primas e novos compradores em outros continentes.

Sociais: a sociedade passou a se dividir em dois grupos principais. De um lado ficou a burguesia, formada pelos donos das fábricas, das máquinas e do dinheiro. Do outro ficou o proletariado, formado pelos operários, que tinham apenas a própria força de trabalho para oferecer em troca de salário. A riqueza cresceu, mas ficou concentrada nas mãos da burguesia, e a desigualdade entre os dois grupos aumentou.

Ambientais: a queima de carvão encheu as cidades de fumaça e trouxe poluição para o ar e para os rios. Esse problema continua até hoje: a queima de combustíveis como o carvão e o petróleo é uma das principais causas do aquecimento global.

Muito do mundo atual vem desse período: o trabalho em troca de salário, as grandes cidades, a produção em grande quantidade e também os problemas ambientais.$aula$
WHERE trilha_id = (SELECT id FROM trilhas WHERE nome = 'Revolução Industrial') AND ordem = 3;

-- ===================== GEOGRAFIA: Clima e Tempo =====================

UPDATE aulas SET conteudo = $aula$No dia a dia, usamos "tempo" e "clima" como se fossem a mesma coisa, mas na Geografia são ideias diferentes.

Tempo é o estado da atmosfera em um lugar e em um momento. Ele descreve o que está acontecendo agora ou nas próximas horas: se chove, se faz sol, se venta, qual é a temperatura. O tempo muda rápido: pode amanhecer com sol e chover à tarde. É o que a previsão do tempo informa.

Clima é o padrão do tempo de uma região, descoberto depois de observar a atmosfera por muitos anos, em geral 30. Ele diz o que é normal esperar em cada época do ano. Por isso o clima muda devagar.

Exemplo: dizer "hoje está frio e chuvoso em Manaus" é falar do tempo. Dizer "Manaus é quente e úmida o ano todo" é falar do clima. Um dia frio em Manaus não muda o clima da cidade, porque o clima é o que acontece na maioria dos anos.

Uma comparação ajuda: o tempo é como o seu humor em um dia, e o clima é como a sua personalidade. Um dia de mau humor não muda quem você é.

Essa diferença é importante para entender as mudanças climáticas. Um único dia muito quente ou muito frio é tempo. A mudança do padrão ao longo de décadas é que é mudança do clima.$aula$
WHERE trilha_id = (SELECT id FROM trilhas WHERE nome = 'Clima e Tempo') AND ordem = 1;

UPDATE aulas SET conteudo = $aula$Por que uma cidade é quente e outra é fria? O clima de cada lugar depende de alguns fatores. Os três principais são a latitude, a altitude e a distância do mar.

Latitude é a distância de um lugar até a linha do Equador. Perto do Equador, os raios do Sol chegam mais diretos o ano todo, e por isso faz mais calor. Quanto mais longe do Equador, em direção aos polos, mais inclinados chegam os raios e mais frio é o clima. É por isso que Belém é mais quente que Porto Alegre.

Altitude é a altura de um lugar em relação ao nível do mar. Quanto mais alto, mais frio: a temperatura cai, em média, cerca de 6 °C a cada 1.000 metros de subida. Isso explica por que Campos do Jordão, que fica na serra, é bem mais fria que cidades próximas em regiões baixas.

Maritimidade é a influência do mar. A água demora para esquentar e demora para esfriar, e por isso deixa a temperatura das cidades do litoral mais estável. Longe do mar acontece o contrário, a continentalidade: a terra esquenta rápido de dia e esfria rápido à noite, e a diferença de temperatura entre o dia e a noite é maior.

Esses fatores agem juntos. Uma cidade pode estar perto do Equador e mesmo assim não ser quente, se ficar em uma altitude muito grande. É o caso de Quito, capital do Equador, que fica a quase 3.000 metros de altura.$aula$
WHERE trilha_id = (SELECT id FROM trilhas WHERE nome = 'Clima e Tempo') AND ordem = 2;

UPDATE aulas SET conteudo = $aula$O Brasil é um país muito extenso e, por isso, tem vários climas. A maior parte do território fica entre a linha do Equador e o Trópico de Capricórnio, o que explica por que o país é, em geral, quente. Quatro dos principais climas ajudam a entender o mapa.

Equatorial: ocorre na Amazônia. É quente e chuvoso o ano todo, quase sem diferença entre as estações. O calor e a umidade constantes sustentam a floresta.

Tropical: ocorre em grande parte do centro do país. Tem duas estações bem marcadas: o verão é quente e chuvoso, e o inverno é seco. É o clima do Cerrado.

Semiárido: ocorre no sertão nordestino. É quente, com pouca chuva e mal distribuída ao longo do ano, o que causa longos períodos de seca. É o clima da Caatinga.

Subtropical: ocorre no Sul. Tem as temperaturas mais baixas do país, chuva bem distribuída durante o ano e as estações mais definidas. No inverno pode haver geada.

Essas diferenças vêm dos fatores do clima. O Sul é mais frio porque está mais longe do Equador (latitude). A Amazônia é úmida por causa da floresta e da grande quantidade de rios. E o sertão recebe pouca chuva porque o ar úmido chega fraco à região.

O clima influencia a vida em cada lugar: a vegetação, o que se planta e até o tipo de moradia.$aula$
WHERE trilha_id = (SELECT id FROM trilhas WHERE nome = 'Clima e Tempo') AND ordem = 3;
