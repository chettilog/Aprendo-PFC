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

// Inicia o servidor
app.listen(PORT, () => {
  console.log(`Servidor rodando em http://localhost:${PORT}`);
});