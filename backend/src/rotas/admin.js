// Rotas exclusivas do administrador
const express = require('express');
const pool = require('../config/banco');
const { verificarToken, exigirPerfil } = require('../middlewares/autenticacao');

const router = express.Router();

// Retorna os 100 logs de auditoria mais recentes
router.get('/logs', verificarToken, exigirPerfil('admin'), async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT l.id, l.usuario_id, u.nome as usuario_nome, l.acao, l.detalhes,
              l.ip, l.sucesso, l.criado_em
       FROM logs l
       LEFT JOIN usuarios u ON u.id = l.usuario_id
       ORDER BY l.criado_em DESC
       LIMIT 100`
    );

    res.json({ logs: result.rows });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao buscar logs', detalhes: err.message });
  }
});

module.exports = router;
