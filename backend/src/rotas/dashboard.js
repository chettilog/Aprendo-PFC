// Dashboard do aluno (RF03 e RF13): XP, nível, progresso por trilha, XP dos últimos 7 dias,
// dias seguidos de estudo, últimas explicações e a próxima aula a fazer
const express = require('express');
const pool = require('../config/banco');
const { verificarToken } = require('../middlewares/autenticacao');
const { XP_POR_NIVEL, calcularNivel } = require('../servicos/xp');
const { calcularDiasSeguidos, escolherProximaAula } = require('../servicos/progresso');

const router = express.Router();

// As datas são calculadas no horário de Brasília, para "hoje" ser o dia do aluno
// e não o dia do servidor (que fica em outro fuso horário)
const FUSO = "'America/Sao_Paulo'";
const HOJE = `(NOW() AT TIME ZONE ${FUSO})::date`;

router.get('/dashboard', verificarToken, async (req, res) => {
  const uid = req.usuario.id;
  try {
    // As consultas rodam em paralelo
    const [usuario, xp, producoes, trilhas, semana, diasEstudados, ultimas, aulas] = await Promise.all([
      pool.query('SELECT nome FROM usuarios WHERE id = $1', [uid]),
      pool.query(
        'SELECT COALESCE(SUM(valor), 0)::int AS total FROM movimentacoes_xp WHERE usuario_id = $1',
        [uid]
      ),
      // Total de explicações enviadas e a nota média delas
      pool.query(
        `SELECT COUNT(*)::int AS total, ROUND(AVG(f.nota))::int AS nota_media
         FROM producoes p
         LEFT JOIN feedbacks f ON f.producao_id = p.id
         WHERE p.usuario_id = $1`,
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
      // XP ganho em cada um dos últimos 7 dias (de 6 dias atrás até hoje)
      pool.query(
        `SELECT to_char(${HOJE} - i, 'YYYY-MM-DD') AS dia,
                COALESCE((SELECT SUM(valor) FROM movimentacoes_xp m
                          WHERE m.usuario_id = $1
                            AND (m.criado_em AT TIME ZONE ${FUSO})::date = ${HOJE} - i), 0)::int AS xp
         FROM generate_series(6, 0, -1) AS i`,
        [uid]
      ),
      // Dias em que o aluno acertou pelo menos parte de uma explicação (para os dias seguidos)
      pool.query(
        `SELECT DISTINCT to_char((p.enviada_em AT TIME ZONE ${FUSO})::date, 'YYYY-MM-DD') AS dia_estudado,
                to_char(${HOJE}, 'YYYY-MM-DD') AS hoje
         FROM producoes p
         JOIN feedbacks f ON f.producao_id = p.id
         WHERE p.usuario_id = $1 AND f.resultado IN ('suficiente', 'parcial')
           AND p.enviada_em >= NOW() - INTERVAL '400 days'`,
        [uid]
      ),
      // As 3 explicações mais recentes
      pool.query(
        `SELECT a.id AS aula_id, a.titulo AS aula_titulo, f.nota, f.resultado, p.enviada_em
         FROM producoes p
         JOIN aulas a ON a.id = p.aula_id
         LEFT JOIN feedbacks f ON f.producao_id = p.id
         WHERE p.usuario_id = $1
         ORDER BY p.enviada_em DESC, p.id DESC
         LIMIT 3`,
        [uid]
      ),
      // Todas as aulas das trilhas ativas, para descobrir a próxima a fazer
      pool.query(
        `SELECT a.id, a.titulo, t.id AS trilha_id, t.nome AS trilha_nome,
                EXISTS (
                  SELECT 1 FROM producoes p
                  JOIN feedbacks f ON f.producao_id = p.id
                  WHERE p.aula_id = a.id AND p.usuario_id = $1 AND f.resultado = 'suficiente'
                ) AS concluida
         FROM aulas a
         JOIN trilhas t ON t.id = a.trilha_id
         WHERE t.ativa = true
         ORDER BY t.materia, t.nome, a.ordem`,
        [uid]
      )
    ]);

    const xpTotal = xp.rows[0]?.total ?? 0;
    const listaTrilhas = trilhas.rows.map(t => ({
      ...t,
      percentual: t.total_aulas > 0 ? Math.round((t.aulas_concluidas / t.total_aulas) * 100) : 0
    }));

    const dias = diasEstudados.rows.map(r => r.dia_estudado);
    const hoje = diasEstudados.rows[0]?.hoje;

    res.json({
      dashboard: {
        nome: usuario.rows[0]?.nome ?? null,
        xp_total: xpTotal,
        nivel: calcularNivel(xpTotal),
        xp_no_nivel: xpTotal % XP_POR_NIVEL,
        xp_por_nivel: XP_POR_NIVEL,
        xp_para_proximo_nivel: XP_POR_NIVEL - (xpTotal % XP_POR_NIVEL),
        producoes_enviadas: producoes.rows[0]?.total ?? 0,
        nota_media: producoes.rows[0]?.nota_media ?? null,
        dias_seguidos: hoje ? calcularDiasSeguidos(dias, hoje) : 0,
        aulas_concluidas: listaTrilhas.reduce((soma, t) => soma + t.aulas_concluidas, 0),
        total_aulas: listaTrilhas.reduce((soma, t) => soma + t.total_aulas, 0),
        trilhas: listaTrilhas,
        xp_ultimos_7_dias: semana.rows,
        ultimas_producoes: ultimas.rows,
        proxima_aula: escolherProximaAula(aulas.rows)
      }
    });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao carregar o dashboard', detalhes: err.message });
  }
});

module.exports = router;
