// Serviço de auditoria: registra eventos na tabela de logs (LGPD - rastreabilidade)
// e cuida para que os logs guardem o mínimo possível de dados pessoais.
const pool = require('../config/banco');

const MESES_DE_RETENCAO = 6;                 // prazo do Marco Civil da Internet (Lei 12.965/2014)
const UM_DIA_MS = 24 * 60 * 60 * 1000;

async function registrarLog(usuarioId, acao, detalhes, ip, sucesso = true) {
  try {
    await pool.query(
      'INSERT INTO logs (usuario_id, acao, detalhes, ip, sucesso) VALUES ($1, $2, $3, $4, $5)',
      [usuarioId, acao, detalhes, ip, sucesso]
    );
  } catch (err) {
    // Se o log falhar, não quebra a aplicação — só imprime no console
    console.error('Erro ao registrar log:', err.message);
  }
}

// Esconde o e-mail antes de gravar no log: "joao@email.com" vira "j***@email.com".
// Dá para perceber tentativas repetidas com o mesmo endereço, sem guardar o endereço inteiro.
function mascararEmail(email) {
  if (typeof email !== 'string') return '***';
  const texto = email.trim();
  const arroba = texto.indexOf('@');
  if (arroba < 1 || arroba === texto.length - 1) return '***';
  return `${texto[0]}***${texto.slice(arroba)}`;
}

// Usado na exclusão de conta: troca o e-mail do titular pela versão mascarada
// em qualquer log antigo onde ele ainda apareça por extenso.
async function removerEmailDosLogs(email) {
  try {
    const resultado = await pool.query(
      `UPDATE logs SET detalhes = REPLACE(detalhes, $1, $2)
       WHERE POSITION($1 IN detalhes) > 0`,
      [email, mascararEmail(email)]
    );
    return resultado.rowCount || 0;
  } catch (err) {
    console.error('Erro ao remover e-mail dos logs:', err.message);
    return 0;
  }
}

// Apaga os logs com mais de 6 meses (prazo de guarda do Marco Civil da Internet)
async function apagarLogsAntigos() {
  try {
    const resultado = await pool.query(
      `DELETE FROM logs WHERE criado_em < NOW() - INTERVAL '${MESES_DE_RETENCAO} months'`
    );
    return resultado.rowCount || 0;
  } catch (err) {
    console.error('Erro ao apagar logs antigos:', err.message);
    return 0;
  }
}

// Roda a limpeza quando o servidor liga e depois uma vez por dia
function agendarLimpezaDeLogs() {
  const limpar = async () => {
    const apagados = await apagarLogsAntigos();
    if (apagados > 0) {
      console.log(`Limpeza de logs: ${apagados} registro(s) com mais de ${MESES_DE_RETENCAO} meses apagado(s)`);
    }
  };
  limpar();
  // unref(): esse relógio não impede o servidor de desligar
  return setInterval(limpar, UM_DIA_MS).unref();
}

module.exports = {
  MESES_DE_RETENCAO,
  registrarLog,
  mascararEmail,
  removerEmailDosLogs,
  apagarLogsAntigos,
  agendarLimpezaDeLogs,
};
