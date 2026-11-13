// Rotas de verificação: a API está no ar? O banco responde?
const express = require('express');
const pool = require('../config/banco');

const router = express.Router();

// Rota de teste simples
router.get('/', (req, res) => {
  res.json({ message: 'API do Aprendo está funcionando!' });
});

// Rota de teste do banco
router.get('/test-db', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.json({ message: 'Conexão com o banco funcionando!', horario: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao conectar com o banco', detalhes: err.message });
  }
});

module.exports = router;
