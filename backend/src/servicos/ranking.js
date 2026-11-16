// Regras do ranking entre colegas
// O aluno é identificado publicamente só pelo primeiro nome e por um código de 4 dígitos,
// no formato "Joao#4821". Nenhum outro dado pessoal aparece no ranking (LGPD).
const { normalizar } = require('./avaliacao');

const LIMITE_DE_COLEGAS = 50;

// "  João Pedro Marchetti " -> "João"
function primeiroNome(nome) {
  return String(nome || '').trim().split(/\s+/)[0] || '';
}

// ("João Pedro", 4821) -> "João#4821"
function formatarCodigo(nome, codigo) {
  return `${primeiroNome(nome)}#${codigo}`;
}

// "Joao#4821" -> { nome: 'joao', codigo: 4821 } (nome sem acento e em minúsculas)
// Devolve null se o texto não estiver no formato Nome#1234
function interpretarCodigo(texto) {
  if (typeof texto !== 'string') return null;
  const partes = texto.trim().match(/^([^#\s]{1,50})\s*#\s*(\d{4})$/);
  if (!partes) return null;
  return { nome: normalizar(partes[1]), codigo: Number(partes[2]) };
}

// O nome digitado precisa bater com o primeiro nome da conta (sem diferenciar acento e maiúsculas).
// Exigir nome + número dificulta achar alunos chutando números.
function nomeConfere(nomeDigitado, nomeDaConta) {
  return normalizar(primeiroNome(nomeDaConta)) === nomeDigitado;
}

// Ordena por XP (empate: por nome) e numera as posições.
// Quem tem o mesmo XP fica na mesma posição.
function montarRanking(participantes, meuId) {
  const ordenados = [...participantes].sort(
    (a, b) => b.xp_total - a.xp_total || primeiroNome(a.nome).localeCompare(primeiroNome(b.nome), 'pt-BR')
  );
  let posicao = 0;
  let xpAnterior = null;
  return ordenados.map((p, indice) => {
    if (p.xp_total !== xpAnterior) {
      posicao = indice + 1;
      xpAnterior = p.xp_total;
    }
    return {
      posicao,
      nome: primeiroNome(p.nome),
      codigo: formatarCodigo(p.nome, p.codigo),
      nivel: p.nivel,
      xp_total: p.xp_total,
      eu: p.id === meuId,
    };
  });
}

module.exports = {
  LIMITE_DE_COLEGAS, primeiroNome, formatarCodigo, interpretarCodigo, nomeConfere, montarRanking,
};
