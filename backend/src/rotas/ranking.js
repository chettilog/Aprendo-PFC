// Ranking entre colegas: o aluno adiciona colegas pelo código (Nome#1234) e compara o XP.
// Ranking geral: os 20 alunos com mais XP, entre os que deixaram ligada a opção de aparecer no ranking.
const express = require('express');
const pool = require('../config/banco');
const { verificarToken } = require('../middlewares/autenticacao');
const { registrarLog } = require('../servicos/logs');
const { calcularNivel } = require('../servicos/xp');
const {
  LIMITE_DE_COLEGAS, TAMANHO_RANKING_GERAL, montarRankingGeral, formatarCodigo, interpretarCodigo, nomeConfere, montarRanking,
} = require('../servicos/ranking');

const router = express.Router();

// Mostra o código do aluno e o ranking entre ele e os colegas que adicionou.
// Colegas que desligaram "aparecer no ranking" não são exibidos.
router.get('/ranking', verificarToken, async (req, res) => {
  const uid = req.usuario.id;
  try {
    const eu = await pool.query(
      'SELECT id, nome, codigo, aparecer_no_ranking FROM usuarios WHERE id = $1',
      [uid]
    );
    if (eu.rows.length === 0) {
      return res.status(404).json({ error: 'Usuário não encontrado' });
    }

    const participantes = await pool.query(
      `SELECT u.id, u.nome, u.codigo, u.avatar,
              COALESCE((SELECT SUM(m.valor) FROM movimentacoes_xp m WHERE m.usuario_id = u.id), 0)::int AS xp_total
       FROM usuarios u
       WHERE u.id = $1
          OR (u.aparecer_no_ranking = true
              AND u.id IN (SELECT c.colega_id FROM colegas c WHERE c.usuario_id = $1))`,
      [uid]
    );

    const ranking = montarRanking(
      participantes.rows.map(p => ({ ...p, nivel: calcularNivel(p.xp_total) })),
      uid
    );

    res.json({
      meu_codigo: formatarCodigo(eu.rows[0].nome, eu.rows[0].codigo),
      aparecer_no_ranking: eu.rows[0].aparecer_no_ranking,
      total_colegas: ranking.length - 1,
      ranking,
    });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao carregar o ranking', detalhes: err.message });
  }
});

// Ranking geral: só alunos (o admin não entra) que deixaram "aparecer no ranking" ligado.
// RANK() dá a mesma posição para quem empata no XP; ROW_NUMBER() corta a lista nos 20 primeiros.
// A linha do próprio aluno sempre volta, para mostrar a posição dele mesmo fora do top 20.
router.get('/ranking/geral', verificarToken, async (req, res) => {
  const uid = req.usuario.id;
  try {
    const eu = await pool.query('SELECT aparecer_no_ranking FROM usuarios WHERE id = $1', [uid]);
    if (eu.rows.length === 0) {
      return res.status(404).json({ error: 'Usuário não encontrado' });
    }

    const resultado = await pool.query(
      `WITH participantes AS (
         SELECT u.id, u.nome, u.avatar,
                COALESCE((SELECT SUM(m.valor) FROM movimentacoes_xp m WHERE m.usuario_id = u.id), 0)::int AS xp_total
         FROM usuarios u
         WHERE u.perfil = 'aluno' AND u.aparecer_no_ranking = true
       ),
       ordenados AS (
         SELECT p.*,
                RANK() OVER (ORDER BY p.xp_total DESC)::int AS posicao,
                ROW_NUMBER() OVER (ORDER BY p.xp_total DESC, p.nome, p.id)::int AS linha,
                COUNT(*) OVER ()::int AS total
         FROM participantes p
       )
       SELECT * FROM ordenados
       WHERE linha <= $2 OR id = $1
       ORDER BY linha`,
      [uid, TAMANHO_RANKING_GERAL]
    );

    res.json({
      aparecer_no_ranking: eu.rows[0].aparecer_no_ranking,
      ...montarRankingGeral(resultado.rows, uid, calcularNivel),
    });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao carregar o ranking geral', detalhes: err.message });
  }
});

// Adiciona um colega pelo código completo (Nome#1234)
router.post('/ranking/colegas', verificarToken, async (req, res) => {
  const uid = req.usuario.id;
  const alvo = interpretarCodigo((req.body || {}).codigo);
  if (!alvo) {
    return res.status(400).json({ error: 'Digite o código no formato Nome#1234' });
  }

  try {
    const busca = await pool.query(
      'SELECT id, nome, codigo FROM usuarios WHERE codigo = $1 AND aparecer_no_ranking = true',
      [alvo.codigo]
    );
    const colega = busca.rows[0];
    // Mesma mensagem quando o código não existe e quando o nome não confere,
    // para não revelar quais códigos estão em uso
    if (!colega || !nomeConfere(alvo.nome, colega.nome)) {
      return res.status(404).json({ error: 'Nenhum aluno encontrado com esse código' });
    }
    if (colega.id === uid) {
      return res.status(400).json({ error: 'Esse é o seu próprio código' });
    }

    const quantos = await pool.query('SELECT COUNT(*)::int AS total FROM colegas WHERE usuario_id = $1', [uid]);
    if (quantos.rows[0].total >= LIMITE_DE_COLEGAS) {
      return res.status(400).json({ error: `Você já tem ${LIMITE_DE_COLEGAS} colegas no ranking` });
    }

    const novo = await pool.query(
      `INSERT INTO colegas (usuario_id, colega_id) VALUES ($1, $2)
       ON CONFLICT (usuario_id, colega_id) DO NOTHING
       RETURNING colega_id`,
      [uid, colega.id]
    );
    if (novo.rows.length === 0) {
      return res.status(409).json({ error: 'Esse colega já está no seu ranking' });
    }

    await registrarLog(uid, 'ranking_adicionar', 'Colega adicionado ao ranking', req.ip, true);
    res.status(201).json({ message: 'Colega adicionado!', colega: formatarCodigo(colega.nome, colega.codigo) });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao adicionar colega', detalhes: err.message });
  }
});

// Remove um colega do ranking (pelo número do código)
router.delete('/ranking/colegas/:codigo', verificarToken, async (req, res) => {
  const { codigo } = req.params;
  if (!/^\d{4}$/.test(codigo)) {
    return res.status(400).json({ error: 'Código inválido' });
  }
  try {
    const removido = await pool.query(
      `DELETE FROM colegas
       WHERE usuario_id = $1 AND colega_id = (SELECT id FROM usuarios WHERE codigo = $2)
       RETURNING colega_id`,
      [req.usuario.id, Number(codigo)]
    );
    if (removido.rows.length === 0) {
      return res.status(404).json({ error: 'Esse colega não está no seu ranking' });
    }
    res.json({ message: 'Colega removido do ranking' });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao remover colega', detalhes: err.message });
  }
});

// Liga ou desliga "aparecer no ranking dos colegas"
router.put('/ranking/visibilidade', verificarToken, async (req, res) => {
  const { aparecer } = req.body || {};
  if (typeof aparecer !== 'boolean') {
    return res.status(400).json({ error: 'Informe se deseja aparecer no ranking (true ou false)' });
  }
  try {
    await pool.query('UPDATE usuarios SET aparecer_no_ranking = $1 WHERE id = $2', [aparecer, req.usuario.id]);
    await registrarLog(
      req.usuario.id,
      'ranking_visibilidade',
      aparecer ? 'Passou a aparecer no ranking' : 'Deixou de aparecer no ranking',
      req.ip,
      true
    );
    res.json({ aparecer_no_ranking: aparecer });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao alterar a visibilidade', detalhes: err.message });
  }
});

module.exports = router;
