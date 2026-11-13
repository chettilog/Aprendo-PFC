// Serviço de auditoria: registra eventos na tabela de logs (LGPD - rastreabilidade)
const pool = require('../config/banco');

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

module.exports = { registrarLog };
