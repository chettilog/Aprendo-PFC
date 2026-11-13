// Produção do aluno (RF06): envia a explicação, recebe a avaliação (RF07) e o XP (RF08)
const express = require('express');
const pool = require('../config/banco');
const { verificarToken } = require('../middlewares/autenticacao');
const { idValido, validarProducao } = require('../utils/validacoes');
const { avaliarProducao } = require('../servicos/avaliacao');
const { XP_POR_AULA, calcularNivel } = require('../servicos/xp');

const router = express.Router();

// Registra a produção (texto), avalia e atribui XP
router.post('/aulas/:id/producoes', verificarToken, async (req, res) => {
  const { id } = req.params;
  if (!idValido(id)) {
    return res.status(400).json({ error: 'Identificador de aula inválido' });
  }

  const { erro, texto } = validarProducao((req.body || {}).conteudo);
  if (erro) {
    return res.status(400).json({ error: erro });
  }

  let client;
  try {
    const aula = await pool.query(
      `SELECT a.id, a.palavras_chave
       FROM aulas a
       JOIN trilhas t ON t.id = a.trilha_id
       WHERE a.id = $1 AND t.ativa = true`,
      [id]
    );
    if (aula.rows.length === 0) {
      return res.status(404).json({ error: 'Aula não encontrada' });
    }

    const avaliacao = avaliarProducao(texto, aula.rows[0].palavras_chave);

    // Transação: produção, feedback e XP são gravados juntos ou nenhum
    client = await pool.connect();
    await client.query('BEGIN');

    const producao = await client.query(
      `INSERT INTO producoes (usuario_id, aula_id, tipo, conteudo)
       VALUES ($1, $2, 'texto', $3)
       RETURNING id, aula_id, tipo, enviada_em`,
      [req.usuario.id, id, texto]
    );

    await client.query(
      'INSERT INTO feedbacks (producao_id, resultado, comentario) VALUES ($1, $2, $3)',
      [producao.rows[0].id, avaliacao.resultado, avaliacao.comentario]
    );

    let xpGanho = 0;
    if (avaliacao.resultado === 'suficiente') {
      // A mesma aula não gera XP duas vezes (UNIQUE usuario_id + aula_id)
      const xp = await client.query(
        `INSERT INTO movimentacoes_xp (usuario_id, aula_id, valor, motivo)
         VALUES ($1, $2, $3, 'Produção suficiente')
         ON CONFLICT (usuario_id, aula_id) DO NOTHING
         RETURNING valor`,
        [req.usuario.id, id, XP_POR_AULA]
      );
      xpGanho = xp.rows.length > 0 ? xp.rows[0].valor : 0;
    }

    const total = await client.query(
      'SELECT COALESCE(SUM(valor), 0)::int AS total FROM movimentacoes_xp WHERE usuario_id = $1',
      [req.usuario.id]
    );
    await client.query('COMMIT');

    const xpTotal = total.rows[0].total;
    res.status(201).json({
      producao: producao.rows[0],
      feedback: { resultado: avaliacao.resultado, comentario: avaliacao.comentario },
      xp: { ganho: xpGanho, total: xpTotal, nivel: calcularNivel(xpTotal) }
    });
  } catch (err) {
    if (client) await client.query('ROLLBACK').catch(() => {});
    // 23503 = violação de chave estrangeira (ex.: conta já excluída com token ainda válido)
    if (err.code === '23503') {
      return res.status(404).json({ error: 'Usuário ou aula não encontrados' });
    }
    res.status(500).json({ error: 'Erro ao registrar produção', detalhes: err.message });
  } finally {
    if (client) client.release();
  }
});

// Lista as produções do próprio aluno em uma aula (mais recentes primeiro)
router.get('/aulas/:id/producoes', verificarToken, async (req, res) => {
  const { id } = req.params;
  if (!idValido(id)) {
    return res.status(400).json({ error: 'Identificador de aula inválido' });
  }

  try {
    const result = await pool.query(
      `SELECT p.id, p.tipo, p.conteudo, p.enviada_em, f.resultado, f.comentario
       FROM producoes p
       LEFT JOIN feedbacks f ON f.producao_id = p.id
       WHERE p.usuario_id = $1 AND p.aula_id = $2
       ORDER BY p.enviada_em DESC`,
      [req.usuario.id, id]
    );
    res.json({ producoes: result.rows });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao listar produções', detalhes: err.message });
  }
});

module.exports = router;
