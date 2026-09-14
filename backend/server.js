// Importa o Express, o framework que gerencia nossas rotas
const express = require('express');

// Importa o CORS, que permite o frontend Flutter conversar com essa API
const cors = require('cors');

// Carrega variáveis de ambiente do arquivo .env (vamos criar ele já já)
require('dotenv').config();

// Cria a aplicação Express
const app = express();

// Middleware: permite que o servidor entenda requisições com corpo em JSON
app.use(express.json());

// Middleware: libera o acesso de outras origens (o Flutter Web, por exemplo)
app.use(cors());

// Define a porta que o servidor vai escutar (usa a do .env, ou 3000 como padrão)
const PORT = process.env.PORT || 3000;

// Rota de teste simples, só pra confirmar que o servidor está no ar
app.get('/', (req, res) => {
  res.json({ message: 'API do Aprendo está funcionando!' });
});

const pool = require('./db');

// Rota de teste: verifica se a conexão com o banco está funcionando
app.get('/test-db', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.json({ message: 'Conexão com o banco funcionando!', horario: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao conectar com o banco', detalhes: err.message });
  }
});
const bcrypt = require('bcrypt');

// Rota de cadastro de usuário
app.post('/cadastro', async (req, res) => {
  try {
    const { nome, email, senha } = req.body;

    if (!nome || !email || !senha) {
      return res.status(400).json({ error: 'Nome, e-mail e senha são obrigatórios' });
    }

    // Criptografa a senha antes de salvar (nunca salvamos senha em texto puro)
    const senhaCriptografada = await bcrypt.hash(senha, 10);

    const result = await pool.query(
      'INSERT INTO usuarios (nome, email, senha) VALUES ($1, $2, $3) RETURNING id, nome, email',
      [nome, email, senhaCriptografada]
    );

    res.status(201).json({ message: 'Usuário cadastrado com sucesso!', usuario: result.rows[0] });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Este e-mail já está cadastrado' });
    }
    res.status(500).json({ error: 'Erro ao cadastrar usuário', detalhes: err.message });
  }
});

// Inicia o servidor
app.listen(PORT, () => {
  console.log(`Servidor rodando em http://localhost:${PORT}`);
});