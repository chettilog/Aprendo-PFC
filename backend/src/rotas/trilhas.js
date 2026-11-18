// Conteúdo: trilhas e aulas (RF04 e RF05)
const express = require('express');
const { erroInterno } = require('../utils/erros');
const pool = require('../config/banco');
const { verificarToken } = require('../middlewares/autenticacao');
const { idValido } = require('../utils/validacoes');

const router = express.Router();

// Lista as trilhas ativas, com a quantidade de aulas de cada uma
router.get('/trilhas', verificarToken, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT t.id, t.nome, t.materia, t.descricao, COUNT(a.id)::int AS total_aulas
       FROM trilhas t
       LEFT JOIN aulas a ON a.trilha_id = t.id
       WHERE t.ativa = true
       GROUP BY t.id
       ORDER BY t.materia, t.nome`
    );
    res.json({ trilhas: result.rows });
  } catch (err) {
    erroInterno(res, err, 'Erro ao listar trilhas');
  }
});

// Lista as aulas de uma trilha ativa, na ordem definida (sem o conteúdo).
// "concluida" = o aluno já tem uma produção suficiente nessa aula;
//               o app usa isso para liberar a próxima aula do caminho.
// "parcial" = ainda não concluiu, mas já acertou parte (ganhou metade do XP).
// "melhor_nota" = maior nota (0 a 100) que o aluno já tirou na aula, ou null.
router.get('/trilhas/:id/aulas', verificarToken, async (req, res) => {
  const { id } = req.params;
  if (!idValido(id)) {
    return res.status(400).json({ error: 'Identificador de trilha inválido' });
  }

  try {
    const trilha = await pool.query(
      'SELECT id, nome, materia FROM trilhas WHERE id = $1 AND ativa = true',
      [id]
    );
    if (trilha.rows.length === 0) {
      return res.status(404).json({ error: 'Trilha não encontrada' });
    }

    const aulas = await pool.query(
      `SELECT a.id, a.titulo, a.ordem, a.nivel,
              EXISTS (
                SELECT 1 FROM producoes p
                JOIN feedbacks f ON f.producao_id = p.id
                WHERE p.aula_id = a.id AND p.usuario_id = $2
                  AND f.resultado = 'suficiente'
              ) AS concluida,
              EXISTS (
                SELECT 1 FROM producoes p
                JOIN feedbacks f ON f.producao_id = p.id
                WHERE p.aula_id = a.id AND p.usuario_id = $2
                  AND f.resultado = 'parcial'
              ) AS tem_parcial,
              (
                SELECT MAX(f.nota) FROM producoes p
                JOIN feedbacks f ON f.producao_id = p.id
                WHERE p.aula_id = a.id AND p.usuario_id = $2
              )::int AS melhor_nota
       FROM aulas a
       WHERE a.trilha_id = $1
       ORDER BY a.ordem`,
      [id, req.usuario.id]
    );

    const lista = aulas.rows.map(({ tem_parcial, ...aula }) => ({
      ...aula,
      parcial: !aula.concluida && Boolean(tem_parcial),
    }));
    res.json({ trilha: trilha.rows[0], aulas: lista });
  } catch (err) {
    erroInterno(res, err, 'Erro ao listar aulas');
  }
});

// Exibe o conteúdo de uma aula (somente de trilhas ativas).
// A aula só abre se o aluno já concluiu todas as anteriores da trilha
// (liberação sequencial, que também libera o nível 2 depois do nível 1).
router.get('/aulas/:id', verificarToken, async (req, res) => {
  const { id } = req.params;
  if (!idValido(id)) {
    return res.status(400).json({ error: 'Identificador de aula inválido' });
  }

  try {
    const result = await pool.query(
      `SELECT a.id, a.trilha_id, a.titulo, a.conteudo, a.ordem, a.nivel, t.nome AS trilha_nome,
              NOT EXISTS (
                SELECT 1 FROM aulas anterior
                WHERE anterior.trilha_id = a.trilha_id AND anterior.ordem < a.ordem
                  AND NOT EXISTS (
                    SELECT 1 FROM producoes p
                    JOIN feedbacks f ON f.producao_id = p.id
                    WHERE p.aula_id = anterior.id AND p.usuario_id = $2
                      AND f.resultado = 'suficiente'
                  )
              ) AS liberada
       FROM aulas a
       JOIN trilhas t ON t.id = a.trilha_id
       WHERE a.id = $1 AND t.ativa = true`,
      [id, req.usuario.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Aula não encontrada' });
    }
    const { liberada, ...aula } = result.rows[0];
    if (liberada === false) {
      return res.status(403).json({ error: 'Conclua as aulas anteriores para liberar esta aula' });
    }
    res.json({ aula });
  } catch (err) {
    erroInterno(res, err, 'Erro ao buscar aula');
  }
});

module.exports = router;
