// Dados da própria conta: ver perfil e excluir conta (RF03 e LGPD)
const express = require('express');
const pool = require('../config/banco');
const { verificarToken } = require('../middlewares/autenticacao');
const { registrarLog, removerEmailDosLogs } = require('../servicos/logs');

const router = express.Router();

// Retorna os dados do usuário logado
router.get('/perfil', verificarToken, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, nome, email, perfil, criado_em FROM usuarios WHERE id = $1',
      [req.usuario.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Usuário não encontrado' });
    }

    await registrarLog(req.usuario.id, 'acesso_perfil', 'Consulta ao próprio perfil', req.ip, true);

    res.json({ usuario: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao buscar perfil', detalhes: err.message });
  }
});

// Permite o usuário logado excluir a própria conta (LGPD - direito à exclusão)
router.delete('/minha-conta', verificarToken, async (req, res) => {
  try {
    const usuarioId = req.usuario.id;

    // Busca o e-mail antes de apagar, para poder tirá-lo dos logs antigos
    const busca = await pool.query('SELECT email FROM usuarios WHERE id = $1', [usuarioId]);

    if (busca.rows.length === 0) {
      return res.status(404).json({ error: 'Usuário não encontrado' });
    }

    const emailUsuario = busca.rows[0].email;

    // Apaga o usuário. Produções, feedbacks e XP somem junto (ON DELETE CASCADE);
    // os logs ficam para auditoria, mas com usuario_id = NULL (ON DELETE SET NULL)
    await pool.query('DELETE FROM usuarios WHERE id = $1', [usuarioId]);

    // Os logs que sobram não podem mais identificar a pessoa:
    // o e-mail é mascarado nos registros antigos e não entra no registro da exclusão
    await removerEmailDosLogs(emailUsuario);

    await registrarLog(
      null,
      'exclusao_conta',
      'Conta excluída pelo próprio titular',
      req.ip,
      true
    );

    res.json({ message: 'Sua conta foi excluída com sucesso. Sentimos sua falta!' });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao excluir conta', detalhes: err.message });
  }
});

module.exports = router;
