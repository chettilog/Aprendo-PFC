// Rotas exclusivas do administrador
const express = require('express');
const pool = require('../config/banco');
const { verificarToken, exigirPerfil } = require('../middlewares/autenticacao');
const { registrarLog } = require('../servicos/logs');

const router = express.Router();

// Retorna os 100 logs de auditoria mais recentes.
// Com ?falhas=true, traz só as ações que não deram certo (login errado, acesso negado...).
// A própria consulta também é registrada: quem audita também fica auditado.
router.get('/logs', verificarToken, exigirPerfil('admin'), async (req, res) => {
  const apenasFalhas = req.query.falhas === 'true';
  try {
    const result = await pool.query(
      `SELECT l.id, l.usuario_id, u.nome as usuario_nome, l.acao, l.detalhes,
              l.ip, l.sucesso, l.criado_em
       FROM logs l
       LEFT JOIN usuarios u ON u.id = l.usuario_id
       ${apenasFalhas ? 'WHERE l.sucesso = false' : ''}
       ORDER BY l.criado_em DESC
       LIMIT 100`
    );

    await registrarLog(
      req.usuario.id,
      'consulta_logs',
      apenasFalhas ? 'Administrador consultou os logs (só falhas)' : 'Administrador consultou os logs',
      req.ip,
      true
    );
    res.json({ logs: result.rows });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao buscar logs', detalhes: err.message });
  }
});

// Visão geral da plataforma para o administrador.
// Só números somados: nenhum nome, e-mail ou texto de aluno sai nesta rota.
// Contam apenas as explicações de alunos (testes feitos por contas admin ficam de fora).
const DE_ALUNOS = `FROM feedbacks f
  JOIN producoes p ON p.id = f.producao_id
  JOIN usuarios u ON u.id = p.usuario_id AND u.perfil = 'aluno'`;

router.get('/admin/visao-geral', verificarToken, exigirPerfil('admin'), async (req, res) => {
  try {
    const [alunos, producoes, resultados, avaliadores, aulas] = await Promise.all([
      pool.query(
        `SELECT COUNT(*)::int AS total,
                COUNT(*) FILTER (WHERE criado_em >= now() - interval '7 days')::int AS novos_7_dias,
                (SELECT COUNT(DISTINCT p.usuario_id) FROM producoes p
                 JOIN usuarios u2 ON u2.id = p.usuario_id AND u2.perfil = 'aluno'
                 WHERE p.enviada_em >= now() - interval '7 days')::int AS ativos_7_dias
         FROM usuarios WHERE perfil = 'aluno'`
      ),
      pool.query(
        `SELECT COUNT(*)::int AS total,
                COUNT(*) FILTER (WHERE p.enviada_em >= now() - interval '7 days')::int AS ultimos_7_dias,
                ROUND(AVG(f.nota))::int AS nota_media
         FROM producoes p
         JOIN usuarios u ON u.id = p.usuario_id AND u.perfil = 'aluno'
         LEFT JOIN feedbacks f ON f.producao_id = p.id`
      ),
      pool.query(`SELECT f.resultado, COUNT(*)::int AS total ${DE_ALUNOS} GROUP BY f.resultado`),
      pool.query(`SELECT f.avaliador, COUNT(*)::int AS total ${DE_ALUNOS} GROUP BY f.avaliador`),
      // Aulas em que os alunos mais têm dificuldade (menor nota média), com pelo menos 1 envio
      pool.query(
        `SELECT a.id, a.titulo, t.nome AS trilha_nome, COUNT(f.id)::int AS tentativas,
                ROUND(AVG(f.nota))::int AS nota_media,
                ROUND(100.0 * COUNT(*) FILTER (WHERE f.resultado = 'suficiente') / COUNT(f.id))::int AS taxa_acerto
         FROM aulas a
         JOIN trilhas t ON t.id = a.trilha_id
         JOIN producoes p ON p.aula_id = a.id
         JOIN usuarios u ON u.id = p.usuario_id AND u.perfil = 'aluno'
         JOIN feedbacks f ON f.producao_id = p.id
         GROUP BY a.id, a.titulo, t.nome
         ORDER BY nota_media ASC, tentativas DESC
         LIMIT 5`
      ),
    ]);

    const contar = (linhas, campo, chaves) =>
      Object.fromEntries(chaves.map(k => [k, linhas.find(l => l[campo] === k)?.total ?? 0]));

    res.json({
      visao_geral: {
        alunos: alunos.rows[0],
        producoes: producoes.rows[0],
        resultados: contar(resultados.rows, 'resultado', ['suficiente', 'parcial', 'insuficiente']),
        avaliadores: contar(avaliadores.rows, 'avaliador', ['ia', 'regras', 'filtro']),
        aulas_mais_dificeis: aulas.rows,
      },
    });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao carregar a visão geral', detalhes: err.message });
  }
});

module.exports = router;
