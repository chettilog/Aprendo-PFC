// Regras de XP e nível (RF08)
const XP_POR_AULA = 50;     // XP máximo de cada aula (resposta totalmente certa)
const XP_POR_NIVEL = 100;   // XP necessário para subir de nível

// Nível 1 vai de 0 a 99 XP, nível 2 de 100 a 199 XP, e assim por diante
function calcularNivel(xpTotal) {
  return Math.floor(xpTotal / XP_POR_NIVEL) + 1;
}

// Quanto XP a aula vale para cada resultado da avaliação
function xpDoResultado(resultado) {
  if (resultado === 'suficiente') return XP_POR_AULA;              // 50
  if (resultado === 'parcial') return Math.floor(XP_POR_AULA / 2); // 25
  return 0;
}

// XP a ganhar agora: só a diferença entre o que o resultado vale e o que o aluno
// já recebeu nessa aula. Nunca negativo, e a soma da aula nunca passa de 50.
//   Ex.: já tinha 25 (parcial) e agora acertou tudo (50) -> ganha 25.
//   Ex.: já tinha 50 e mandou de novo -> ganha 0.
function xpAGanhar(resultado, xpJaRecebidoNaAula) {
  return Math.max(0, xpDoResultado(resultado) - xpJaRecebidoNaAula);
}

module.exports = { XP_POR_AULA, XP_POR_NIVEL, calcularNivel, xpDoResultado, xpAGanhar };
