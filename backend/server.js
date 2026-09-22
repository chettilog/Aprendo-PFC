// Importa o Express, o framework que gerencia nossas rotas
const express = require('express');
// Importa o CORS, que permite o frontend Flutter conversar com essa API
const cors = require('cors');
// Carrega variáveis de ambiente do arquivo .env
require('dotenv').config();

const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('./db');

// Cria a aplicação Express
const app = express();

// Middleware: permite que o servidor entenda requisições com corpo em JSON
app.use(express.json());
// Middleware: libera o acesso de outras origens (o Flutter Web, por exemplo)
app.use(cors());

// Define a porta que o servidor vai escutar (usa a do .env, ou 3000 como padrão)
const PORT = process.env.PORT || 3000;

// Middleware: valida o token JWT em rotas protegidas
function verificarToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Token não fornecido' });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
    if (err) {
      return res.status(403).json({ error: 'Token inválido ou expirado' });
    }
    req.usuario = decoded;
    next();
  });
}

// Função utilitária: registra um evento na tabela de logs
async function registrarLog(usuarioId, acao, detalhes, ip, sucesso = true) {
  try {
    await pool.query(
      'INSERT INTO logs (usuario_id, acao, detalhes, ip, sucesso) VALUES ($1, $2, $3, $4, $5)',
      [usuarioId, acao, detalhes, ip, sucesso]
    );
  } catch (err) {
    // Se o log falhar, não quebra a aplicação — só imprime no console
    console.error('Erro ao registrar log:', err.message);
  }
}

// Rota de teste simples
app.get('/', (req, res) => {
  res.json({ message: 'API do Aprendo está funcionando!' });
});

// Rota de teste do banco
app.get('/test-db', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.json({ message: 'Conexão com o banco funcionando!', horario: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao conectar com o banco', detalhes: err.message });
  }
});

// Rota de cadastro de usuário
app.post('/cadastro', async (req, res) => {
  try {
    const { nome, email, senha } = req.body;

    if (!nome || !email || !senha) {
      return res.status(400).json({ error: 'Nome, e-mail e senha são obrigatórios' });
    }

    const senhaCriptografada = await bcrypt.hash(senha, 10);

    const result = await pool.query(
      'INSERT INTO usuarios (nome, email, senha) VALUES ($1, $2, $3) RETURNING id, nome, email',
      [nome, email, senhaCriptografada]
    );

        // Registra log de cadastro bem-sucedido
    await registrarLog(
      result.rows[0].id,
      'cadastro',
      `Novo usuário: ${email}`,
      req.ip,
      true
    );

    res.status(201).json({ message: 'Usuário cadastrado com sucesso!', usuario: result.rows[0] });
  } catch (err) {
        if (err.code === '23505') {
      // Registra log de tentativa de cadastro com email já existente
      await registrarLog(
        null,
        'cadastro_falha',
        `Email já cadastrado: ${req.body.email}`,
        req.ip,
        false
      );
      return res.status(409).json({ error: 'Este e-mail já está cadastrado' });
    }
    res.status(500).json({ error: 'Erro ao cadastrar usuário', detalhes: err.message });
  }
});

// Rota de login
app.post('/login', async (req, res) => {
  try {
    const { email, senha } = req.body;

    if (!email || !senha) {
      return res.status(400).json({ error: 'E-mail e senha são obrigatórios' });
    }

    const result = await pool.query(
      'SELECT id, nome, email, senha FROM usuarios WHERE email = $1',
      [email]
    );

        if (result.rows.length === 0) {
      // Registra tentativa de login com email inexistente
      await registrarLog(
        null,
        'login_falha',
        `Email não cadastrado: ${email}`,
        req.ip,
        false
      );
      return res.status(401).json({ error: 'E-mail ou senha inválidos' });
    }

    const usuario = result.rows[0];

    const senhaCorreta = await bcrypt.compare(senha, usuario.senha);

        if (!senhaCorreta) {
      // Registra tentativa de login com senha errada
      await registrarLog(
        usuario.id,
        'login_falha',
        `Senha incorreta`,
        req.ip,
        false
      );
      return res.status(401).json({ error: 'E-mail ou senha inválidos' });
    }

    // Login bem-sucedido: gera um token JWT
    const token = jwt.sign(
      {
        id: usuario.id,
        email: usuario.email,
      },
      process.env.JWT_SECRET,
      { expiresIn: '2h' }
    );

        // Registra log de login bem-sucedido
    await registrarLog(
      usuario.id,
      'login',
      `Login realizado`,
      req.ip,
      true
    );

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

// Rota protegida: retorna os dados do usuário logado
app.get('/perfil', verificarToken, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, nome, email, criado_em FROM usuarios WHERE id = $1',
      [req.usuario.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Usuário não encontrado' });
    }

       // Registra log de acesso ao perfil
    await registrarLog(
      req.usuario.id,
      'acesso_perfil',
      `Consulta ao próprio perfil`,
      req.ip,
      true
    );

    res.json({ usuario: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao buscar perfil', detalhes: err.message });
  }
});

// Rota protegida: retorna os logs de auditoria
app.get('/logs', verificarToken, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT l.id, l.usuario_id, u.nome as usuario_nome, l.acao, l.detalhes, 
              l.ip, l.sucesso, l.criado_em
       FROM logs l
       LEFT JOIN usuarios u ON u.id = l.usuario_id
       ORDER BY l.criado_em DESC
       LIMIT 100`
    );

    res.json({ logs: result.rows });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao buscar logs', detalhes: err.message });
  }
});

// Inicia o servidor
app.listen(PORT, () => {
  console.log(`Servidor rodando em http://localhost:${PORT}`);
});