// Cadastro e login (RF01 e RF02)
const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../config/banco');
const { registrarLog, mascararEmail } = require('../servicos/logs');
const { validarCadastro } = require('../utils/validacoes');

const router = express.Router();

// Versão atual dos documentos aceitos (Termos 1.1 + Política 1.2; atualizar quando mudarem)
const VERSAO_TERMOS = '1.2';

// Cadastro de usuário
router.post('/cadastro', async (req, res) => {
  try {
    const { senha, aceitouTermos, idadeMinima } = req.body || {};
    const nome = typeof req.body?.nome === 'string' ? req.body.nome.trim() : '';
    const email = typeof req.body?.email === 'string' ? req.body.email.trim() : '';

    const erroValidacao = validarCadastro(nome, email, senha);
    if (erroValidacao) {
      return res.status(400).json({ error: erroValidacao });
    }

    // Validação LGPD: exige aceite explícito dos termos antes de criar conta
    if (!aceitouTermos) {
      return res.status(400).json({
        error: 'É necessário aceitar os Termos de Uso e a Política de Privacidade'
      });
    }

    // Validação LGPD (Art. 14): a idade mínima da plataforma é 12 anos.
    // Guardamos só a declaração, não a data de nascimento (minimização de dados).
    if (idadeMinima !== true) {
      return res.status(400).json({
        error: 'É necessário declarar que você tem 12 anos ou mais'
      });
    }

    // A senha nunca é guardada como texto: o bcrypt gera um hash irreversível
    const senhaCriptografada = await bcrypt.hash(senha, 10);

    const result = await pool.query(
      `INSERT INTO usuarios (nome, email, senha, termos_aceitos_em, termos_versao)
       VALUES ($1, $2, $3, NOW(), $4)
       RETURNING id, nome, email, termos_aceitos_em, termos_versao`,
      [nome, email, senhaCriptografada, VERSAO_TERMOS]
    );

    await registrarLog(
      result.rows[0].id,
      'cadastro',
      `Novo usuário (termos v${VERSAO_TERMOS}, declarou ter 12 anos ou mais)`,
      req.ip,
      true
    );

    res.status(201).json({
      message: 'Usuário cadastrado com sucesso!',
      usuario: result.rows[0]
    });
  } catch (err) {
    // 23505 = violação de UNIQUE (e-mail já existe)
    if (err.code === '23505') {
      await registrarLog(
        null,
        'cadastro_falha',
        `E-mail já cadastrado: ${mascararEmail(req.body.email)}`,
        req.ip,
        false
      );
      return res.status(409).json({ error: 'Este e-mail já está cadastrado' });
    }
    res.status(500).json({ error: 'Erro ao cadastrar usuário', detalhes: err.message });
  }
});

// Login: confere e-mail e senha e devolve um token JWT válido por 2 horas
router.post('/login', async (req, res) => {
  try {
    const { email, senha } = req.body || {};

    if (!email || !senha) {
      return res.status(400).json({ error: 'E-mail e senha são obrigatórios' });
    }

    const result = await pool.query(
      'SELECT id, nome, email, senha FROM usuarios WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      // Registra tentativa de login com e-mail inexistente
      // O e-mail digitado é gravado mascarado (ex.: j***@email.com), nunca por extenso
      await registrarLog(null, 'login_falha', `E-mail não cadastrado: ${mascararEmail(email)}`, req.ip, false);
      // Mensagem genérica: não revela se o e-mail existe
      return res.status(401).json({ error: 'E-mail ou senha inválidos' });
    }

    const usuario = result.rows[0];
    const senhaCorreta = await bcrypt.compare(senha, usuario.senha);

    if (!senhaCorreta) {
      await registrarLog(usuario.id, 'login_falha', 'Senha incorreta', req.ip, false);
      return res.status(401).json({ error: 'E-mail ou senha inválidos' });
    }

    // O token leva só o id do usuário: nenhum dado pessoal fica guardado no navegador
    const token = jwt.sign(
      { id: usuario.id },
      process.env.JWT_SECRET,
      { expiresIn: '2h' }
    );

    await registrarLog(usuario.id, 'login', 'Login realizado', req.ip, true);

    res.json({
      message: 'Login realizado com sucesso!',
      token: token,
      usuario: {
        id: usuario.id,
        nome: usuario.nome,
        email: usuario.email,
      },
    });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao realizar login', detalhes: err.message });
  }
});

module.exports = router;
