// Recuperação de senha por código enviado ao e-mail
// 1. POST /senha/esqueci   { email }                      -> envia um código de 6 dígitos
// 2. POST /senha/redefinir { email, codigo, novaSenha }   -> troca a senha se o código conferir
const express = require('express');
const crypto = require('crypto');
const bcrypt = require('bcrypt');
const pool = require('../config/banco');
const { erroInterno } = require('../utils/erros');
const { validarSenha } = require('../utils/validacoes');
const { registrarLog, mascararEmail } = require('../servicos/logs');
const { enviarEmail } = require('../servicos/email');
const { limites } = require('../middlewares/limites');

const router = express.Router();

const VALIDADE_MINUTOS = 15;
const MAX_TENTATIVAS = 5;

// Resposta sempre igual, exista o e-mail ou não: assim ninguém descobre quem tem conta
const RESPOSTA_PEDIDO = 'Se o e-mail estiver cadastrado, você receberá um código em instantes. Confira também a caixa de spam.';
const CODIGO_INVALIDO = 'Código inválido ou expirado. Peça um novo código.';

// Código de 6 dígitos com gerador criptográfico (Math.random não é seguro para isso)
function gerarCodigo() {
  return String(crypto.randomInt(0, 1000000)).padStart(6, '0');
}

function textoDoEmail(nome, codigo) {
  return `Olá, ${nome.split(' ')[0]}!\n\n`
    + `Seu código para criar uma nova senha no Aprendo é: ${codigo}\n\n`
    + `Ele vale por ${VALIDADE_MINUTOS} minutos e só pode ser usado uma vez.\n`
    + 'Se você não pediu a troca de senha, ignore este e-mail: sua senha continua a mesma.\n\n'
    + 'Equipe Aprendo';
}

function emailDoCorpo(req) {
  return typeof req.body?.email === 'string' ? req.body.email.trim() : '';
}

router.post('/senha/esqueci', limites.recuperacaoPorIp, limites.recuperacaoPorEmail, async (req, res) => {
  const email = emailDoCorpo(req);
  if (!email) {
    return res.status(400).json({ error: 'Informe o e-mail da conta' });
  }
  try {
    const busca = await pool.query('SELECT id, nome, email FROM usuarios WHERE lower(email) = lower($1)', [email]);
    if (busca.rows.length === 0) {
      await registrarLog(null, 'recuperacao_sem_conta', `Pedido para e-mail sem conta: ${mascararEmail(email)}`, req.ip, false);
      return res.json({ message: RESPOSTA_PEDIDO });
    }

    const usuario = busca.rows[0];
    const codigo = gerarCodigo();
    const hash = await bcrypt.hash(codigo, 10);

    // Um pedido novo cancela os códigos anteriores que ainda não foram usados
    await pool.query(
      'UPDATE recuperacoes_senha SET usado_em = now() WHERE usuario_id = $1 AND usado_em IS NULL',
      [usuario.id]
    );
    await pool.query(
      `INSERT INTO recuperacoes_senha (usuario_id, codigo_hash, expira_em)
       VALUES ($1, $2, now() + make_interval(mins => $3))`,
      [usuario.id, hash, VALIDADE_MINUTOS]
    );
    await registrarLog(usuario.id, 'recuperacao_pedida', 'Código de recuperação de senha solicitado', req.ip, true);

    // O envio não é esperado: a resposta sai no mesmo tempo, com conta ou sem conta
    enviarEmail({ para: usuario.email, assunto: 'Aprendo: código para criar uma nova senha', texto: textoDoEmail(usuario.nome, codigo) })
      .then(enviado => {
        if (!enviado) registrarLog(usuario.id, 'recuperacao_email_falha', 'Falha no envio do e-mail de recuperação', req.ip, false);
      });

    res.json({ message: RESPOSTA_PEDIDO });
  } catch (err) {
    erroInterno(res, err, 'Erro ao pedir a recuperação de senha');
  }
});

router.post('/senha/redefinir', limites.recuperacaoCodigo, async (req, res) => {
  const email = emailDoCorpo(req);
  const codigo = typeof req.body?.codigo === 'string' ? req.body.codigo.trim() : '';
  const { novaSenha } = req.body || {};

  if (!email || !/^\d{6}$/.test(codigo)) {
    return res.status(400).json({ error: 'Informe o e-mail e o código de 6 dígitos' });
  }
  const erroSenha = validarSenha(novaSenha);
  if (erroSenha) {
    return res.status(400).json({ error: erroSenha });
  }

  try {
    // Pedido mais recente ainda válido: não usado, dentro da validade e com tentativas sobrando
    const busca = await pool.query(
      `SELECT r.id, r.usuario_id, r.codigo_hash, r.tentativas
       FROM recuperacoes_senha r
       JOIN usuarios u ON u.id = r.usuario_id
       WHERE lower(u.email) = lower($1) AND r.usado_em IS NULL AND r.expira_em > now()
       ORDER BY r.criado_em DESC
       LIMIT 1`,
      [email]
    );
    const pedido = busca.rows[0];
    if (!pedido || pedido.tentativas >= MAX_TENTATIVAS) {
      return res.status(400).json({ error: CODIGO_INVALIDO });
    }

    if (!(await bcrypt.compare(codigo, pedido.codigo_hash))) {
      // Conta a tentativa errada; na 5ª, o código deixa de valer
      await pool.query(
        `UPDATE recuperacoes_senha SET tentativas = tentativas + 1,
                usado_em = CASE WHEN tentativas + 1 >= $2 THEN now() ELSE usado_em END
         WHERE id = $1`,
        [pedido.id, MAX_TENTATIVAS]
      );
      await registrarLog(pedido.usuario_id, 'recuperacao_codigo_errado', 'Código de recuperação incorreto', req.ip, false);
      return res.status(400).json({ error: 'Código incorreto. Confira o e-mail e tente de novo.' });
    }

    // Código certo: troca a senha, encerra as sessões abertas e marca o código como usado
    const novoHash = await bcrypt.hash(novaSenha, 10);
    await pool.query('UPDATE usuarios SET senha = $1, senha_alterada_em = $2 WHERE id = $3',
      [novoHash, new Date(), pedido.usuario_id]);
    await pool.query('UPDATE recuperacoes_senha SET usado_em = now() WHERE usuario_id = $1 AND usado_em IS NULL',
      [pedido.usuario_id]);
    await registrarLog(pedido.usuario_id, 'recuperacao_senha', 'Senha redefinida pelo código enviado ao e-mail', req.ip, true);

    res.json({ message: 'Senha alterada! Entre com a nova senha.' });
  } catch (err) {
    erroInterno(res, err, 'Erro ao redefinir a senha');
  }
});

module.exports = router;
module.exports.gerarCodigo = gerarCodigo;
module.exports.textoDoEmail = textoDoEmail;
