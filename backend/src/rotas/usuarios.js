// Dados da própria conta: ver e editar o perfil (RF15) e excluir a conta (RF21 e LGPD)
const express = require('express');
const bcrypt = require('bcrypt');
const pool = require('../config/banco');
const { verificarToken } = require('../middlewares/autenticacao');
const { registrarLog, removerEmailDosLogs } = require('../servicos/logs');
const { validarNome, validarSenha, validarAvatar } = require('../utils/validacoes');

const router = express.Router();

// Retorna os dados do usuário logado
router.get('/perfil', verificarToken, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, nome, email, perfil, avatar, criado_em FROM usuarios WHERE id = $1',
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

// Edição do perfil (RF15): o usuário troca o próprio nome.
// O e-mail não é editável, porque é o dado de acesso à conta.
router.put('/perfil', verificarToken, async (req, res) => {
  const nome = (req.body || {}).nome;
  const erro = validarNome(nome);
  if (erro) {
    return res.status(400).json({ error: erro });
  }

  try {
    const result = await pool.query(
      `UPDATE usuarios SET nome = $1 WHERE id = $2
       RETURNING id, nome, email, perfil, avatar, criado_em`,
      [nome.trim(), req.usuario.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Usuário não encontrado' });
    }

    await registrarLog(req.usuario.id, 'edicao_perfil', 'Nome alterado pelo próprio titular', req.ip, true);
    res.json({ message: 'Perfil atualizado com sucesso!', usuario: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao atualizar perfil', detalhes: err.message });
  }
});

// Troca do avatar (RF15): o aluno escolhe um dos ícones prontos do app.
// Não há envio de foto, para não guardar imagem do rosto de alunos menores de idade.
router.put('/perfil/avatar', verificarToken, async (req, res) => {
  const avatar = (req.body || {}).avatar;
  const erro = validarAvatar(avatar);
  if (erro) {
    return res.status(400).json({ error: erro });
  }
  try {
    const result = await pool.query(
      'UPDATE usuarios SET avatar = $1 WHERE id = $2 RETURNING avatar',
      [avatar, req.usuario.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Usuário não encontrado' });
    }
    await registrarLog(req.usuario.id, 'edicao_avatar', 'Avatar alterado pelo próprio titular', req.ip, true);
    res.json({ message: 'Avatar atualizado!', avatar: result.rows[0].avatar });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao atualizar o avatar', detalhes: err.message });
  }
});

// Troca de senha (RF15): exige a senha atual, para que ninguém troque a senha
// usando apenas um token esquecido aberto em outro aparelho
router.put('/perfil/senha', verificarToken, async (req, res) => {
  const { senhaAtual, novaSenha } = req.body || {};
  if (typeof senhaAtual !== 'string' || senhaAtual.length === 0) {
    return res.status(400).json({ error: 'Informe a senha atual' });
  }
  const erro = validarSenha(novaSenha);
  if (erro) {
    return res.status(400).json({ error: erro });
  }
  if (novaSenha === senhaAtual) {
    return res.status(400).json({ error: 'A nova senha deve ser diferente da atual' });
  }

  try {
    const busca = await pool.query('SELECT senha FROM usuarios WHERE id = $1', [req.usuario.id]);
    if (busca.rows.length === 0) {
      return res.status(404).json({ error: 'Usuário não encontrado' });
    }

    const confere = await bcrypt.compare(senhaAtual, busca.rows[0].senha);
    if (!confere) {
      await registrarLog(req.usuario.id, 'troca_senha_falha', 'Senha atual incorreta', req.ip, false);
      // 400, e não 401: o usuário continua logado, só errou a senha atual
      return res.status(400).json({ error: 'A senha atual está incorreta' });
    }

    const novoHash = await bcrypt.hash(novaSenha, 10);
    await pool.query('UPDATE usuarios SET senha = $1 WHERE id = $2', [novoHash, req.usuario.id]);
    await registrarLog(req.usuario.id, 'troca_senha', 'Senha alterada pelo próprio titular', req.ip, true);

    res.json({ message: 'Senha alterada com sucesso!' });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao alterar a senha', detalhes: err.message });
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
