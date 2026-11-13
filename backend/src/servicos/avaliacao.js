// Avaliação da produção do aluno (RF07)
//
// Como a nota é decidida, em 3 etapas:
//   1. Filtro local (preFiltro): barra texto sem sentido, lista de palavras soltas e cópia da aula.
//      Não gasta chamada de IA e não pode ser enganado por "palavra-chave + letras aleatórias".
//   2. IA com rubrica (servicos/ia.js): nota de 0 a 100 somando conceito, completude e clareza.
//   3. Se a IA não estiver configurada ou falhar, usa as regras de palavras-chave (avaliarPorRegras).
//
// A nota vira resultado:  >= 70 suficiente (50 XP)  |  40 a 69 parcial (25 XP)  |  < 40 insuficiente (0 XP)

const { iaConfigurada, avaliarComIA } = require('./ia');

const NOTA_SUFICIENTE = 70;
const NOTA_PARCIAL = 40;

// Palavras muito comuns do português (artigos, preposições, verbos frequentes...).
// Servem para reconhecer frases de verdade e não marcar palavras normais como "estranhas".
const PALAVRAS_COMUNS = new Set(`
a o as os um uma uns umas de do da dos das em no na nos nas por pelo pela pelos pelas para pra pro
com sem sob sobre entre ate apos ante desde contra e ou mas porem nem que se como quando onde
porque pois porque entao logo assim tambem ainda ja so apenas mesmo mesma muito muita muitos muitas
pouco mais menos tanto quanto qual quais cada todo toda todos todas outro outra outros outras
esse essa esses essas este esta estes estas isso isto aquele aquela aquilo ele ela eles elas eu tu
voce voces nos me te lhe seu sua seus suas meu minha nao sim ser e sao era foi sera seja estar esta
estao estava ter tem tinha teve haver ha fazer faz fazendo feito dar da dizer diz pode podem poder
vai vao ir vem vir sai sair entra entrar fica ficar usa usar quer querer deve sempre nunca vez vezes
exemplo tipo coisa coisas forma jeito parte valor valores numero numeros conta resultado igual
diferente outro primeiro segundo terceiro dois tres quatro cinco zero um mesmo qualquer algum alguma
nenhum nenhuma bem mal maior menor antes depois aqui ali la ou seja significa quer dizer chamado
chamada chamamos existe existem precisa cada vale vira tudo nada alguem ninguem acho sei entendi
vc vcs pq q tb tbm msm n eh
`.trim().split(/\s+/));

// Pares de consoantes que existem em palavras do português (ex.: "br" em "abrir", "nt" em "ponto").
// Uma palavra com um par fora desta lista (ex.: "sdk", "qw", "zx") provavelmente foi digitada ao acaso.
const PARES_VALIDOS = new Set(`
bl br bs bt bj bd bm bn bv cl cr ch ct cc cn dr dj dm dv dn fl fr ft gl gr gn gm
lh lt lm lp lc ld lg lf lv lr ls lb ln lq lx lz lj mp mb mn
nh nd nt ns nc ng nq nj nf nv nz nx nr nl nm nn pl pr ps pt pn pc
rr rc rd rg rm rn rp rs rt rv rb rf rl rq rj rz rx
sc ss st sp sm sl sn sq sf sb sd sg sv sj sr sh tr tm tn tl vr xc xp xt
`.trim().split(/\s+/));

// Remove acentos e deixa em minúsculas, para comparar os textos
function normalizar(texto) {
  return texto.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();
}

// Separa o texto em palavras (só letras)
function palavrasDe(texto) {
  return normalizar(texto || '').split(/[^a-z]+/).filter(Boolean);
}

const VOGAIS = /[aeiou]/;

// Uma palavra é "estranha" se parece digitada ao acaso (ex.: "asdkj", "qweqwe", "zzzz")
function palavraEstranha(palavra, vocabulario) {
  if (palavra.length <= 2 || vocabulario.has(palavra)) return false;
  if (!VOGAIS.test(palavra)) return true;              // sem vogal: "sdfg"
  if (/(.)\1\1/.test(palavra)) return true;            // letra repetida 3 vezes: "aaaa"
  if (/[kwy]/.test(palavra)) return true;              // letras raras no português
  if (/q(?!u)/.test(palavra)) return true;             // "q" sem "u" depois: "qwe"
  if (palavra.length > 24) return true;
  for (let i = 0; i < palavra.length - 1; i++) {
    const par = palavra.slice(i, i + 2);
    if (!VOGAIS.test(par[0]) && !VOGAIS.test(par[1]) && !PARES_VALIDOS.has(par)) {
      return true;                                     // par de consoantes impossível: "sdk"
    }
  }
  return false;
}

// Sequências de 4 palavras seguidas, para comparar trechos de texto
function trechos(palavras) {
  const lista = [];
  for (let i = 0; i + 4 <= palavras.length; i++) {
    lista.push(palavras.slice(i, i + 4).join(' '));
  }
  return lista;
}

// Etapa 1: filtro local. Devolve { ok: true } ou { ok: false, motivo, comentario }
function preFiltro(texto, aula = {}) {
  const palavras = palavrasDe(texto);
  const vocabulario = new Set([
    ...PALAVRAS_COMUNS,
    ...palavrasDe(aula.titulo),
    ...palavrasDe(aula.conteudo),
    ...palavrasDe(aula.palavras_chave),
  ]);

  const distintas = new Set(palavras);
  if (distintas.size < 5) {
    return { ok: false, motivo: 'poucas_palavras',
      comentario: 'Escreva uma explicação com frases completas, usando as suas palavras.' };
  }

  const estranhas = palavras.filter(p => palavraEstranha(p, vocabulario));
  if (estranhas.length / palavras.length > 0.2) {
    return { ok: false, motivo: 'sem_sentido',
      comentario: 'Seu texto parece ter palavras sem sentido. Explique o conteúdo com frases de verdade.' };
  }

  const comuns = palavras.filter(p => PALAVRAS_COMUNS.has(p));
  if (comuns.length / palavras.length < 0.15) {
    return { ok: false, motivo: 'lista_de_palavras',
      comentario: 'Parece uma lista de palavras soltas. Explique com frases o que cada ideia significa.' };
  }

  const trechosAluno = trechos(palavras);
  if (trechosAluno.length > 0) {
    const trechosAula = new Set(trechos(palavrasDe(aula.conteudo)));
    const copiados = trechosAluno.filter(t => trechosAula.has(t)).length;
    if (copiados / trechosAluno.length >= 0.5) {
      return { ok: false, motivo: 'copia',
        comentario: 'Seu texto está muito parecido com o da aula. Tente explicar com as suas palavras.' };
    }
  }

  return { ok: true };
}

// Etapa 3 (reserva): nota pela proporção de palavras-chave da aula que o aluno citou
function avaliarPorRegras(texto, palavrasChave) {
  const lista = (palavrasChave || '').split(',').map(p => p.trim()).filter(Boolean);
  if (lista.length === 0) {
    return { nota: NOTA_SUFICIENTE, comentario: 'Produção registrada com sucesso.' };
  }
  const alvo = normalizar(texto);
  const citadas = lista.filter(p => alvo.includes(normalizar(p)));
  const faltantes = lista.filter(p => !citadas.includes(p));
  const nota = Math.round((citadas.length / lista.length) * 100);

  let comentario;
  if (faltantes.length === 0) {
    comentario = `Boa explicação! Você falou de: ${citadas.join(', ')}.`;
  } else if (citadas.length > 0) {
    comentario = `Você falou de ${citadas.join(', ')}. Tente explicar também: ${faltantes.join(', ')}.`;
  } else {
    comentario = `Tente explicar: ${faltantes.join(', ')}.`;
  }
  return { nota, comentario };
}

// Converte a nota (0 a 100) no resultado
function resultadoDaNota(nota) {
  if (nota >= NOTA_SUFICIENTE) return 'suficiente';
  if (nota >= NOTA_PARCIAL) return 'parcial';
  return 'insuficiente';
}

function montarAvaliacao(nota, comentario, avaliador, criterios = null) {
  return {
    nota,
    resultado: resultadoDaNota(nota),
    comentario: comentario.slice(0, 255),
    avaliador,   // 'filtro', 'ia' ou 'regras'
    criterios,   // { conceito, completude, clareza } quando a IA avaliou
  };
}

// Avalia a produção. "aula" precisa de: titulo, conteudo, resposta_referencia, palavras_chave
async function avaliarProducao(texto, aula) {
  const filtro = preFiltro(texto, aula);
  if (!filtro.ok) {
    return montarAvaliacao(0, filtro.comentario, 'filtro');
  }

  if (iaConfigurada()) {
    try {
      const ia = await avaliarComIA(texto, aula);
      return montarAvaliacao(ia.nota, ia.comentario, 'ia', ia.criterios);
    } catch (err) {
      // Sem internet, chave inválida, limite do plano gratuito... o aluno não fica travado
      console.error('IA indisponível, usando avaliação por regras:', err.message);
    }
  }

  const regras = avaliarPorRegras(texto, aula.palavras_chave);
  return montarAvaliacao(regras.nota, regras.comentario, 'regras');
}

module.exports = {
  NOTA_SUFICIENTE,
  NOTA_PARCIAL,
  normalizar,
  palavrasDe,
  palavraEstranha,
  preFiltro,
  avaliarPorRegras,
  resultadoDaNota,
  avaliarProducao,
};
