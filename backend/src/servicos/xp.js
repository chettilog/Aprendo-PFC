// Regras de XP e nível (RF08)
const XP_POR_AULA = 50;     // XP na primeira produção suficiente de cada aula
const XP_POR_NIVEL = 100;   // XP necessário para subir de nível

// Nível 1 vai de 0 a 99 XP, nível 2 de 100 a 199 XP, e assim por diante
function calcularNivel(xpTotal) {
  return Math.floor(xpTotal / XP_POR_NIVEL) + 1;
}

module.exports = { XP_POR_AULA, XP_POR_NIVEL, calcularNivel };
