// Dashboard do aluno (RF03 e RF13): XP, nível, progresso por trilha e XP dos últimos 7 dias
const express = require('express');
const pool = require('../config/banco');
const { verificarToken } = require('../middlewares/autenticacao');
const { XP_POR_NIVEL, calcularNivel } = require('../servicos/xp');

const router = express.Router();

router.get('/dashboard', verificarToken, async (req, res) => {
  const uid = req.usuario.id;
  try {
    // As 4 consultas rodam em paralelo
    const [xp, producoes, trilhas, semana] = await Promise.all([
      pool.query(
        'SELECT COALESCE(SUM(valor), 0)::int AS total FROM movimentacoes_xp WHERE usuario_id = $1',
        [uid]
      ),
      pool.query(
        'SELECT COUNT(*)::int AS total FROM producoes WHERE usuario_id = $1',
        [uid]
      ),
      // Uma aula conta como concluída após uma produção suficiente (RN01 do RF13)
      pool.query(
        `SELECT t.id, t.nome, t.materia,
                COUNT(a.id)::int AS total_aulas,
                COUNT(DISTINCT c.aula_id)::int AS aulas_concluidas
         FROM trilhas t
         LEFT JOIN aulas a ON a.trilha_id = t.id
         LEFT JOIN (
           SELECT DISTINCT p.aula_id
           FROM producoes p
           JOIN feedbacks f ON f.producao_id = p.id
           WHERE p.usuario_id = $1 AND f.resultado = 'suficiente'
         ) c ON c.aula_id = a.id
         WHERE t.ativa = true
         GROUP BY t.id
         ORDER BY t.materia, t.nome`,
        [uid]
      ),
      pool.query(
        `SELECT to_char(CURRENT_DATE - i, 'YYYY-MM-DD') AS dia,
                COALESCE((SELECT SUM(valor) FROM movimentacoes_xp
                          WHERE usuario_id = $1 AND criado_em::date = CURRENT_DATE - i), 0)::int AS xp
         FROM generate_series(6, 0, -1) AS i`,
        [uid]
      )
    ]);

    const xpTotal = xp.rows[0].total;
    const listaTrilhas = trilhas.rows.map(t => ({
      ...t,
      percentual: t.total_aulas > 0 ? Math.round((t.aulas_concluidas / t.total_aulas) * 100) : 0
    }));

    res.json({
      dashboard: {
        xp_total: xpTotal,
        nivel: calcularNivel(xpTotal),
        xp_no_nivel: xpTotal % XP_POR_NIVEL,
        xp_por_nivel: XP_POR_NIVEL,
        producoes_enviadas: producoes.rows[0].total,
        aulas_concluidas: listaTrilhas.reduce((soma, t) => soma + t.aulas_concluidas, 0),
        total_aulas: listaTrilhas.reduce((soma, t) => soma + t.total_aulas, 0),
        trilhas: listaTrilhas,
        xp_ultimos_7_dias: semana.rows
      }
    });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao carregar o dashboard', detalhes: err.message });
  }
});

module.exports = router;
