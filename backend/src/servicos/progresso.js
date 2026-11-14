// Regras do progresso do aluno mostradas no dashboard:
// dias seguidos de estudo e qual é a próxima aula a fazer.

const MS_POR_DIA = 24 * 60 * 60 * 1000;

// "2026-11-14" -> número do dia (contado a partir de 1970).
// Assim dá para comparar datas só somando e subtraindo 1, sem se preocupar com horas.
function numeroDoDia(dia) {
  return Math.round(Date.parse(`${dia}T00:00:00Z`) / MS_POR_DIA);
}

// Conta quantos dias seguidos o aluno estudou, terminando hoje.
//   dias: lista de datas "AAAA-MM-DD" em que ele acertou pelo menos parte de uma explicação
//   hoje: data de hoje "AAAA-MM-DD"
// Se ele ainda não estudou hoje, a sequência continua valendo até ontem
// (só zera quando passa um dia inteiro sem estudar).
function calcularDiasSeguidos(dias, hoje) {
  const estudados = new Set((dias || []).map(numeroDoDia));
  let dia = numeroDoDia(hoje);
  if (!estudados.has(dia)) dia -= 1;

  let seguidos = 0;
  while (estudados.has(dia)) {
    seguidos += 1;
    dia -= 1;
  }
  return seguidos;
}

// Escolhe a aula do botão "Continuar de onde parei".
//   aulas: todas as aulas das trilhas ativas, em ordem (trilha, depois ordem da aula),
//          cada uma com { id, titulo, trilha_id, trilha_nome, concluida }
// Regra: a primeira aula não concluída de uma trilha que o aluno já começou;
// se ele não começou nenhuma, a primeira aula da primeira trilha;
// se já concluiu tudo, null.
function escolherProximaAula(aulas) {
  const porTrilha = new Map();
  for (const aula of aulas || []) {
    if (!porTrilha.has(aula.trilha_id)) porTrilha.set(aula.trilha_id, []);
    porTrilha.get(aula.trilha_id).push(aula);
  }

  let primeiraNaoComecada = null;
  for (const lista of porTrilha.values()) {
    const pendente = lista.find(a => !a.concluida);
    if (!pendente) continue;                       // trilha toda concluída
    if (lista.some(a => a.concluida)) return resumir(pendente); // trilha em andamento
    if (!primeiraNaoComecada) primeiraNaoComecada = pendente;
  }
  return primeiraNaoComecada ? resumir(primeiraNaoComecada) : null;
}

function resumir(aula) {
  return {
    id: aula.id,
    titulo: aula.titulo,
    trilha_id: aula.trilha_id,
    trilha_nome: aula.trilha_nome,
  };
}

module.exports = { calcularDiasSeguidos, escolherProximaAula };
