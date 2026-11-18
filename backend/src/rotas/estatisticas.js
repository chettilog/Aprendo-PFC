// Dashboard de estatísticas do aluno (aba "Dashboard" do app)
// Reúne indicadores e os dados dos gráficos: XP por dia, distribuição dos resultados,
// melhor nota por aula, média dos critérios da rubrica e desempenho por matéria.
// Todos os números são só do próprio aluno.
const express = require('express');
const { erroInterno } = require('../utils/erros');
const pool = require('../config/banco');
const { verificarToken } = require('../middlewares/autenticacao');
const { XP_POR_NIVEL, calcularNivel } = require('../servicos/xp');
const { calcularDiasSeguidos } = require('../servicos/progresso');

const router = express.Router();

const FUSO = "'America/Sao_Paulo'";
const HOJE = `(NOW() AT TIME ZONE ${FUSO})::date`;
const DIAS_DO_GRAFICO = 30;

// Porcentagem arredondada; 0 quando não há total
function percentual(parte, total) {
  return total > 0 ? Math.round((parte / total) * 100) : 0;
}

router.get('/estatisticas', verificarToken, async (req, res) => {
  const uid = req.usuario.id;
  try {
    const [xp, resultados, xpPorDia, aulas, criterios, diasEstudados] = await Promise.all([
      pool.query(
        'SELECT COALESCE(SUM(valor), 0)::int AS total FROM movimentacoes_xp WHERE usuario_id = $1',
        [uid]
      ),
      // Quantas explicações tiveram cada resultado, e a nota média geral
      pool.query(
        `SELECT COUNT(*)::int AS total,
                COUNT(*) FILTER (WHERE f.resultado = 'suficiente')::int AS suficiente,
                COUNT(*) FILTER (WHERE f.resultado = 'parcial')::int AS parcial,
                COUNT(*) FILTER (WHERE f.resultado = 'insuficiente')::int AS insuficiente,
                ROUND(AVG(f.nota))::int AS nota_media
         FROM producoes p
         JOIN feedbacks f ON f.producao_id = p.id
         WHERE p.usuario_id = $1`,
        [uid]
      ),
      // XP ganho em cada um dos últimos 30 dias (horário de Brasília)
      pool.query(
        `SELECT to_char(${HOJE} - i, 'YYYY-MM-DD') AS dia,
                COALESCE((SELECT SUM(valor) FROM movimentacoes_xp m
                          WHERE m.usuario_id = $1
                            AND (m.criado_em AT TIME ZONE ${FUSO})::date = ${HOJE} - i), 0)::int AS xp
         FROM generate_series(${DIAS_DO_GRAFICO - 1}, 0, -1) AS i`,
        [uid]
      ),
      // Todas as aulas ativas, com a melhor nota, o número de tentativas e se foi concluída
      pool.query(
        `SELECT a.id AS aula_id, a.titulo, a.ordem, t.id AS trilha_id, t.nome AS trilha_nome, t.materia,
                MAX(f.nota)::int AS melhor_nota,
                COUNT(p.id)::int AS tentativas,
                COALESCE(BOOL_OR(f.resultado = 'suficiente'), false) AS concluida,
                COALESCE((SELECT SUM(m.valor) FROM movimentacoes_xp m
                          WHERE m.usuario_id = $1 AND m.aula_id = a.id), 0)::int AS xp
         FROM aulas a
         JOIN trilhas t ON t.id = a.trilha_id
         LEFT JOIN producoes p ON p.aula_id = a.id AND p.usuario_id = $1
         LEFT JOIN feedbacks f ON f.producao_id = p.id
         WHERE t.ativa = true
         GROUP BY a.id, t.id
         ORDER BY t.materia, t.nome, a.ordem`,
        [uid]
      ),
      // Média de cada critério da rubrica, nas explicações corrigidas pela IA
      pool.query(
        `SELECT COUNT(*)::int AS avaliadas,
                ROUND(AVG((f.criterios->>'conceito')::numeric))::int AS conceito,
                ROUND(AVG((f.criterios->>'completude')::numeric))::int AS completude,
                ROUND(AVG((f.criterios->>'clareza')::numeric))::int AS clareza
         FROM producoes p
         JOIN feedbacks f ON f.producao_id = p.id
         WHERE p.usuario_id = $1 AND f.criterios IS NOT NULL`,
        [uid]
      ),
      pool.query(
        `SELECT DISTINCT to_char((p.enviada_em AT TIME ZONE ${FUSO})::date, 'YYYY-MM-DD') AS dia_estudado,
                to_char(${HOJE}, 'YYYY-MM-DD') AS hoje
         FROM producoes p
         JOIN feedbacks f ON f.producao_id = p.id
         WHERE p.usuario_id = $1 AND f.resultado IN ('suficiente', 'parcial')
           AND p.enviada_em >= NOW() - INTERVAL '400 days'`,
        [uid]
      ),
    ]);

    const xpTotal = xp.rows[0]?.total ?? 0;
    const r = resultados.rows[0] || {};
    const totalProducoes = r.total ?? 0;
    const listaAulas = aulas.rows;

    // XP acumulado ao longo dos 30 dias, partindo do XP que o aluno já tinha antes do período
    const xpNoPeriodo = xpPorDia.rows.reduce((soma, d) => soma + d.xp, 0);
    let acumulado = xpTotal - xpNoPeriodo;
    const serieXp = xpPorDia.rows.map(d => {
      acumulado += d.xp;
      return { dia: d.dia, xp: d.xp, acumulado };
    });

    // Desempenho por matéria
    const materias = new Map();
    for (const aula of listaAulas) {
      if (!materias.has(aula.materia)) {
        materias.set(aula.materia, { materia: aula.materia, total_aulas: 0, aulas_concluidas: 0, xp: 0, notas: [] });
      }
      const m = materias.get(aula.materia);
      m.total_aulas += 1;
      if (aula.concluida) m.aulas_concluidas += 1;
      m.xp += aula.xp;
      if (aula.melhor_nota !== null) m.notas.push(aula.melhor_nota);
    }
    const porMateria = [...materias.values()].map(({ notas, ...m }) => ({
      ...m,
      percentual: percentual(m.aulas_concluidas, m.total_aulas),
      nota_media: notas.length ? Math.round(notas.reduce((a, b) => a + b, 0) / notas.length) : null,
    }));

    const c = criterios.rows[0] || {};
    const dias = diasEstudados.rows.map(d => d.dia_estudado);
    const hoje = diasEstudados.rows[0]?.hoje;
    const aulasConcluidas = listaAulas.filter(a => a.concluida).length;

    res.json({
      estatisticas: {
        resumo: {
          xp_total: xpTotal,
          nivel: calcularNivel(xpTotal),
          xp_no_nivel: xpTotal % XP_POR_NIVEL,
          xp_por_nivel: XP_POR_NIVEL,
          aulas_concluidas: aulasConcluidas,
          total_aulas: listaAulas.length,
          producoes_enviadas: totalProducoes,
          nota_media: r.nota_media ?? null,
          taxa_acerto: percentual(r.suficiente ?? 0, totalProducoes),
          dias_seguidos: hoje ? calcularDiasSeguidos(dias, hoje) : 0,
        },
        resultados: {
          suficiente: r.suficiente ?? 0,
          parcial: r.parcial ?? 0,
          insuficiente: r.insuficiente ?? 0,
        },
        xp_por_dia: serieXp,
        notas_por_aula: listaAulas,
        criterios_medios: {
          avaliadas: c.avaliadas ?? 0,
          conceito: c.conceito ?? null,
          completude: c.completude ?? null,
          clareza: c.clareza ?? null,
        },
        por_materia: porMateria,
      },
    });
  } catch (err) {
    erroInterno(res, err, 'Erro ao carregar as estatísticas');
  }
});

module.exports = router;
