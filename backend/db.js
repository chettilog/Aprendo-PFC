// Importa o módulo Pool do pacote 'pg', que gerencia conexões com o PostgreSQL
const { Pool } = require('pg');
require('dotenv').config();

// Cria um "pool" de conexões usando os dados do .env
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

// Exporta o pool para que outros arquivos (como as rotas) possam usá-lo
module.exports = pool;