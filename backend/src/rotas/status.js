// Rotas de verificação: a API está no ar? O banco responde?
const express = require('express');
const { erroInterno } = require('../utils/erros');
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
    erroInterno(res, err, 'Erro ao conectar com o banco');
  }
});

module.exports = router;
